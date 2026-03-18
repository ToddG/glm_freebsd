# glm_freebsd

A Gleam package that allows you to easily create FreeBSD packages for your Gleam applications, along with a service script to manage the application (e.g. start|stop).

This is based on https://github.com/patmaddox/ex_freebsd

[![Package Version](https://img.shields.io/hexpm/v/glm_freebsd)](https://hex.pm/packages/glm_freebsd)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_freebsd/)

Further documentation can be found at <https://hexdocs.pm/glm_freebsd>.

## Quickstart

### Install gleam and erlang

We need a minimum of gleam 1.14 and erlang28:

```shell
# use `latest`
echo 'FreeBSD-ports: { url: "pkg+https://pkg.FreeBSD.org/${ABI}/latest" }' > /usr/local/etc/pkg/repos/FreeBSD.conf
pkg update
pkg install -y erlang-runtime28 gleam rebar3 
```

### Run a quick test to ensure everything works

```sh
# gleam 1.14 (and json) needs erlang28
export PATH=/usr/local/lib/erlang28/bin:$PATH

# build the target app release files (in this case we have ./priv/example but you'll want to use your app path here)
pushd ./priv/example && gleam export erlang-shipment && popd

# now generate the freebsd package
rm -rf ./tmp && gleam run -- templates --input ./priv/example/ --output ./tmp

# package should be here
ls
>> example-1.0.0.pkg

# install
pkg install example-1.0.0.pkg

# test
service example start
service example status
cat /var/log/example.log
service example stop
```