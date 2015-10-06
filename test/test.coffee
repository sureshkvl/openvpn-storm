jsonfile = require('jsonfile')
Start = require('./../src/context').start
Stop = require('./../src/context').stop
Update = require('./../src/context').update
Promise = require 'bluebird'
diff = require('deep-diff').diff
server1 = {}
server1.config = {
                "port": 7001,
                "dev": "tun2",
                "proto": "udp",
                "ca": "ca.crt",
                "dh": "dh1024.pem",
                "cert": "server.crt",
                "key": "server.key",
                "server": "172.17.0.0 255.255.255.0",
                "client-config-dir": "/var/stormflash/meta/ccd",
                "certificates": [{
                    "name":"ca",
                    "data":"LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlEN3pDQ0ExaWdBd0lCQWdJSkFLeGxDb3hrT2xySU1BMEdDU3FHU0liM0RRRUJCUVVBTUlHc01Rc3dDUVlEDQpWUVFHRXdKSlRqRUxNQWtHQTFVRUNCTUNWRTR4RURBT0JnTlZCQWNUQjBOb1pXNXVZV2t4RkRBU0JnTlZCQW9UDQpDMk5oYkhOdlpuUnNZV0p6TVJJd0VBWURWUVFMRXdsTFJWbFRWVkpGVTBneEVUQVBCZ05WQkFNVENFTk9VMVZTDQpSVk5JTVJNd0VRWURWUVFwRXdwT1FVMUZVMVZTUlZOSU1Td3dLZ1lKS29aSWh2Y05BUWtCRmgxemRYSmxjMmhyDQpkVzFoY2k1elFHTmhiSE52Wm5Sc1lXSnpMbU52YlRBZUZ3MHhOREF6TVRVeE5qRXdORGxhRncweU5EQXpNVEl4DQpOakV3TkRsYU1JR3NNUXN3Q1FZRFZRUUdFd0pKVGpFTE1Ba0dBMVVFQ0JNQ1ZFNHhFREFPQmdOVkJBY1RCME5vDQpaVzV1WVdreEZEQVNCZ05WQkFvVEMyTmhiSE52Wm5Sc1lXSnpNUkl3RUFZRFZRUUxFd2xMUlZsVFZWSkZVMGd4DQpFVEFQQmdOVkJBTVRDRU5PVTFWU1JWTklNUk13RVFZRFZRUXBFd3BPUVUxRlUxVlNSVk5JTVN3d0tnWUpLb1pJDQpodmNOQVFrQkZoMXpkWEpsYzJocmRXMWhjaTV6UUdOaGJITnZablJzWVdKekxtTnZiVENCbnpBTkJna3Foa2lHDQo5dzBCQVFFRkFBT0JqUUF3Z1lrQ2dZRUF1MUtwRjZuQks2Y1BDYkpmR1QyN01BSVZGd09pQk1vMlBxYklpYVBhDQp6VTE3SzF5Slo4Yjh0a3h6WXNnK0NRN2dUZ3BYTU4ybzJnMFl5NkwyN1lVd3VmM1Q4b2h0dnBxSWIxSi9CVTNUDQpKbWYwUE55QjgrQ2g1c1lMell5bG5QcFdEbmZVQk5PWS9paE1vSHY5eE1PWU1yT0V1ZlBNMURla2tiUk8zTXhIDQpycU1DQXdFQUFhT0NBUlV3Z2dFUk1CMEdBMVVkRGdRV0JCUk50S0U5NkpBdC9QTGZVRDRVQ0gvYnF0ZTdSVENCDQo0UVlEVlIwakJJSFpNSUhXZ0JSTnRLRTk2SkF0L1BMZlVENFVDSC9icXRlN1JhR0JzcVNCcnpDQnJERUxNQWtHDQpBMVVFQmhNQ1NVNHhDekFKQmdOVkJBZ1RBbFJPTVJBd0RnWURWUVFIRXdkRGFHVnVibUZwTVJRd0VnWURWUVFLDQpFd3RqWVd4emIyWjBiR0ZpY3pFU01CQUdBMVVFQ3hNSlMwVlpVMVZTUlZOSU1SRXdEd1lEVlFRREV3aERUbE5WDQpVa1ZUU0RFVE1CRUdBMVVFS1JNS1RrRk5SVk5WVWtWVFNERXNNQ29HQ1NxR1NJYjNEUUVKQVJZZGMzVnlaWE5vDQphM1Z0WVhJdWMwQmpZV3h6YjJaMGJHRmljeTVqYjIyQ0NRQ3NaUXFNWkRwYXlEQU1CZ05WSFJNRUJUQURBUUgvDQpNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0R0JBR1FiZHdXalNkRmNWczM0V1JyODZybytUcFFqalFWWXF0bGsycndhDQp2RGlLTmVCZ0diaTZwbGdtQ1c0R2Y2WEgreHJHMG9RZ05oR1Q0ZmJreHJ5ZjBSUDJJK3RmMFdPUW5zZFFzYkRuDQpvZ0tRSzNmbkFRVitZNk0zT01qMXdKTjhDOEl6RmMrdWh1TmJwZW1zQjNiek9MU2pobzR2YTVtL1ZxRi9jMlZIDQpieVlGDQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0t"
                },
                {
                    "name":"dh",
                    "data":"LS0tLS1CRUdJTiBESCBQQVJBTUVURVJTLS0tLS0NCk1JR0hBb0dCQUtjWGxIS2t5NC9JWTlkNldydkRheW5uMi96a3dqWDlFdDdjV2VKNVFhd1U4Q0pzcDI1RjdOWk8NCkJ3Z3AxNTh2NDRPQnNGWjloWU1lV3ZncGN3bXJpVk04Szhka244d1pTbUtTZlVBVnV0Z1prYU5wMUU3dG95cmINCldwQkc0WE1RKzBPcnRmTUJNSFpjcUNxMkFxZEhJM2hJcU96dHhKeGN0aDUxKzlRc2dMS3pBZ0VDDQotLS0tLUVORCBESCBQQVJBTUVURVJTLS0tLS0="
                },
                {
                    "name":"cert",
                    "data":"Q2VydGlmaWNhdGU6DQogICAgRGF0YToNCiAgICAgICAgVmVyc2lvbjogMyAoMHgyKQ0KICAgICAgICBTZXJpYWwgTnVtYmVyOiAxICgweDEpDQogICAgU2lnbmF0dXJlIEFsZ29yaXRobTogc2hhMVdpdGhSU0FFbmNyeXB0aW9uDQogICAgICAgIElzc3VlcjogQz1JTiwgU1Q9VE4sIEw9Q2hlbm5haSwgTz1jYWxzb2Z0bGFicywgT1U9S0VZU1VSRVNILCBDTj1DTlNVUkVTSC9uYW1lPU5BTUVTVVJFU0gvZW1haWxBZGRyZXNzPXN1cmVzaGt1bWFyLnNAY2Fsc29mdGxhYnMuY29tDQogICAgICAgIFZhbGlkaXR5DQogICAgICAgICAgICBOb3QgQmVmb3JlOiBNYXIgMTUgMTY6MTE6MzkgMjAxNCBHTVQNCiAgICAgICAgICAgIE5vdCBBZnRlciA6IE1hciAxMiAxNjoxMTozOSAyMDI0IEdNVA0KICAgICAgICBTdWJqZWN0OiBDPUlOLCBTVD1UTiwgTD1DaGVubmFpLCBPPWNhbHNvZnRsYWJzLCBPVT1LRVlTVVJFU0gsIENOPXNlcnZlci9uYW1lPU5BTUVTVVJFU0gvZW1haWxBZGRyZXNzPXN1cmVzaGt1bWFyLnNAY2Fsc29mdGxhYnMuY29tDQogICAgICAgIFN1YmplY3QgUHVibGljIEtleSBJbmZvOg0KICAgICAgICAgICAgUHVibGljIEtleSBBbGdvcml0aG06IHJzYUVuY3J5cHRpb24NCiAgICAgICAgICAgICAgICBQdWJsaWMtS2V5OiAoMTAyNCBiaXQpDQogICAgICAgICAgICAgICAgTW9kdWx1czoNCiAgICAgICAgICAgICAgICAgICAgMDA6ZTA6ZjM6ZDI6MGQ6ODM6MzQ6MmY6NGY6MGE6NDg6NzY6NjE6Njk6NGY6DQogICAgICAgICAgICAgICAgICAgIDZkOmI5OjYxOjA5OjYxOjBjOmQ2OmQ0OmQ2OjQwOjAwOjU0OjRlOmIyOmFmOg0KICAgICAgICAgICAgICAgICAgICA1YjpiZToyMDphMTo0ZTo1ZTozMzoxMzo0ZjozZToyMjplMzpiYjozZDo0ZjoNCiAgICAgICAgICAgICAgICAgICAgODU6MjQ6NTk6ZGU6ZmI6ZDU6YmI6NWE6Y2M6Mjc6NTk6MWI6ZDY6OWE6OGY6DQogICAgICAgICAgICAgICAgICAgIDIwOjI1Ojk2OmY2OjVjOjFhOjIzOjEzOmJhOjJmOjIxOjI1OjI2OmVlOjI5Og0KICAgICAgICAgICAgICAgICAgICAwMzpiYjpmMDowMzphNjpkOToxNDo0YTozMDowMzo3YTowYTo2NDo0Zjo0NzoNCiAgICAgICAgICAgICAgICAgICAgYjc6OWU6Mzk6MGM6ZDk6ZDE6ODM6Mjc6Y2M6ZjI6NjI6NzY6Y2Q6Y2Y6M2I6DQogICAgICAgICAgICAgICAgICAgIDY5OjE0OjgwOmMxOjlhOmY5OjU3Ojk3OjRiOjNhOmQ4OjViOmNiOjc1OjcyOg0KICAgICAgICAgICAgICAgICAgICBiZDpkNDphNDo5NTo4NTplMDphNjpjMjplNw0KICAgICAgICAgICAgICAgIEV4cG9uZW50OiA2NTUzNyAoMHgxMDAwMSkNCiAgICAgICAgWDUwOXYzIGV4dGVuc2lvbnM6DQogICAgICAgICAgICBYNTA5djMgQmFzaWMgQ29uc3RyYWludHM6IA0KICAgICAgICAgICAgICAgIENBOkZBTFNFDQogICAgICAgICAgICBOZXRzY2FwZSBDZXJ0IFR5cGU6IA0KICAgICAgICAgICAgICAgIFNTTCBTZXJ2ZXINCiAgICAgICAgICAgIE5ldHNjYXBlIENvbW1lbnQ6IA0KICAgICAgICAgICAgICAgIEVhc3ktUlNBIEdlbmVyYXRlZCBTZXJ2ZXIgQ2VydGlmaWNhdGUNCiAgICAgICAgICAgIFg1MDl2MyBTdWJqZWN0IEtleSBJZGVudGlmaWVyOiANCiAgICAgICAgICAgICAgICA2NDo1NjpCQjpENTpGRTpDQzpFMDoyQzpCQTpBRTpFRTo0QTpBMzo5OTo2MzozNTpGOTo3Qjo1ODo5RQ0KICAgICAgICAgICAgWDUwOXYzIEF1dGhvcml0eSBLZXkgSWRlbnRpZmllcjogDQogICAgICAgICAgICAgICAga2V5aWQ6NEQ6QjQ6QTE6M0Q6RTg6OTA6MkQ6RkM6RjI6REY6NTA6M0U6MTQ6MDg6N0Y6REI6QUE6RDc6QkI6NDUNCiAgICAgICAgICAgICAgICBEaXJOYW1lOi9DPUlOL1NUPVROL0w9Q2hlbm5haS9PPWNhbHNvZnRsYWJzL09VPUtFWVNVUkVTSC9DTj1DTlNVUkVTSC9uYW1lPU5BTUVTVVJFU0gvZW1haWxBZGRyZXNzPXN1cmVzaGt1bWFyLnNAY2Fsc29mdGxhYnMuY29tDQogICAgICAgICAgICAgICAgc2VyaWFsOkFDOjY1OjBBOjhDOjY0OjNBOjVBOkM4DQoNCiAgICAgICAgICAgIFg1MDl2MyBFeHRlbmRlZCBLZXkgVXNhZ2U6IA0KICAgICAgICAgICAgICAgIFRMUyBXZWIgU2VydmVyIEF1dGhlbnRpY2F0aW9uDQogICAgICAgICAgICBYNTA5djMgS2V5IFVzYWdlOiANCiAgICAgICAgICAgICAgICBEaWdpdGFsIFNpZ25hdHVyZSwgS2V5IEVuY2lwaGVybWVudA0KICAgIFNpZ25hdHVyZSBBbGdvcml0aG06IHNoYTFXaXRoUlNBRW5jcnlwdGlvbg0KICAgICAgICAgODA6ZTU6OTQ6YmU6MDc6ZWE6MGY6ZDk6M2I6OWY6ZjA6ZDc6N2U6YTE6Mjc6NWE6OWI6ZGE6DQogICAgICAgICBhYjo0MDo0Mzo5MjphYzo2Njo4MDo4NDplODo1ZDo4YTo4MDo1MzphNjpiNzo0OToxMzpkZDoNCiAgICAgICAgIGZkOjk0OjVhOjQyOjUzOmVhOmM4OjBiOjhjOjUwOjdkOmIwOjJiOmM5OjE4OjBmOjhmOjRmOg0KICAgICAgICAgZGU6ZmU6ZTg6ZDI6N2E6MzY6ZDg6NTc6NGY6ZjU6YmU6ODk6OGQ6ZjY6OTk6NmQ6MjQ6OTk6DQogICAgICAgICA5YzowNTo2NjpkODozNjowYzozMjoxYzo1Zjo4Mzo5NzoyYzo1YzphOTozZDphZDphYjo2MzoNCiAgICAgICAgIDE3OjZmOjU0OmQ2OjA4OjBkOmU1Ojg0Ojk5Ojg1OjZiOmNjOjI1OmQ2OjcyOjUyOjUyOjUzOg0KICAgICAgICAgY2Y6MGM6N2I6NTA6ODc6MDE6Njc6OTQ6NDY6MWU6NDY6Zjg6NGY6NDU6N2U6ODY6NGY6MmY6DQogICAgICAgICBiMTo5YQ0KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlFVFRDQ0E3YWdBd0lCQWdJQkFUQU5CZ2txaGtpRzl3MEJBUVVGQURDQnJERUxNQWtHQTFVRUJoTUNTVTR4DQpDekFKQmdOVkJBZ1RBbFJPTVJBd0RnWURWUVFIRXdkRGFHVnVibUZwTVJRd0VnWURWUVFLRXd0allXeHpiMlowDQpiR0ZpY3pFU01CQUdBMVVFQ3hNSlMwVlpVMVZTUlZOSU1SRXdEd1lEVlFRREV3aERUbE5WVWtWVFNERVRNQkVHDQpBMVVFS1JNS1RrRk5SVk5WVWtWVFNERXNNQ29HQ1NxR1NJYjNEUUVKQVJZZGMzVnlaWE5vYTNWdFlYSXVjMEJqDQpZV3h6YjJaMGJHRmljeTVqYjIwd0hoY05NVFF3TXpFMU1UWXhNVE01V2hjTk1qUXdNekV5TVRZeE1UTTVXakNCDQpxakVMTUFrR0ExVUVCaE1DU1U0eEN6QUpCZ05WQkFnVEFsUk9NUkF3RGdZRFZRUUhFd2REYUdWdWJtRnBNUlF3DQpFZ1lEVlFRS0V3dGpZV3h6YjJaMGJHRmljekVTTUJBR0ExVUVDeE1KUzBWWlUxVlNSVk5JTVE4d0RRWURWUVFEDQpFd1p6WlhKMlpYSXhFekFSQmdOVkJDa1RDazVCVFVWVFZWSkZVMGd4TERBcUJna3Foa2lHOXcwQkNRRVdIWE4xDQpjbVZ6YUd0MWJXRnlMbk5BWTJGc2MyOW1kR3hoWW5NdVkyOXRNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdODQpBRENCaVFLQmdRRGc4OUlOZ3pRdlR3cElkbUZwVDIyNVlRbGhETmJVMWtBQVZFNnlyMXUrSUtGT1hqTVRUejRpDQo0N3M5VDRVa1dkNzcxYnRhekNkWkc5YWFqeUFsbHZaY0dpTVR1aThoSlNidUtRTzc4QU9tMlJSS01BTjZDbVJQDQpSN2VlT1F6WjBZTW56UEppZHMzUE8ya1VnTUdhK1ZlWFN6cllXOHQxY3IzVXBKV0Y0S2JDNXdJREFRQUJvNElCDQpmVENDQVhrd0NRWURWUjBUQkFJd0FEQVJCZ2xnaGtnQmh2aENBUUVFQkFNQ0JrQXdOQVlKWUlaSUFZYjRRZ0VODQpCQ2NXSlVWaGMza3RVbE5CSUVkbGJtVnlZWFJsWkNCVFpYSjJaWElnUTJWeWRHbG1hV05oZEdVd0hRWURWUjBPDQpCQllFRkdSV3U5WCt6T0FzdXE3dVNxT1pZelg1ZTFpZU1JSGhCZ05WSFNNRWdka3dnZGFBRkUyMG9UM29rQzM4DQo4dDlRUGhRSWY5dXExN3RGb1lHeXBJR3ZNSUdzTVFzd0NRWURWUVFHRXdKSlRqRUxNQWtHQTFVRUNCTUNWRTR4DQpFREFPQmdOVkJBY1RCME5vWlc1dVlXa3hGREFTQmdOVkJBb1RDMk5oYkhOdlpuUnNZV0p6TVJJd0VBWURWUVFMDQpFd2xMUlZsVFZWSkZVMGd4RVRBUEJnTlZCQU1UQ0VOT1UxVlNSVk5JTVJNd0VRWURWUVFwRXdwT1FVMUZVMVZTDQpSVk5JTVN3d0tnWUpLb1pJaHZjTkFRa0JGaDF6ZFhKbGMyaHJkVzFoY2k1elFHTmhiSE52Wm5Sc1lXSnpMbU52DQpiWUlKQUt4bENveGtPbHJJTUJNR0ExVWRKUVFNTUFvR0NDc0dBUVVGQndNQk1Bc0dBMVVkRHdRRUF3SUZvREFODQpCZ2txaGtpRzl3MEJBUVVGQUFPQmdRQ0E1WlMrQitvUDJUdWY4TmQrb1NkYW05cXJRRU9TckdhQWhPaGRpb0JUDQpwcmRKRTkzOWxGcENVK3JJQzR4UWZiQXJ5UmdQajAvZS91alNlamJZVjAvMXZvbU45cGx0SkptY0JXYllOZ3d5DQpIRitEbHl4Y3FUMnRxMk1YYjFUV0NBM2xoSm1GYTh3bDFuSlNVbFBQREh0UWh3Rm5sRVllUnZoUFJYNkdUeSt4DQptZz09DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0t"
                },
                {
                    "name":"key",
                    "data":"LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tDQpNSUlDZUFJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0FtSXdnZ0plQWdFQUFvR0JBT0R6MGcyRE5DOVBDa2gyDQpZV2xQYmJsaENXRU0xdFRXUUFCVVRyS3ZXNzRnb1U1ZU14TlBQaUxqdXoxUGhTUlozdnZWdTFyTUoxa2IxcHFQDQpJQ1dXOWx3YUl4TzZMeUVsSnU0cEE3dndBNmJaRkVvd0Ezb0taRTlIdDU0NUROblJneWZNOG1KMnpjODdhUlNBDQp3WnI1VjVkTE90aGJ5M1Z5dmRTa2xZWGdwc0xuQWdNQkFBRUNnWUVBbW56WU5ROTJOMGRBK0tMVUkwNjVQQ2E0DQpHajZIQzRSWVQrR1dhb0Nqc044WDZJb282WW55VW1Pem8xZUpTSDJ2OWFQREY0ZzlQYVV3ck5TK2J4Sk4vWWlPDQppNlM3YzErd3VCcVdKY2dzdVB2MTNNOHYyT0c1K1liY2ZUcWV4OW9KRHVYaHpTMEJ3RE43VnZmLzdXblpQYmlxDQorc3ZvdThJN2lMaDhTZDM3eHdFQ1FRRCtHYTFFQ2pvM1NyTmphTHJyckZRTnZwYUpja3RHdW5wNjI4SjgyRXN3DQozUnRyaUJ0NnNoYU94WExDa2hUeVUveWRrSjlYYnNZOXArbHJNR1hrVjZrUEFrRUE0cUpiaGFwejdOWC9NSXdxDQordlFIZTU2Nno3aUsybjFiTmg1Y1NVbVF3dlBtRXJEaGJjZnJzdkduMGtJOWNLSmQ0Qit4R3hmdVpPblBRekgzDQpWcVZZcVFKQkFQMWNHTmxZNFVjMFlyM2lOVTY4RzJ0QTk5VEFjN0pvU2F1cTU3ZVg2eEVqeGkxb0h3NHQrRFFQDQpTQ2dkaEdsRHVRUmFxYWFDTzRSS29vRlFWcWhoaDUwQ1FRREJDZVhHN3E4YlZoT3RPRmNMdG53Qk1leVJMZkVuDQp0WXJSaC82M2RlL1Yvb1ZEK21HcGJwWTJyMXR3M25jU3oxb0NvenZwaGZMTEJkUkN1ZmFoV09reEFrQXhqRlkrDQp0ck54SWRUWDhtSmF5UEZJQW1lZ2RWVE1YMHBNS1ZxOGpVamZnSUl3dmczWVhHMlpybzVRbVp0K2NpYTBJQXQ5DQphYmozSlF3QkRzbWk0c0MvDQotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0t"
                }
                ]
            }

user0 = {     
	"id": "039ecacc-979f-47f9-9ea0-1cc3bc7005ed",                       
	"email": "sureshkumar0@calsoftlabs.com",
	"cname": "0@device.intercloud.net",
	"push": [
		"dhcp-option DNS 8.8.8.8",
		"ip-win32 dynamic",
		"route-delay 5",
		"redirect-gateway def1"
		]
	}
user1 = {
	"id": "139ecacc-979f-47f9-9ea0-1cc3bc7005ed",
	"email": "sureshkumar1@calsoftlabs.com",
	"cname": "1@device.intercloud.net",
	"push": [
		"dhcp-option DNS 8.8.8.8",
		"ip-win32 dynamic",
		"route-delay 5",
		"redirect-gateway def1"
		]
	}

user2 = {
	"id": "239ecacc-979f-47f9-9ea0-1cc3bc7005ed",
	"email": "sureshkumar2@calsoftlabs.com",
	"cname": "2@device.intercloud.net",
	"push": [
		"dhcp-option DNS 8.8.8.8",
		"ip-win32 dynamic",
		"route-delay 5",
		"redirect-gateway def1"
		]
	}

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
			console.log "result from Start:\n ", context			
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

updatecall1 = ()->
	#console.log "processing the start "

	context.service.servers[0].config.status = "/var/log/server-status.log"
	#context.service.servers.push server1

	console.log "input to the update ", JSON.stringify context
	getPromise()
	.then (resp) =>
			return Update context
		.catch (err) =>
			console.log "Update err ", err
		.then (resp) =>
			console.log "result from Update:\n "			
			console.log resp
			context = resp
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
	setTimeout(updatecall1,15000)

#for fn in updatefiles
#setTimeout(updatecall1,15000,fn) if config.updatejson?	
#setTimeout(stopcall, 15000) if config.stopjson?

