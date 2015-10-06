schema_server =
    name: "openvpn"
    type: "object"
    additionalProperties: true
    properties:
        id:                 {"type":"string", "required":false}
        port:                {"type":"number", "required":true}
        dev:                 {"type":"string", "required":true}
        proto:               {"type":"string", "required":true}
        ca:                  {"type":"string", "required":true}
        dh:                  {"type":"string", "required":true}
        cert:                {"type":"string", "required":true}
        key:                 {"type":"string", "required":true}
        server:              {"type":"string", "required":true}
        'ifconfig-pool-persist': {"type":"string", "required":false}
        'script-security':   {"type":"string", "required":false}
        multihome:           {"type":"boolean", "required":false}
        management:          {"type":"string", "required":false}
        cipher:              {"type":"string", "required":false}
        'tls-cipher':        {"type":"string", "required":false}
        auth:                {"type":"string", "required":false}
        topology:            {"type":"string", "required":false}
        'route-gateway':     {"type":"string", "required":false}
        'client-config-dir': {"type":"string", "required":false}
        'ccd-exclusive':     {"type":"boolean", "required":false}
        'client-to-client':  {"type":"boolean", "required":false}
        route:
            items: { type: "string" }
        push:
            items: { type: "string" }
        'tls-timeout':       {"type":"number", "required":false}
        'max-clients':       {"type":"number", "required":false}
        'persist-key':       {"type":"boolean", "required":false}
        'persist-tun':       {"type":"boolean", "required":false}
        status:              {"type":"string", "required":false}
        keepalive:           {"type":"string", "required":false}
        'comp-lzo':          {"type":"string", "required":false}
        sndbuf:              {"type":"number", "required":false}
        rcvbuf:              {"type":"number", "required":false}
        txqueuelen:          {"type":"number", "required":false}
        'replay-window':     {"type":"string", "required":false}
        'duplicate-cn':      {"type":"boolean", "required":false}
        'log-append':        {"type":"string", "required":false}
        verb:                {"type":"number", "required":false}
        mlock:               {"type":"boolean", "required":false}
        'tun-mtu':           {"type":"number", "required":false}
        mssfix:              {"type":"string", "required":false}
        certificates:
            items:
                #encoding: {"type":"string", "required":true}
                name: {"type":"string", "required":true}
                data: {"type":"string", "required":true}
                

schema_client =
    name: "openvpn"
    type: "object"
    additionalProperties: true
    properties:
        id:                  {"type":"string", "required":false}
        pull:                {"type":"boolean", "required":true}
        'tls-client':        {"type":"boolean", "required":true}
        dev:                 {"type":"string", "required":true}
        proto:               {"type":"string", "required":false}
        ca:                  {"type":"string", "required":true}
        dh:                  {"type":"string", "required":false}
        cert:                {"type":"string", "required":true}
        key:                 {"type":"string", "required":true}
        remote:              {"type":"string", "required":true}
        cipher:              {"type":"string", "required":false}
        'tls-cipher':        {"type":"string", "required":false}
        'remote-random':     {"type":"boolean", "required":false}
        'resolv-retry':      {"type":"string", "required":false}
        ping:                {"type":"number", "required":false}
        'ping-restart':      {"type":"number", "required":false}
        log:                 {"type":"string", "required":false}
        route:
            items: { type: "string" }
        push:
            items: { type: "string" }
        'persist-key':       {"type":"boolean", "required":false}
        'persist-tun':       {"type":"boolean", "required":false}
        status:              {"type":"string", "required":false}
        'comp-lzo':          {"type":"string", "required":false}
        verb:                {"type":"number", "required":false}
        mlock:               {"type":"boolean", "required":false}
        certificates:
            items:
                #encoding: {"type":"string", "required":true}
                name: {"type":"string", "required":true}
                data: {"type":"string", "required":true}                
schema_user = 
    name: "openvpn"
    type: "object"
    additionalProperties: true
    properties:
        id:      { type: "string", required: true}
        email:   { type: "string", required: true}
        cname:   { type: "string", required: true}
        ccdPath: { type: "string", required: true}
        push:
            items: { type: "string" }

module.exports.user = schema_user
module.exports.server = schema_server
module.exports.client = schema_client       