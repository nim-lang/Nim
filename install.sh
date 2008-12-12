#! /bin/sh
# 
# Nimrod installation script
#   (c) 2008 Andreas Rumpf
#

if [ $# -eq 1 ] ; then

  if test -f bin/nimrod
  then 
    echo "Nimrod already built -- skipping this phase"
  else
    echo "building Nimrod..."
    sh ./build.sh || exit 1
    echo "...done"
  fi
  
  case $1 in
    "/usr/bin")
      configdir=/etc
      libdir=/usr/lib/nimrod
      mkdir -p /usr/lib/nimrod
      mkdir -p /usr/share/nimrod/doc

      cp bin/nimrod /usr/bin/nimrod
      cp config/nimdoc.cfg /etc/nimdoc.cfg
      cp -r -p lib /usr/lib/nimrod
      cp -r -p doc /usr/share/nimrod/doc
      ;;
    "/usr/local/bin")
      configdir=/etc
      libdir=/usr/local/lib/nimrod
      mkdir -p /usr/local/lib/nimrod
      mkdir -p /usr/local/share/nimrod/doc

      cp bin/nimrod /usr/local/bin/nimrod
      cp config/nimdoc.cfg /etc/nimdoc.cfg
      cp -r -p lib /usr/local/lib/nimrod
      cp -r -p doc /usr/local/share/nimrod/doc
      ;;
    *)
      configdir="$1/nimrod/config"
      libdir="$1/nimrod/lib"
      mkdir -p $1/nimrod
      mkdir -p $1/nimrod/bin
      mkdir -p $1/nimrod/config
      mkdir -p $1/nimrod/lib
      mkdir -p $1/nimrod/doc

      cp bin/nimrod $1/nimrod/bin/nimrod
      cp config/nimdoc.cfg $1/nimrod/config/nimdoc.cfg
      cp -r -p lib $1/nimrod
      cp -r -p doc $1/nimrod
      ;;
  esac
  # write the configuration file
  cat >$configdir/nimrod.cfg <<EOF
# Configuration file for the Nimrod Compiler.
# Feel free to edit the default values as you need.

cc = gcc
lib=$libdir
path="\$lib/base"
path="\$lib/base/gtk"
path="\$lib/base/cairo"
path="\$lib/base/x11"
path="\$lib/base/sdl"
path="\$lib/base/opengl"
path="\$lib/base/zip"
path="\$lib/windows"
path="\$lib/posix"
path="\$lib/ecmas"
path="\$lib/extra"

@if release:
  obj_checks:off
  field_checks:off
  range_checks:off
  bound_checks:off
  overflow_checks:off
  assertions:off

  stacktrace:off
  debugger:off
  line_dir:off
  opt:speed
@end

# additional options always passed to the compiler:
--verbosity: "1"
hint[LineTooLong]=off

@if unix and not bsd:
  passl= "-ldl"
@end

@if icc:
  passl = "-cxxlib"
  passc = "-cxxlib"
@end

# Configuration for the GNU C/C++ compiler:
#gcc.exe = "gcc-4.3"
#gcc.linkerExe = "gcc-4.3"
gcc.options.debug = "-g"
@if macosx:
  gcc.options.always = "-w -fasm-blocks"
@else:
  gcc.options.always = "-w"
@end
gcc.options.speed = "-O3 -fno-strict-aliasing"
gcc.options.size = "-Os"
EOF
  echo "installation successful"
else
  echo "Nimrod installation script"
  echo "Usage: [sudo] sh install.h DIR"
  echo "Where DIR may be:"
  echo "  /usr/bin"
  echo "  /usr/local/bin"
  echo "  /opt"
  echo "  <some other dir> (treated like '/opt')"
  echo "To deinstall, use the command:"
  echo "sh deinstall.sh DIR"
  exit 1
fi
