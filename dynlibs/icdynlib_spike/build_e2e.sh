#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir"

nim=${NIM_ICDYNLIB_COMPILER:-"../../bin/nim"}
cc=${CC:-cc}

case "$(uname -s)" in
  Darwin) library="$script_dir/libproducer.dylib" ;;
  Linux) library="$script_dir/libproducer.so" ;;
  *) echo "unsupported platform" >&2; exit 1 ;;
esac

rm -rf nimcache generated generator consumer c_consumer "$library"

"$nim" ic --app:lib --nimcache:"$script_dir/nimcache" \
  --out:"$library" producer.nim
"$nim" c -d:release --out:"$script_dir/generator" generate.nim
"$script_dir/generator" "$script_dir/nimcache" "$script_dir/producer.nim" \
  "$library" producer "$script_dir/generated"

"$nim" c -r --path:"$script_dir/generated" \
  --out:"$script_dir/consumer" consumer.nim
"$cc" -I"$script_dir/generated" consumer.c "$library" \
  -Wl,-rpath,"$script_dir" -o "$script_dir/c_consumer"
"$script_dir/c_consumer"

if "$nim" check unsupported_managed.nim >/dev/null 2>&1; then
  echo "managed ABI type was not rejected" >&2
  exit 1
fi
if "$nim" check unsupported_generic.nim >/dev/null 2>&1; then
  echo "generic ABI routine was not rejected" >&2
  exit 1
fi
