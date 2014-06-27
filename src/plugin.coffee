OpenvpnService = require './openvpn-service'
OpenvpnServerRegistry = require('./openvpn-registry').VpnServerRegistry
OpenvpnUserRegistry = require('./openvpn-registry').VpnUserRegistry
async = require('async')

@include = ->
    agent = @settings.agent
    unless agent?
        throw  new Error "this plugin requires to be running in the context of a valid StormAgent!"

    plugindir = @settings.plugindir
    plugindir ?= "/var/stormflash/plugins/openvpn"

    serverRegistry = new OpenvpnServerRegistry plugindir+"/openvpn-servers.db"
    userRegistry = new OpenvpnUserRegistry plugindir+"/openvpn-users.db"

    serverRegistry.on 'ready', ->
        for service in @list()
            continue unless service instanceof OpenvpnService

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
            service = new OpenvpnService null, @body, {}
        catch err
            return @next err
            
        #agent.log "service info:", service

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
                    user.ccdPath = server["client-config-dir"]
                    entry = userRegistry.add user.id, user
                    userRegistry.addUser entry.data
                    callback "Failed to add openvpn user! #{entry.data}"

        async.parallel tasks, (err, results) =>
            return @next err if err?
            @send results

    @del '/openvpn/server/:id/users/:user': ->
        vpn.deleteuser @params.id, @params.user,  (res) =>
            unless res instanceof Error
                @send 204
            else
                @next new Error "Failed to delete openvpn user ! #{res}"

    @get '/openvpn/server/:id': ->
        service = serverRegistry.get @params.id
        unless service?
            @send 404
        else
            @send service

    @get '/openvpn/server': ->
        @send serverRegistry.list()


