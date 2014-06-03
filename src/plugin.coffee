openvpn = require './openvpn'
@include = ->        

    vpnserverdata=require('./openvpn').VpnServerData
    vpnuserdata=require('./openvpn').VpnUserData
    #vpn = new vpnlib
    vpnagent = @settings.agent
    configpath = "/config/openvpn"
    ###  
    validateClientSchema = ->
        result = validate @body, vpnlib.clientSchema
        console.log result
        return @next new Error "Invalid openvpn client configuration posting!: #{result.errors}" unless result.valid
        @next()

    validateServerSchema = ->
        result = validate @body, vpnlib.serverSchema
        console.log result
        return @next new Error "Invalid openvpn server configuration posting!: #{result.errors}" unless result.valid
        @next()

    validateUser = ->
        result = validate @body, vpnlib.userSchema
        console.log result
        return @next new Error "Invalid openvpn user configuration posting!: #{result.errors}" unless result.valid
        @next()

    ###    
    @post '/openvpn/server': ->
    	openvpn.new (new vpnserverdata null,@body)
    	instance = openvpn.new @body
    	filename = configpath + "/" + "#{instance.id}.conf"
    	openvpn.configvpn instance, filename, openvpn.serverdb, (res) =>
    		unless res instanceof Error
    			@send instance	
    		else
    			next new Error "Invalid openvpn server posting! #{res}"	
    	###
        instance = vpn.new @body
        filename = configpath + "/" + "#{instance.id}.conf"
        vpn.configvpn instance, filename, vpn.serverdb, (res) =>
            unless res instanceof Error
                @send instance
            else
                @next new Error "Invalid openvpn server posting! #{res}"
        ###       
    
    @del '/openvpn/server/:server': ->
        filename = configpath + "/" + "#{@params.server}.conf"
        openvpn.delInstance @params.server , vpn.serverdb, filename, (res) =>
            unless res instanceof Error
                @send 204
            else
                @next res


    @post '/openvpn/server/:server/users': ->
        res = (new vpnuserdata null,@body)
        @send res if res instanceof Error	
        file =  if @body.email then @body.email else @body.cname
        #get ccdpath from the DB
        entry = openvpn.getServerEntryByID @params.server
        console.log entry.config
        unless entry instanceof Error
            ccdpath = vpn.getCcdPath entry
            console.log 'ccdpath is ' + ccdpath
            filename = ccdpath + "/" + "#{file}"
            openvpn.addUser @body, filename, (res) =>
                @send res
        else
            @next entry

    @del '/openvpn/server/:id/users/:user': ->
        #get ccdpath from the DB
        entry = openvpn.getServerEntryByID @params.id
        unless entry instanceof Error
            ccdpath = openvpn.getCcdPath entry
            openvpn.delUser @params.user, ccdpath, (res) =>
                @send 204
        else
            @next entry

            
    @get '/openvpn/server/:id': ->
        #get vpnmgmtport from DB for this given @params.id
        entry = openvpn.getServerEntryByID @params.id
        unless entry instanceof Error
            vpnmgmtport = openvpn.getMgmtPort entry
            serverstatus = openvpn.getStatusFile entry
            openvpn.getInfo vpnmgmtport, serverstatus, @params.id, (result) =>
                @send result
        else
            @next entry


    @get '/openvpn/server': ->
        #get list of server instances from the DB
        res = openvpn.listServers()
        @send res

    ###
    #client endpoints are not used currently, we will convert it later
    @get '/openvpn/client': ->
        #get list of client instances from the DB
        res = vpn.listClients()
        @send res

    @post '/openvpn/client', validateClientSchema, ->
        instance = vpn.new @body
        filename = configpath + "/" + "#{instance.id}.conf"
        vpn.configvpn instance, filename, vpn.clientdb, (res) =>
            unless res instanceof Error
                @send instance
            else
                @next new Error "Invalid openvpn client posting! #{res}"

    @del '/openvpn/client/:client': ->
        filename = configpath + "/" + "#{@params.client}.conf"
        vpn.delInstance @params.client, vpn.clientdb, filename, (res) =>
            unless res instanceof Error
                @send 204
            else
                @next res
    ###


