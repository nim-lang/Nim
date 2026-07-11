#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir"

case "$(uname -s)" in
  Darwin) library="$script_dir/libproducer.dylib" ;;
  Linux) library="$script_dir/libproducer.so" ;;
  *) echo "unsupported platform" >&2; exit 1 ;;
esac

manifest="${library%.*}.abi.nif"

rm -rf nimcache generated generator consumer "$library" "$manifest"

"$script_dir/build_producer.sh"
"$script_dir/build_consumer.sh"
