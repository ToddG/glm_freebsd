#!/bin/sh

# now generate the freebsd package
rm -rf ./tmp && gleam run -- templates --input ./priv/example/ --output ./tmp

# package should be here
ls

# install
pkg install -y example-1.0.0.pkg

# test
rm /var/log/example.log
ps aux
service example start
sleep 1
ps aux
sleep 1
service example status
sleep 1
cat /var/log/example.log
sleep 1
service example stop
ps aux
