import gleam/option.{type Option}
import gleam/dict.{type Dict}

pub type PkgConfig {
  PkgConfig(
    description: String,
    maintainer: String,
    deps: List(String),
    user: Option(String),
  )
}

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
