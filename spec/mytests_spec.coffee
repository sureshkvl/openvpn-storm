frisby = require('frisby')

serverSchema =        
	id:  String
	port: Number 
	dev:  String
	proto: String
	ca:  String
	dh:  String 
	cert: String 
	key:  String
	server: String 

serverdata =
    "port": 7000
    "dev": "tun1"
    "proto": "udp"
    "ca": "/var/stormflash/meta/ca-bundle.pem"
    "dh": "/etc/dh1024.pem"
    "cert": "/var/stormflash/meta/openvpn.cert"
    "key": "/var/stormflash/meta/openvpn.key"
    "server": "172.17.0.0 255.255.255.0"
    "multihome": true
    "management": "127.0.0.1 2020"
    "cipher": "AES-256-CBC"
    "auth": "SHA1"
    "topology": "subnet"
    "route": null
    "push": ["comp-lzo no"]
    "status": "/var/log/server-status.log"
    "keepalive": "5 60"
    "sndbuf": 262144
    "rcvbuf": 262144
    "txqueuelen": 500
    "verb": 3
    "mlock": true
    "script-security": "3 system"
    "tls-cipher": "DHE-RSA-AES256-SHA"
    "route-gateway": "172.17.0.1"
    "client-config-dir": "/var/stormflash/meta/ccd"
    "ccd-exclusive": true
    "max-clients": 254
    "persist-key": true
    "persist-tun": true
    "comp-lzo": "no"
    "replay-window": "512 15"
    "client-to-client": true
options =
	json : true


#Test the openvpn server APIs..
# Sequence 
# 1. post the server
# 2. Get the server 
# 3. delete the server

#Post the openvpn server
frisby.create('1.POST_server')
	.post('http://192.168.122.94:5000/openvpn/server', serverdata , options)
	.expectStatus(200)
	.inspectJSON()	#dump the Json response in the console
	.afterJSON (res)->		
		id = res.id   #serverid
		return unless res.running is true

		# GET the running OPENVPN SERVER data
		frisby.create('2.GET_Server')
			.get('http://192.168.122.94:5000/openvpn/server/' + id)
			.expectStatus(200)
			.expectJSONTypes serverSchema
			.expectJSON 
				port : (val)->  expect(val).toBe(7000)  #custom function to validate the JSON Data
			.inspectJSON()	#dump the Json response in the console
			.afterJSON (res)->			
				#List the servers
				frisby.create('3.GET_Servers')
					.get('http://192.168.122.94:5000/openvpn/server/')
					.expectStatus(200)					
					.inspectJSON()	#dump the Json response in the console
					.afterJSON (res)->											

						#DELETE the running SERVER
						frisby.create('4.Delete_Server')
							.delete('http://192.168.122.94:5000/openvpn/server/' + id)
							.expectStatus(204)					
							.after (err,res,body)->
								console.log "delete server over"
							.toss()
					.toss()
			.toss()
	.toss()

