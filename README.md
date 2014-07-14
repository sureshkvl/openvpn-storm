openvpn
===================


*List of APIs*
=============

<table>
  <tr>
    <th>Verb</th><th>URI</th><th>Description</th>
  </tr>
  <tr>
    <td>POST</td><td>/openvpn/server</td><td>Create openvpn server configuration</td>
  </tr>
  
  <tr>
    <td>POST</td><td>/openvpn/server/:server/users</td><td>Add user to openvpn server configuration</td>
  </tr>
  <tr>
    <td>GET</td><td>/openvpn/server</td><td>Describe openvpn server info</td>
  </tr>
  <tr>
    <td>GET</td><td>/openvpn/server/:id</td><td>Describe server server-id openvpn info</td>
  </tr>
  
  <tr>
    <td>DELETE</td><td>/openvpn/server/:id/users/:user</td><td>Delete user from server with server-id</td>
  </tr>
  <tr>
    <td>DELETE</td><td>/openvpn/server/:server</td><td>Delete server-id info  from server</td>
  </tr> 
</table>


**POST openvpn API**

    Verb      URI                Description
    POST      /openvpn/server	 Create openvpn server configuration


**Example Request and Response**

### Request JSON
    
    {
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
        "push": [
            "comp-lzo no"
        ],
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
    }
    
### Response JSON   

    {
        "id": "b90736af-b58f-4929-8e9a-de4bf0fd7aa5",
        "running": true
    } 



**POST openvpn user API**

    Verb	URI	        	         Description
    POST	/openvpn/server/:server/users	 Add openvpn user.


**Example Request and Response**

### Request JSON
    [
    {
        "id": "439ecacc-979f-47f9-9ea0-1cc3bc7005ed",
        "email": "grani@clearpathnet.com",
        "cname": "5C_F8_A1_14_34_5D@device.intercloud.net",
        "push": [
            "dhcp-option DNS 8.8.8.8",
            "ip-win32 dynamic",
            "route-delay 5",
            "redirect-gateway def1"
        ]
    }
    ]
 
### Response JSON	

    {
    "439ecacc-979f-47f9-9ea0-1cc3bc7005ed": {
        "id": "439ecacc-979f-47f9-9ea0-1cc3bc7005ed",
        "email": "grani@clearpathnet.com",
        "cname": "5C_F8_A1_14_34_5D@device.intercloud.net",
        "push": [
            "dhcp-option DNS 8.8.8.8",
            "ip-win32 dynamic",
            "route-delay 5",
            "redirect-gateway def1"
        ],
        "ccdpath": "/var/stormflash/meta/ccd",
        "saved": true
    }
    }

**GET openvpn server API**

    Verb	URI	                 Description
    GET	        /openvpn/server	         Show openvpn server configuration. 

**Example Request and Response**


### Response JSON
    [
    {
        "id": "b90736af-b58f-4929-8e9a-de4bf0fd7aa5",
        "data": {
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
            "push": [
                "comp-lzo no"
            ],
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
        },
        "saved": true,
        "isRunning": true,
        "_events": {
            "running": [
                null,
                null
            ]
        },
        "configPath": "/var/stormflash/plugins/openvpn",
        "logPath": "/var/log/openvpn",
        "out": 22,
        "err": 24,
        "configs": {
            "service": {
                "filename": "/var/stormflash/plugins/openvpn/b90736af-b58f-4929-8e9a-de4bf0fd7aa5.conf"
            }
        },
        "invocation": {
            "name": "openvpn",
            "path": "/usr/sbin",
            "monitor": true,
            "args": [
                "--config",
                "/var/stormflash/plugins/openvpn/b90736af-b58f-4929-8e9a-de4bf0fd7aa5.conf"
            ],
            "options": {
                "detached": true,
                "stdio": [
                    "ignore",
                    22,
                    24
                ]
            }
        },
        "isReady": true,
        "instance": 12862
    }
    ]


**GET openvpn server API**

    Verb	URI	                 Description
    GET	        /openvpn/server/:id	 Show openvpn server configuration by ID. 

**Example Request and Response**


### Response JSON

    {
        "id": "b90736af-b58f-4929-8e9a-de4bf0fd7aa5",
        "data": {
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
            "push": [
                "comp-lzo no"
            ],
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
        },
        "saved": true,
        "isRunning": true,
        "_events": {
            "running": [
                null,
                null
            ]
        },
        "configPath": "/var/stormflash/plugins/openvpn",
        "logPath": "/var/log/openvpn",
        "out": 22,
        "err": 24,
        "configs": {
            "service": {
                "filename": "/var/stormflash/plugins/openvpn/b90736af-b58f-4929-8e9a-de4bf0fd7aa5.conf"
            }
        },
        "invocation": {
            "name": "openvpn",
            "path": "/usr/sbin",
            "monitor": true,
            "args": [
                "--config",
                "/var/stormflash/plugins/openvpn/b90736af-b58f-4929-8e9a-de4bf0fd7aa5.conf"
            ],
            "options": {
                "detached": true,
                "stdio": [
                    "ignore",
                    22,
                    24
                ]
            }
        },
        "isReady": true,
        "instance": 12862
    }

**DELETE openvpn user API**

    Verb	URI	                               Description
    DELETE	/openvpn/server/:id/users/:user	       Delete openvpn user from client-config-directory


**Example Request and Response**

### Response JSON

    Status Code: 204 No Content


**DELETE openvpn API**

    Verb	URI	                   Description
    DELETE	openvpn/server/:server	   Delete openvpn configuration by ID.


**Example Request and Response**

### Response JSON    

    Status Code: 204 No Content
    Connection: keep-alive

