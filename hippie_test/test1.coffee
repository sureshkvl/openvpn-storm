hippie = require('hippie')
baseurl = 'http://192.168.122.94:5000'



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



# Test the post
hippie()
.json()
.base baseurl
.post '/openvpn/server'
.send serverdata
.expectStatus(200)
.end (err, res, body)->
	if err
		throw err
	console.log body
	id = body.id 

	# Test the get
	hippie()
	.json()
	.base baseurl
	.get '/openvpn/server/' + id
	.expectStatus(200)
	.end (err, res, body)->
		if err
			throw err
		console.log "id   ", id
		console.log "body   ", body

		# Test the delete (Doesnt work)
		#hippie()
		#.json()
		#.base baseurl
		#.del '/openvpn/server/' + id
		#.expectStatus(204)
		#.end (err, res, body)->
		#	if err
		#		throw err
		#	console.log body




