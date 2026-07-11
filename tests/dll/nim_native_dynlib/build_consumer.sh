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

if [ ! -f "$library" ]; then
  echo "producer library not found; run ./build_producer.sh first" >&2
  exit 1
fi
if [ ! -f "$manifest" ]; then
  echo "producer ABI manifest not found; run ./build_producer.sh first" >&2
  exit 1
fi

"$nim" c -d:release --out:"$script_dir/generator" generate.nim
"$script_dir/generator" "$script_dir/nimcache" "$script_dir/producer.nim" \
  "$manifest" "$library" \
  "$script_dir/generated/producer_abi.nim"

"$nim" c -r --mm:orc -d:useMalloc --out:"$script_dir/consumer" consumer.nim

if "$nim" c --hints:off --warnings:off --mm:orc -d:useMalloc \
    --out:"$script_dir/consumer_copy_should_fail" \
    consumer_copy_should_fail.nim >/dev/null 2>&1; then
  echo "copying a generated move-only binding unexpectedly compiled" >&2
  exit 1
fi
