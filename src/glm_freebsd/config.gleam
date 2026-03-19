import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile
import tom.{type Toml}

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
    pkg_user_uid: Int,
    pkg_version: String,
    pkg_www: String,
    pkg_var_dir: String,
    pkg_path_extensions: String,
    pkg_command: String,
    pkg_command_args: String,
    pkg_proc_name: String,
  )
}

pub fn load_toml(path: String, output_path: String) -> Config {
  case simplifile.read(path) {
    Error(e) -> {
      io.println_error(
        "unable to load the toml file at path:"
        <> path
        <> ", error: "
        <> string.inspect(e),
      )
      panic
    }
    Ok(text) -> {
      case tom.parse(text) {
        Error(e) -> {
          io.println_error(
            "unable to parse the toml file at path:"
            <> path
            <> ", error: "
            <> string.inspect(e),
          )
          panic
        }
        Ok(parsed) -> {
          config(parsed, output_path)
        }
      }
    }
  }
}

fn config(parsed: Dict(String, Toml), output_path: String) -> Config {
  let pkg_name = get_string_or(parsed, "name", "ERROR")
  let pkg_prefix = get_string_or(parsed, "freebsd.pkg_prefix", "/usr/local")
  let pkg_scripts_str =
    get_string_or(
      parsed,
      "freebsd.pkg_scripts",
      "post-install=post-install.sh,pre-deinstall=pre-deinstall.sh",
    )
  let pkg_scripts = pkg_scripts_str |> string.split(",")
  let pkg_scripts_dict =
    pkg_scripts
    |> list.map(fn(s) { string.split_once(s, "=") })
    |> list.filter_map(fn(s) { s })
    |> list.map(fn(t) {
      let #(key, script) = t
      let script_path = output_path <> "/" <> script
      #(key, script_path)
    })
    |> dict.from_list

  let freebsd_deps_list =
    get_string_or(parsed, "freebsd.deps.list", "")
    |> string.split(",")

  let deps_dict =
    freebsd_deps_list
    |> list.map(fn(dep) {
      let version =
        get_string_or(parsed, "freebsd.deps." <> dep <> ".version", "ERROR")
      let origin =
        get_string_or(parsed, "freebsd.deps." <> dep <> ".origin", "ERROR")
      #(dep, dict.from_list([#("version", version), #("origin", origin)]))
    })
    |> dict.from_list

  Config(
    pkg_proc_name: get_string_or(
      parsed,
      "freebsd.pkg_proc_name",
      "/usr/local/lib/erlang28/erts-16.2/bin/beam.smp",
    ),
    pkg_path_extensions: get_string_or(
      parsed,
      "freebsd.pkg_path_extensions",
      "/usr/local/lib/erlang28/bin",
    ),
    pkg_command: get_string_or(parsed, "freebsd.pkg_command", "entrypoint.sh"),
    pkg_command_args: get_string_or(parsed, "freebsd.pkg_command_args", "run"),
    pkg_dependencies: deps_dict,
    pkg_bin_path: get_string_or(
      parsed,
      "freebsd.pkg_bin_path",
      pkg_prefix <> "/bin",
    ),
    pkg_config_dir: get_string_or(
      parsed,
      "freebsd.pkg_config_dir",
      [pkg_prefix, "etc", pkg_name <> ".d"] |> string.join("/"),
    ),
    pkg_daemon_flags: get_string_or(parsed, "freebsd.pkg_daemon_flags", ""),
    pkg_comment: get_string_or(
      parsed,
      "description",
      "TODO: ENTER A COMMENT HERE",
    ),
    pkg_conf_dir_uppercase: pkg_name |> string.uppercase,
    pkg_description: get_string_or(
      parsed,
      "freebsd.pkg_description",
      "TODO: ENTER A DESCRIPTION HERE.",
    ),
    pkg_env_file: get_string_or(
      parsed,
      "freebsd.pkg_env_file",
      pkg_name <> ".env",
    ),
    pkg_name:,
    pkg_origin: get_string_or(
      parsed,
      "freebsd.pkg_origin",
      "devel/" <> pkg_name,
    ),
    pkg_prefix:,
    pkg_scripts: pkg_scripts_dict,
    pkg_username: get_string_or(
      parsed,
      "freebsd.pkg_username",
      get_string_or(parsed, "name", "user"),
    ),
    pkg_user_uid: get_int_or(parsed, "freebsd.pkg_user_uid", 2001),
    pkg_user: get_bool_or(parsed, "freebsd.pkg_user", False),
    pkg_version: get_string_or(parsed, "version", "0.0.0"),
    pkg_www: get_string_or(parsed, "repository.repo", "TODO: ENTER A URL HERE."),
    pkg_var_dir: get_string_or(
      parsed,
      "freebsd.var_dir",
      "/var/run/" <> pkg_name,
    ),
    pkg_maintainer: get_string_or(
      parsed,
      "freebsd.pkg_maintainer",
      "TODO: ENTER MAINTAINER HERE",
    ),
  )
}

fn get_string_or(
  toml: Dict(String, Toml),
  key: String,
  default: String,
) -> String {
  let path = key |> string.split(".")
  case tom.get_string(toml, path) {
    Error(e) -> {
      io.println_error(
        "ERROR: path not found, path: "
        <> string.inspect(path)
        <> ", error: "
        <> string.inspect(e)
        <> ", using default: "
        <> default,
      )
      default
    }
    Ok(v) -> {
      io.println("DEBUG: found path: " <> string.inspect(path) <> ", value: " <> v)
      v
    }
  }
}

fn get_bool_or(toml: Dict(String, Toml), key: String, default: Bool) -> Bool {
  let path = key |> string.split(".")
  case tom.get_bool(toml, path) {
    Error(e) -> {
      io.println_error(
        "ERROR: path not found, path: "
        <> string.inspect(path)
        <> ", error: "
        <> string.inspect(e)
        <> ", using default: "
        <> bool.to_string(default),
      )
      default
    }
    Ok(v) -> {
      io.println("DEBUG: found path: " <> string.inspect(path) <> ", value: " <> bool.to_string(v))
      v
    }
  }
}

fn get_int_or(toml: Dict(String, Toml), key: String, default: Int) -> Int {
  let path = key |> string.split(".")
  case tom.get_int(toml, path) {
    Error(e) -> {
      io.println_error(
        "ERROR: path not found, path: "
        <> string.inspect(path)
        <> ", error: "
        <> string.inspect(e)
        <> ", using default: "
        <> int.to_string(default),
      )
      default
    }
    Ok(v) -> {
      io.println("DEBUG: found path: " <> string.inspect(path) <> ", value: " <> int.to_string(v))
      v
    }
  }
}
