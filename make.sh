#! /bin/sh

echo "update path with erlang28 binary, as that's needed for gleam "
echo "and/or the gleam json library"
export PATH=/usr/local/lib/erlang28/bin:$PATH

gleam clean
gleam build --target erlang
gleam run -m gleescript

echo "run the executable ./glm_freebsd"

./glm_freebsd --help
