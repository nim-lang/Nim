#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir"

nim=${NIM_NATIVE_DYNLIB_COMPILER:-"../../bin/nim"}

case "$(uname -s)" in
  Darwin) library="$script_dir/libproducer.dylib" ;;
  Linux) library="$script_dir/libproducer.so" ;;
  *) echo "unsupported platform" >&2; exit 1 ;;
esac

rm -rf nimcache generated generator consumer "$library"

# The ordinary C build also emits stable semantic BIF for binding generation.
"$nim" c --experimental:abi --emitBif:on --app:lib --mm:orc -d:useMalloc \
  --nimcache:"$script_dir/nimcache" --out:"$library" producer.nim

"$nim" c -d:release --out:"$script_dir/generator" generate.nim
"$script_dir/generator" "$script_dir/nimcache" "$script_dir/producer.nim" \
  "$script_dir/nimcache/producer.abi.nif" "$library" \
  "$script_dir/generated/producer_abi.nim"

"$nim" c -r --mm:orc -d:useMalloc --out:"$script_dir/consumer" consumer.nim
