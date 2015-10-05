Valid = require('jsonschema').Validator
Validator = new Valid
assert = require 'assert'
Promise = require 'bluebird'
async = require 'async'
needle = Promise.promisifyAll(require('needle'))
utils = require('utils')._


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
                    return { id: resp[1].id }            
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
                    return { id: resp[1].id }            
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

Update =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name
    throw new Error "openvpn-storm.Start missing server,client info" if utils.isEmpty(context.service.servers) and utils.isEmpty(context.service.clients)

    #step1. process all the server array. if instance is not preset - assume that is new server.  post the server and update the instance id
    #step2: process all the server arry which has instance in it,  (diff with old history is present , put  the server cofnig)
    #step3: process all the users array - if user is not present in history then user post
    #                                          if history user is not in the list, then delete the user
    #step4: process all the clients array : if instance is not present - assume that is the new client . post it
    #step5: process all the clients array : if instance is  present - (diff with old history,put the client config if required)

###
delUser = (URL,id,user) ->
    getPromise()
    .then (resp) =>     
        #console.log instance.users            
        console.log "del url  : /openvpn/server/#{id}/users/#{user.cname}"
        needle.deleteAsync  URL + "/openvpn/server/#{id}/users/#{user.cname}", user, json:true
        .then (resp) =>
            throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
            #console.log "response" + JSON.stringify resp
            return resp
        .catch (err) =>
            throw err   

postUser = (URL,id, user) ->
    getPromise()
    .then (resp) =>
        console.log "post url  : /openvpn/server/#{id}/users"       
        needle.postAsync  URL + "/openvpn/server/#{id}/users", user, json:true
        .then (resp) =>
            throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200            
            return resp
        .catch (err) =>
            throw err

putServer = (URL, instance) ->
    getPromise()
    .then (resp) =>
        console.log "put url  : /openvpn/#{instance.name}/#{instance.id}"               
        console.log "conf",instance.conf
        needle.putAsync  URL + "/openvpn/#{instance.name}/#{instance.id}", instance.conf, json:true
        .then (resp) =>
            throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200            
            return resp
        .catch (err) =>
            throw err   

Validate =  (config) ->
    policyConfig = {}
    if config.server?.enable and config.server?.coreConfig
        policyConfig.server = config.server.coreConfig
    if config.client?.enable and config.client?.coreConfig
        policyConfig.client = config.server.coreConfig

    for name, conf of policyConfig
        options = {}
        options.propertyName = name
        res = Validator.validate conf, schema[name], options
        if res.errors?.length
            throw new Error "openvpn.Validate ", res


Start =  (context) ->
    throw new Error 'openvpn-storm.Start missingParams' unless context.bInstalledPackages and context.service.name

    if context.instances?.length is 2
        return context
    context.instances ?= []
    configObj = context.service.factoryConfig?.config
    console.log "configObj ",configObj
    console.log "context.servicce.name ", context.service.name
    config = configObj[context.service.name]
    console.log "config  ",config
   
    configs = []
    if config.server?.enable and config.server?.coreConfig
        configs.push {name: 'server', config: config.server.coreConfig}
    if config.client?.enable and config.client?.coreConfig
        configs.push {name: 'client', config: config.client.coreConfig}

    getPromise()
    .then (resp) =>
        Promise.map configs, (config) ->
            needle.postAsync context.baseUrl + "/openvpn/#{config.name}", config.config, json:true
            .then (resp) =>
                throw new Error 'invalidStatusCode' unless resp[0].statusCode is 200
                return { name: config.name, id: resp[1].id }
            .catch (err) =>
                throw err

        .then (resp) =>
            return resp

        .catch (err) =>
            throw err

    .then (resp) =>
        for res in resp
            if res
                inst = null
                inst = instance for instance in context.instances when instance[res.name]
                if inst
                    inst[res.name] = res.id
                else
                    context.instances.push res
        return context

    .catch (err) =>
        throw err

Stop = (context) ->
    instances = context?.instances
    getPromise()
    .then (resp) ->
        Promise.map instances, (instance) =>
            needle.deleteAsync context.baseUrl+ "/openvpn/#{instance.name}/#{instance.id}", null
            .then (resp) =>
                throw new Error name:'invalidStatusCode', value:resp[0].statusCode unless resp[0].statusCode is 204
                return 'done'
            .catch (err) =>
                throw err

    .catch (error) =>
        throw error


Update = (context) ->
    throw new Error name:'openvpn-storm.Update missingParams' unless context.instances and context.service.policyConfig
    policyConfig = {}
    policyConfig.server = {}
    config = context.service.policyConfig[context.service.name]
    console.log "config is ", config
    policyConfig.server.config = config.server.coreConfig  if config.server?.enable and config.server?.coreConfig
    policyConfig.server.users = config.server.users  if config.server?.enable and config.server?.users
    for instance in context.instances
        instance.conf = policyConfig[instance.name].config
        instance.users = policyConfig[instance.name].users
        putServer context.baseUrl, instance  if instance.conf? and instance.conf isnt null
    
    #user addition/removal
    if context.history?.server?.users?
        ExistingUsers = context.history.server.users  
    else
        context.history = {}
        context.history.server = {}
        context.history.server.users = []
        ExistingUsers = context.history.server.users  

    console.log "ExistingUsers", ExistingUsers
    console.log context.instances[0].users 

    for user in context.instances[0].users 
        unless user in ExistingUsers
            console.log "User POST ", user
            postUser context.baseUrl,context.instances[0].id, user 
            ExistingUsers.push user
    for user in ExistingUsers
        unless user in context.instances[0].users
            delUser context.baseUrl,context.instances[0].id,user
            ExistingUsers.pop user

    console.log "ExistingUsers final"
    console.log ExistingUsers
    console.log context.history.server.users 
    console.log context
###

module.exports.start = Start
module.exports.stop = Stop
#module.exports.update = Update
#module.exports.validate = Validate