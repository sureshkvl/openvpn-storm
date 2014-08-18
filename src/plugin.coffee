
OpenvpnRegistry = require('./openvpn-registry').OpenvpnRegistry
OpenvpnUserRegistry = require('./openvpn-registry').OpenvpnUserRegistry
OpenvpnClientService = require('./openvpn-service').OpenvpnClient
OpenvpnServerService = require('./openvpn-service').OpenvpnServer

async = require('async')

@include = ->
    agent = @settings.agent
    unless agent?
        throw  new Error "this plugin requires to be running in the context of a valid StormAgent!"

    plugindir = @settings.plugindir
    plugindir ?= "/var/stormflash/plugins/openvpn"

    #clientRegistry = new OpenvpnRegistry plugindir+"/openvpn-clients.db"
    serverRegistry = new OpenvpnRegistry plugindir+"/openvpn-servers.db"
    userRegistry = new OpenvpnUserRegistry plugindir+"/openvpn-users.db"

    serverRegistry.on 'ready', ->
        for service in @list()
            continue unless service instanceof OpenvpnServerService

            agent.log "restore: trying to recover:", service
            do (service) -> service.generate (err) ->
                if err?
                    return agent.log "restore: openvpn #{service.id} failed to generate configs!"
                agent.invoke service, (err, instance) ->
                    if err?
                        agent.log "restore: openvpn #{service.id} invoke failed with:", err
                    else
                        agent.log "restore: openvpn #{service.id} invoke succeeded wtih #{instance}"
    
    clientRegistry.on 'ready', ->
        for service in @list()
            continue unless service instanceof OpenvpnClientService

            agent.log "restore: trying to recover:", service
            do (service) -> service.generate (err) ->
                if err?
                    return agent.log "restore: openvpn #{service.id} failed to generate configs!"
                agent.invoke service, (err, instance) ->
                    if err?
                        agent.log "restore: openvpn #{service.id} invoke failed with:", err
                    else
                        agent.log "restore: openvpn #{service.id} invoke succeeded wtih #{instance}"
    

    @post '/openvpn/server': ->
        try
            service = new OpenvpnServerService null, @body, {}
        catch err
            return @next err
            
        service.generate (err, results) =>
            return @next err if err?
            agent.log "POST /openvpn/server generation results:", results
            serverRegistry.add service
            agent.invoke service, (err, instance) =>
                if err?
                    #serverRegistry.remove service.id
                    return @next err
                else
                    @send {id: service.id, running: true}
    
    @del '/openvpn/server/:server': ->
        service = serverRegistry.get @params.server
        return @send 404 unless service?

        serverRegistry.remove @params.server
        @send 204


    @post '/openvpn/server/:server/users': ->
        serverId = @params.server
        users = @body
        server = serverRegistry.get serverId
        return @send 400 unless serverId? and users? and server?

        users = [ users ] unless users instanceof Array
        tasks = {}
        for user in users
            do (user) ->
                tasks[user.id] = (callback) ->
                    user.ccdpath = server.data["client-config-dir"]
                    entry = userRegistry.add user.id, user
                    userRegistry.adduser entry
                    callback null, entry

        async.parallel tasks, (err, results) =>
            return @next err if err?
            @send results

    @del '/openvpn/server/:id/users/:user': ->
        serverId = @params.id
        userId = @params.user
        ulist = userRegistry.list()
        server = serverRegistry.get serverId
        if ulist
            for entry in ulist                
                user = entry if entry and entry.cname is userId
        return @send 400 unless serverId? and user? and server?
        userRegistry.deleteuser server, user,  (res) =>
            unless res instanceof Error
                userRegistry.remove user.id
                @send {deleted: true}
            else
                @next new Error "Failed to delete openvpn user ! #{user.id}"

    @get '/openvpn/server/:id': ->
        service = serverRegistry.get @params.id
        unless service?
            @send 404
        else
            @send service

    @get '/openvpn/server': ->
        @send serverRegistry.list()


    @post '/openvpn/client': ->
        try
            service = new OpenvpnClientService null, @body, {}
        catch err
            return @next err

        service.generate (err, results) =>
            return @next err if err?
            agent.log "POST /openvpn/client generation results:", results
            clientRegistry.add service
            agent.invoke service, (err, instance) =>
                if err?
                    #serverRegistry.remove service.id
                    return @next err
                else
                    @send {id: service.id, running: true}

    @del '/openvpn/client/:client': ->
        service = clientRegistry.get @params.client
        return @send 404 unless service?

        clientRegistry.remove @params.client
        @send 204

    @get '/openvpn/client': ->
        @send clientRegistry.list()

    
