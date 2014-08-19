openvpn-storm
===================

Synopsis
--------
openvpn-storm is a storm plugin for managing the openvpn service.

It provides the REST API to configure the openvpn server and start the server using stormflash framework. Also the openvpn process is monitored by the stormflash.


List of APIs
-------------

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
  <tr>
    <td>POST</td><td>/openvpn/client</td><td>Create openvpn client configuration</td>
  </tr>
  <tr>
    <td>GET</td><td>/openvpn/client</td><td>Describe openvpn client info</td>
  </tr>
  <tr>
    <td>DELETE</td><td>/openvpn/client/:client</td><td>Delete client-id info  from client</td>
  </tr>
</table>


###POST openvpn API

    Verb      URI                Description
    POST      /openvpn/server    Create openvpn server configuration and starts the openvpn server

#### Request JSON
    
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
    
#### Response JSON

    {
        "id": "b90736af-b58f-4929-8e9a-de4bf0fd7aa5",
        "running": true
    } 


###POST openvpn user API

    Verb    URI                              Description
    POST    /openvpn/server/:server/users    Add openvpn user

#### Request JSON
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
 
#### Response JSON

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


###GET openvpn server API

    Verb    URI                  Description
    GET     /openvpn/server      Show openvpn server configuration

#### Response JSON
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


###GET openvpn server API

    Verb    URI                    Description
    GET     /openvpn/server/:id    Show openvpn server configuration by ID

#### Response JSON

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


###DELETE openvpn user API

    Verb    URI                                Description
    DELETE  /openvpn/server/:id/users/:user    Delete openvpn user from client-config-directory

#### Response JSON

    Status Code: 204 No Content


###DELETE openvpn API

    Verb    URI                        Description
    DELETE  openvpn/server/:server     Delete openvpn configuration by ID.

#### Response JSON

    Status Code: 204 No Content
    Connection: keep-alive


###POST openvpn client API

    Verb      URI                Description
    POST      /openvpn/client    Create openvpn client configuration and starts the openvpn client

#### Request JSON

    {
        "pull": true,
        "tls-client": true,
        "dev": "tun1",
        "remote": "192.168.122.2 7000",
        "proto": "udp",
        "ca": "/var/stormflash/meta/ca.crt",
        "cert": "/var/stormflash/meta/client1.crt",
        "key": "/var/stormflash/meta/client1.key",
        "cipher": "AES-256-CBC",
        "tls-cipher": "DHE-RSA-AES256-SHA",
        "persist-key": true,
        "persist-tun": true,
        "status": "/var/log/client-status.log",
        "comp-lzo": "no",
        "verb": 3,
        "mlock": true
    }

#### Response JSON

    {
        "id": "528ae0a3-f871-4988-9d27-1a67d656f7a2",
        "running": true
    }


###GET openvpn client API

    Verb    URI                  Description
    GET     /openvpn/client      Show openvpn client configurations

#### Response JSON
    [
      {
        "id": "528ae0a3-f871-4988-9d27-1a67d656f7a2",
        "data": {
          "pull": true,
          "tls-client": true,
          "dev": "tun1",
          "remote": "192.168.122.2 7000",
          "proto": "udp",
          "ca": "/var/stormflash/meta/ca.crt",
          "cert": "/var/stormflash/meta/client1.crt",
          "key": "/var/stormflash/meta/client1.key",
          "cipher": "AES-256-CBC",
          "tls-cipher": "DHE-RSA-AES256-SHA",
          "persist-key": true,
          "persist-tun": true,
          "status": "/var/log/client-status.log",
          "comp-lzo": "no",
          "verb": 3,
          "mlock": true
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
        "out": 25,
        "err": 26,
        "configs": {
          "service": {
            "filename": "/var/stormflash/plugins/openvpn/528ae0a3-f871-4988-9d27-1a67d656f7a2.conf"
          }
        },
        "invocation": {
          "name": "openvpn",
          "path": "/usr/sbin",
          "monitor": true,
          "args": [
            "--config",
            "/var/stormflash/plugins/openvpn/528ae0a3-f871-4988-9d27-1a67d656f7a2.conf"
          ],
          "options": {
            "detached": true,
            "stdio": [
              "ignore",
              25,
              26
            ]
          }
        },
        "isReady": true,
        "instance": 14788
      }
    ]


###DELETE openvpn client API

    Verb    URI                        Description
    DELETE  openvpn/client/:client     Delete openvpn client configuration by ID

#### Response JSON

    HTTP/1.1 204 No Content
    X-Powered-By: Zappa 0.4.22
    Date: Tue, 19 Aug 2014 04:47:23 GMT
    Connection: keep-alive



Copyright & License
--------------------
LICENSE 

MIT

COPYRIGHT AND PERMISSION NOTICE

Copyright (c) 2014-2015, Clearpath Networks, <licensing@clearpathnet.com>.

All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
