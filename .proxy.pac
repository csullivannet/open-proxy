function FindProxyForURL(url, host) {
    // If it matches DOMAIN, use the VPN
    // Otherwise, go direct
    if ( shExpMatch(host, "*.domain.com") ) {
        return "PROXY 192.168.96.2:3128";
    } else if ( shExpMatch(host, "*.domain.net") ) { 
        return "PROXY 192.168.96.2:3128";
    } else if ( shExpMatch(host, "*.domain.ca") ) { 
        return "PROXY 192.168.96.2:3128";
    } else if ( shExpMatch(host, "*.domain.org") ) {
        return "PROXY 192.168.96.2:3128";
    } else {
        return "DIRECT";
    }
}
