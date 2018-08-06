#! /bin/sh

# build development version of the compiler; can be rerun safely

set -u
set -e

[ -d csources ] || git clone --depth 1 https://github.com/nim-lang/csources.git
(
  ## avoid changing dir in case of failure
  cd csources
  sh build.sh
)

bin/nim c koch
./koch boot -d:release
./koch tools # Compile Nimble and other tools.

