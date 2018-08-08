#! /bin/sh

# build development version of the compiler; can be rerun safely

set -u # error on undefined variables
set -e # exit on first error

echo_run(){
  echo "\n$@"
  "$@"
}

[ -d csources ] || echo_run git clone --depth 1 https://github.com/nim-lang/csources.git
(
  ## avoid changing dir in case of failure
  echo_run cd csources
  echo_run sh build.sh
)

echo_run bin/nim c koch
echo_run ./koch boot -d:release
echo_run ./koch tools # Compile Nimble and other tools.
