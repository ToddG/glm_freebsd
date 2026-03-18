import gleam/dict.{type Dict}
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glm_freebsd/config
import shellout.{type Lookups}
import simplifile.{Execute, FilePermissions, Read, Write}

pub type FreeBSDManifest {
  FreeBSDManifest(
    name: String,
    version: String,
    origin: String,
    comment: String,
    www: String,
    maintainer: String,
    prefix: String,
    desc: String,
    scripts: Dict(String, String),
    deps: Dict(String, Dict(String, String)),
    users: List(String),
  )
}

pub const lookups: Lookups = [
  #(
    ["color", "background"],
    [
      #("buttercup", ["252", "226", "174"]),
      #("mint", ["182", "255", "234"]),
      #("pink", ["255", "175", "243"]),
    ],
  ),
]

pub fn zero() {
  set.from_list([])
}

pub fn four() {
  set.from_list([Read])
}

pub fn five() {
  set.from_list([Read, Execute])
}

pub fn six() {
  set.from_list([Read, Write])
}

pub fn seven() {
  set.from_list([Read, Write, Execute])
}

pub fn run_build(cfg: config.Config, input_path: String, output_path: String) {
  FreeBSDManifest(
    name: cfg.pkg_name,
    version: cfg.pkg_version,
    origin: cfg.pkg_origin,
    comment: cfg.pkg_comment,
    www: cfg.pkg_www,
    maintainer: cfg.pkg_maintainer,
    prefix: cfg.pkg_prefix,
    desc: cfg.pkg_description,
    scripts: cfg.pkg_scripts,
    deps: cfg.pkg_dependencies,
    users: [cfg.pkg_username],
  )
  |> write_manifest(output_path)

  stage(cfg, input_path, output_path)

  rc(cfg, output_path)
  rc_conf(cfg, output_path)

  plist(cfg, output_path)

  pkg(output_path)

  io.println("Build completed successfully")
  Ok(Nil)
}

fn stage(cfg: config.Config, input_path: String, output_path: String) {
  let install_dir = install_dir(output_path, cfg)
  let libexec_dir = install_dir <> "/libexec/" <> cfg.pkg_name
  case simplifile.create_directory_all(libexec_dir) {
    Error(e) -> {
      io.println_error(
        "unable to create libexec directory: "
        <> libexec_dir
        <> ", error: "
        <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      let release_dir = rel_dir(input_path)
      case simplifile.copy_directory(release_dir, libexec_dir) {
        Error(e) -> {
          io.println_error(
            "unable to copy release dir: "
            <> release_dir
            <> " to libexec_dir: "
            <> libexec_dir
            <> ", error: "
            <> string.inspect(e),
          )
          io.println_error(
            "have you run `gleam export erlang-shipment` in your target project?",
          )
          panic
        }
        Ok(_) -> {
          make_entrypoint_executable(libexec_dir)
          make_sample_env_file(cfg, output_path)
        }
      }
    }
  }
}

fn make_entrypoint_executable(libexec_dir: String) {
  let entrypoint_path = libexec_dir <> "/entrypoint.sh"
  let perms = FilePermissions(user: five(), group: five(), other: five())
  case simplifile.set_permissions(entrypoint_path, to: perms) {
    Error(e) -> {
      io.println_error(
        "unable to set permissions on entrypoint: "
        <> entrypoint_path
        <> ", error: "
        <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      io.println("updated entrypoint.sh permissions: " <> entrypoint_path)
    }
  }
}

fn make_sample_env_file(cfg: config.Config, output_path: String) {
  let conf_dir = stage_dir(output_path) <> cfg.pkg_config_dir
  case simplifile.create_directory_all(conf_dir) {
    Error(e) -> {
      io.println_error(
        "unable to create conf dir: "
        <> conf_dir
        <> ", error: "
        <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      let perms = FilePermissions(user: seven(), group: five(), other: five())
      case simplifile.set_permissions(conf_dir, to: perms) {
        Error(e) -> {
          io.println_error(
            "unable to set permissions on conf_dir: "
            <> conf_dir
            <> ", error: "
            <> string.inspect(e),
          )
          panic
        }
        Ok(_) -> {
          let env_sample_contents =
            "
# Environment variables defined here will be available to your application.
# NOTE: comments below are for elixir...TODO: update comments for gleam
# RELEASE_COOKIE=\"generate with Base.url_encode64(:crypto.strong_rand_bytes(40))\"
# DATABASE_URL=\"ecto://username:password@host/database\"
"
          let env_sample_file = conf_dir <> "/" <> cfg.pkg_env_file <> ".sample"
          case simplifile.write(env_sample_file, env_sample_contents) {
            Error(e) -> {
              io.println_error(
                "unable to write sample contents to: "
                <> env_sample_file
                <> ", error: "
                <> string.inspect(e),
              )
              panic
            }
            Ok(_) -> {
              let perms =
                FilePermissions(user: four(), group: four(), other: zero())
              case simplifile.set_permissions(env_sample_file, to: perms) {
                Error(e) -> {
                  io.println_error(
                    "unable to set permissions on env_sample_file: "
                    <> env_sample_file
                    <> " permissions: "
                    <> string.inspect(perms)
                    <> ", error: "
                    <> string.inspect(e),
                  )
                  panic
                }
                Ok(_) -> {
                  io.println("wrote " <> env_sample_file)
                }
              }
            }
          }
        }
      }
    }
  }
}

fn write_manifest(manifest: FreeBSDManifest, output_path: String) {
  let tmp_dir = tmp_dir(output_path)
  let assert Ok(_) = simplifile.create_directory_all(tmp_dir)
  let manifest_file = manifest_file(output_path)

  // load scripts
  let keys = dict.keys(manifest.scripts)
  let scripts_dict =
    keys
    |> list.map(fn(key) {
      case dict.get(manifest.scripts, key) {
        Error(e) -> {
          io.println_error(
            "unable to retrieve script for key: "
            <> key
            <> ", error: "
            <> string.inspect(e),
          )
          panic
        }
        Ok(script_path) -> {
          case simplifile.read(script_path) {
            Error(e) -> {
              io.println_error(
                "unable to read script: "
                <> script_path
                <> ", for key:"
                <> key
                <> ", error: "
                <> string.inspect(e),
              )
              panic
            }
            Ok(text) -> #(key, text)
          }
        }
      }
    })
    |> dict.from_list

  case
    json.object([
      #("name", json.string(manifest.name)),
      #("version", json.string(manifest.version)),
      #("origin", json.string(manifest.origin)),
      #("comment", json.string(manifest.comment)),
      #("www", json.string(manifest.www)),
      #("maintainer", json.string(manifest.maintainer)),
      #("prefix", json.string(manifest.prefix)),
      #("desc", json.string(manifest.desc)),
      #("scripts", json.dict(scripts_dict, fn(k) { k }, json.string)),
      #(
        "deps",
        json.dict(manifest.deps, fn(k) { k }, fn(d) {
          json.dict(d, fn(k) { k }, json.string)
        }),
      ),
      #("users", json.array(manifest.users, of: json.string)),
    ])
    |> json.to_string
    |> simplifile.write(manifest_file, _)
  {
    Error(e) -> {
      io.println_error(
        "unable to write " <> manifest_file <> ", error:" <> string.inspect(e),
      )
    }
    Ok(_) -> {
      io.println("wrote " <> manifest_file)
    }
  }
}

fn rc_conf(cfg: config.Config, output_path: String) {
  let install_dir = install_dir(output_path, cfg)
  let etc_dir = install_dir <> "/etc"
  let rc_conf_dir = etc_dir <> "/rc.conf.d"
  let rc_conf_file = rc_conf_dir <> "/" <> cfg.pkg_name
  let rc_conf_source_file = output_path <> "/rc_conf"

  case simplifile.create_directory_all(rc_conf_dir) {
    Error(e) -> {
      io.println_error(
        "unable to create rc_conf_dir:"
        <> rc_conf_dir
        <> ", error: "
        <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      case simplifile.copy_file(rc_conf_source_file, rc_conf_file) {
        Error(e) -> {
          io.println_error(
            "unable to write rc_conf, source:"
            <> rc_conf_source_file
            <> ", target: "
            <> rc_conf_file
            <> ", error: "
            <> string.inspect(e),
          )
          panic
        }
        Ok(_) -> {
          let perms =
            FilePermissions(user: four(), group: four(), other: zero())
          case simplifile.set_permissions(rc_conf_file, to: perms) {
            Error(e) -> {
              io.println_error(
                "unable to set permissions on rc_conf_file: "
                <> rc_conf_file
                <> " to perms: "
                <> string.inspect(perms)
                <> ", error: "
                <> string.inspect(e),
              )
              panic
            }
            Ok(_) -> {
              io.println("wrote " <> rc_conf_file)
            }
          }
        }
      }
    }
  }
}

fn rc(cfg: config.Config, output_path: String) {
  let install_dir = install_dir(output_path, cfg)
  let etc_dir = install_dir <> "/etc"
  let rc_dir = etc_dir <> "/rc.d"
  let rc_file = rc_dir <> "/" <> cfg.pkg_name

  case simplifile.create_directory_all(rc_dir) {
    Error(e) -> {
      io.println_error(
        "unable to create dir: " <> rc_dir <> ", error: " <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      let rc_script = output_path <> "/rc"
      case simplifile.copy_file(rc_script, rc_file) {
        Error(e) -> {
          io.println_error(
            "unable to copy file: "
            <> rc_script
            <> " to rc_file: "
            <> rc_file
            <> ", error: "
            <> string.inspect(e),
          )
          panic
        }
        Ok(_) -> {
          let perms =
            FilePermissions(user: five(), group: four(), other: zero())
          case simplifile.set_permissions(rc_file, to: perms) {
            Error(e) -> {
              io.println_error(
                "unable to set permissions on rc_file: "
                <> rc_file
                <> " to perms: "
                <> string.inspect(perms)
                <> ", error: "
                <> string.inspect(e),
              )
              panic
            }
            Ok(_) -> {
              io.println("wrote " <> rc_file)
            }
          }
        }
      }
    }
  }
}

fn plist(cfg: config.Config, output_path: String) {
  let plist_file = tmp_dir(output_path) <> "/pkg-plist"
  let files = rel_files(cfg, output_path)

  let content = files |> string.join("\n") <> "\n"
  case simplifile.write(plist_file, content) {
    Error(e) -> {
      io.println_error(
        "unable to copy write plist_file: "
        <> plist_file
        <> ", error: "
        <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      io.println("wrote " <> plist_file)
    }
  }
}

fn manifest_file(output_path: String) {
  let tmp_dir = tmp_dir(output_path)
  tmp_dir <> "/+MANIFEST"
}

fn stage_dir(output_path: String) -> String {
  tmp_dir(output_path) <> "/stage"
}

fn install_dir(output_path: String, cfg: config.Config) -> String {
  stage_dir(output_path) <> cfg.pkg_prefix
}

fn tmp_dir(output_path: String) -> String {
  output_path <> "/freebsd"
}

fn rel_dir(input_path: String) -> String {
  input_path <> "/build/erlang-shipment"
}

fn recursive_files(dir: String) -> List(String) {
  do_recursive_files([dir], [])
}

fn do_recursive_files(
  inputs: List(String),
  outputs: List(String),
) -> List(String) {
  case inputs {
    [] -> outputs
    [h, ..rest] -> {
      case simplifile.is_directory(h) {
        Error(e) -> {
          io.println_error(
            "unable to check if target is a directory: "
            <> h
            <> ", error: "
            <> string.inspect(e),
          )
          panic
        }
        Ok(True) -> {
          case simplifile.get_files(h) {
            Error(e) -> {
              io.println_error(
                "unable to get files for dir: "
                <> h
                <> ", error: "
                <> string.inspect(e),
              )
              panic
            }
            Ok(files) -> {
              do_recursive_files(list.append(files, rest), outputs)
            }
          }
        }
        Ok(False) -> {
          case simplifile.is_symlink(h), simplifile.is_file(h) {
            Ok(False), Ok(True) -> {
              //io.println("target is a file, adding: " <> h)
              do_recursive_files(rest, [h, ..outputs])
            }
            Ok(True), Ok(False) -> {
              //io.println("targetfile is a symlink, adding: " <> h)
              do_recursive_files(rest, [h, ..outputs])
            }
            _, _ -> {
              io.println_error(
                "warning: targetfile is neither a symlink nor a file, skipping: "
                <> h,
              )
              do_recursive_files(rest, outputs)
            }
          }
        }
      }
    }
  }
}

fn rel_files(cfg: config.Config, output_path: String) -> List(String) {
  let stage_dir = stage_dir(output_path)
  let files = recursive_files(stage_dir)
  files
  |> list.map(fn(path) {
    string.replace(path, stage_dir <> cfg.pkg_prefix <> "/", "")
  })
}

fn pkg(output_path: String) {
  let stage_dir = stage_dir(output_path)
  let manifest_file = manifest_file(output_path)
  let tmp_dir = tmp_dir(output_path)

  let args = [
    "create",
    "-M",
    manifest_file,
    "-r",
    stage_dir,
    "-p",
    tmp_dir <> "/pkg-plist",
  ]

  let _ =
    shellout.command(run: "pkg", in: ".", with: args, opt: [])
    |> result.map(with: fn(output) {
      io.print(output)
      0
    })
    |> result.map_error(with: fn(detail) {
      let #(status, message) = detail
      let style =
        shellout.display(["bold", "italic"])
        |> dict.merge(from: shellout.color(["pink"]))
        |> dict.merge(from: shellout.background(["brightblack"]))
      message
      |> shellout.style(with: style, custom: lookups)
      |> io.print_error
      status
    })
  Nil
}
