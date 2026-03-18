#!/bin/sh

echo "update path with erlang28 binary, as that's needed for gleam "
echo "and/or the gleam json library"
export PATH=/usr/local/lib/erlang28/bin:$PATH

echo "build the 'example' app's erlang-shipment."
echo "NOTE: you will want to do this for YOUR app, prior to generating "
echo "the freebsd package for YOUR app."
pushd ./priv/example && gleam export erlang-shipment && popd

echo "generate a freebsd package for the 'example' app..."
rm -rf ./tmp && gleam run -- templates --input ./priv/example/ --output ./tmp

echo "here is the generated manifest"
cat ./tmp/freebsd/+MANIFEST | jq

echo "examine the output of ls, there should be a package named: example-1.0.0.pkg"
ls

echo "install the package"
pkg install -y example-1.0.0.pkg

echo "clear out the example.log so we can see what this invocation logs..."
rm /var/log/example.log

echo "you should not see the example app in yet"
ps aux

echo "start the example service"
service example start
sleep 1


echo "the example service should be in the process list now"
ps aux
sleep 1

echo "the example service should show up as started"
service example status
sleep 1

echo "the example service should show in the logs now"
cat /var/log/example.log
sleep 1

echo "the example service should shut down"
service example stop

echo "the example service should no longer be in the process list"
ps aux
