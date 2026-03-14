import argv
import clip.{type Command}
import clip/help
import clip/opt.{type Opt}
import gleam/io
import gleam/list
import gleam/string
import gleam/string_tree
import handles
import handles/ctx
import simplifile
import yodel

type Config {
  Config(
    pkg_name: String,
    pkg_user: Bool,
    pkg_username: String,
    beam_path: String,
    conf_dir: String,
    config_dir: String,
    bin_path: String,
    conf_dir_var: String,
    daemon_flags: String,
    env_file_name: String,
    var_dir: String,
    pkg_prefix: String,
  )
}

type App {
  App(input: String, output: String)
}

fn input_opt() -> Opt(String) {
  opt.new("input") |> opt.help("path to target app")
}

fn output_opt() -> Opt(String) {
  opt.new("output") |> opt.help("path to place generated files")
}

fn command() -> Command(App) {
  clip.command({
    use input <- clip.parameter
    use output <- clip.parameter

    App(input, output)
  })
  |> clip.opt(input_opt())
  |> clip.opt(output_opt())
}

fn load_toml(path: String) -> Config {
  case yodel.load(path) {
    Ok(config) -> {
      Config(
        pkg_name: yodel.get_string_or(config, "name", ""),
        pkg_user: yodel.get_bool_or(config, "freebsd.pkg_user", True),
        pkg_username: yodel.get_string_or(config, "freebsd.pkg_username", yodel.get_string_or(config, "name", "user")),
        beam_path: yodel.get_string_or(config, "freebsd.beam_path", ""),
        conf_dir: yodel.get_string_or(config, "freebsd.conf_dir", ""),
        config_dir: yodel.get_string_or(config, "freebsd.config_dir", ""),
        bin_path: yodel.get_string_or(config, "freebsd.bin_path", ""),
        conf_dir_var: yodel.get_string_or(config, "freebsd.conf_dir_var", ""),
        daemon_flags: yodel.get_string_or(config, "freebsd.daemon_flags", ""),
        env_file_name: yodel.get_string_or(config, "freebsd.env_file_name", ""),
        var_dir: yodel.get_string_or(config, "freebsd.var_dir", ""),
        pkg_prefix: yodel.get_string_or(config, "freebsd.pkg_prefix", ""),
      )
    }
    _ -> {
      io.println_error("Unable to load file at path: " <> path)
      panic
    }
  }
}

fn reify_template(config: Config, template: String, template_path: String) -> String {
  case handles.prepare(template) {
    Ok(prepared_template) -> {
      case
        handles.run(
          prepared_template,
          ctx.Dict([
            ctx.Prop("pkg_name", ctx.Str(config.pkg_name)),
            ctx.Prop("pkg_user", ctx.Bool(config.pkg_user)),
            ctx.Prop("pkg_username", ctx.Str(config.pkg_username)),
            ctx.Prop("beam_path", ctx.Str(config.beam_path)),
            ctx.Prop("conf_dir", ctx.Str(config.conf_dir)),
            ctx.Prop("config_dir", ctx.Str(config.config_dir)),
            ctx.Prop("bin_path", ctx.Str(config.bin_path)),
            ctx.Prop("conf_dir_var", ctx.Str(config.conf_dir_var)),
            ctx.Prop("daemon_flags", ctx.Str(config.daemon_flags)),
            ctx.Prop("env_file_name", ctx.Str(config.env_file_name)),
            ctx.Prop("var_dir", ctx.Str(config.var_dir)),
            ctx.Prop("pkg_prefix", ctx.Str(config.pkg_prefix)),
          ]),
          [],
        )
      {
        Ok(result) -> {
          string_tree.to_string(result)
        }
        Error(e) -> {
          io.print_error("Unable to run the template: " <> template_path <> ", error:" <> string.inspect(e))
          panic
        }
      }
    }
    Error(e) -> {
      io.print_error("Unable to prepare template: " <> template_path <> ", error:" <> string.inspect(e))
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
      io.print_error(
        "Unable to read extract the basename from template_file_path: "
        <> template_file_path,
      )
      panic
    }
  }
}

fn process_template(config: Config, template_path: String, output_dir: String) {
  let output_file_path = output_dir <> "/" <> output_filename(template_path)
  case simplifile.read(template_path) {
    Ok(template_text) -> {
      let output_text = reify_template(config, template_text, template_path)
      case simplifile.write(to: output_file_path, contents: output_text) {
        Ok(_) -> {
          io.println("wrote: " <> output_file_path)
        }
        Error(_) -> {
          io.print_error("unable to write output file: " <> output_file_path)
        }
      }
    }
    _ -> {
      io.print_error("Unable to read template_path: " <> template_path)
      panic
    }
  }
  Nil
}

fn process_templates(config: Config, template_path: String, output_dir: String) {
  // let assert Ok(files) = simplifile.get_files("./priv/templates/freebsd.pkg")
  let assert Ok(files) = simplifile.get_files(template_path)
  files
  |> list.map(process_template(config, _, output_dir))
  Nil
}

pub fn main() -> Nil {
  let result =
    command()
    |> clip.help(help.simple("application", "generate package for target app"))
    |> clip.run(argv.load().arguments)

  case result {
    Error(e) -> io.println_error(e)
    Ok(app) -> {
      app |> string.inspect |> io.println
      let gleam_toml_path = app.input <> "/gleam.toml"
      let config = load_toml(gleam_toml_path)
      config |> string.inspect |> io.println
      let assert Ok(_) = simplifile.create_directory_all(app.output)
      process_templates(config, "./priv/templates/freebsd.pkg", app.output)
    }
  }
}
