StormRegistry = require 'stormregistry'
StormData = require 'stormdata'

OpenvpnService = require './openvpn-service'

class VpnServerRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            console.log "restoring #{key} with:",val
            entry = new OpenvpnService key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            # an entry is removed in Registry
            entry.destructor() if entry.destructor?

        super filename

    add: (service) ->
        return unless service instanceof OpenvpnService
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

class VpnUserRegistry extends StormRegistry

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
            @adduser entry.data

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

module.exports.VpnServerRegistry  = VpnServerRegistry
module.exports.VpnUserRegistry  = VpnUserRegistry 
