# glm_freebsd

A Gleam package that allows you to easily create FreeBSD packages for your Gleam applications, along with a service script to manage the application's lifecycle.

This is based on https://github.com/patmaddox/ex_freebsd

[![Package Version](https://img.shields.io/hexpm/v/glm_freebsd)](https://hex.pm/packages/glm_freebsd)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_freebsd/)

```sh
//TODO
```

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
# first build the target app release files (in this case we have ./priv/example but you'll want to use your app path here)
rm -rf ./tmp
pushd ./priv/example
gleam export erlang-shipment
popd
gleam run -- templates --input ./priv/example/ --output ./tmp
ls 
>> example-1.0.0.pkg
```

### Error?

Attempting to install the generated package fails b/c of a missing dependency:

```shell
pkg install example
...
Updating FreeBSD-ports repository catalogue...
FreeBSD-ports repository is up to date.
Updating FreeBSD-ports-kmods repository catalogue...
FreeBSD-ports-kmods repository is up to date.
All repositories are up to date.
pkg: example has a missing dependency: cdiff
```

TODO: I'll ask on the FreeBSD forums as to what I need to do here...
