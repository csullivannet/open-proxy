# open-proxy
A collection of docker containers to control connecting to a Cisco Anyconnect VPN

## Overview
This service is not quite ready for public distribution.
It was originally designed for use with my client's Anyconnect VPN, and has not been modularized for general use.
Much work remains to be done with `vpn.sh` to help control set up and management of the VPN service. As well, more testing needs to be done for reliability and robustness of the tool.

This service was built and designed with Fedora 25+ in mind and may not (ever) work anywhere else.

## Manual updates necessary:
```.proxy.pac - domains
etc/squid/squid.conf - DNS
etc/bind-local/named.conf - DNS + domains
etc/bind-proxy/named.conf - DNS + domains
etc/openconnect/openconnect.conf - general configuration
etc/ssh/* - your ssh keys
docker-compose.yml - VPN Endpoint```
