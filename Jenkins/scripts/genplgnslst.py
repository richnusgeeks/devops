#! /usr/bin/env python
import jenkins as jks

server = jks.Jenkins('http://localhost:8080', 
           username='admin',
           password='admin')

with open('plugins.list', 'wb') as lst:
  lst.writelines('\n'.join([i['shortName'] for i in server.get_plugins_info()]))
