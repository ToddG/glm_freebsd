import gleam/list
import gleam/dict.{type Dict}
import gleam/io
import gleam/string
import yodel

// ------------------------------------------------------------------
// Load the gleam.toml file, read both the global sections and the
// [freebsd] section. These vars will be loaded and used to generate
// files from the templates.
//
// If a config variable is not specified or cannot be defaulted,
// then a TODO comment is generated as the value for the replaced variable.
// ------------------------------------------------------------------
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

pub fn load_toml(path: String, output_path: String) -> Config {
  case yodel.load(path) {
    Ok(config) -> {
      let pkg_name = yodel.get_string_or(config, "name", "ERROR")
      let pkg_prefix =
        yodel.get_string_or(config, "freebsd.pkg_prefix", "/usr/local")
      let pkg_scripts_str =
        yodel.get_string_or(
          config,
          "freebsd.pkg_scripts",
          "post-install=post-install.sh,pre-deinstall=pre-deinstall.sh",
        )
      let pkg_scripts=pkg_scripts_str |> string.split(",")
      let pkg_scripts_dict =
      pkg_scripts
      |> list.map(fn(s){string.split_once(s, "=")})
      |> list.filter_map(fn(s){s})
      |> list.map(fn(t){
        let #(key, script) = t
        let script_path = output_path <> "/" <> script
        #(key, script_path)
        }
      )
      |> dict.from_list

      let freebsd_deps_list = yodel.get_string_or(
      config,
      "freebsd.deps.list",
      "",
      )
      |> string.split(",")

      let deps_dict =
      freebsd_deps_list
      |> list.map(fn(dep){
        let version = yodel.get_string_or(config, "freebsd.deps." <> dep <> ".version", "ERROR")
        let origin = yodel.get_string_or(config, "freebsd.deps." <> dep <> ".origin", "ERROR")
        #(dep, dict.from_list([#("version", version), #("origin", origin)]))
      })
      |> dict.from_list

      Config(
        pkg_dependencies: deps_dict,
        pkg_bin_path: yodel.get_string_or(
          config,
          "freebsd.pkg_bin_path",
          pkg_prefix <> "/bin",
        ),
        pkg_config_dir: yodel.get_string_or(
          config,
          "freebsd.pkg_config_dir",
          [pkg_prefix, "etc", pkg_name <> ".d"] |> string.join("/"),
        ),
        pkg_daemon_flags: yodel.get_string_or(
          config,
          "freebsd.pkg_daemon_flags",
          "",
        ),
        pkg_comment: yodel.get_string_or(
          config,
          "description",
          "TODO: ENTER A COMMENT HERE",
        ),
        pkg_conf_dir_uppercase: pkg_name |> string.uppercase,
        pkg_description: yodel.get_string_or(
          config,
          "freebsd.pkg_description",
          "TODO: ENTER A DESCRIPTION HERE.",
        ),
        pkg_env_file: yodel.get_string_or(
          config,
          "freebsd.pkg_env_file",
          pkg_name <> ".env",
        ),
        pkg_name:,
        pkg_origin: yodel.get_string_or(
          config,
          "freebsd.pkg_origin",
          "devel/" <> pkg_name,
        ),
        pkg_prefix:,
        pkg_scripts: pkg_scripts_dict,
        pkg_username: yodel.get_string_or(
          config,
          "freebsd.pkg_username",
          yodel.get_string_or(config, "name", "user"),
        ),
        pkg_user: yodel.get_bool_or(config, "freebsd.pkg_user", False),
        pkg_version: yodel.get_string_or(config, "version", "0.0.0"),
        pkg_www: yodel.get_string_or(
          config,
          "repository.repo",
          "TODO: ENTER A URL HERE.",
        ),
        pkg_var_dir: yodel.get_string_or(
          config,
          "freebsd.var_dir",
          "/var/run/" <> pkg_name,
        ),
        pkg_maintainer: yodel.get_string_or(
          config,
          "freebsd.pkg_maintainer",
          "TODO: ENTER MAINTAINER HERE",
        ),
      )
    }
    _ -> {
      io.println_error("Unable to load file at path: " <> path)
      panic
    }
  }
}
