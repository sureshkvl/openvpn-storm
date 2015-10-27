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
        return server
    .catch (err) =>
        throw err

DeleteClient = (baseUrl,client)->
    needle.deleteAsync baseUrl + "/openvpn/client/#{client.instance}", json:true
    .then (resp) =>
        throw new Error 'invalidStatusCode' unless resp[0].statusCode is 204
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


Start =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    #throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    configObj = context.service.factoryConfig?.config
    config = configObj[context.service.name]

    servers =  config.servers ? []
    clients =  config.clients ? []
    
    #throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(servers) and utils.isEmpty(clients)
    return context if utils.isEmpty(servers) and utils.isEmpty(clients)
    return context unless config.enable is true

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
    throw new Error 'openvpn-storm.Stop missingParams' unless context.bInstalledPackages and context.service.name
    #throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    #configObj = context.service.factoryConfig?.config
    #config = configObj[context.service.name]
    config = context.policyConfig[context.service.name]
    servers =  config.servers ? []
    clients =  config.clients ? []
    
    throw new Error "openvpn-storm.Stop missing server,client info" if utils.isEmpty(servers) and utils.isEmpty(clients)
    return context unless config.enable is true
   
    getPromise()
    .then (resp) =>
        Promise.map servers, (server) ->
            return DeleteServer(context.baseUrl,server)
        .then (resp) =>
            servers = utils.difference(servers,resp)
            config.servers = servers
            #context.service.servers = servers
            return resp
        .catch (err) =>
            throw err
    .then (resp) =>
        Promise.map clients, (client) ->
            return DeleteClient(context.baseUrl,client)
        .then (resp) =>
            clients = utils.difference(clients,resp)
            config.clients = clients
            #context.service.clients = clients
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

Update =  (context) ->
    throw new Error 'openvpn-storm.Update missingParams' unless context.bInstalledPackages and context.service.name
    #throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    #servers =  context.service.servers ? []
    #clients =  context.service.clients ? []

    config = context.policyConfig[context.service.name]
    servers =  config.servers ? []
    clients =  config.clients ? []


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
###
    policyConfig = {}
    if config.enable and config.coreConfig
        policyConfig.zebra = config.coreConfig
    if config.protocol.ospf.enable and config.protocol.ospf.config
        policyConfig.ospfd = config.protocol.ospf.config

    for name, conf of policyConfig
        options = {}
        options.propertyName = name
        res = Validator.validate conf, schema[name], options
        if res.errors?.length
            throw new Error "openvpn.Validate ", res
###

module.exports.start = Start
module.exports.stop = Stop
module.exports.update = Update
module.exports.validate = Validate
