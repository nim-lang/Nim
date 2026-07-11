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

manifest="${library%.*}.abi.nif"
rm -rf nimcache consumer "$library" "$manifest"

"$nim" c --experimental:abi --app:lib \
  --nimcache:"$script_dir/nimcache" --out:"$library" producer.nim

test -f "$manifest"
"$nim" c -r --out:"$script_dir/consumer" consumer.nim
