#!/bin/bash

# Get environment variables to show up in SSH session
eval $(printenv | awk -F= '{print "export " "\""$1"\"""=""\""$2"\"" }' >> /etc/profile)

echo "starting ssh"
service ssh start
echo "starting app"
flask run --host=0.0.0.0 --port 80