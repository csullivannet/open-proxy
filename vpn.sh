#!/bin/bash
#
# This script is used to manage a proxy environment to DOMAIN
# using openconnect, squid, bind, and sshd provided by
# docker containers.

# Run this script as root
#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root"
#   exit 1
#fi
# Placeholder for function to check for elevated privileges
elevate_priv(){
    if [[ $EUID -ne 0 ]]; then
        echo $@
        sudo "$0" "$@"
        exit $?
    fi
}

# Manipulating /etc/resolv.conf can require SELINUX context
# We will check to see if it is enabled and if so react accordingly
# TODO: This does not always work reliably and needs more attention
#       Because of this, switching resolvers has been disabled.
SELINUX_STATUS=$(getenforce)
selinux_resolv(){
    elevate_priv $@
    if [ $SELINUX_STATUS = "Enforcing" -o $SELINUX_STATUS = "Permissive" ]; then
        restorecon -v /etc/resolv.conf
        echo "Selinux context on resolv.conf restored."
    fi
}

# Tell the current session to use the proxy:
set_proxy(){
    export http_proxy="http://192.168.96.2:3128"
    export HTTP_PROXY="http://192.168.96.2:3128"
    export https_proxy="https://192.168.96.2:3128"
    export HTTPS_PROXY="https://192.168.96.2:3128"
}

case "$1" in
    install)
        elevate_priv $@

        if [ -d "/opt/open-proxy" ]; then
            echo "Install directory already exists. Please remove and try again."
        else
            echo "This will install the Dockerized Proxy Service."
            echo "---------------------------------------------------------------------"
            echo "Script dependencies: "
            echo "Docker 17.06 +"
            echo "Docker Compose 1.16.1 +"
            echo "Python 2.7+"
            echo "ssh-keygen"
            echo "---------------------------------------------------------------------"
            echo "The container network will be mapped to 192.168.96.0/24, confirm that"
            echo "there are no conflicts with this subnet before installing."
            echo "---------------------------------------------------------------------"
            echo "This script will attempt to automatically elevate privileges where"
            echo "necessary, you may be prompted for your credentials."
            echo "---------------------------------------------------------------------"
            echo "This script comes without warranty and is used at your own risk!"
            echo "Do you wish to proceed? (yes/no)"

            i=0
            CONTINUE=false

            while [ $i -ne 1 ] || [ ! $CONTINUE = "yes" ]; do
                read CONTINUE

                if [ $CONTINUE = "no" ]; then
                    echo "Quitting."
                    exit 1
                elif [ $i -le 0 ] && [ $CONTINUE != "yes" ]; then
                    echo "Please enter \"yes\" or \"no\":"
                    let i+=1
                elif [ $CONTINUE = "yes" ]; then
                    echo "Installing..."
                    break
                else
                    echo "An explicit \"yes\" is required to continue."
                    exit 1
                fi
            done

            mkdir -p /opt
            tar -xf open-proxy.tgz -C /opt

            echo "You can now start the proxy using $0 start."
            echo "A .proxy_pac is available for use at /opt/open-proxy/.proxy_pac"
            echo "The Chrome extension Proxy Switcher & Manager by yorkis.dev is recommended."
        fi
        ;;

    start)
        elevate_priv $@ 

        echo "Username:"
        read READ_USER
        READ_USER=vn0ecgy
        echo "Password:"
        read -s READ_PASSWORD
        echo "RSA Token:"
        read READ_TOKEN

        export USER=$READ_USER
        export PASSWORD=$READ_PASSWORD  
        export TOKEN=$READ_TOKEN

        echo $USER
        echo $TOKEN
        docker-compose -f /opt/open-proxy/docker-compose.yml up -d

        if [ ! -z ~/.proxy.pac ]; then
            cp /opt/open-proxy/.proxy.pac ~/.proxy.pac
        fi
        
        # Don't switch resolvers 
        #if [ ! -f ~/.resolv.conf.bak ]; then
        #    cp /etc/resolv.conf ~/.resolv.conf.bak
        #    echo "nameserver 192.168.96.3" > /etc/resolv.conf
        #    selinux_resolv
        #fi 
        ;;

    stop)
        elevate_priv $@

        docker update --restart=no sshd squid bind-proxy bind-local openconnect
        docker stop sshd squid bind-proxy bind-local openconnect

        # Don't switch resolvers
        #mv ~/.resolv.conf.bak /etc/resolv.conf 2> /dev/null
        #selinux_resolv
        ;;
        
    restart)
        case "$2" in
        "")
            $0 stop
            sleep 5
            $0 start
            ;;

        vpn)
            elevate_priv $@

            docker update --restart=no openconnect
            docker stop openconnect
            docker-compose -f /opt/open-proxy/docker-compose.yml up -d openconnect
            ;;

        esac
        ;;

    http)
        case "$2" in
        enable)
            export http_proxy="http://192.168.96.2:3128"
            export HTTP_PROXY="http://192.168.96.2:3128"
            export https_proxy="https://192.168.96.2:3128"
            export HTTPS_PROXY="https://192.168.96.2:3128"
            ;;

        disable)
            export http_proxy=""
            export HTTP_PROXY=""
            export https_proxy=""
            export HTTPS_PROXY=""
            ;;

        esac
        ;;

    proxy-docker)
        elevate_priv $@

        case $2 in
        enable)
            if [ -d /etc/systemd/system ]; then
                mkdir -p /etc/systemd/system/docker.service.d
                cp /opt/open-proxy/etc/docker/http-proxy.conf /etc/systemd/system/docker.service.d/
                systemctl daemon-reload
                systemctl restart docker
            else
                echo "Your system does not use systemd."
            fi
            ;;

        disable)
            if [ -d /etc/systemd/system/docker.service.d ]; then
                rm -f /etc/systemd/system/docker.service.d/http-proxy.conf
                systemctl daemon-reload
                systemctl restart docker
            else
                echo "Your system does not use systemd."
            fi
            ;;

        esac
        ;;

    *)
        echo "Usage: $0 {install|start|stop|restart|http|proxy-docker|hosts|help|*}"
        echo "       install: installs the Dockerized Proxy Service."
        echo "       start: starts the proxy environment. This will replace your /etc/resolv.conf"
        echo "       stop: stops the proxy environment. This will restore your /etc/resolv.conf"
        echo "       restart: restarts the proxy environment."
        echo "       restart vpn: restarts openconnect."
        echo "       proxy-docker enable: tells the docker daemon to use the Dockerized squid proxy."
        echo "       proxy-docker disable: tells the docker daemon not to use any proxy."
        echo "       help | *: any other command will display this message."
        ;;

esac
