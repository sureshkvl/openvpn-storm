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


Start =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    servers =  context.service.servers  unless utils.isEmpty(context.service.servers)
    clients =  context.service.clients  unless utils.isEmpty(context.service.clients)
    
    getPromise()
    .then (resp) =>
        if servers?
            Promise.map servers, (server) ->
                needle.postAsync context.baseUrl + "/openvpn/server", server.config, json:true
                .then (resp) =>
                    throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
                    server.instance = resp[1].id
                    server.history ?= {}
                    server.history.config = utils.extend {},server.config
                    server.history.users = []
                    return server
                .catch (err) =>
                    throw err
            .then (resp) =>
                return resp
            .catch (err) =>
                throw err
    .then (resp) =>
        if clients?
            Promise.map clients, (client) ->
                needle.postAsync context.baseUrl + "/openvpn/client", client.config, json:true
                .then (resp) =>
                    throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
                    client.instance = resp[1].id
                    client.history ?= {}
                    client.history.config = utils.extend {},client.config
                    return client                    
                .catch (err) =>
                    throw err
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

    servers =  context.service.servers  unless utils.isEmpty(context.service.servers)
    clients =  context.service.clients  unless utils.isEmpty(context.service.clients)
   
    getPromise()
    .then (resp) =>
        if servers?
            Promise.map servers, (server) ->
                needle.deleteAsync context.baseUrl + "/openvpn/server/#{server.instance}", json:true
                .then (resp) =>
                    throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204                    
                    return "done"            
                .catch (err) =>
                    throw err
            .then (resp) =>
                return resp
            .catch (err) =>
                throw err
    .then (resp) =>
        if clients?
            Promise.map clients, (client) ->
                needle.deleteAsync context.baseUrl + "/openvpn/client/#{client.instance}", json:true
                .then (resp) =>
                    throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204                    
                    return "done"            
                .catch (err) =>
                    throw err
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

Update =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)
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
    servers =  context.service.servers  unless utils.isEmpty(context.service.servers)
    clients =  context.service.clients  unless utils.isEmpty(context.service.clients)
    getPromise()
    .then (resp) =>
        #step 1 and 2
        if servers?
            Promise.map servers, (server) =>    
                console.log "inside update server map ", server
                unless server.instance?
                    console.log "server instance not present .. hence new server case"
                    needle.postAsync context.baseUrl + "/openvpn/server", server.config, json:true
                    .then (resp) =>
                        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
                        server.instance = resp[1].id
                        server.history ?= {}
                        server.history.config = utils.extend {},server.config
                        server.history.users = []
                        return server
                    .catch (err) =>
                        throw err        
                else if server.instance? and server.config? and server.history.config?
                    console.log "server instance is present .. hence server modification case"
                    #find the difference between  server.config , server.history.config 
                    differences = diff(server.config,server.history.config)     
                    console.log differences               
                    unless utils.isEmpty(differences) or  not differences?
                        console.log "server config difference is found...server put call"
                        needle.putAsync context.baseUrl + "/openvpn/server/#{server.instance}", server.config, json:true
                        .then (resp) =>
                            throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200                        
                            server.history.config = server.config
                            return server
                        .catch (err) =>
                            throw err              
                    #find the diff between the current users and history users
                    #console.log "server.config.users", server.users
                    #console.log "server.history.users", server.history.users
                    currentusers = server.users
                    historyusers = server.history.users
                    #console.log "currentusers", currentusers
                    #console.log "historyusers",historyusers

                    for user in currentusers when not utils.isEmpty(currentusers)
                        result =  UserExists(historyusers, user.id)
                        if result is false
                            console.log "this user is a new user- To be posted", user
                            needle.postAsync context.baseUrl + "/openvpn/server/#{server.instance}/users", user, json:true
                            .then (resp) =>
                                throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200                                
                                historyusers.push user
                                return resp.body
                            .catch (err) =>
                                throw err       

                    for user in historyusers when not utils.isEmpty(historyusers)
                        result =  UserExists(currentusers, user.id)
                        if result is false
                            console.log "this user is a removed user- To be deleted", user
                            needle.deleteAsync context.baseUrl + "/openvpn/server/#{server.instance}/users/#{user.cname}", json:true
                            .then (resp) =>
                                throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200                                
                                historyusers.pop user
                                return resp.body
                            .catch (err) =>
                                throw err                                      
            .then (resp)=>
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
                        client.history.users = []
                        return client
                    .catch (err) =>
                        throw err        
                else if client.instance? and client.config? and client.history.config?
                    #find the difference between  server.config , server.history.config 
                    differences = diff(client.config,client.history.config)                    
                    unless utils.isEmpty(differences) or  not differences?
                        needle.putAsync context.baseUrl + "/openvpn/client/#{client.instance}", client.config, json:true
                        .then (resp) =>
                            throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200                        
                            client.history.config = client.config
                            return client   
                        .catch (err) =>
                            throw err                


    .then (resp)=>
        return resp
    .catch (err)=>
        throw err

module.exports.start = Start
module.exports.stop = Stop
module.exports.update = Update
#module.exports.validate = Validate