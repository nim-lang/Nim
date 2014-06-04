#!/bin/sh

if [ -e build/empty.txt ]; then
  rm -f build/empty.txt
  rmdir build
fi
if [ ! -e build/build.sh ]; then
  git clone -q --depth=1 git://github.com/nimrod-code/csources build
fi

pushd build
sh build.sh
popd

bin/nimrod c koch
./koch boot -d:release -d:useGnuReadline

export PATH="`pwd`/bin:$PATH"

pushd compiler
nimrod c -d:release c2nim/c2nim.nim
nimrod c -d:release pas2nim/pas2nim.nim
popd

pushd lib
nimrod c --app:lib -d:createNimRtl -d:release nimrtl.nim
popd

pushd tools
nimrod c -d:release nimgrep.nim
popd
