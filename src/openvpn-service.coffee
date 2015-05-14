StormService = require('stormservice')
merge = require('fmerge')
fs = require('fs')

class OpenvpnService extends StormService

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
            #hack - add the management console configuration
            vpnconfig += "management #{@configPath}/#{@id}_mgmt.sock  unix" + "\n"

            callback vpnconfig

    destructor: ->
        @eliminate()
        #@out.close()
        #@err.close()
        @emit 'destroy'


class OpenvpnServerService extends OpenvpnService

    constructor: (id, data, opts) ->

        @schema =
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

        #create ccd directory
        ccdpath = data["client-config-dir"]
        if ccdpath?
            try
                fs.mkdir "#{ccdpath}", () ->
            catch err
                #@settings.agent.log 'Error : ', err

        super id, data, opts


class OpenvpnClientService extends OpenvpnService
    constructor: (id, data, opts) ->

        @schema =
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

        super id, data, opts

class OpenvpnMgmtClient

    net = require("net")
    
    constructor: (context) ->

        @client = null

    #Method to start vpn mgmt client
    connect: (options, callback) ->
        @client = net.connect options, (result) =>
            @client.setEncoding 'utf8'
            callback null, @client
        @client.on 'error', (err) =>
            @settings.agent.log 'vpn mgmt client connection error :', err.message
            return callback err, null
        @client.on 'end',() =>
            @settings.agent.log 'vpn mgmt client disconnected :'

    execute: (command, callback) ->
        if @client?
            @settings.agent.log "command ", command
            @client.write command
            @client.on "data", (data) =>
                @settings.agent.log "in client data ", data
                @settings.agent.log "vpn mgmt parsing data ", data.toString()
                message = String(data)
                if (message.indexOf ('ERROR')) >= 0
                    callback 'error in executing command', null
                else
                    callback null, true
        else
            callback "error", null

    disconnect: ->
        try
            @client.end()
        catch err
            @settings.agent.log "unable to properly terminate vpn mgmt client: #{@client}", err


module.exports.OpenvpnService = OpenvpnService
module.exports.OpenvpnClient = OpenvpnClientService
module.exports.OpenvpnServer = OpenvpnServerService
module.exports.OpenvpnMgmtClient = OpenvpnMgmtClient


