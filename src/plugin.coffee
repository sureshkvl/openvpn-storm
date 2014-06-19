openvpn = require './openvpn'

async = require 'async'

@include = ->
    vpn = new openvpn @settings

    @post '/openvpn/server': ->
    	vpn.addserver @body, (res) =>
            unless res instanceof Error
                @send res
            else
                @next new Error "Invalid openvpn server posting! #{res}"

    @del '/openvpn/server/:server': ->
        vpn.deleteserver @params.server, (res) =>
            unless res instanceof Error
                @send 204
            else
                @next new Error "Failed to delete openvpn server! #{res}"


    @post '/openvpn/server/:server/users': ->
        users = @body
        users = [ users ] unless users instanceof Array

        tasks = {}
        for user in users
            tasks[user.id] = (callback) =>
                vpn.adduser @params.server, @body, (res) =>
                    unless res instanceof Error
                        callback null, res
                    else
                        callback "Failed to add openvpn user! #{res}"

        async.parallel tasks, (err, results) =>
            return @next err if err?

            unless results? and results.length > 0
                @next "Unable to add openvpn users!"
            else
                @send results

    @del '/openvpn/server/:id/users/:user': ->
        vpn.deleteuser @params.id, @params.user,  (res) =>
            unless res instanceof Error
                @send 204
            else
                @next new Error "Failed to delete openvpn user ! #{res}"



    @get '/openvpn/server/:id': ->
        vpn.getServerbyID @params.id, (res) =>
            unless res instanceof Error
                @send res
            else
                @next new Error "Failed to get openvpn server! #{res}"


    @get '/openvpn/server': ->
        vpn.listServers (res) =>
            unless res instanceof Error
                @send res
            else
                @next new Error "Failed to list openvpn servers! #{res}"


