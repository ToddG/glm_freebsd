import argv
import clip.{type Command}
import clip/help
import clip/opt.{type Opt}
import gleam/io
import gleam/string
import glm_freebsd/packager

type App {
  App(
    app_dir: String,
    templates_dir: String,
    staging_dir: String,
    output_dir: String,
  )
}

fn app_dir_path_opt() -> Opt(String) {
  opt.new("application")
  |> opt.short("a")
  |> opt.help(
    "gleam target application directory (location of the target app's gleam.toml file)",
  )
}

fn template_dir_path_opt() -> Opt(String) {
  opt.new("templates")
  |> opt.short("t")
  |> opt.help("path to custom templates directory")
  |> opt.default("./priv/templates/freebsd")
}

fn output_dir_path_opt() -> Opt(String) {
  opt.new("output")
  |> opt.short("o")
  |> opt.help("path to place generated (output) files (will create directory)")
}

fn staging_dir_path_opt() -> Opt(String) {
  opt.new("staging")
  |> opt.short("s")
  |> opt.help(
    "path to place intermediate (staging) files (will create directory)",
  )
}

fn command() -> Command(App) {
  clip.command({
    use app_dir <- clip.parameter
    use templates_dir <- clip.parameter
    use staging_dir <- clip.parameter
    use output_dir <- clip.parameter

    App(app_dir:, templates_dir:, staging_dir:, output_dir:)
  })
  |> clip.opt(app_dir_path_opt())
  |> clip.opt(template_dir_path_opt())
  |> clip.opt(staging_dir_path_opt())
  |> clip.opt(output_dir_path_opt())
}

pub fn main() -> Nil {
  let result =
    command()
    |> clip.help(help.simple(
      "package",
      "package target gleam application as a FreeBSD package with service scripts",
    ))
    |> clip.run(argv.load().arguments)

  case result {
    Error(e) -> io.println_error(e)
    Ok(app) -> {
      case
        packager.run(
          app.app_dir,
          app.templates_dir,
          app.staging_dir,
          app.output_dir,
        )
      {
        Error(e) -> io.println_error(e |> string.inspect)
        Ok(o) -> {
          io.println(o)
          io.println("package created")
        }
      }
      Nil
    }
  }
}
