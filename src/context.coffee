#Valid = require('jsonschema').Validator
validate = require('json-schema').validate
#Validator = new Valid
assert = require 'assert'
Promise = require 'bluebird'
async = require 'async'
needle = Promise.promisifyAll(require('needle'))
utils = require('utils')._
diff = require('deep-diff').diff

schema_user = require('./schema').user
schema_server = require('./schema').server
schema_client = require('./schema').client

schema =
    "server": schema_server
    "client": schema_client
    "user" : schema_user

getPromise = ->
    return new Promise (resolve, reject) ->
        resolve()

PostServer = (baseUrl,server)->
    needle.postAsync baseUrl + "/openvpn/server", server.config, json:true
    .then (resp) =>
        console.log "statuscode: ", resp[0].statusCode
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        # we should return the instance object for success case
        return { id : server.id, instance_id : resp[1].id }
    .catch (err) =>
        throw err

PostClient = (baseUrl,client)->
    needle.postAsync baseUrl + "/openvpn/client", client.config, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        return { id : client.id, instance_id : resp[1].id }        
    .catch (err) =>
        throw err

DeleteServer = (baseUrl,server,instanceid)->
    needle.deleteAsync baseUrl + "/openvpn/server/#{instanceid}", json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204
        return server
    .catch (err) =>
        throw err

DeleteClient = (baseUrl,client,instanceid)->
    needle.deleteAsync baseUrl + "/openvpn/client/#{instanceid}", json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204
        return client
    .catch (err) =>
        throw err

PutServer = (baseUrl,server,instanceid)->
    needle.putAsync baseUrl + "/openvpn/server/#{instanceid}", server.config, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        #server.history.config = utils.extend {},server.config
        return server
    .catch (err) =>
        throw err

PutClient = (baseUrl,client,instanceid)->
    needle.putAsync baseUrl + "/openvpn/client/#{instanceid}", client.config, json:true
    .then (resp) =>
        console.log "respo code", resp[0].statusCode
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        return client
    .catch (err) =>
        throw err

PostUser = (baseUrl,serverid,user)->
    needle.postAsync baseUrl + "/openvpn/server/#{serverid}/users", user, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        return resp.body
    .catch (err) =>
        throw err


DeleteUser = (baseUrl,serverid,user)->
    needle.deleteAsync baseUrl + "/openvpn/server/#{serverid}/users/#{user.cname}", json:true
    .then (resp) =>
        console.log "response code is", resp[0].statusCode
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        return resp.body
    .catch (err) =>
        throw err



# utility functions
#---------------------------------------------------------------------------------

GetInstanceObject = (list,id)->
    for item in list
        if item.id is id
            return item
    return null

GetHistoryObject = (history,id)->
    for obj in history
        if obj.id is id
            return obj
    return null

removeItem = (list,id)->
    itr = 0
    for item in list
        if item.id is id 
            index = itr
            break
        itr++
    console.log "iterator is ",itr
    console.log "index is", index
    delete list[index]

UserExists = (list,id)->
    for item in list
        if item.id is id
            return true
    return false



# utility functions
#---------------------------------------------------------------------------------

Start =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    
    configObj = context.service.factoryConfig?.config
    config = configObj[context.service.name]

    servers =  config.servers ? []
    clients =  config.clients ? []
    context.instances ?= []
    context.history ?= {}
    context.history?.servers = []
    context.history?.clients = []

    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(servers) and utils.isEmpty(clients)
    return context unless config.enable is true

    getPromise()
    .then (resp) =>
        Promise.map servers, (server) ->
            return PostServer(context.baseUrl,server)
        .then (resp) =>
            context.instances.push item for item in resp          
            return resp
        .then (resp) =>
            #history obect to be updated here            
            console.log "resp", resp
            console.log "Servers", servers
            return resp if utils.isEmpty(servers)                 
            for i in resp
                for server in servers #where server.id is i.id 
                    context.history.servers.push server if server.id is i.id
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        Promise.map clients, (client) ->
            return PostClient(context.baseUrl,client)
        .then (resp) =>
            # instance objects
            context.instances.push item for item in resp 
            return resp
        .then (resp) =>
            #history update 
            return  if utils.isEmpty(clients)            
            for i in resp
                for client in clients #where client.id is i.id 
                    context.history.clients.push client if client.id is i.id 
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        return context
    .catch (err) =>
        throw err

Stop = (context) ->
    throw new Error 'openvpn-storm.Stop missingParams' unless context.bInstalledPackages and context.service.name

    config = context.policyConfig[context.service.name]
    servers =  config.servers ? []
    clients =  config.clients ? []
    instances = context.instances
    history = context.history

    throw new Error "openvpn-storm.Stop missing server,client info" if utils.isEmpty(servers) and utils.isEmpty(clients)
    return context unless config.enable is true
   
    getPromise()
    .then (resp) =>
        Promise.map servers, (server) ->
            #check the server id is present in the instances array
            instance = GetInstanceObject(instances,server.id)
            console.log "instance is "
            console.log instance
            throw new Error " server instance is not found" unless instance?            
            return  DeleteServer(context.baseUrl,server,instance.instance_id)
        .then (resp) =>
            #response contains servers array.
            # remove the instances and history from the context
            for s in resp
                removeItem(instances,s.id)
                removeItem(history.servers, s.id)        
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        Promise.map clients, (client) ->
            #check the client id is present in the instances array
            instance = GetInstanceObject(instances,client.id)
            console.log "instance is "
            console.log instance
            throw new Error " client instance is not found" unless instance?
            return DeleteClient(context.baseUrl,client,instance.instance_id)
        .then (resp) =>
            #response contains clients array.
            # remove the respective instances and history from the context
            for c in resp
                removeItem(instances,c.id)
                removeItem(history.clients, c.id)        
            return resp            
        .catch (err) =>
            throw err
    .then (resp) =>
        return context
    .catch (err) =>
        throw err



###
#Update logic
    iterate the clients array
       a. if instance is not present - assume that is the new client . 
           - post the client and update the instance id, and save the config in the history
       b. if the instance is present (assume this is the existing running client)
            i) diff with config and history config 
                if diff is found, then client config is changed,
                put the client config 
    
    iterate the servers array. 
       a. if instance is not preset  - assume this is  a new server.  
           - post the server and update the instance id, and save the config in history
       b.if instance is present, (assume this is the existing running server) 
            i) diff with config and history config 
                if diff is found, then server config is changed,
                put the server config 

       c. check the current users aray and history users array in the server         
             if current user is not present in the history users 
                      then this is the new user , POST the new user and update it in the history users
            if history user is not present in the current users , 
                       then this uses to be deleted. DELETE this user
    



UpdateClient = (baseUrl,client)->
    getPromise()
    .then (resp) =>
        return PostClient(baseUrl,client) unless client.instance?
        differences = diff(client.config,client.history.config)
        return PutClient(baseUrl,client) unless utils.isEmpty(differences) or  not differences?
        return client #no difference in client config
    .catch (err) =>
        throw err


UpdateServer = (baseUrl,server)->
    getPromise()
    .then (resp) =>
        #put server , post server
        return  PostServer(baseUrl,server) unless server.instance?
        differences = diff(server.config,server.history.config)
        return  PutServer(baseUrl,server) unless utils.isEmpty(differences) or  not differences?
        #return resolve server #no difference in server config
        
    .then (resp) =>

        currentusers = server.users ? []
        historyusers = server.history.users ? []

        #process the currentusers array
        console.log "currentusers ",currentusers
        Promise.map currentusers, (currentuser) =>
            console.log "currentuser  ",currentuser
            result =  UserExists(historyusers, currentuser.id)
            if result is false
                historyusers.push currentuser
                return PostUser(baseUrl,server.instance,currentuser)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp)=>
        currentusers = server.users ? []
        historyusers = server.history.users ? []
        #process the historyusers array
        console.log "historyusers ", historyusers
        Promise.map historyusers, (historyuser) =>
            console.log "historyuser ", historyuser
            result =  UserExists(currentusers, historyuser.id)
            if result is false
                historyusers.pop historyuser
                return DeleteUser(baseUrl,server.instance,historyuser)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp)=>
        return resp
    .catch (err)=>
        throw err

###

UpdateUsers = (baseUrl,instanceid,server,history)->
    getPromise()
    .then (resp) =>
        currentusers = server.users ? []
        historyusers = history.users ? []

        #process the currentusers array
        console.log "currentusers ",currentusers
        Promise.map currentusers, (currentuser) =>
            console.log "currentuser  ",currentuser
            result =  UserExists(historyusers, currentuser.id)
            if result is false
                historyusers.push currentuser
                return PostUser(baseUrl,instanceid,currentuser)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp)=>
        currentusers = server.users ? []
        historyusers = history.users ? []
        #process the historyusers array
        console.log "historyusers ", historyusers
        Promise.map historyusers, (historyuser) =>
            console.log "historyuser ", historyuser
            result =  UserExists(currentusers, historyuser.id)
            if result is false
                historyusers.pop historyuser
                return DeleteUser(baseUrl,instanceid,historyuser)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp)=>
        return resp
    .catch (err)=>
        throw err


Update =  (context) ->
    throw new Error 'openvpn-storm.Update missingParams' unless context.bInstalledPackages and context.service.name
    config = context.policyConfig[context.service.name]
    servers =  config.servers ? []
    clients =  config.clients ? []
    instances = context.instances
    history = context.history

    getPromise()
    .then (resp) =>
        #processing the clients array
        Promise.map clients, (client) =>
            #check the client id is present in the instances array
            instance = GetInstanceObject(instances,client.id)
            console.log "instance is "
            console.log instance
            #if instance is not present, then post the new client               
            if instance is null
                getPromise()
                .then (resp)=>
                    return PostClient(context.baseUrl,client)
                .then (resp)=>
                    # received instance object, update the instance object
                    console.log "Update Post client Response" 
                    console.log resp
                    context.instances.push resp  
                    return resp
                .then (resp)=>
                    #history to be update here
                    context.history.clients.push client
                    return resp
                .catch (err)=>
                    throw err
            #if instance is present, then put client config
            else
                history = GetHistoryObject(context.history.clients,client.id)
                #history diff  to be done
                #differences = diff(client.config,history.config)
                console.log "history is "
                console.log history
                getPromise()
                .then (resp)=>
                    return  PutClient(context.baseUrl,client,instance.instance_id)
                .then (resp)=>
                    history = utils.extend {},client.config
                    return resp
                .catch (err)=>
                    throw err
        .then (resp) =>
            #updateclient response to be validated
            return resp
        .catch (err) =>
            throw err
    .then (resp)=>
        #processing the servers array 
        Promise.map servers, (server) =>            
            #check the server id is present in the instances array
            instance = GetInstanceObject(instances,server.id)
            console.log "instance is "
            console.log instance
            #if instance is not present, then post the new server                
            if instance is null
                getPromise()
                .then (resp)=>
                    return PostServer(context.baseUrl,server)
                .then (resp)=>
                    # received instance object, update the instance object
                    console.log "Update Post Server Response" 
                    #console.log resp
                    context.instances.push resp  
                    #Post the Users if users are available in servers array
                    #Promise.map server.users, (user) =>
                    #    return PostUser(context.baseUrl,resp.instance_id,user)
                    #.then (resp)=>
                    #    return resp
                    #.catch (err)=>
                    #    return err
                    return resp
                .then (resp)=>
                    #history to be update here
                    context.history.servers.push server
                    return resp
                .then (resp)=>
                    history = GetHistoryObject(context.history.servers,server.id)    
                    return UpdateUsers(context.baseUrl,resp.instance_id,server,history)
                .catch (err)=>
                    throw err
            #if instance is present, then put server config
            else
                history = GetHistoryObject(context.history.servers,server.id)
                #history diff  to be done
                #differences = diff(server.config,history.config)
                console.log "history is "
                console.log history
                getPromise()
                .then (resp)=>
                    return  PutServer(context.baseUrl,server,instance.instance_id)
                .then (resp)=>                         
                    return UpdateUsers(context.baseUrl,instance.instance_id,server,history)
                .then (resp)=>
                    history.config = utils.extend {},server.config                    
                    return resp
                .catch (err)=>
                    throw err
        .then (resp) =>
            #update server response to be validated here
            return resp
        .catch (err)=>
            throw err
    .then (response)=>
        #console.log "Final response",response
        return context
    .catch (err)=>
        throw err

#input to the validate is  { servers:[],clients:[]}
Validate =  (config) ->
    throw new Error "openvpn.Validate - invalid input" unless config.servers? and config.clients?
    for server in config.servers
        chk = validate server.config, schema['server']
        console.log 'server validate result ', chk
        unless chk.valid
            throw new Error "server schema check failed"+  chk.valid
            return  false
        if server.users?
            for user in server.users
                chk = validate user, schema['user']
                console.log 'user validate result ', chk
                unless chk.valid
                    throw new Error "user schema check failed"+  chk.valid
                    return  false

    for client in config.clients
        chk = validate client.config, schema['client']
        console.log 'client validate result ', chk
        unless chk.valid
            throw new Error "client schema check failed"+  chk.valid
            return  false

    return true

module.exports.start = Start
module.exports.stop = Stop
module.exports.update = Update
module.exports.validate = Validate
