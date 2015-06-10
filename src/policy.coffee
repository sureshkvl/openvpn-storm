assert = require 'assert'
request = require 'request'
Promise = require 'bluebird'
async = require 'async'
needle = Promise.promisifyAll(require('needle'))

validateUUID = (data, opts) ->
    validator = require 'validator'
    return validator.isUUID(data)

validatePort = (data, opts) ->
    return false if  data > 65536 or data < 0
    match = opts.rules?.filter (rule) ->
        return true if rule is data
    return false if match?.len > 0 and opts.rules?.len > 0
    return true

validateProtocol = (data, rules) ->
    match = opts.rules?.filter (rule) ->
        return true if data is rule
    return true if match.len > 0
    return false

validateString = (data, rules) ->
    return true

validateMaps =
    "type:uuid": validateUUID
    "type:port": validatePort
    "type:string": validateString
    "type:protocol": validateProtocol

getPromise = ->
    return new Promise (resolve, reject) ->
        resolve()


 schema =
        id:                 {"type":"string", "required":false, "validate":"type:uuid"}
        port:                {"type":"number", "required":true, "validate":"type:port"}
        dev:                 {"type":"string", "required":true, "validate":"type:string", "rules":["tun", "tap"]}
        proto:               {"type":"string", "required":true, "validate":"type:protocol", "rules":["tcp", "udp"]}
        ca:                  {"type":"string", "required":true}
        dh:                  {"type":"string", "required":true}
        cert:                {"type":"string", "required":true}
        key:                 {"type":"string", "required":true}
        server:              {"type":"string", "required":true}
        'ifconfig-pool-persist': {"type":"string", "required":false}
        'script-security':   {"type":"string", "required":false}
        multihome:           {"type":"boolean", "required":false}
        management:          {"type":"string", "required":false}
        cipher:              {"type":"string", "required":false}
        'tls-cipher':        {"type":"string", "required":false}
        auth:                {"type":"string", "required":false}
        topology:            {"type":"string", "required":false}
        'route-gateway':     {"type":"string", "required":false}
        'client-config-dir': {"type":"string", "required":false}
        'ccd-exclusive':     {"type":"boolean", "required":false}
        'client-to-client':  {"type":"boolean", "required":false}
        route:
            items: { type: "string" }
        push:
            items: { type: "string" }
        'tls-timeout':       {"type":"number", "required":false}
        'max-clients':       {"type":"number", "required":false}
        'persist-key':       {"type":"boolean", "required":false}
        'persist-tun':       {"type":"boolean", "required":false}
        status:              {"type":"string", "required":false}
        keepalive:           {"type":"string", "required":false}
        'comp-lzo':          {"type":"string", "required":false}
        sndbuf:              {"type":"number", "required":false}
        rcvbuf:              {"type":"number", "required":false}
        txqueuelen:          {"type":"number", "required":false}
        'replay-window':     {"type":"string", "required":false}
        'duplicate-cn':      {"type":"boolean", "required":false}
        'log-append':        {"type":"string", "required":false}
        verb:                {"type":"number", "required":false}
        mlock:               {"type":"boolean", "required":false}
        'tun-mtu':           {"type":"number", "required":false}
        mssfix:              {"type":"string", "required":false}

validate =  (obj, schema, callback) ->
    getPromise()
    .then  ->
        for key, val in schema
            assert val.required and obj[key]?, "unable to find required field #{key}"
            if val.type?
                assert typeof obj[key] is val.type, "mismatched value found for key #{key} expected is #{schema.type}"
            # Niw vakudate the value
            result = validateMaps[schema.validate?]? obj.key, rules:schema.rules
            result ?= {}
            assert unless result instanceof Error "validation failed for the values in the passed in object for key:#{key} with error #{result}"
            return true
    .nodeify (callback)



unSetup =  (context, callback) ->
        securityUnConnect context
        .then (resp) ->
            deleteServers context
        .then (resp) ->
            deletePackages context
        .nodeify (callback)


deletePackages = (context, callback) ->
    getPromise()
    .then (resp) ->
        if context.bInstalledPackages
            # Delete entire context
            Promise.map context.reqPackages, (pkg) ->
                return needle.deleteAsync context.baseUrl+"/packages/#{pkg.id}"
                    .then (resp) ->
                        throw new Error name:'invalidStatusCode', value:resp[0].statusCode unless resp[0].statusCode is 204
                        return resp[1]
                    .catch (err) ->
                        console.log "error in deleting package", pkg
                        throw err
            .then (results) ->
                context.bInstalledPackages = false
        return context
    .nodeify (callback)

deleteServers = (context, callback) ->
    getPromise()
    .then (resp) ->
        if context.serverId
            return needle.deleteAsync context.baseUrl+"/openvpn/#{context.serverId}"
        else
           return
    .then (resp) ->
        if resp?
            throw new Error name:'invalidStatusCode', value:resp[0].statusCode unless resp[0].statusCode is 200
        return "success"
    .nodeify (callback)

    


setup =  (context, data, callback) ->
        # Check if the packages are present in the endpoint
    Promise.try =>
        validate data, schema
        .then (resp) =>
            context.setupData = data
            return context
        .then (resp) =>
            throw new Error 'missingParams' unless data?
            pkgs = require('../package.json').stormflash.packages
            reqPackages = []
            for pkg in pkgs
                pack =
                    name: pkg.split("://")[1]
                    version: '*'
                    source:pkg.split("://")[0]+"://"
                reqPackages.push pack
            plugin =
                name:require('../package.json').name
                version:require('../package.json').version
                source:"npm://"
            reqPackages.push  plugin
            console.log "required packages int hem minion", reqPackages
            context.reqPackages = reqPackages
            return context
        .then (context) =>
            return needle.getAsync context.baseUrl+'/packages'
        .then (resp) =>
            #return JSON.parse resp[1]
            return resp[1]
        .then (resp) =>
            unless context.bInstalledPackages
                pkgs = resp.packages
                pkgs?.filter (pkg) =>
                    context.reqPackages = context.reqPackages.filter (rpkg) =>
                        return true if pkg.name is rpkg.name and (pkg.source is rpkg.source or pkg.source is 'builtin') and (rpkg.version is "*" or rpkg.version is pkg.version)
                console.log "required packages are ", context.reqPackages
                return Promise.map context.reqPackages, (pkg) =>
                    needle.postAsync context.baseUrl+"/packages", pkg, {json:true}
                    .then (resp) =>
                            throw new Error name:'invalidStatusCode', value:resp[0].statusCode unless resp[0].statusCode  is 200 and resp[1]?
                            console.log "response data is ", resp[1]
                            if resp[1].data?
                                presp = resp[1].data
                            else
                                presp = resp[1]
                            pkg.id = presp.id
                            retries = 5
                            console.log "response to package installation is ", presp
                            checkInstallation = (rtries, pinfo ) =>
                                rtries--
                                throw new Error "retriesComplete"  if rtries is 1
                                console.log "trying to fetch, retriy #{rtries} ", new Date
                                needle.getAsync context.baseUrl+"/packages/#{pinfo.id}"
                                .then (resp) =>
                                    console.log "response for get package #{pinfo.id} is ", resp[1]
                                    throw new Error "invalidResponse" unless resp[1]?.status?
                                    unless resp[1]?.status?.installed and resp[1]?.status?.imported and retries
                                        return Promise.delay(50000).then =>  return checkInstallation rtries , pinfo
                                    return resp[1]
                                .catch (err) =>
                                    console.log "error in fetching status of the package #{presp.id} ", err
                                    throw new Error err
                            type = presp?.source?.split(":")
                            console.log "source is ", presp.source , "and type is ", type
                            if type[0]? and type[0] is "npm"
                                checkInstallation retries, presp
                                .then =>
                                    console.log "done verifying the package"
                                    return presp
                                .catch (err) ->
                                    console.log "error in fetching status of package ", presp, "error is ", err
                                    throw new Error err
                            else
                                console.log "returning wiht out verifying installation status"
                                return presp
                    .catch (err) =>
                        console.log "error in posting package ", err, pkg
                        throw new Error err
            else return {}
        .then (results) =>
            personalities = [
                path:data.caBundle.filename
                contents: data.caBundle.data
                postxfer: ""
               ,
                path:data.caKey.filename
                contents: data.caKey.data
                postxfer: ""
               ,
                path:data.caCert.filename
                contents:data.caCert.data
                postxfer: ""
            ]
            console.log "setting up personalities"
            Promise.map personalities, (personality) =>
                needle.postAsync context.baseUrl+"/personality", personality:personality, {json:true}
                .then (resp) =>
                    console.log "resonse for personality is ", resp[0], resp[1]
                    throw new Error 'invalidStatusCode' unless resp[0].statusCode  is 200
                    console.log "response for personality is ", resp[1]
                    return resp[1]
                .catch (err) =>
                    console.log "error in posting personality " , err
                    throw new Error err
            .then (results) =>
                context.bInstalledPackages = true
                unless context.bPolicyPush
                    #Promise.props
                    console.log "posting the openvpn server"
                    needle.postAsync context.baseUrl+"/openvpn", data?.server, json:true
                    .then (resp) ->
                        throw new Error 'invalidStatusCode' unless resp[0].statusCode  is 200
                        return resp[1]
        .then (result) =>
            context.setup = data?.server
            context.serverid = result.id
            context.bPolicyPush = true
            return context
        .nodeify (callback)


securityConnect =  (context, opts, callback) ->
    if opts.bDelete?
        return securityUnConnect context, opts, callback
    getPromise()
    .then (resp) ->
        throw new Error name:'missingParams'  unless opts?.value?.clients? and opts?.value?.servers?
        Promise.filter opts.value.servers (server) ->
            needle.postAsync context.baseUrl+"/openvpn/#{context.serverId}/users", opts?.value?.clients, json:true
            .then (resp) ->
                throw new Error name:'invalidStatusCode', value:resp[0].statusCode unless resp[0].statusCode is 200
                return resp[1]
    .then (resp) ->
        console.log "response is ", resp
    .nodeify (callback)

                
securityUnConnect =  (context, opts, callback) ->
    getPromise()
    .then (resp) ->
        throw new Error name:'missingParams'  unless opts? and opts.clients? and opts.servers?
        Promise.filter opts.servers (server) ->
            Promise.filter opts.clients (client) ->
                needle.deleteAsync context.baseUrl+"/openvpn/#{context.serverId}/users/#{client.id}"
                .then (resp) ->
                    throw new Error name:'invalidStatusCode', value:resp[0].statusCode unless resp[0].statusCode is 200
                    return resp[1]
    .then (resp) ->
        console.log "response is ", resp
    .nodeify (callback)

modify = (context, opts, callback) ->

module.exports.actions  = {"securityConnect": securityConnect, "securityUnConnect":securityUnConnect}
module.exports.setup = setup
module.exports.modify = modify
module.exports.unsetup = unSetup


if require.main is module
    context =
        baseUrl:"http://67.229.243.35:5000"
    config =
        "clearpath-openvpn":
            caBundle: encoding:'base64', data:"", filename:""
            caKey: encoding:'base64', data:"", filename:""
            caCert: encoding:'base64', data:"", filename:""
            server:
                port:  7000
                dev:   "tun1"
                proto: "udp"
                ca:    "/var/stormflash/meta/ca-bundle.pem"
                dh:    "/etc/dh1024.pem"
                cert:  "/var/stormflash/meta/openvpn.cert"
                key:   "/var/stormflash/meta/openvpn.key"
                server: "172.17.0.0 255.255.255.0"
                multihome: true
                management: "127.0.0.1 2020"
                cipher: "AES-256-CBC"
                auth: "SHA1"
                topology: "subnet"
                route: null
                push: [
                   "comp-lzo no"
                ]
                status: "/var/log/server-status.log"
                keepalive: "5 60"
                sndbuf: 262144
                rcvbuf: 262144
                txqueuelen: 500
                verb: 3
                mlock: true
                "script-security": "3 system"
                "tls-cipher": "DHE-RSA-AES256-SHA"
                "route-gateway": "172.17.0.1"
                "client-config-dir": "/var/stormflash/meta/ccd"
                "ccd-exclusive": true
                "max-clients": 254
                "persist-key": true
                "persist-tun": true
                "comp-lzo": "no"
                "client-to-client": true
    config = require('/tmp/valid.json')

    needle.postAsync context.baseUrl+"/personality", personality:{path:config.caBundle.filename, contents:config.caBundle.data, postxfer:""}, {json:true}
    .then (resp) ->
        console.log "response is ", resp[1]
    ###
    setup  context, config, (err, results) ->
        console.log err, results
    ###
