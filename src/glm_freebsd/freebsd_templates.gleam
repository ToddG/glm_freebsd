import gleam/list
import gleam/string
import gleam/string_tree
import glm_freebsd/config
import handles
import handles/ctx
import logging
import simplifile

fn reify_template(
  cfg: config.Config,
  template: String,
  template_path: String,
) -> String {
  case handles.prepare(template) {
    Ok(prepared_template) -> {
      case
        handles.run(
          prepared_template,
          ctx.Dict([
            ctx.Prop("pkg_name", ctx.Str(cfg.pkg_name)),
            ctx.Prop("pkg_user", ctx.Bool(cfg.pkg_user)),
            ctx.Prop("pkg_username", ctx.Str(cfg.pkg_username)),
            ctx.Prop("pkg_user_uid", ctx.Int(cfg.pkg_user_uid)),
            ctx.Prop("pkg_config_dir", ctx.Str(cfg.pkg_config_dir)),
            ctx.Prop("pkg_bin_path", ctx.Str(cfg.pkg_bin_path)),
            ctx.Prop(
              "pkg_conf_dir_uppercase",
              ctx.Str(cfg.pkg_conf_dir_uppercase),
            ),
            ctx.Prop("pkg_daemon_flags", ctx.Str(cfg.pkg_daemon_flags)),
            ctx.Prop("pkg_env_file", ctx.Str(cfg.pkg_env_file)),
            ctx.Prop("pkg_var_dir", ctx.Str(cfg.pkg_var_dir)),
            ctx.Prop("pkg_prefix", ctx.Str(cfg.pkg_prefix)),
            ctx.Prop("pkg_proc_name", ctx.Str(cfg.pkg_proc_name)),
            ctx.Prop("pkg_path_extensions", ctx.Str(cfg.pkg_path_extensions)),
            ctx.Prop("pkg_command", ctx.Str(cfg.pkg_command)),
            ctx.Prop("pkg_command_args", ctx.Str(cfg.pkg_command_args)),
          ]),
          [],
        )
      {
        Ok(result) -> {
          string_tree.to_string(result)
        }
        Error(e) -> {
          logging.log(
            logging.Error,
            "unable to run the template: "
              <> template_path
              <> ", error:"
              <> string.inspect(e),
          )
          panic
        }
      }
    }
    Error(e) -> {
      logging.log(
        logging.Error,
        "unable to prepare template: "
          <> template_path
          <> ", error:"
          <> string.inspect(e),
      )
      panic
    }
  }
}

fn output_filename(template_file_path: String) -> String {
  case template_file_path |> string.split("/") |> list.last() {
    Ok(template_basename) -> {
      let filename =
        template_basename
        |> string.split(".")
        |> list.reverse()
        |> list.drop(1)
        |> list.reverse()
        |> string.join(".")
      filename
    }
    _ -> {
      logging.log(
        logging.Error,
        "unable to read extract the basename from template_file_path: "
          <> template_file_path,
      )
      panic
    }
  }
}

fn process_template(
  cfg: config.Config,
  template_path: String,
  output_dir: String,
) {
  let output_file_path = output_dir <> "/" <> output_filename(template_path)
  case simplifile.read(template_path) {
    Ok(template_text) -> {
      let output_text = reify_template(cfg, template_text, template_path)
      case simplifile.write(to: output_file_path, contents: output_text) {
        Ok(_) -> {
          logging.log(logging.Info, "wrote " <> output_file_path)
        }
        Error(_) -> {
          logging.log(
            logging.Error,
            "unable to write output file: " <> output_file_path,
          )
        }
      }
    }
    _ -> {
      logging.log(
        logging.Error,
        "unable to read template_path: " <> template_path,
      )
      panic
    }
  }
  Nil
}

fn process_templates(
  cfg: config.Config,
  template_path: String,
  output_dir: String,
) {
  let assert Ok(files) = simplifile.get_files(template_path)
  files
  |> list.map(process_template(cfg, _, output_dir))
  Nil
}

pub fn gen_files_from_templates(
  cfg: config.Config,
  input_path: String,
  output_path: String,
) {
  let base_templates_dir = "./priv/templates/freebsd.pkg"
  let tmp_templates_dir = output_path <> "/templates"
  let custom_templates_dir = input_path <> cfg.pkg_templates_dir
  case simplifile.create_directory_all(tmp_templates_dir) {
    Error(e) -> {
      logging.log(
        logging.Error,
        "unable to create temporary templates path: "
          <> tmp_templates_dir
          <> ", error: "
          <> string.inspect(e),
      )
      panic
    }
    Ok(_) -> {
      case simplifile.is_directory(base_templates_dir) {
        Error(e) -> {
          logging.log(
            logging.Error,
            "unable to create temporary templates path: "
              <> tmp_templates_dir
              <> ", error: "
              <> string.inspect(e),
          )
          panic
        }
        Ok(_) -> {
          case
            simplifile.copy_directory(base_templates_dir, tmp_templates_dir)
          {
            Error(e) -> {
              logging.log(
                logging.Error,
                "unable to copy temporary templates from: "
                  <> base_templates_dir
                  <> ", to path: "
                  <> tmp_templates_dir
                  <> ", error: "
                  <> string.inspect(e),
              )
              panic
            }
            Ok(_) -> {
              case simplifile.is_directory(custom_templates_dir) {
                Error(e) -> {
                  logging.log(
                    logging.Debug,
                    "custom application templates dir not found: "
                      <> custom_templates_dir
                      <> ", error: "
                      <> string.inspect(e),
                  )
                  logging.log(
                    logging.Info,
                    "skipping copying custom application pkg templates b/c templates dir not found: "
                      <> custom_templates_dir,
                  )
                }
                Ok(_) -> {
                  case
                    simplifile.copy_directory(
                      custom_templates_dir,
                      tmp_templates_dir,
                    )
                  {
                    Error(e) -> {
                      logging.log(
                        logging.Error,
                        "unable to copy custom templates over base templates, custom_templates_dir: "
                          <> custom_templates_dir
                          <> ", target_dir: "
                          <> tmp_templates_dir
                          <> ", error: "
                          <> string.inspect(e),
                      )
                      panic
                    }
                    Ok(_) -> {
                      logging.log(
                        logging.Info,
                        "copied custom templates over base templates, custom_templates_dir: "
                          <> custom_templates_dir
                          <> ", target_dir: "
                          <> tmp_templates_dir,
                      )
                    }
                  }
                }
              }
            }
          }
          process_templates(cfg, tmp_templates_dir, output_path)
        }
      }
    }
  }
}
