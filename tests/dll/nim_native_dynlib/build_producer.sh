#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir"

nim=${NIM_NATIVE_DYNLIB_COMPILER:-"../../../bin/nim"}

case "$(uname -s)" in
  Darwin) library="$script_dir/libproducer.dylib" ;;
  Linux) library="$script_dir/libproducer.so" ;;
  *) echo "unsupported platform" >&2; exit 1 ;;
esac

# Build the producer and emit the semantic and native ABI artifacts used by the
# consumer binding generator.
"$nim" c --experimental:abi --emitBif:on --app:lib --mm:orc -d:useMalloc \
  --nimcache:"$script_dir/nimcache" --out:"$library" producer.nim
