StormRegistry = require 'stormregistry'
StormData = require 'stormdata'

OpenvpnService = require('./openvpn-service').OpenvpnService
OpenvpnClientService = require('./openvpn-service').OpenvpnClient
OpenvpnServerService = require('./openvpn-service').OpenvpnServer

class OpenvpnRegistry extends StormRegistry
    constructor: (@svc, filename) ->
        @on 'load', (key,val) ->
            console.log "restoring #{key} with:",val

            if @svc is "client"            
                entry = new OpenvpnClientService key,val
            else
                entry = new OpenvpnServerService key,val

            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            # an entry is removed in Registry
            entry.destructor() if entry.destructor?

        super filename

    add: (service) ->
        if @svc is "client"
            return unless service instanceof OpenvpnClientService 
        else
            return unless service instanceof OpenvpnServerService 
            
        entry = super service.id, service
        # register for 'running' events of this service and update DB
        entry.on "running", (instance) =>
            if entry.instance isnt instance
                entry.instance = instance
                @update entry

    update: (service) ->
        service.data.instance = service.instance
        super service.id, service
        delete service.data.instance

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof OpenvpnService 
            entry.data.id = entry.id
            entry.data
        else
            entry


class UserData extends StormData

    userSchema =
        name: "openvpn"
        type: "object"
        additionalProperties: true
        properties:
            id:      { type: "string", required: false}
            email:   { type: "string", required: false}
            cname:   { type: "string", required: false}
            ccdPath: { type: "string", required: false}
            push:
                items: { type: "string" }

    constructor: (id, data) ->
        super id, data, userSchema

#------------------------------------------------------------------------

class OpenvpnUserRegistry extends StormRegistry
   
    fs = require 'fs'

    constructor: (filename) ->
        @on 'load', (key,val) ->
            entry = new UserData key,val
            if entry?
                entry.saved = true
                @add key, entry

        @on 'removed', (key) ->
            # an entry is removed in Registry
        super filename

        @on 'added', (entry) ->
            #Commented here as the addition is done through plugin POST call
            #@adduser entry.data

    get: (key) ->
        entry = super key
        return unless entry?
        if entry.data? and entry.data instanceof UserData
            entry.data.id = entry.id
            entry.data
        else
            entry

    adduser: (user) ->
        file =  if user.cname then user.cname else user.email
        filename = user.ccdpath + "/" + "#{file}"
        gconfig = ''
        for key, val of user
            switch (typeof val)
                when "object"
                    if val instanceof Array
                        for i in val
                            gconfig += "#{key} #{i}\n" if key is "iroute"
                            gconfig += "#{key} \"#{i}\"\n" if key is "push"
        console.log "filename for ccd generated is ", filename
        fs.writeFileSync filename,gconfig

    deleteuser: (server, user, callback) ->
        path = require 'path'        
        ccdpath = server.data["client-config-dir"]
        cname = user["cname"]
        email = user["email"]
        file =  if cname then cname else email
        filename = ccdpath + "/" + "#{file}"        
        exists = path.existsSync filename
        if not exists
            console.log 'file removed already'            
            return callback new Error "user is already removed!"
        fs.unlink filename, (err) =>
            if err
                callback(err)
            else
                console.log 'removed file'
                callback(true)

module.exports.OpenvpnRegistry  = OpenvpnRegistry
module.exports.OpenvpnUserRegistry  = OpenvpnUserRegistry
