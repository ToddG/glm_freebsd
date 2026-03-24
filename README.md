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
./make.sh
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
[freebsd]
pkg_user = true
pkg_description = "This is a longer description .........................................................."
pkg_maintainer = "someone@example.com"
pkg_config_dir = "/some/path/outside/of/the/application/space"
pkg_env_file = "example.env"

[freebsd.deps]
list = "pstree,tree"

[freebsd.deps.pstree]
version = "2.36"
origin = "sysutils/pstree"

[freebsd.deps.tree]
version = "2.2.1"
origin = "sysutils/tree"
```



### Create an erlang-shipment

```bash
gleam export erlang-shipment
```

### Build the `glm_freebsd` tool (if not already built)

```shell
$ make.sh
```

### Create a FreeBSD package

```bash
# clear the temporary build directory, can be anything
rm -rf ./tmp 

# run glm_freebsd to generate the package, the package file will be in this directory upon completion
./glm_freebsd templates --input [PATH_TO_YOUR_APPNAME_TOML_FILE] --output ./tmp

# try installing the package in FreeBSD
sudo pkg install [PATH_TO_YOUR_GENERATED_PACKAGE_FILE].pkg
```

See the [test_pkg.sh](./test_pkg.sh) for further details.

## Environment Files and 12 Factor Apps

Applications being bundled into a FreeBSD Service will almost certainly require some sort of configuration. Per the
concept of 12 factor apps, this configuration should be external to the app and be _provided_ to the application 
by the runtime.

By default, at runtime, the environment file will be read from the applications configuration directory:

       /usr/local/etc/[PACKAGE_NAME].d/[PACKAGE_NAME].env

However, the location that the service management looks for the configuration file can be configured via these fields in gleam.toml:

       [freebsd]
       pkg_config_dir=...
       pkg_env_file=...

The configuration file can be placed in the correct location by your IAC 
(infrastructure-as-code, e.g. ansible,chef,puppet,pulumi,terraform,etc.).

When the service manager launches the service, it reads this environment file and includes these environment key/value pairs
in the process environment the service instance is started with.

## Toml Elements

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

There are other fields that you might want to use. See the [config.gleam](./src/glm_freebsd/config.gleam) file for fulll details.

## Example run

Start a test run

```bash
# ./test_pkg.sh
```

Output...

```bash
update path with erlang28 binary, as that's needed for gleam
and/or the gleam json library
-------------------------------------------------------------------------------
build the 'example' app's erlang-shipment.
-------------------------------------------------------------------------------
NOTE: you will want to do this for YOUR app, prior to generating
the freebsd package for YOUR app.
/opt/repos/glm_freebsd/priv/example /opt/repos/glm_freebsd
  Compiling gleam_stdlib
  Compiling envoy
  Compiling gleam_erlang
  Compiling gleeunit
  Compiling logging
  Compiling example
   Compiled in 0.66s
   Exported example

Your Erlang shipment has been generated to /opt/repos/glm_freebsd/priv/example/build/erlang-shipment.

It can be copied to a compatible server with Erlang installed and run with
one of the following scripts:
    - entrypoint.ps1 (PowerShell script)
    - entrypoint.sh (POSIX Shell script)

/opt/repos/glm_freebsd
-------------------------------------------------------------------------------
building the FreeBSD application service package...
-------------------------------------------------------------------------------
   Compiled in 0.03s
    Running glm_freebsd.main
logging level set to: info
INFO application starting...
INFO wrote ./tmp/pre-deinstall.sh
INFO wrote ./tmp/rc
INFO wrote ./tmp/post-install.sh
INFO wrote ./tmp/rc_conf
INFO wrote ./tmp/freebsd/+MANIFEST
INFO updated entrypoint.sh permissions: ./tmp/freebsd/stage/usr/local/libexec/example/entrypoint.sh
INFO wrote ./tmp/freebsd/stage/usr/local/etc/rc.d/example
INFO wrote ./tmp/freebsd/stage/usr/local/etc/rc.conf.d/example
INFO wrote ./tmp/freebsd/pkg-plist
INFO
INFO Build completed successfully
-------------------------------------------------------------------------------
here is the generated manifest
-------------------------------------------------------------------------------
{
  "name": "example",
  "version": "1.0.0",
  "origin": "devel/example",
  "comment": "An example app that will be used to create a FreeBSD package (with service scripts).",
  "www": "git@github.com:someuser/example_app.git",
  "maintainer": "someone@example.com",
  "prefix": "/usr/local",
  "desc": "This is a longer description ..........................................................",
  "scripts": {
    "pre-deinstall": "CONFIG_DIR=\"/tmp\"\n\n\nPKG_USER=\"example\"\n\nif [ -n \"${PKG_ROOTDIR}\" ] && [ \"${PKG_ROOTDIR}\" != \"/\" ]; then\n  PW=\"/usr/sbin/pw -R ${PKG_ROOTDIR}\"\nelse\n  PW=/usr/sbin/pw\nfi\nif ${PW} usershow ${PKG_USER} >/dev/null 2>&1; then\n  echo \"==> pkg user '${PKG_USER}' should be manually removed.\"\n  echo \"  ${PW} userdel ${PKG_USER}\"\nfi\n\n\nif [ -d \"${CONFIG_DIR}\" ]\nthen\n  echo \"==> config directory '${CONFIG_DIR}' should be manually removed.\"\n  echo \"  rm -rf ${CONFIG_DIR}\"\nfi\n\nif [ -d \"/var/run/example\" ]\nthen\n  echo \"==> run directory '/var/run/example' should be manually removed.\"\n  echo \"  rm -rf /var/run/example\"\nfi\n",
    "post-install": "PKG_NAME=\"example\"\nCONFIG_DIR=\"/tmp\"\nCONFIG_FILE=\"/tmp/example.env\"\n\n\nPKG_USER=\"example\"\n\nif [ -n \"${PKG_ROOTDIR}\" ] && [ \"${PKG_ROOTDIR}\" != \"/\" ]; then\n  PW=\"/usr/sbin/pw -R ${PKG_ROOTDIR}\"\nelse\n  PW=/usr/sbin/pw\nfi\n\necho \"===> Creating user.\"\nif ! ${PW} groupshow ${PKG_USER} >/dev/null 2>&1; then\n  echo \"Group: '${PKG_USER}'.\"\n  ${PW} groupadd ${PKG_USER} -g 2001\nelse\n  echo \"Using existing group: '${PKG_USER}'.\"\nfi\n\nif ! ${PW} usershow ${PKG_USER} >/dev/null 2>&1; then\n  echo \"User: '${PKG_USER}'.\"\n  ${PW} useradd ${PKG_USER} -u 2001 -g ${PKG_USER} -c \"${PKG_NAME} user\" -d /nonexistent -s /usr/sbin/nologin\nelse\n  echo \"Using existing user: '${PKG_USER}'.\"\nfi\n\n\nif [ ! -f $CONFIG_FILE ]\nthen\n  echo \"===> Creating config in ${CONFIG_FILE}\"\n  echo \"# example config file\" > $CONFIG_FILE\n  echo 'FOO=\"bar\"' >> $CONFIG_FILE\n  chmod 0444 $CONFIG_FILE\nfi\n"
  },
  "deps": {
    "tree": {
      "version": "2.2.1",
      "origin": "sysutils/tree"
    },
    "pstree": {
      "version": "2.36",
      "origin": "sysutils/pstree"
    }
  },
  "users": [
    "example"
  ]
}
-------------------------------------------------------------------------------
building the FreeBSD application service package...
-------------------------------------------------------------------------------
create the environment file
install the (local) package
Updating FreeBSD-ports repository catalogue...
FreeBSD-ports repository is up to date.
Updating FreeBSD-ports-kmods repository catalogue...
FreeBSD-ports-kmods repository is up to date.
All repositories are up to date.
Checking integrity... done (0 conflicting)
The following 1 package(s) will be affected (of 0 checked):

New packages to be INSTALLED:
        example: 1.0.0 [unknown-repository]

Number of packages to be installed: 1
[workstation.jail] [1/1] Installing example-1.0.0...
[workstation.jail] Extracting example-1.0.0: 100%
===> Creating user.
Using existing group: 'example'.
Using existing user: 'example'.
clear out the example.log so we can see what this invocation logs...
rm: /var/log/example.log: No such file or directory
-------------------------------------------------------------------------------
you should not see the example app in yet
-------------------------------------------------------------------------------
root 55880  0.0  0.0 14164  2692  1  S+J  14:49   0:00.00 grep -i example
-------------------------------------------------------------------------------
start the example service
-------------------------------------------------------------------------------
Service example started as pid 55925.
-------------------------------------------------------------------------------
the example service should be in the process list now
-------------------------------------------------------------------------------
example 55925 16.5  0.9 1406164 75812  -  SJ   14:49   0:00.42 /usr/local/lib/erlang28/erts-16.2/bin/beam.smp -- -root /usr/local/lib/erlang28 -bindir /usr/local/lib/erlang28/erts-16.2/bin -progname erl -- -home /nonexistent -- -pa /usr/local/libexec/example/envoy/ebin /usr/local/libexec/example/example/ebi
root    55923  0.2  0.0   14184  2552  -  SsJ  14:49   0:00.00 daemon: example[55925] (daemon)
example 55933  0.0  0.0   14076  2444  -  SsJ  14:49   0:00.00 erl_child_setup 234702
root    55935  0.0  0.0   14164  2684  1  S+J  14:49   0:00.00 grep -i example
-------------------------------------------------------------------------------
the example service should show up as started
-------------------------------------------------------------------------------
example is running as pid 55925.
-------------------------------------------------------------------------------
the example service should show in the logs now
Hello from example!
environment: dict.from_list([#("BINDIR", "/usr/local/lib/erlang28/erts-16.2/bin"), #("BLOCKSIZE", "K"), #("DEBUGGING", ""), #("DEBUG_DO", ":"), #("DEBUG_SKIP", ""), #("EMU", "beam"), #("ERL_CRASH_DUMP", "/var/run/example/example_erl_crash.dump"), #("EXAMPLE_CONF_DIR", "/tmp"), #("FOO", "bar"), #("HOME", "/nonexistent"), #("LANG", "C.UTF-8"), #("MAIL", "/var/mail/example"), #("MM_CHARSET", "UTF-8"), #("PATH", "/usr/local/lib/erlang28/erts-16.2/bin:/usr/local/lib/erlang28/bin:/sbin:/bin:/usr/sbin:/usr/bin"), #("PROGNAME", "erl"), #("PWD", "/"), #("RC_PID", "55881"), #("RELEASE_TMP", "/var/run/example"), #("ROOTDIR", "/usr/local/lib/erlang28"), #("SHELL", "/usr/sbin/nologin"), #("USER", "example"), #("_TTY", "/dev/pts/1")])
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
the example service should shut down
-------------------------------------------------------------------------------
Stopping example.
Waiting for PIDS: 55925.
-------------------------------------------------------------------------------
the example service should no longer be in the process list
-------------------------------------------------------------------------------
root 56027  0.0  0.0 14164  2696  1  S+J  14:49   0:00.00 grep -i example

```
