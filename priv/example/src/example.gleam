import envoy
import gleam/erlang/process
import gleam/string
import logging

pub fn main() -> Nil {
  let _ = logging.configure()
  logging.log(logging.Info, "Hello from example!")
  logging.log(logging.Info, "environment: " <> string.inspect(envoy.all()))
  process.sleep(10)
}
