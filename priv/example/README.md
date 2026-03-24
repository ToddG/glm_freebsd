# example

This is an example app. It's purpose is to:

* show how to use glm_freebsd
* glm_freebsd takes a gleam app (like this one) and mogrifies it into a FreeBSD `package` that can be installed.

This app is composed of:

* a typical gleam app created with `gleam new example`
* a modified gleam.toml file
  * has added fields to configure building FreeBSD packages (see below)

```ini
[freebsd]
pkg_user = true
pkg_description = "This is a longer description .........................................................."
pkg_maintainer = "someone@example.com"
pkg_scripts = "post-install=post-install.sh,pre-deinstall=pre-deinstall.sh"
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

## Development

You _can_ build this example app directly:

```sh
gleam check # Check the project
gleam run   # Run the project
gleam test  # Run the tests
```

However, it's purpose is to show how to use _glm_freebsd_. For that, navigate to the _glm_freebsd_ directory and run the `test_pkg.sh` test script:

```bash
glm_freebsd $ ./test_pkg.sh 
```

Note that the environment displayed is the shell environment of the user that invoked the test_pkg.sh command.
When running as a FreeBSD service, the environment displayed will be the environment of the running service.
That running environment **should** be the environment provided by the environment file specified by the
`pkg_config_dir`/`pkg_env_file` (or the default if those are not specified).