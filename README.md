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
./test_pkg.sh
```

## Usage

### Create a gleam app

```bash
$ gleam new APPNAME
```

### Update the APPNAME/gleam.toml 

Add the relevant FreeBSD package info to the gleam.toml

```bash
$ cd APPNAME
APPNAME $ vim gleam.toml
```

Add these elements:

```toml
name = "example"
version = "1.0.0"

...

[freebsd]
pkg_user = true
pkg_description = "This is a longer description .........................................................."
pkg_maintainer = "someone@example.com"
pkg_scripts = "post-install=post-install.sh,pre-deinstall=pre-deinstall.sh"


[freebsd.deps]
list = "pstree,tree"

[freebsd.deps.pstree]
version = "2.36"
origin = "sysutils/pstree"

[freebsd.deps.tree]
version = "2.2.1"
origin = "sysutils/tree"
```

NOTES: pkg_scripts and freebsd.deps are optional and just shown here to illustrate what you _might_ want to put here. See below for a discussion on these elements.


#### Toml Elements

We pull the package name and version from the toml here:
```toml
name = "example"
version = "1.0.0"
```

The rest of the data comes from the [freebsd] described below:

| TOML FIELD              | DESCRIPTION                                                                                                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [freebsd]               | this is the root toml element that this packaging code uses                                                                                               |
| pkg_user [true          | false] : if true then the package creates a user when installed. defaults to true.                                                                        |
| pkg_username            | the username to create if pkg_user is true. defaults to the value in 'name' above.                                                                        |
| pkg_description         | a longer description used by the packaging system.                                                                                                        |
| pkg_maintainer          | email address of the package maintainer. e.g. someone@example.com                                                                                         |
| pkg_scripts             | comma separated k=v pairs, where k=script name, and value is a file in the output directory<br/> typically a file generated from a template.defaults to:  "post-install=post-install.sh,pre-deinstall=pre-deinstall.sh"|


| TOML FIELD              | DESCRIPTION                                                                                                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [freebsd.deps]          | the root of the list of OS package dependencies that YOUR package needs in order to function. `list` is the only child element.                           |
| list                    | a list of the packages (DEP_NAME) that will follow.                                                                                                       |


| TOML FIELD              | DESCRIPTION                                                                                                                                               |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [freebsd.deps.DEP_NAME] | the root of a FreeBSD OS package dependency declaration. `version` and `origin` are the only child elements.                                              |
| version | the dependency version                                                                                                                                    |
| origin | the dependency origin                                                                                                                                     |

There are other fields that you might want to use. See the config.gleam file and specifically this Config:

```rust
pub type Config {
  Config(
    pkg_bin_path: String,
    pkg_config_dir: String,
    pkg_daemon_flags: String,
    pkg_dependencies: Dict(String, Dict(String, String)),
    pkg_env_file: String,
    pkg_comment: String,
    pkg_conf_dir_uppercase: String,
    pkg_description: String,
    pkg_maintainer: String,
    pkg_name: String,
    pkg_origin: String,
    pkg_prefix: String,
    pkg_scripts: Dict(String, String),
    pkg_user: Bool,
    pkg_username: String,
    pkg_version: String,
    pkg_www: String,
    pkg_var_dir: String,
  )
}
```

So if you wanted to pass in certain daemon flags, then you'd specify that in the toml file as `pkg_daemon_flags = "...etc..."` under [freebsd].

### Create an erlang-shipment

```bash
gleam export erlang-shipment
```

### Create a FreeBSD package

```bash
# clear the temporary directory
rm -rf ./tmp 

# run glm_freebsd to generate the package, the package file will be in this directory upon completion
gleam run -- templates --input ./priv/example/ --output ./tmp

# try installing the package
# see the ./test_pkg.sh for further details.
```