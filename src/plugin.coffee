@include = ->        

    vpnserverdata=require('./vpnlib').VpnServerData
    vpnuserdata=require('./vpnlib').VpnUserData
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
    	vpnagent.new (new vpnserverdata null,@body)
    	instance = vpnagent.new @body
    	filename = configpath + "/" + "#{instance.id}.conf"
    	vpnagent.configvpn instance, filename, vpn.serverdb, (res) =>
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
        vpnagent.delInstance @params.server , vpn.serverdb, filename, (res) =>
            unless res instanceof Error
                @send 204
            else
                @next res


    @post '/openvpn/server/:server/users': ->
        res = (new vpnuserdata null,@body)
        @send res if res instanceof Error	
        file =  if @body.email then @body.email else @body.cname
        #get ccdpath from the DB
        entry = vpnagent.getServerEntryByID @params.server
        console.log entry.config
        unless entry instanceof Error
            ccdpath = vpn.getCcdPath entry
            console.log 'ccdpath is ' + ccdpath
            filename = ccdpath + "/" + "#{file}"
            vpnagent.addUser @body, filename, (res) =>
                @send res
        else
            @next entry

    @del '/openvpn/server/:id/users/:user': ->
        #get ccdpath from the DB
        entry = vpnagent.getServerEntryByID @params.id
        unless entry instanceof Error
            ccdpath = vpnagent.getCcdPath entry
            vpnagent.delUser @params.user, ccdpath, (res) =>
                @send 204
        else
            @next entry

            
    @get '/openvpn/server/:id': ->
        #get vpnmgmtport from DB for this given @params.id
        entry = vpnagent.getServerEntryByID @params.id
        unless entry instanceof Error
            vpnmgmtport = vpnagent.getMgmtPort entry
            serverstatus = vpnagent.getStatusFile entry
            vpnagent.getInfo vpnmgmtport, serverstatus, @params.id, (result) =>
                @send result
        else
            @next entry


    @get '/openvpn/server': ->
        #get list of server instances from the DB
        res = vpnagent.listServers()
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


