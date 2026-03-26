#! /usr/local/bin/bash

# run this on the target FreeBSD HOST, or better yet, within a JAIL

echo "update path with erlang28 binary, as that's needed for gleam "
echo "and/or the gleam json library"
if [ ! -d "/usr/local/lib/erlang28/bin" ]; then
  echo "erlang28 is not installed! install and re-run test. aborting!"
  exit 1
fi
export PATH=/usr/local/lib/erlang28/bin:$PATH

echo "-------------------------------------------------------------------------------"
echo "build the 'example' app's erlang-shipment."
echo "-------------------------------------------------------------------------------"
echo "NOTE: you will want to do this for YOUR app, prior to generating "
echo "the freebsd package for YOUR app."
pushd ./priv/example && gleam export erlang-shipment && popd

#echo "-------------------------------------------------------------------------------"
#echo "verify that glm_freebsd has been built"
#echo "-------------------------------------------------------------------------------"
#rm -rf ./tmp
#if [ ! -e "./glm_freebsd" ]; then
#  echo "must run ./make.sh to build `./glm_freebsd`, aborting!"
#  exit 1
#fi
echo "-------------------------------------------------------------------------------"
echo "building the FreeBSD application service package..."
echo "-------------------------------------------------------------------------------"
#./glm_freebsd templates --input ./priv/example/ --output ./tmp
gleam run -- templates --input ./priv/example/ --output ./tmp --log info

echo "-------------------------------------------------------------------------------"
echo "here is the generated manifest"
echo "-------------------------------------------------------------------------------"
cat ./tmp/freebsd/+MANIFEST | jq

if [ ! -e "example-1.0.0.pkg" ]; then
  echo "package `example-1.0.0.pkg` was not created, aborting!"
  exit 1
fi

echo "-------------------------------------------------------------------------------"
echo "building the FreeBSD application service package..."
echo "-------------------------------------------------------------------------------"
echo "create the environment file"
echo "FOO=bar" > /tmp/example.env
echo "install the (local) package"
pkg install -y example-1.0.0.pkg

echo "clear out the example.log so we can see what this invocation logs..."
rm /var/log/example.log

echo "-------------------------------------------------------------------------------"
echo "you should not see the example app in yet"
echo "-------------------------------------------------------------------------------"
ps aux | grep -i example

echo "-------------------------------------------------------------------------------"
echo "start the example service"
echo "-------------------------------------------------------------------------------"
service example start
sleep 1

echo "-------------------------------------------------------------------------------"
echo "the example service should be in the process list now"
echo "-------------------------------------------------------------------------------"
ps aux | grep -i example
sleep 1

echo "-------------------------------------------------------------------------------"
echo "the example service should show up as started"
echo "-------------------------------------------------------------------------------"
service example status
sleep 1

echo "-------------------------------------------------------------------------------"
echo "the example service should show in the logs now"
cat /var/log/example.log
echo "-------------------------------------------------------------------------------"
sleep 1

echo "-------------------------------------------------------------------------------"
echo "the example service should shut down"
echo "-------------------------------------------------------------------------------"
service example stop

echo "-------------------------------------------------------------------------------"
echo "the example service should no longer be in the process list"
echo "-------------------------------------------------------------------------------"
ps aux | grep -i example

echo "-------------------------------------------------------------------------------"
echo "uninstall the package"
echo "-------------------------------------------------------------------------------"
pkg remove -y example
