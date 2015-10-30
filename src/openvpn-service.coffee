StormService = require('stormservice')
merge = require('fmerge')
fs = require('fs')
path = require 'path'
exec = require('child_process').exec

ServerSchema = require('./schema').server
ClientSchema = require('./schema').client

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
            #certificates processing

            dir = "#{@configPath}/#{@id}"             
            fs.mkdirSync(dir) unless fs.existsSync dir

            for cert in @data.certificates
                filename = switch cert.name
                    when "ca" then @data.ca
                    when "dh" then @data.dh
                    when "cert"  then @data.cert
                    when "key"  then @data.key
                    when "secret" then @data.secret
                path = "#{dir}/#{filename}"
                console.log "path"
                fs.writeFileSync path, new Buffer(cert.data || '',"base64")

            for key, val of @data
                switch (typeof val)
                    when "object"
                        if val instanceof Array
                            for i in val
                                # certs are not processed here
                                vpnconfig += "#{key} #{i}\n" if key is "route"
                                vpnconfig += "#{key} \"#{i}\"\n" if key is "push"
                    when "number", "string"
                        if key in ['ca','dh','cert','key','secret']
                            vpnconfig += key + ' ' + "#{dir}/#{val}" + "\n"
                        else
                            vpnconfig += key + ' ' + val + "\n"
                    when "boolean"
                        vpnconfig += key + "\n"
            callback vpnconfig

    updateService: (newdata, callback)->
        @data = merge @data, newdata
        #create ccd directory
        ccdpath = newdata["client-config-dir"]
        if ccdpath?
            try
                fs.mkdir "#{ccdpath}", () ->
            catch err
        @generate callback

    destructor: ->
        @eliminate()
        #@out.close()
        #@err.close()
        @emit 'destroy'


class OpenvpnServerService extends OpenvpnService

    constructor: (id, data, opts) ->

        @schema = ServerSchema

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

        @schema = ClientSchema
        super id, data, opts


module.exports.OpenvpnService = OpenvpnService
module.exports.OpenvpnClient = OpenvpnClientService
module.exports.OpenvpnServer = OpenvpnServerService

Context = require('./context')
module.exports.Context = Context
