Valid = require('jsonschema').Validator
Validator = new Valid
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
    "user" : schema_server

getPromise = ->
    return new Promise (resolve, reject) ->
        resolve()

PostServer = (baseUrl,server)->
    needle.postAsync baseUrl + "/openvpn/server", server.config, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        server.instance = resp[1].id
        server.history ?= {}
        server.history.config = utils.extend {},server.config
        server.history.users = []
        return server
    .catch (err) =>
        throw err

PostClient = (baseUrl,client)->
    needle.postAsync baseUrl + "/openvpn/client", client.config, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        client.instance = resp[1].id
        client.history ?= {}
        client.history.config = utils.extend {},client.config
        return client   
    .catch (err) =>
        throw err

DeleteServer = (baseUrl,server)->
    needle.deleteAsync baseUrl + "/openvpn/server/#{server.instance}", json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204    
        #Todo : delete the server object
        server = null
        return server            
    .catch (err) =>
        throw err

DeleteClient = (baseUrl,client)->
    needle.deleteAsync baseUrl + "/openvpn/client/#{client.instance}", json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204     
        #Todo : delete the client object               
        client = null
        return client
    .catch (err) =>
        throw err

PutServer = (baseUrl,server)->
    needle.putAsync baseUrl + "/openvpn/server/#{server.instance}", server.config, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200                        
        server.history.config = utils.extend {},server.config
        return server
    .catch (err) =>
        throw err

PutClient = (baseUrl,client)->
    needle.putAsync baseUrl + "/openvpn/client/#{client.instance}", client.config, json:true
    .then (resp) =>
        console.log "respo code", resp[0].statusCode
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        client.history.config = utils.extend {},client.config
        return client
    .catch (err) =>
        throw err

PostUser = (baseUrl,serverid,user)->
    needle.postAsync baseUrl + "/openvpn/server/#{serverid}/users", user, json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200                                
        #historyusers.push user
        return resp.body
    .catch (err) =>
        throw err       


DeleteUser = (baseUrl,serverid,user)->
    needle.deleteAsync baseUrl + "/openvpn/server/#{serverid}/users/#{user.cname}", json:true
    .then (resp) =>
        console.log "response code is", resp[0].statusCode
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
        #historyusers.pop user
        return resp.body
    .catch (err) =>
        throw err


Start =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    servers =  context.service.servers ? [] # unless utils.isEmpty(context.service.servers)
    clients =  context.service.clients ? [] # unless utils.isEmpty(context.service.clients)
    
    getPromise()
    .then (resp) =>
        Promise.map servers, (server) ->
            return PostServer(context.baseUrl,server)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        Promise.map clients, (client) ->              
            return PostClient(context.baseUrl,client)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        return context
    .catch (err) =>
        throw err

Stop = (context) ->
    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    servers =  context.service.servers  ? [] #unless utils.isEmpty(context.service.servers)
    clients =  context.service.clients  ? [] #unless utils.isEmpty(context.service.clients)
   
    getPromise()
    .then (resp) =>
        #if servers?
        Promise.map servers, (server) ->
            return DeleteServer(context.baseUrl,server)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        #if clients?
        Promise.map clients, (client) ->
            return DeleteClient(context.baseUrl,client)
        .then (resp) =>
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        return context
    .catch (err) =>
        throw err

UserExists = (list,id)->
    for item in list
        if item.id is id
            return true
    return false





###
    #logic
    step1. iterate the servers array. 
       a. if instance is not preset  - assume this is  a new server.  
           - post the server and update the instance id, and save the config in history
       b.if instance is present, (assume this is the existing running server) 
            i) diff with config and history config 
                if diff is found, then server config is changed,
                put the server config 

            ii) check the current users aray and history users array              
                - if current user is not present in the history users 
                      then this is the new user , POST the new user and update it in the history users
                - if history user is not present in the current users , 
                       then this uses to be deleted. DELETE this user
    step2: iterate the clients array
       a. if instance is not present - assume that is the new client . 
           - post the client and update the instance id, and save the config in the history
       b. if the instance is present (assume this is the existing running client)
            i) diff with config and history config 
                if diff is found, then client config is changed,
                put the client config 
###


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
        return PostServer(baseUrl,server) unless server.instance?
        differences = diff(server.config,server.history.config)                    
        return PutServer(baseUrl,server) unless utils.isEmpty(differences) or  not differences?
        return server #no difference in server config
    .catch (err) =>
        throw err    

Update =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    servers =  context.service.servers ? []  #unless utils.isEmpty(context.service.servers)
    clients =  context.service.clients ? [] #unless utils.isEmpty(context.service.clients)

    getPromise()
    .then (resp) =>
        #processing the clients array
        Promise.map clients, (client) =>
            return UpdateClient(context.baseUrl,client)
        .then (resp) =>
            #updateclient response to be validated
            return resp
        .catch (err) =>
            throw err 
    .then (resp)=>        
        #processing the servers array 
        Promise.map servers, (server) =>
            return UpdateServer(context.baseUrl,server)
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
#a
###
        Promise.map servers, (server) =>    
            console.log "inside update server map ", server
            unless server.instance?
                console.log "server instance not present .. hence new server case"
                return PostServer(context.baseUrl,server)

            else if server.instance? and server.config? and server.history.config?
                console.log "server instance is present .. hence server modification case"
                #find the difference between  server.config , server.history.config 
                differences = diff(server.config,server.history.config)     
                console.log differences               
                unless utils.isEmpty(differences) or  not differences?
                    console.log "server config difference is found...server put call"
                    return PutServer(context.baseUrl,server)
                        
                    #find the diff between the current users and history users
                    #console.log "server.config.users", server.users
                    #console.log "server.history.users", server.history.users
                server.users ?= []
                server.history.users ?= []
                currentusers = server.users                     
                historyusers = server.history.users
                console.log "currentusers", currentusers
                console.log "historyusers",historyusers                
                    

                for user in currentusers when not utils.isEmpty(currentusers)
                    result =  UserExists(historyusers, user.id)
                    if result is false
                            console.log "this user is a new user- To be posted", user
                            return PostUser user
                    for user in historyusers when not utils.isEmpty(historyusers)
                        result =  UserExists(currentusers, user.id)
                        if result is false
                            console.log "this user is a removed user- To be deleted", user
                            return DeleteUser
            .then (resp)=>
                console.log "\n\npromise map - servers response are ", resp
                return resp
            .catch (err)=>
                throw err

        if clients?
            Promise.map clients, (client) =>    
                console.log "inside update client map ", client
                unless client.instance?
                    needle.postAsync context.baseUrl + "/openvpn/client", client.config, json:true
                    .then (resp) =>
                        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
                        client.instance = resp[1].id
                        client.history ?= {}
                        client.history.config = utils.extend {},client.config                    
                        return client
                    .catch (err) =>
                        throw err        
                else if client.instance? and client.config? and client.history.config?
                    #find the difference between  server.config , server.history.config 
                    differences = diff(client.config,client.history.config)                    
                    unless utils.isEmpty(differences) or  not differences?
                        return PutClient               


    .then (resp)=>
        console.log "\n\n\nfinal response", resp
        return context
    .catch (err)=>
        throw err
###
module.exports.start = Start
module.exports.stop = Stop
module.exports.update = Update
#module.exports.validate = Validate