openvpn = require './openvpn'


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
        vpn.adduser @params.server, @body, (res) =>
            unless res instanceof Error
                @send res
            else
                @next new Error "Failed to add openvpn user! #{res}"


    @del '/openvpn/server/:id/users/:user': ->
        vpn.deleteuser @params.id, @params.user,  (res) =>
            unless res instanceof Error
                @send 204
            else
                @next new Error "Failed to delete openvpn user ! #{res}"


            
    @get '/openvpn/server/:id': ->
        vpn.servers.get @params.id, (res) =>
            unless res instanceof Error
                @send res
            else
                @next new Error "Failed to get openvpn server! #{res}"


    @get '/openvpn/server': ->
        vpn.servers.list (res) =>
            unless res instanceof Error
                @send res
            else
                @next new Error "Failed to list openvpn servers! #{res}"


