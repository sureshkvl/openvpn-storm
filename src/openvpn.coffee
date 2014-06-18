StormData = require('stormdata')
StormRegistry = require('stormregistry')

class ServerData extends StormData

    # testing openvpn validation with test schema
    serverSchema =
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

    constructor: (id, data) ->
        super id, data, serverSchema

#---------------------------------------------------------------------

class Servers extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            entry = new ServerData key,val
            if entry?
                entry.saved = true
                @add key, entry

        @on 'removed', (key) ->
            # an entry is removed in Registry
        super filename


    get: (key) ->
        entry = super key
        return unless entry?
        if entry.data? and entry.data instanceof ServerData
            entry.data.id = entry.id
            entry.data
        else
            entry

#----------------------------------------------------------------------

class UserData extends StormData

    userSchema =
        name: "openvpn"
        type: "object"
        additionalProperties: false
        properties:
            id:    { type: "string", required: true }
            email: { type: "string", required: false}
            cname: { type: "string", required: false}
            push:
                items: { type: "string" }

    constructor: (id, data) ->
        super id, data, userSchema

#------------------------------------------------------------------------

class Users extends StormRegistry

    constructor: (filename) ->
        @on 'load', (key,val) ->
            entry = new UserData key,val
            if entry?
                entry.saved = true
                @add key, entry

        @on 'removed', (key) ->
            # an entry is removed in Registry
        super filename


    get: (key) ->
        entry = super key
        return unless entry?
        if entry.data? and entry.data instanceof UserData
            entry.data.id = entry.id
            entry.data
        else
            entry

#-----------------------------------------------------------------------------

class Openvpn

    fs = require 'fs'
    validate = require('json-schema').validate
    exec = require('child_process').exec
    uuid = require 'node-uuid'


    constructor: (@settings) ->

        #XXX check feasibility to get plugin dir from settings
        @config = "/var/stormflash/meta"
        fs.mkdir "#{@config}", (result) =>
            fs.mkdir "/var/stormflash/plugins/openvpn", (result) =>
                @servers = new Servers "/var/stormflash/plugins/openvpn/servers.db"
                @users = new Users "/var/stormflash/plugins/openvpn/users.db"


    addserver: (server, callback) ->
        try
            configData = new ServerData null, server
        catch err
            return callback new Error "Invalid schema! #{err}"
            
        @generateConfig configData, (configFile) =>
            # XXX must discover location of openvpn binary
            # monitor option must be derived from package.json
            out = fs.openSync "/var/log/openvpn_#{configData.id}.out", 'a'
            err = fs.openSync "/var/log/openvpn_#{configData.id}.err", 'a'
            env = process.env
            env.PATH= '/bin:/sbin:/usr/bin:/usr/sbin'
            env.LD_LIBRARY_PATH= '/lib:/usr/lib'
            serverInfo =
                "name": "openvpn"
                "path": "/usr/sbin"
                "monitor": false
                "args": [ "--config", "#{configFile}"]
                "options":
                    env:env
                    detached:true
                    stdio: ['ignore', out, err]

            data = @settings.agent.newInstance serverInfo
            @serverInstance = @settings.agent.instances.add data.id, data
                
            # Start the server Instance
            @settings.agent.start @serverInstance.id, (key, pid) =>
                @settings.agent.log "Server Instance result ", key, pid
                return callback new Error "Failed to start openvpn server instance. Error is #{key}" if key instanceof Error
                #server.key = key
                @settings.agent.log "pid result ", pid
                configData.pid = pid
                @settings.agent.log "instance result ", @serverInstance.id 
                configData.instanceId = @serverInstance.id
                @settings.agent.log "server id result ", configData.id
                result = @servers.add configData.id, configData
                
                @settings.agent.log "printing result for openvpn server db add: ", result
                
                #creating the ccd dir
                ccdpath = result.data["client-config-dir"]
                if ccdpath?
                    try
                        fs.mkdir "#{ccdpath}", () ->
                        @settings.agent.log 'created ccd path'
                    catch err                                           
                        @settings.agent.log 'Error : ', err 
                callback result

    generateConfig: (configData, callback) ->
        server = configData.data
        service = "openvpn"
        gconfig = ''
        for key, val of server
           switch (typeof val)
               when "object"
                   if val instanceof Array
                       for i in val
                           gconfig += "#{key} #{i}\n" if key is "route"
                           gconfig += "#{key} \"#{i}\"\n" if key is "push"
               when "number", "string"
                   gconfig += key + ' ' + val + "\n"
               when "boolean"
                   gconfig += key + "\n"

        filename = @config + "/" + configData.id + ".conf"
        console.log 'writing vpn config onto file' + filename
        fs.writeFileSync filename,gconfig
        #exec "touch /var/stormflash/meta/on"
        callback filename
    
    listServers:(callback)->
        callback @servers.list()

    getServerbyID:(id, callback)->
        callback @servers.get id

    deleteserver: (id, callback) ->


    adduser: (serverid, user, callback) ->
        file =  if user.cname then user.cname else user.email
        res = @servers.get serverid
        callback new Error "Error: Unknown Server instance" unless res?
        ccdpath = res.data["client-config-dir"]
        #fs.mkdirSync "#{ccdpath}"
        #exec "mkdir #{ccdpath}"
        filename = ccdpath + "/" + "#{file}"
        service = "openvpn"
        gconfig = ''
        for key, val of user
            switch (typeof val)
                when "object"
                    if val instanceof Array
                        for i in val
                            gconfig += "#{key} #{i}\n" if key is "iroute"
                            gconfig += "#{key} \"#{i}\"\n" if key is "push"
        console.log filename
        fs.writeFileSync filename,gconfig
        configData = new UserData null, user
        result = @users.add configData.id, configData

        ###
        #send SIGHUP to the openvpn server - Needed when existing user config is modified, not needed for new additions
        #Reference - https://openvpn.net/index.php/open-source/documentation/howto.html#control
        @settings.agent.log "existing openvpn server PId for this server instance: ", res.pid
        exec "/bin/kill -HUP #{res.pid}", (error, stdout, stderr) =>
            return callback new Error 'SIGUP Error for openvpn server instance' + error if error
            @settings.agent.log 'Reloaded openvpn instance'
        ###
        return callback(configData)
        
    deleteuser: (serverid, userid, callback) ->
          


    ###
    getCcdPath: (entry) ->
        console.log entry.config
        return entry.config["client-config-dir"]

    getServerEntryByID: (id) ->
        entry = @serverdb.get id
        if entry
            return entry
        else
            return new Error "Invalid ID posting! #{id}"

    getMgmtPort: (entry) ->
        console.log 'entry is ' + entry.config
        console.log 'management ip port is ' + entry.config.management
        port = entry.config.management.split(" ")
        return port[1]

    getStatusFile: (entry) ->
        console.log 'status file is ' + entry.status
        return entry.config.status


    new: (config) ->
        instance = {}
        instance.id = uuid.v4()
        instance.config = config
        #instance.config.id ?= uuid.v4()
        return instance

    configvpn: (instance, filename, idb, callback) ->
        console.log 'idb is ' + idb
        service = "openvpn"
        config = ''
        for key, val of instance.config
            switch (typeof val)
                when "object"
                    if val instanceof Array
                        for i in val
                            config += "#{key} #{i}\n" if key is "route"
                            config += "#{key} \"#{i}\"\n" if key is "push"
                when "number", "string"
                    config += key + ' ' + val + "\n"
                when "boolean"
                    config += key + "\n"
        console.log 'writing vpn config onto file' + filename
        #fileops.createFile filename, (result) ->
        fs.writeFileSync filename,config
        #return new Error "Unable to create configuration file #{filename}!" if result instanceof Error
        #fileops.updateFile filename, config
        exec "touch /var/stormflash/meta/on"
        try
            idb.set instance.id, instance, ->
                console.log "#{instance.id} added to OpenVPN service configuration"
            callback({result:true})
        catch err
            console.log err
            callback(err)


    addUser: (body, filename, callback) ->
        service = "openvpn"
        config = ''
        for key, val of body
            switch (typeof val)
                when "object"
                    if val instanceof Array
                        for i in val
                            config += "#{key} #{i}\n" if key is "iroute"
                            config += "#{key} \"#{i}\"\n" if key is "push"

        id = body.id
        #fileops.createFile filename, (err) ->
        #    return new Error "Unable to create configuration file #{filename}!" if err instanceof Error
        fs.writeFileSync filename,config
        #    fileops.updateFile filename, config
        try
            '''
            TODO: implement a module to act on service
            '''
            console.log "exec : monit restart #{service}"
            #exec "monit restart #{service}"
            db.user.set id, body, ->
                console.log "#{id} added to OpenVPN service configuration"
                console.log body
            callback({result: true })
        catch err
            callback(err)

    delInstance: (id, idb, filename, callback) ->
        entry = idb.get id
        console.log 'filename to be removed ' + filename
        #spawnvpn takes care of killing openvpn instance.
        #To keep it generic, we need to call service module to stop this process
        #service module should have mapping with id to process id
        #fileops.removeFile filename, (err) =>
        fs.unlink filename, (err)=>
            console.log 'result of removing file '  + err
            unless err instanceof Error
                idb.rm id, =>
                    console.log "removed VPN client ID: #{id}"
                callback(true)
            else
                error = new Error "Unable to delete the instance #{id}! #{err}" if err instanceof Error
                callback (error)

    delUser: (userid, ccdpath, callback) ->
        path = require 'path'
        entry = db.user.get userid

        try
            throw new Error "user does not exist!" unless entry
            if entry.email
                file = entry.email
            else
                file = entry.cname
            filename = "#{ccdpath}" + "/#{file}"
            console.log "removing user config on #{filename}..."
            #fileops.fileExists filename, (exists) ->
            exists = path.existsSync filename
            if not exists
                console.log 'file removed already'
                err = new Error "user is already removed!"
                callback(err)
            else
                console.log 'remove the file'
                #fileops.removeFile filename, (err) ->
                fs.unlink filename, (err) ->
                    if err
                        callback(err)
                    else
                        console.log 'removed file'
                    db.user.rm userid, ->
                        console.log "removed VPN user ID: #{userid}"
                    callback(true)
        catch err
            callback(err)

    listServers: ->
        res = {"servers":[]}
        @serverdb.forEach (key,val) ->
            console.log 'found server ' + key
            res.servers.push val
        console.log 'listing'
        return res.servers

    listClientByID: (key) ->
        entry = @clientdb.get key
        return new Error "Entry with the given key #{key} does not exist" unless entry
        return entry

    listClients: ->
        res = {"clients":[]}
        @clientdb.forEach (key,val) ->
            console.log 'found client ' + key
            res.clients.push val unless key == "management"
        console.log 'listing'
        return res.clients

    getInfo: (port, filename, id, callback) ->
        console.log 'in getInfo'
        res =
            id: id
            users: []
            connections: []

        db.user.forEach (key,val) ->
            console.log 'found ' + key
            res.users.push val

        # TODO: should retrieve the openvpn configuration and inspect "management" and "status" property

        Lazy = require 'lazy'
        status = new Lazy
        status
            .lines
            .map(String)
            .filter (line) ->
                not (
                    /^OpenVPN/.test(line) or
                    /^Updated/.test(line) or
                    /^Common/.test(line) or
                    /^ROUTING/.test(line) or
                    /^Virtual/.test(line) or
                    /^GLOBAL/.test(line) or
                    /^UNDEF/.test(line) or
                    /^END/.test(line) or
                    /^Max bcast/.test(line))
            .map (line) ->
                #console.log "lazy: #{line}"
                return line.trim().split ','
            .forEach (fields) ->
                switch fields.length
                    when 5
                        res.connections.push {
                            cname: fields[0]
                            remote: fields[1]
                            received: fields[2]
                            sent: fields[3]
                            since: fields[4]
                        }
                    when 4
                        for conn in res.connections
                            if conn.cname is fields[1]
                                conn.ip = fields[0]
            .join =>
                console.log res
                callback(res)

        console.log "checking for live connections..."

        # OPENVPN MGMT API v1
        net = require 'net'
        conn = net.connect port, '127.0.0.1', ->
            console.log 'connection to openvpn mgmt successful!'
            response = ''
            @setEncoding 'ascii'
            @on 'prompt', =>
                @write "status\n"
            @on 'response', =>
                console.log "response: #{response}"
                status.emit 'end'
                @write "exit\n"
                @end
            @on 'data', (data) =>
                console.log "read: "+data+"\n"
                if /^>/.test(data)
                    @emit 'prompt'
                else
                    response += data
                    status.emit 'data',data
                    if /^END$/gm.test(response)
                        @emit 'response'
            @on 'end', =>
                console.log 'connection to openvpn mgmt ended!'
                status.emit 'end'
                @end

        # When we CANNOT make a connection to OPENVPN MGMT port, we fallback to checking file
        conn.on 'error', (error) ->
            console.log error
            statusfile = filename # hard-coded for now...

            console.log "failling back to processing #{statusfile}..."
            #statusfile = "openvpn-status.log" # hard-coded for now...
            fs = require 'fs'
            stream = fs.createReadStream statusfile, encoding: 'utf8'
            stream.on 'open', ->
                console.log "sending #{statusfile} to lazy status..."
                stream.on 'data', (data) ->
                    status.emit 'data',data
                stream.on 'end', ->
                    status.emit 'end'

            stream.on 'error', (error) ->
                console.log error
                status.emit 'end'
    ###

module.exports = Openvpn
