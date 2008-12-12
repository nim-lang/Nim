#! /bin/sh

set -e

if test -z "$make"; then
  make=make
fi

hostname=`hostname`

for opts in \
  "" \
  "--enable-debug" \
  "--disable-wchar" \
  "--disable-multibyte" \
  "--without-alloca" \
  "--disable-wchar --without-alloca" \
  "--disable-approx" \
  "--disable-agrep" \
  "--enable-system-abi" \
  "--disable-largefile" \
  "--disable-nls" \
  "--disable-warnings"; do

  rm -rf tmp-build
  mkdir tmp-build
  cd tmp-build

  echo "$hostname: Configure options \"$opts\"..." >&2
  ../configure $opts > build-log.txt 2>&1
  $make >> build-log.txt 2>&1
  $make check >> build-log.txt 2>&1
  cd ..
done
