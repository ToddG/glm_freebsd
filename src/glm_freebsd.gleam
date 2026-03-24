import gleam/io
import gleam/string
import argv
import clip/help
import clip/opt.{type Opt}
import clip.{type Command}
import glm_freebsd/config
import glm_freebsd/freebsd_build
import glm_freebsd/freebsd_templates
import simplifile
import logging

type App {
  App(input: String, output: String, log: String)
}

fn input_opt() -> Opt(String) {
  opt.new("input") |> opt.help("path to target app (directory with gleam.toml, and environment file, if provided.)")
}

fn output_opt() -> Opt(String) {
  opt.new("output") |> opt.help("path to place generated files (will create output dir)")
}

fn log_opt() -> Opt(String) {
  opt.new("log")
  |> opt.default("info")
  |> opt.help("log output verbosity, debug|warn|error")
}

fn templates() -> Command(App) {
  clip.command({
    use input <- clip.parameter
    use output <- clip.parameter
    use log <- clip.parameter

    App(input, output, log)
  })
  |> clip.opt(input_opt())
  |> clip.opt(output_opt())
  |> clip.opt(log_opt())
}

fn configure_logging(level: String)->Nil{
  let _ = logging.configure()
  let level = level |> string.lowercase
  let logging_level =
    case level  {
      "debug" -> logging.Debug
      "info" -> logging.Info
      "error" -> logging.Error
      _ -> logging.Debug
    }
  let _ = logging.set_level(logging_level)
  io.println("logging level set to: " <> level)
  logging.log(logging.Info, "application starting...")
}

fn debug(s: String)->Nil{
  logging.log(logging.Debug, "------------------------------------------------------------------")
  logging.log(logging.Debug, s)
  logging.log(logging.Debug, "------------------------------------------------------------------")
}

pub fn main() -> Nil {
  let result =
    templates()
    |> clip.help(help.simple("templates", "generate templates for target app"))
    |> clip.run(argv.load().arguments)

  case result {
    Error(e) -> logging.log(logging.Error,e)
    Ok(app) -> {
      let input_path = app.input
      let output_path = app.output
      configure_logging(app.log)
      let gleam_toml_path = input_path <> "/gleam.toml"
      debug("load gleam.toml file")
      let cfg = config.load_toml(gleam_toml_path, output_path)
      debug("create directories")
      let assert Ok(_) = simplifile.create_directory_all(output_path)
      debug("gen files from templates")
      let _ = freebsd_templates.gen_files_from_templates(cfg, output_path)
      debug("package files into freebsd package")
      let _ = freebsd_build.run_build(cfg, input_path, output_path)
      Nil
    }
  }
}
