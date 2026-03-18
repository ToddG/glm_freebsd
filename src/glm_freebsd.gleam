import argv
import clip.{type Command}
import clip/help
import clip/opt.{type Opt}
import gleam/io
import freebsd_templates
import freebsd_build
import config
import simplifile

type App {
  App(input: String, output: String)
}

fn input_opt() -> Opt(String) {
  opt.new("input") |> opt.help("path to target app (directory with gleam.toml)")
}

fn output_opt() -> Opt(String) {
  opt.new("output") |> opt.help("path to place generated files (will create output dir)")
}

fn templates() -> Command(App) {
  clip.command({
    use input <- clip.parameter
    use output <- clip.parameter

    App(input, output)
  })
  |> clip.opt(input_opt())
  |> clip.opt(output_opt())
}


pub fn main() -> Nil {
  let result =
    templates()
    |> clip.help(help.simple("templates", "generate templates for target app"))
    |> clip.run(argv.load().arguments)

  case result {
    Error(e) -> io.println_error(e)
    Ok(app) -> {
      let input_path = app.input
      let output_path = app.output
      let gleam_toml_path = input_path <> "/gleam.toml"
      let config = config.load_toml(gleam_toml_path, output_path)
      let assert Ok(_) = simplifile.create_directory_all(output_path)
      let _ = freebsd_templates.gen_files_from_templates(config, output_path)
      let _ = freebsd_build.run_build(config, input_path, output_path)
      Nil
    }
  }
}
