StormService = require('stormservice')
merge = require('fmerge')
fs = require 'fs'

class OpenvpnClientService extends StormService

    schema :
        name: "openvpn"
        type: "object"
        additionalProperties: true
        properties:
            id:                  {"type":"string", "required":false}
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


    invocation:
        name: 'openvpn'
        path: '/usr/sbin'
        monitor: true
        args: []
        options:
            detached: true
            stdio: ["ignore", -1, -1]

    constructor: (id, data, opts) ->
        if data.instance?
            @instance = data.instance
            delete data.instance

        opts ?= {}
        opts.configPath ?= "/var/stormflash/plugins/openvpn"
        opts.logPath ?= "/var/log/openvpn"

        super id, data, opts

        @configs =
            service:    filename:"#{@configPath}/#{@id}.conf"

        @invocation = merge @invocation,
            args: ["--config", "#{@configs.service.filename}"]
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
        #@out.close()
        #@err.close()
        @emit 'destroy'

module.exports = OpenvpnClientService

