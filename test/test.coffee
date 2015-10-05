jsonfile = require('jsonfile')
Start = require('./../src/context').start
Stop = require('./../src/context').stop
Update = require('./../src/context').update
Promise = require 'bluebird'

argv = require('minimist')(process.argv.slice(2))
if argv.h?
	console.log """
        -h view this help
        -S <json filename> - Start with the given json file input
        -s <json filename> - Stop with the given json file input
        -U <json filename> - Update with the given json file input, Multiple files can be separated by comma ,  .
    """
	return
context = {}
config =
	startjson: argv.S 
	stopjson: argv.s 
	updatejson: argv.U 

instances = null

unless config.startjson? or config.stopjson? or config.updatejson?
	console.log "minimum one input required"
	return

#console.log "config.updatejson  ", config.updatejson
#updatefiles = []
#updatefiles = config.updatejson.split ","

#console.log "updatefiles ", updatefiles

getPromise = ->
	return new Promise (resolve, reject) ->
		resolve()

startcall = ()->
	#console.log "processing the start "
	#console.log "Processing the  Start file.. ",config.startjson
	jsonfile.readFile config.startjson,(err,obj)->
		console.log err if err?
		#console.log "JSON Input ", obj

		getPromise()
		.then (resp) =>
			return Start obj
		.catch (err) =>
			console.log "Start err ", err
		.then (resp) =>
			context = resp
			console.log "result from Start:\n ", JSON.stringify context			
		.done

updatecall = (filename)->
	#console.log "processing the start "
	console.log "Processing the  Update file.. ",filename
	jsonfile.readFile filename,(err,obj)->
		console.log err if err?		
		unless obj.instances? 
			obj.instances = instances if instances isnt null?
		console.log "JSON Input ", obj
		getPromise()
		.then (resp) =>
			return Update obj
		.catch (err) =>
			console.log "Update err ", err
		.then (resp) =>
			console.log "result from Update:\n "			
			console.log resp
		.done


stopcall = ()->
	getPromise()
	.then (resp) =>
		console.log "stop context is ", context
		return Stop context
	.catch (err) =>
		console.log "Stop err ", err
	.then (resp) =>
		console.log "result from Stop:\n ",resp
	.done

if config.startjson?
	startcall() 
#for fn in updatefiles
#	setTimeout(updatecall,15000,fn) if config.updatejson?	
setTimeout(stopcall, 15000) if config.stopjson?
