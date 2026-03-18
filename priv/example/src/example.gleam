import gleam/io
import gleam/erlang/process

pub fn main() -> Nil {
  io.println("Hello from example!")
  process.sleep_forever()
}
