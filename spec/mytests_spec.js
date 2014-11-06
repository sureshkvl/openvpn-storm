// Generated by CoffeeScript 1.7.1
var frisby, options, serverSchema, serverdata;

frisby = require('frisby');

serverSchema = {
  id: String,
  port: Number,
  dev: String,
  proto: String,
  ca: String,
  dh: String,
  cert: String,
  key: String,
  server: String
};

serverdata = {
  "port": 7000,
  "dev": "tun1",
  "proto": "udp",
  "ca": "/var/stormflash/meta/ca-bundle.pem",
  "dh": "/etc/dh1024.pem",
  "cert": "/var/stormflash/meta/openvpn.cert",
  "key": "/var/stormflash/meta/openvpn.key",
  "server": "172.17.0.0 255.255.255.0",
  "multihome": true,
  "management": "127.0.0.1 2020",
  "cipher": "AES-256-CBC",
  "auth": "SHA1",
  "topology": "subnet",
  "route": null,
  "push": ["comp-lzo no"],
  "status": "/var/log/server-status.log",
  "keepalive": "5 60",
  "sndbuf": 262144,
  "rcvbuf": 262144,
  "txqueuelen": 500,
  "verb": 3,
  "mlock": true,
  "script-security": "3 system",
  "tls-cipher": "DHE-RSA-AES256-SHA",
  "route-gateway": "172.17.0.1",
  "client-config-dir": "/var/stormflash/meta/ccd",
  "ccd-exclusive": true,
  "max-clients": 254,
  "persist-key": true,
  "persist-tun": true,
  "comp-lzo": "no",
  "replay-window": "512 15",
  "client-to-client": true
};

options = {
  json: true
};

frisby.create('1.POST_server').post('http://192.168.122.94:5000/openvpn/server', serverdata, options).expectStatus(200).inspectJSON().afterJSON(function(res) {
  var id;
  id = res.id;
  if (res.running !== true) {
    return;
  }
  return frisby.create('2.GET_Server').get('http://192.168.122.94:5000/openvpn/server/' + id).expectStatus(200).expectJSONTypes(serverSchema).expectJSON({
    port: function(val) {
      return expect(val).toBe(7000);
    }
  }).inspectJSON().afterJSON(function(res) {
    return frisby.create('3.GET_Servers').get('http://192.168.122.94:5000/openvpn/server/').expectStatus(200).inspectJSON().afterJSON(function(res) {
      return frisby.create('4.Delete_Server')["delete"]('http://192.168.122.94:5000/openvpn/server/' + id).expectStatus(204).after(function(err, res, body) {
        return console.log("delete server over");
      }).toss();
    }).toss();
  }).toss();
}).toss();
