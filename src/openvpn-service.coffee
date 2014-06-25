StormService = require('stormservice')


class OpenvpnService extends StormService

    schema :
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


    userSchema:
        name: "openvpn"
        type: "object"
        additionalProperties: true
        properties:
            id:    { type: "string", required: false}
            email: { type: "string", required: false}
            cname: { type: "string", required: false}
            push:
                items: { type: "string" }


    invocation:
        name: 'openvpn'
        path: '/usr/bin'
        monitor: false
        args: []
        options:
            detached: true
            stdio: ["ignore", -1, -1]

    constructor: (id, data, opts) ->
        if data.instance?
            @instance = data.instance
            delete data.instance

        config = require('./package.json').config
        opts ?= {}
        opts.configPath ?= config.configPath
        opts.logPath ?= config.logPath

        super id, data, opts

        @configs =
            service:    filename:"#{@configPath}/#{@id}/server.conf"

        @invocation = merge @invocation,
            args: [ "--config_file=#{@configs.serivce.filename}" ]
            options: { stdio: ["ignore", @out, @err] }

        @configs.service.generator = (callback) =>
            vpnconfig = ''
            for key, val of @data
                switch (typeof val)
                    when "object"
                        if val instanceof Array
                            for i in val
                                vpnconfig += "#{key} #{i}\n" if key is "route"
                                vpnconfig += "#{key} \"#{i}\"\n" if key is "push"
                    when "number", "string"
                        vpnconfig += key + ' ' + val + "\n"
                    when "boolean"
                        vpnconfig += key + "\n"
            callback vpnconfig

    destructor: ->
        @eliminate()
        @out.close()
        @err.close()
        @emit 'destroy'

module.exports = OpenvpnService







