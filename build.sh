#! /bin/sh
# Generated from niminst
# Template is in tools/buildsh.tmpl
# To regenerate run ``niminst csource`` or ``koch csource``

set -e

while :
do
  case "$1" in
    --extraBuildArgs)
      extraBuildArgs=" $2"
      shift 2
      ;;
    --) # End of all options
      shift
      break;
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)  # No more options
      break
      ;;
  esac
done

CC="gcc"
LINKER="gcc"
COMP_FLAGS="-w -O3 -fno-strict-aliasing$extraBuildArgs"
LINK_FLAGS=""
# platform detection
ucpu=`uname -m`
uos=`uname`

# convert to lower case:
ucpu=`echo $ucpu | tr "[:upper:]" "[:lower:]"`
uos=`echo $uos | tr "[:upper:]" "[:lower:]"`

case $uos in
  *linux* ) 
    myos="linux" 
    LINK_FLAGS="$LINK_FLAGS -ldl -lm"
    ;;
  *freebsd* ) 
    myos="freebsd"
    LINK_FLAGS="$LINK_FLAGS -lm"
    ;;
  *openbsd* )
    myos="openbsd" 
    LINK_FLAGS="$LINK_FLAGS -lm"
    ;;
  *netbsd* )
    myos="netbsd"
    LINK_FLAGS="$LINK_FLAGS -lm"
    ;;
  *darwin* ) 
    myos="macosx"
    CC="clang"
    LINKER="clang"
    LINK_FLAGS="$LINK_FLAGS -ldl -lm"
    if [ "$HOSTTYPE" = "x86_64" ] ; then
      ucpu="amd64"
    fi
    ;;
  *aix* )
    myos="aix"
    LINK_FLAGS="$LINK_FLAGS -ldl -lm"    
    ;;
  *solaris* | *sun* ) 
    myos="solaris"
    LINK_FLAGS="$LINK_FLAGS -ldl -lm -lsocket -lnsl"
    ;;
  *haiku* )
    myos="haiku"
    ;;
  *) 
    echo "Error: unknown operating system: $uos"
    exit 1
    ;;
esac

case $ucpu in
  *i386* | *i486* | *i586* | *i686* | *bepc* | *i86pc* ) 
    mycpu="i386" ;;
  *amd*64* | *x86-64* | *x86_64* ) 
    mycpu="amd64" ;;
  *sparc*|*sun* ) 
    mycpu="sparc" ;;
  *ppc64* ) 
    if [ "$myos" = "linux" ] ; then
      COMP_FLAGS="$COMP_FLAGS -m64"
      LINK_FLAGS="$LINK_FLAGS -m64"
    fi
    mycpu="powerpc64" ;;
  *power*|*Power* ) 
    mycpu="powerpc" ;;
  *mips* ) 
    mycpu="mips" ;;
  *arm*|*armv6l* )
    mycpu="arm" ;;
  *) 
    echo "Error: unknown processor: $ucpu"
    exit 1
    ;;
esac

# call the compiler:

case $myos in
windows) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimrod.c -o build/1_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimrod.c -o build/1_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/system.c -o build/1_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/system.c -o build/1_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/commands.c -o build/1_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/commands.c -o build/1_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/os.c -o build/1_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/os.c -o build/1_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/strutils.c -o build/1_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/strutils.c -o build/1_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parseutils.c -o build/1_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parseutils.c -o build/1_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/times.c -o build/1_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/times.c -o build/1_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/winlean.c -o build/1_1/winlean.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/winlean.c -o build/1_1/winlean.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/msgs.c -o build/1_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/msgs.c -o build/1_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/options.c -o build/1_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/options.c -o build/1_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lists.c -o build/1_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lists.c -o build/1_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/strtabs.c -o build/1_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/strtabs.c -o build/1_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/hashes.c -o build/1_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/hashes.c -o build/1_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/tables.c -o build/1_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/tables.c -o build/1_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/math.c -o build/1_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/math.c -o build/1_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sockets.c -o build/1_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sockets.c -o build/1_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ropes.c -o build/1_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ropes.c -o build/1_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/platform.c -o build/1_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/platform.c -o build/1_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/crc.c -o build/1_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/crc.c -o build/1_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nversion.c -o build/1_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nversion.c -o build/1_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/condsyms.c -o build/1_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/condsyms.c -o build/1_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ast.c -o build/1_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ast.c -o build/1_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/idents.c -o build/1_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/idents.c -o build/1_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/intsets.c -o build/1_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/intsets.c -o build/1_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/idgen.c -o build/1_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/idgen.c -o build/1_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/astalgo.c -o build/1_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/astalgo.c -o build/1_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rodutils.c -o build/1_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rodutils.c -o build/1_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/extccomp.c -o build/1_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/extccomp.c -o build/1_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/osproc.c -o build/1_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/osproc.c -o build/1_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/streams.c -o build/1_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/streams.c -o build/1_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/wordrecg.c -o build/1_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/wordrecg.c -o build/1_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/babelcmd.c -o build/1_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/babelcmd.c -o build/1_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lexer.c -o build/1_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lexer.c -o build/1_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimlexbase.c -o build/1_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimlexbase.c -o build/1_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/llstream.c -o build/1_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/llstream.c -o build/1_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimconf.c -o build/1_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimconf.c -o build/1_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/main.c -o build/1_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/main.c -o build/1_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/syntaxes.c -o build/1_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/syntaxes.c -o build/1_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parser.c -o build/1_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parser.c -o build/1_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/pbraces.c -o build/1_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/pbraces.c -o build/1_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/filters.c -o build/1_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/filters.c -o build/1_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/renderer.c -o build/1_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/renderer.c -o build/1_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/filter_tmpl.c -o build/1_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/filter_tmpl.c -o build/1_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rodread.c -o build/1_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rodread.c -o build/1_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/types.c -o build/1_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/types.c -o build/1_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/trees.c -o build/1_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/trees.c -o build/1_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/memfiles.c -o build/1_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/memfiles.c -o build/1_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rodwrite.c -o build/1_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rodwrite.c -o build/1_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/passes.c -o build/1_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/passes.c -o build/1_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/magicsys.c -o build/1_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/magicsys.c -o build/1_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimsets.c -o build/1_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimsets.c -o build/1_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/bitsets.c -o build/1_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/bitsets.c -o build/1_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semthreads.c -o build/1_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semthreads.c -o build/1_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/importer.c -o build/1_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/importer.c -o build/1_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lookups.c -o build/1_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lookups.c -o build/1_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semdata.c -o build/1_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semdata.c -o build/1_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/treetab.c -o build/1_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/treetab.c -o build/1_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/evals.c -o build/1_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/evals.c -o build/1_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semfold.c -o build/1_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semfold.c -o build/1_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/saturate.c -o build/1_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/saturate.c -o build/1_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/transf.c -o build/1_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/transf.c -o build/1_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/cgmeth.c -o build/1_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/cgmeth.c -o build/1_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sempass2.c -o build/1_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sempass2.c -o build/1_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lambdalifting.c -o build/1_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lambdalifting.c -o build/1_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/evaltempl.c -o build/1_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/evaltempl.c -o build/1_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sem.c -o build/1_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sem.c -o build/1_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/procfind.c -o build/1_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/procfind.c -o build/1_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/pragmas.c -o build/1_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/pragmas.c -o build/1_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semtypinst.c -o build/1_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semtypinst.c -o build/1_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sigmatch.c -o build/1_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sigmatch.c -o build/1_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parampatterns.c -o build/1_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parampatterns.c -o build/1_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/docgen.c -o build/1_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/docgen.c -o build/1_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rstast.c -o build/1_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rstast.c -o build/1_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rst.c -o build/1_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rst.c -o build/1_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rstgen.c -o build/1_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rstgen.c -o build/1_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/highlite.c -o build/1_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/highlite.c -o build/1_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/algorithm.c -o build/1_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/algorithm.c -o build/1_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/aliases.c -o build/1_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/aliases.c -o build/1_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/patterns.c -o build/1_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/patterns.c -o build/1_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/cgen.c -o build/1_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/cgen.c -o build/1_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ccgutils.c -o build/1_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ccgutils.c -o build/1_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/cgendata.c -o build/1_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/cgendata.c -o build/1_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ccgmerge.c -o build/1_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ccgmerge.c -o build/1_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/jsgen.c -o build/1_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/jsgen.c -o build/1_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/json.c -o build/1_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/json.c -o build/1_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lexbase.c -o build/1_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lexbase.c -o build/1_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/unicode.c -o build/1_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/unicode.c -o build/1_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/passaux.c -o build/1_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/passaux.c -o build/1_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/depends.c -o build/1_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/depends.c -o build/1_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/docgen2.c -o build/1_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/docgen2.c -o build/1_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/service.c -o build/1_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/service.c -o build/1_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parseopt.c -o build/1_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parseopt.c -o build/1_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_1/nimrod.o \
build/1_1/system.o \
build/1_1/commands.o \
build/1_1/os.o \
build/1_1/strutils.o \
build/1_1/parseutils.o \
build/1_1/times.o \
build/1_1/winlean.o \
build/1_1/msgs.o \
build/1_1/options.o \
build/1_1/lists.o \
build/1_1/strtabs.o \
build/1_1/hashes.o \
build/1_1/tables.o \
build/1_1/math.o \
build/1_1/sockets.o \
build/1_1/ropes.o \
build/1_1/platform.o \
build/1_1/crc.o \
build/1_1/nversion.o \
build/1_1/condsyms.o \
build/1_1/ast.o \
build/1_1/idents.o \
build/1_1/intsets.o \
build/1_1/idgen.o \
build/1_1/astalgo.o \
build/1_1/rodutils.o \
build/1_1/extccomp.o \
build/1_1/osproc.o \
build/1_1/streams.o \
build/1_1/wordrecg.o \
build/1_1/babelcmd.o \
build/1_1/lexer.o \
build/1_1/nimlexbase.o \
build/1_1/llstream.o \
build/1_1/nimconf.o \
build/1_1/main.o \
build/1_1/syntaxes.o \
build/1_1/parser.o \
build/1_1/pbraces.o \
build/1_1/filters.o \
build/1_1/renderer.o \
build/1_1/filter_tmpl.o \
build/1_1/rodread.o \
build/1_1/types.o \
build/1_1/trees.o \
build/1_1/memfiles.o \
build/1_1/rodwrite.o \
build/1_1/passes.o \
build/1_1/magicsys.o \
build/1_1/nimsets.o \
build/1_1/bitsets.o \
build/1_1/semthreads.o \
build/1_1/importer.o \
build/1_1/lookups.o \
build/1_1/semdata.o \
build/1_1/treetab.o \
build/1_1/evals.o \
build/1_1/semfold.o \
build/1_1/saturate.o \
build/1_1/transf.o \
build/1_1/cgmeth.o \
build/1_1/sempass2.o \
build/1_1/lambdalifting.o \
build/1_1/evaltempl.o \
build/1_1/sem.o \
build/1_1/procfind.o \
build/1_1/pragmas.o \
build/1_1/semtypinst.o \
build/1_1/sigmatch.o \
build/1_1/parampatterns.o \
build/1_1/docgen.o \
build/1_1/rstast.o \
build/1_1/rst.o \
build/1_1/rstgen.o \
build/1_1/highlite.o \
build/1_1/algorithm.o \
build/1_1/aliases.o \
build/1_1/patterns.o \
build/1_1/cgen.o \
build/1_1/ccgutils.o \
build/1_1/cgendata.o \
build/1_1/ccgmerge.o \
build/1_1/jsgen.o \
build/1_1/json.o \
build/1_1/lexbase.o \
build/1_1/unicode.o \
build/1_1/passaux.o \
build/1_1/depends.o \
build/1_1/docgen2.o \
build/1_1/service.o \
build/1_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_1/nimrod.o \
build/1_1/system.o \
build/1_1/commands.o \
build/1_1/os.o \
build/1_1/strutils.o \
build/1_1/parseutils.o \
build/1_1/times.o \
build/1_1/winlean.o \
build/1_1/msgs.o \
build/1_1/options.o \
build/1_1/lists.o \
build/1_1/strtabs.o \
build/1_1/hashes.o \
build/1_1/tables.o \
build/1_1/math.o \
build/1_1/sockets.o \
build/1_1/ropes.o \
build/1_1/platform.o \
build/1_1/crc.o \
build/1_1/nversion.o \
build/1_1/condsyms.o \
build/1_1/ast.o \
build/1_1/idents.o \
build/1_1/intsets.o \
build/1_1/idgen.o \
build/1_1/astalgo.o \
build/1_1/rodutils.o \
build/1_1/extccomp.o \
build/1_1/osproc.o \
build/1_1/streams.o \
build/1_1/wordrecg.o \
build/1_1/babelcmd.o \
build/1_1/lexer.o \
build/1_1/nimlexbase.o \
build/1_1/llstream.o \
build/1_1/nimconf.o \
build/1_1/main.o \
build/1_1/syntaxes.o \
build/1_1/parser.o \
build/1_1/pbraces.o \
build/1_1/filters.o \
build/1_1/renderer.o \
build/1_1/filter_tmpl.o \
build/1_1/rodread.o \
build/1_1/types.o \
build/1_1/trees.o \
build/1_1/memfiles.o \
build/1_1/rodwrite.o \
build/1_1/passes.o \
build/1_1/magicsys.o \
build/1_1/nimsets.o \
build/1_1/bitsets.o \
build/1_1/semthreads.o \
build/1_1/importer.o \
build/1_1/lookups.o \
build/1_1/semdata.o \
build/1_1/treetab.o \
build/1_1/evals.o \
build/1_1/semfold.o \
build/1_1/saturate.o \
build/1_1/transf.o \
build/1_1/cgmeth.o \
build/1_1/sempass2.o \
build/1_1/lambdalifting.o \
build/1_1/evaltempl.o \
build/1_1/sem.o \
build/1_1/procfind.o \
build/1_1/pragmas.o \
build/1_1/semtypinst.o \
build/1_1/sigmatch.o \
build/1_1/parampatterns.o \
build/1_1/docgen.o \
build/1_1/rstast.o \
build/1_1/rst.o \
build/1_1/rstgen.o \
build/1_1/highlite.o \
build/1_1/algorithm.o \
build/1_1/aliases.o \
build/1_1/patterns.o \
build/1_1/cgen.o \
build/1_1/ccgutils.o \
build/1_1/cgendata.o \
build/1_1/ccgmerge.o \
build/1_1/jsgen.o \
build/1_1/json.o \
build/1_1/lexbase.o \
build/1_1/unicode.o \
build/1_1/passaux.o \
build/1_1/depends.o \
build/1_1/docgen2.o \
build/1_1/service.o \
build/1_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimrod.c -o build/1_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimrod.c -o build/1_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/system.c -o build/1_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/system.c -o build/1_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/commands.c -o build/1_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/commands.c -o build/1_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/os.c -o build/1_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/os.c -o build/1_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/strutils.c -o build/1_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/strutils.c -o build/1_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parseutils.c -o build/1_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parseutils.c -o build/1_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/times.c -o build/1_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/times.c -o build/1_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/winlean.c -o build/1_2/winlean.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/winlean.c -o build/1_2/winlean.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/msgs.c -o build/1_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/msgs.c -o build/1_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/options.c -o build/1_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/options.c -o build/1_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lists.c -o build/1_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lists.c -o build/1_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/strtabs.c -o build/1_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/strtabs.c -o build/1_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/hashes.c -o build/1_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/hashes.c -o build/1_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/tables.c -o build/1_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/tables.c -o build/1_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/math.c -o build/1_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/math.c -o build/1_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sockets.c -o build/1_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sockets.c -o build/1_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ropes.c -o build/1_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ropes.c -o build/1_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/platform.c -o build/1_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/platform.c -o build/1_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/crc.c -o build/1_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/crc.c -o build/1_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nversion.c -o build/1_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nversion.c -o build/1_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/condsyms.c -o build/1_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/condsyms.c -o build/1_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ast.c -o build/1_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ast.c -o build/1_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/idents.c -o build/1_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/idents.c -o build/1_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/intsets.c -o build/1_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/intsets.c -o build/1_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/idgen.c -o build/1_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/idgen.c -o build/1_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/astalgo.c -o build/1_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/astalgo.c -o build/1_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rodutils.c -o build/1_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rodutils.c -o build/1_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/extccomp.c -o build/1_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/extccomp.c -o build/1_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/osproc.c -o build/1_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/osproc.c -o build/1_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/streams.c -o build/1_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/streams.c -o build/1_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/wordrecg.c -o build/1_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/wordrecg.c -o build/1_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/babelcmd.c -o build/1_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/babelcmd.c -o build/1_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lexer.c -o build/1_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lexer.c -o build/1_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimlexbase.c -o build/1_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimlexbase.c -o build/1_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/llstream.c -o build/1_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/llstream.c -o build/1_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimconf.c -o build/1_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimconf.c -o build/1_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/main.c -o build/1_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/main.c -o build/1_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/syntaxes.c -o build/1_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/syntaxes.c -o build/1_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parser.c -o build/1_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parser.c -o build/1_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/pbraces.c -o build/1_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/pbraces.c -o build/1_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/filters.c -o build/1_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/filters.c -o build/1_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/renderer.c -o build/1_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/renderer.c -o build/1_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/filter_tmpl.c -o build/1_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/filter_tmpl.c -o build/1_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rodread.c -o build/1_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rodread.c -o build/1_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/types.c -o build/1_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/types.c -o build/1_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/trees.c -o build/1_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/trees.c -o build/1_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/memfiles.c -o build/1_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/memfiles.c -o build/1_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rodwrite.c -o build/1_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rodwrite.c -o build/1_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/passes.c -o build/1_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/passes.c -o build/1_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/magicsys.c -o build/1_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/magicsys.c -o build/1_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimsets.c -o build/1_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimsets.c -o build/1_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/bitsets.c -o build/1_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/bitsets.c -o build/1_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semthreads.c -o build/1_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semthreads.c -o build/1_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/importer.c -o build/1_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/importer.c -o build/1_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lookups.c -o build/1_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lookups.c -o build/1_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semdata.c -o build/1_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semdata.c -o build/1_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/treetab.c -o build/1_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/treetab.c -o build/1_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/evals.c -o build/1_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/evals.c -o build/1_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semfold.c -o build/1_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semfold.c -o build/1_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/saturate.c -o build/1_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/saturate.c -o build/1_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/transf.c -o build/1_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/transf.c -o build/1_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/cgmeth.c -o build/1_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/cgmeth.c -o build/1_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sempass2.c -o build/1_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sempass2.c -o build/1_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lambdalifting.c -o build/1_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lambdalifting.c -o build/1_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/evaltempl.c -o build/1_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/evaltempl.c -o build/1_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sem.c -o build/1_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sem.c -o build/1_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/procfind.c -o build/1_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/procfind.c -o build/1_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/pragmas.c -o build/1_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/pragmas.c -o build/1_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semtypinst.c -o build/1_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semtypinst.c -o build/1_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sigmatch.c -o build/1_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sigmatch.c -o build/1_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parampatterns.c -o build/1_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parampatterns.c -o build/1_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/docgen.c -o build/1_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/docgen.c -o build/1_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rstast.c -o build/1_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rstast.c -o build/1_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rst.c -o build/1_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rst.c -o build/1_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rstgen.c -o build/1_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rstgen.c -o build/1_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/highlite.c -o build/1_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/highlite.c -o build/1_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/algorithm.c -o build/1_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/algorithm.c -o build/1_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/aliases.c -o build/1_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/aliases.c -o build/1_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/patterns.c -o build/1_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/patterns.c -o build/1_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/cgen.c -o build/1_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/cgen.c -o build/1_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ccgutils.c -o build/1_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ccgutils.c -o build/1_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/cgendata.c -o build/1_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/cgendata.c -o build/1_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ccgmerge.c -o build/1_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ccgmerge.c -o build/1_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/jsgen.c -o build/1_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/jsgen.c -o build/1_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/json.c -o build/1_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/json.c -o build/1_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lexbase.c -o build/1_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lexbase.c -o build/1_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/unicode.c -o build/1_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/unicode.c -o build/1_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/passaux.c -o build/1_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/passaux.c -o build/1_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/depends.c -o build/1_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/depends.c -o build/1_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/docgen2.c -o build/1_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/docgen2.c -o build/1_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/service.c -o build/1_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/service.c -o build/1_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parseopt.c -o build/1_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parseopt.c -o build/1_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_2/nimrod.o \
build/1_2/system.o \
build/1_2/commands.o \
build/1_2/os.o \
build/1_2/strutils.o \
build/1_2/parseutils.o \
build/1_2/times.o \
build/1_2/winlean.o \
build/1_2/msgs.o \
build/1_2/options.o \
build/1_2/lists.o \
build/1_2/strtabs.o \
build/1_2/hashes.o \
build/1_2/tables.o \
build/1_2/math.o \
build/1_2/sockets.o \
build/1_2/ropes.o \
build/1_2/platform.o \
build/1_2/crc.o \
build/1_2/nversion.o \
build/1_2/condsyms.o \
build/1_2/ast.o \
build/1_2/idents.o \
build/1_2/intsets.o \
build/1_2/idgen.o \
build/1_2/astalgo.o \
build/1_2/rodutils.o \
build/1_2/extccomp.o \
build/1_2/osproc.o \
build/1_2/streams.o \
build/1_2/wordrecg.o \
build/1_2/babelcmd.o \
build/1_2/lexer.o \
build/1_2/nimlexbase.o \
build/1_2/llstream.o \
build/1_2/nimconf.o \
build/1_2/main.o \
build/1_2/syntaxes.o \
build/1_2/parser.o \
build/1_2/pbraces.o \
build/1_2/filters.o \
build/1_2/renderer.o \
build/1_2/filter_tmpl.o \
build/1_2/rodread.o \
build/1_2/types.o \
build/1_2/trees.o \
build/1_2/memfiles.o \
build/1_2/rodwrite.o \
build/1_2/passes.o \
build/1_2/magicsys.o \
build/1_2/nimsets.o \
build/1_2/bitsets.o \
build/1_2/semthreads.o \
build/1_2/importer.o \
build/1_2/lookups.o \
build/1_2/semdata.o \
build/1_2/treetab.o \
build/1_2/evals.o \
build/1_2/semfold.o \
build/1_2/saturate.o \
build/1_2/transf.o \
build/1_2/cgmeth.o \
build/1_2/sempass2.o \
build/1_2/lambdalifting.o \
build/1_2/evaltempl.o \
build/1_2/sem.o \
build/1_2/procfind.o \
build/1_2/pragmas.o \
build/1_2/semtypinst.o \
build/1_2/sigmatch.o \
build/1_2/parampatterns.o \
build/1_2/docgen.o \
build/1_2/rstast.o \
build/1_2/rst.o \
build/1_2/rstgen.o \
build/1_2/highlite.o \
build/1_2/algorithm.o \
build/1_2/aliases.o \
build/1_2/patterns.o \
build/1_2/cgen.o \
build/1_2/ccgutils.o \
build/1_2/cgendata.o \
build/1_2/ccgmerge.o \
build/1_2/jsgen.o \
build/1_2/json.o \
build/1_2/lexbase.o \
build/1_2/unicode.o \
build/1_2/passaux.o \
build/1_2/depends.o \
build/1_2/docgen2.o \
build/1_2/service.o \
build/1_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_2/nimrod.o \
build/1_2/system.o \
build/1_2/commands.o \
build/1_2/os.o \
build/1_2/strutils.o \
build/1_2/parseutils.o \
build/1_2/times.o \
build/1_2/winlean.o \
build/1_2/msgs.o \
build/1_2/options.o \
build/1_2/lists.o \
build/1_2/strtabs.o \
build/1_2/hashes.o \
build/1_2/tables.o \
build/1_2/math.o \
build/1_2/sockets.o \
build/1_2/ropes.o \
build/1_2/platform.o \
build/1_2/crc.o \
build/1_2/nversion.o \
build/1_2/condsyms.o \
build/1_2/ast.o \
build/1_2/idents.o \
build/1_2/intsets.o \
build/1_2/idgen.o \
build/1_2/astalgo.o \
build/1_2/rodutils.o \
build/1_2/extccomp.o \
build/1_2/osproc.o \
build/1_2/streams.o \
build/1_2/wordrecg.o \
build/1_2/babelcmd.o \
build/1_2/lexer.o \
build/1_2/nimlexbase.o \
build/1_2/llstream.o \
build/1_2/nimconf.o \
build/1_2/main.o \
build/1_2/syntaxes.o \
build/1_2/parser.o \
build/1_2/pbraces.o \
build/1_2/filters.o \
build/1_2/renderer.o \
build/1_2/filter_tmpl.o \
build/1_2/rodread.o \
build/1_2/types.o \
build/1_2/trees.o \
build/1_2/memfiles.o \
build/1_2/rodwrite.o \
build/1_2/passes.o \
build/1_2/magicsys.o \
build/1_2/nimsets.o \
build/1_2/bitsets.o \
build/1_2/semthreads.o \
build/1_2/importer.o \
build/1_2/lookups.o \
build/1_2/semdata.o \
build/1_2/treetab.o \
build/1_2/evals.o \
build/1_2/semfold.o \
build/1_2/saturate.o \
build/1_2/transf.o \
build/1_2/cgmeth.o \
build/1_2/sempass2.o \
build/1_2/lambdalifting.o \
build/1_2/evaltempl.o \
build/1_2/sem.o \
build/1_2/procfind.o \
build/1_2/pragmas.o \
build/1_2/semtypinst.o \
build/1_2/sigmatch.o \
build/1_2/parampatterns.o \
build/1_2/docgen.o \
build/1_2/rstast.o \
build/1_2/rst.o \
build/1_2/rstgen.o \
build/1_2/highlite.o \
build/1_2/algorithm.o \
build/1_2/aliases.o \
build/1_2/patterns.o \
build/1_2/cgen.o \
build/1_2/ccgutils.o \
build/1_2/cgendata.o \
build/1_2/ccgmerge.o \
build/1_2/jsgen.o \
build/1_2/json.o \
build/1_2/lexbase.o \
build/1_2/unicode.o \
build/1_2/passaux.o \
build/1_2/depends.o \
build/1_2/docgen2.o \
build/1_2/service.o \
build/1_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimrod.c -o build/1_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimrod.c -o build/1_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/system.c -o build/1_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/system.c -o build/1_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/commands.c -o build/1_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/commands.c -o build/1_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/os.c -o build/1_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/os.c -o build/1_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/strutils.c -o build/1_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/strutils.c -o build/1_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parseutils.c -o build/1_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parseutils.c -o build/1_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/times.c -o build/1_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/times.c -o build/1_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/winlean.c -o build/1_2/winlean.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/winlean.c -o build/1_2/winlean.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/msgs.c -o build/1_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/msgs.c -o build/1_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/options.c -o build/1_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/options.c -o build/1_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lists.c -o build/1_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lists.c -o build/1_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/strtabs.c -o build/1_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/strtabs.c -o build/1_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/hashes.c -o build/1_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/hashes.c -o build/1_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/tables.c -o build/1_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/tables.c -o build/1_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/math.c -o build/1_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/math.c -o build/1_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_3/sockets.c -o build/1_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_3/sockets.c -o build/1_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ropes.c -o build/1_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ropes.c -o build/1_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_3/platform.c -o build/1_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_3/platform.c -o build/1_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/crc.c -o build/1_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/crc.c -o build/1_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nversion.c -o build/1_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nversion.c -o build/1_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/condsyms.c -o build/1_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/condsyms.c -o build/1_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ast.c -o build/1_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ast.c -o build/1_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/idents.c -o build/1_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/idents.c -o build/1_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/intsets.c -o build/1_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/intsets.c -o build/1_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/idgen.c -o build/1_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/idgen.c -o build/1_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/astalgo.c -o build/1_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/astalgo.c -o build/1_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rodutils.c -o build/1_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rodutils.c -o build/1_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/extccomp.c -o build/1_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/extccomp.c -o build/1_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/osproc.c -o build/1_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/osproc.c -o build/1_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/streams.c -o build/1_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/streams.c -o build/1_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/wordrecg.c -o build/1_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/wordrecg.c -o build/1_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/babelcmd.c -o build/1_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/babelcmd.c -o build/1_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lexer.c -o build/1_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lexer.c -o build/1_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimlexbase.c -o build/1_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimlexbase.c -o build/1_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/llstream.c -o build/1_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/llstream.c -o build/1_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimconf.c -o build/1_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimconf.c -o build/1_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/main.c -o build/1_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/main.c -o build/1_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/syntaxes.c -o build/1_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/syntaxes.c -o build/1_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parser.c -o build/1_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parser.c -o build/1_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/pbraces.c -o build/1_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/pbraces.c -o build/1_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/filters.c -o build/1_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/filters.c -o build/1_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/renderer.c -o build/1_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/renderer.c -o build/1_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/filter_tmpl.c -o build/1_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/filter_tmpl.c -o build/1_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rodread.c -o build/1_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rodread.c -o build/1_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/types.c -o build/1_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/types.c -o build/1_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/trees.c -o build/1_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/trees.c -o build/1_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/memfiles.c -o build/1_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/memfiles.c -o build/1_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rodwrite.c -o build/1_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rodwrite.c -o build/1_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/passes.c -o build/1_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/passes.c -o build/1_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/magicsys.c -o build/1_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/magicsys.c -o build/1_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/nimsets.c -o build/1_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/nimsets.c -o build/1_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/bitsets.c -o build/1_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/bitsets.c -o build/1_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semthreads.c -o build/1_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semthreads.c -o build/1_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/importer.c -o build/1_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/importer.c -o build/1_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lookups.c -o build/1_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lookups.c -o build/1_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semdata.c -o build/1_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semdata.c -o build/1_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/treetab.c -o build/1_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/treetab.c -o build/1_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/evals.c -o build/1_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/evals.c -o build/1_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semfold.c -o build/1_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semfold.c -o build/1_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/saturate.c -o build/1_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/saturate.c -o build/1_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/transf.c -o build/1_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/transf.c -o build/1_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/cgmeth.c -o build/1_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/cgmeth.c -o build/1_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sempass2.c -o build/1_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sempass2.c -o build/1_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lambdalifting.c -o build/1_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lambdalifting.c -o build/1_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/evaltempl.c -o build/1_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/evaltempl.c -o build/1_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sem.c -o build/1_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sem.c -o build/1_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/procfind.c -o build/1_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/procfind.c -o build/1_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/pragmas.c -o build/1_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/pragmas.c -o build/1_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/semtypinst.c -o build/1_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/semtypinst.c -o build/1_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/sigmatch.c -o build/1_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/sigmatch.c -o build/1_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parampatterns.c -o build/1_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parampatterns.c -o build/1_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/docgen.c -o build/1_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/docgen.c -o build/1_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rstast.c -o build/1_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rstast.c -o build/1_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rst.c -o build/1_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rst.c -o build/1_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/rstgen.c -o build/1_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/rstgen.c -o build/1_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/highlite.c -o build/1_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/highlite.c -o build/1_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/algorithm.c -o build/1_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/algorithm.c -o build/1_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/aliases.c -o build/1_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/aliases.c -o build/1_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/patterns.c -o build/1_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/patterns.c -o build/1_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/cgen.c -o build/1_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/cgen.c -o build/1_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ccgutils.c -o build/1_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ccgutils.c -o build/1_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/cgendata.c -o build/1_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/cgendata.c -o build/1_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/ccgmerge.c -o build/1_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/ccgmerge.c -o build/1_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/jsgen.c -o build/1_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/jsgen.c -o build/1_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/json.c -o build/1_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/json.c -o build/1_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/lexbase.c -o build/1_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/lexbase.c -o build/1_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/unicode.c -o build/1_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/unicode.c -o build/1_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/passaux.c -o build/1_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/passaux.c -o build/1_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/depends.c -o build/1_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/depends.c -o build/1_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/docgen2.c -o build/1_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/docgen2.c -o build/1_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/service.c -o build/1_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/service.c -o build/1_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_2/parseopt.c -o build/1_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_2/parseopt.c -o build/1_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_2/nimrod.o \
build/1_2/system.o \
build/1_2/commands.o \
build/1_2/os.o \
build/1_2/strutils.o \
build/1_2/parseutils.o \
build/1_2/times.o \
build/1_2/winlean.o \
build/1_2/msgs.o \
build/1_2/options.o \
build/1_2/lists.o \
build/1_2/strtabs.o \
build/1_2/hashes.o \
build/1_2/tables.o \
build/1_2/math.o \
build/1_3/sockets.o \
build/1_2/ropes.o \
build/1_3/platform.o \
build/1_2/crc.o \
build/1_2/nversion.o \
build/1_2/condsyms.o \
build/1_2/ast.o \
build/1_2/idents.o \
build/1_2/intsets.o \
build/1_2/idgen.o \
build/1_2/astalgo.o \
build/1_2/rodutils.o \
build/1_2/extccomp.o \
build/1_2/osproc.o \
build/1_2/streams.o \
build/1_2/wordrecg.o \
build/1_2/babelcmd.o \
build/1_2/lexer.o \
build/1_2/nimlexbase.o \
build/1_2/llstream.o \
build/1_2/nimconf.o \
build/1_2/main.o \
build/1_2/syntaxes.o \
build/1_2/parser.o \
build/1_2/pbraces.o \
build/1_2/filters.o \
build/1_2/renderer.o \
build/1_2/filter_tmpl.o \
build/1_2/rodread.o \
build/1_2/types.o \
build/1_2/trees.o \
build/1_2/memfiles.o \
build/1_2/rodwrite.o \
build/1_2/passes.o \
build/1_2/magicsys.o \
build/1_2/nimsets.o \
build/1_2/bitsets.o \
build/1_2/semthreads.o \
build/1_2/importer.o \
build/1_2/lookups.o \
build/1_2/semdata.o \
build/1_2/treetab.o \
build/1_2/evals.o \
build/1_2/semfold.o \
build/1_2/saturate.o \
build/1_2/transf.o \
build/1_2/cgmeth.o \
build/1_2/sempass2.o \
build/1_2/lambdalifting.o \
build/1_2/evaltempl.o \
build/1_2/sem.o \
build/1_2/procfind.o \
build/1_2/pragmas.o \
build/1_2/semtypinst.o \
build/1_2/sigmatch.o \
build/1_2/parampatterns.o \
build/1_2/docgen.o \
build/1_2/rstast.o \
build/1_2/rst.o \
build/1_2/rstgen.o \
build/1_2/highlite.o \
build/1_2/algorithm.o \
build/1_2/aliases.o \
build/1_2/patterns.o \
build/1_2/cgen.o \
build/1_2/ccgutils.o \
build/1_2/cgendata.o \
build/1_2/ccgmerge.o \
build/1_2/jsgen.o \
build/1_2/json.o \
build/1_2/lexbase.o \
build/1_2/unicode.o \
build/1_2/passaux.o \
build/1_2/depends.o \
build/1_2/docgen2.o \
build/1_2/service.o \
build/1_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_2/nimrod.o \
build/1_2/system.o \
build/1_2/commands.o \
build/1_2/os.o \
build/1_2/strutils.o \
build/1_2/parseutils.o \
build/1_2/times.o \
build/1_2/winlean.o \
build/1_2/msgs.o \
build/1_2/options.o \
build/1_2/lists.o \
build/1_2/strtabs.o \
build/1_2/hashes.o \
build/1_2/tables.o \
build/1_2/math.o \
build/1_3/sockets.o \
build/1_2/ropes.o \
build/1_3/platform.o \
build/1_2/crc.o \
build/1_2/nversion.o \
build/1_2/condsyms.o \
build/1_2/ast.o \
build/1_2/idents.o \
build/1_2/intsets.o \
build/1_2/idgen.o \
build/1_2/astalgo.o \
build/1_2/rodutils.o \
build/1_2/extccomp.o \
build/1_2/osproc.o \
build/1_2/streams.o \
build/1_2/wordrecg.o \
build/1_2/babelcmd.o \
build/1_2/lexer.o \
build/1_2/nimlexbase.o \
build/1_2/llstream.o \
build/1_2/nimconf.o \
build/1_2/main.o \
build/1_2/syntaxes.o \
build/1_2/parser.o \
build/1_2/pbraces.o \
build/1_2/filters.o \
build/1_2/renderer.o \
build/1_2/filter_tmpl.o \
build/1_2/rodread.o \
build/1_2/types.o \
build/1_2/trees.o \
build/1_2/memfiles.o \
build/1_2/rodwrite.o \
build/1_2/passes.o \
build/1_2/magicsys.o \
build/1_2/nimsets.o \
build/1_2/bitsets.o \
build/1_2/semthreads.o \
build/1_2/importer.o \
build/1_2/lookups.o \
build/1_2/semdata.o \
build/1_2/treetab.o \
build/1_2/evals.o \
build/1_2/semfold.o \
build/1_2/saturate.o \
build/1_2/transf.o \
build/1_2/cgmeth.o \
build/1_2/sempass2.o \
build/1_2/lambdalifting.o \
build/1_2/evaltempl.o \
build/1_2/sem.o \
build/1_2/procfind.o \
build/1_2/pragmas.o \
build/1_2/semtypinst.o \
build/1_2/sigmatch.o \
build/1_2/parampatterns.o \
build/1_2/docgen.o \
build/1_2/rstast.o \
build/1_2/rst.o \
build/1_2/rstgen.o \
build/1_2/highlite.o \
build/1_2/algorithm.o \
build/1_2/aliases.o \
build/1_2/patterns.o \
build/1_2/cgen.o \
build/1_2/ccgutils.o \
build/1_2/cgendata.o \
build/1_2/ccgmerge.o \
build/1_2/jsgen.o \
build/1_2/json.o \
build/1_2/lexbase.o \
build/1_2/unicode.o \
build/1_2/passaux.o \
build/1_2/depends.o \
build/1_2/docgen2.o \
build/1_2/service.o \
build/1_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimrod.c -o build/1_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimrod.c -o build/1_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/system.c -o build/1_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/system.c -o build/1_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/commands.c -o build/1_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/commands.c -o build/1_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/os.c -o build/1_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/os.c -o build/1_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/strutils.c -o build/1_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/strutils.c -o build/1_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parseutils.c -o build/1_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parseutils.c -o build/1_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/times.c -o build/1_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/times.c -o build/1_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/winlean.c -o build/1_1/winlean.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/winlean.c -o build/1_1/winlean.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/msgs.c -o build/1_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/msgs.c -o build/1_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/options.c -o build/1_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/options.c -o build/1_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lists.c -o build/1_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lists.c -o build/1_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/strtabs.c -o build/1_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/strtabs.c -o build/1_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/hashes.c -o build/1_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/hashes.c -o build/1_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/tables.c -o build/1_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/tables.c -o build/1_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/math.c -o build/1_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/math.c -o build/1_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sockets.c -o build/1_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sockets.c -o build/1_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ropes.c -o build/1_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ropes.c -o build/1_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_4/platform.c -o build/1_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_4/platform.c -o build/1_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/crc.c -o build/1_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/crc.c -o build/1_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nversion.c -o build/1_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nversion.c -o build/1_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/condsyms.c -o build/1_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/condsyms.c -o build/1_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ast.c -o build/1_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ast.c -o build/1_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/idents.c -o build/1_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/idents.c -o build/1_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/intsets.c -o build/1_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/intsets.c -o build/1_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/idgen.c -o build/1_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/idgen.c -o build/1_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/astalgo.c -o build/1_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/astalgo.c -o build/1_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rodutils.c -o build/1_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rodutils.c -o build/1_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/extccomp.c -o build/1_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/extccomp.c -o build/1_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/osproc.c -o build/1_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/osproc.c -o build/1_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/streams.c -o build/1_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/streams.c -o build/1_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/wordrecg.c -o build/1_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/wordrecg.c -o build/1_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/babelcmd.c -o build/1_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/babelcmd.c -o build/1_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lexer.c -o build/1_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lexer.c -o build/1_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimlexbase.c -o build/1_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimlexbase.c -o build/1_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/llstream.c -o build/1_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/llstream.c -o build/1_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimconf.c -o build/1_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimconf.c -o build/1_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/main.c -o build/1_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/main.c -o build/1_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/syntaxes.c -o build/1_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/syntaxes.c -o build/1_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parser.c -o build/1_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parser.c -o build/1_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/pbraces.c -o build/1_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/pbraces.c -o build/1_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/filters.c -o build/1_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/filters.c -o build/1_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/renderer.c -o build/1_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/renderer.c -o build/1_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/filter_tmpl.c -o build/1_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/filter_tmpl.c -o build/1_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rodread.c -o build/1_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rodread.c -o build/1_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/types.c -o build/1_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/types.c -o build/1_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/trees.c -o build/1_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/trees.c -o build/1_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/memfiles.c -o build/1_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/memfiles.c -o build/1_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rodwrite.c -o build/1_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rodwrite.c -o build/1_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/passes.c -o build/1_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/passes.c -o build/1_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/magicsys.c -o build/1_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/magicsys.c -o build/1_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/nimsets.c -o build/1_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/nimsets.c -o build/1_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/bitsets.c -o build/1_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/bitsets.c -o build/1_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semthreads.c -o build/1_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semthreads.c -o build/1_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/importer.c -o build/1_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/importer.c -o build/1_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lookups.c -o build/1_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lookups.c -o build/1_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semdata.c -o build/1_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semdata.c -o build/1_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/treetab.c -o build/1_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/treetab.c -o build/1_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/evals.c -o build/1_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/evals.c -o build/1_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semfold.c -o build/1_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semfold.c -o build/1_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/saturate.c -o build/1_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/saturate.c -o build/1_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/transf.c -o build/1_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/transf.c -o build/1_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/cgmeth.c -o build/1_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/cgmeth.c -o build/1_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sempass2.c -o build/1_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sempass2.c -o build/1_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lambdalifting.c -o build/1_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lambdalifting.c -o build/1_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/evaltempl.c -o build/1_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/evaltempl.c -o build/1_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sem.c -o build/1_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sem.c -o build/1_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/procfind.c -o build/1_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/procfind.c -o build/1_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/pragmas.c -o build/1_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/pragmas.c -o build/1_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/semtypinst.c -o build/1_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/semtypinst.c -o build/1_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/sigmatch.c -o build/1_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/sigmatch.c -o build/1_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parampatterns.c -o build/1_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parampatterns.c -o build/1_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/docgen.c -o build/1_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/docgen.c -o build/1_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rstast.c -o build/1_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rstast.c -o build/1_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rst.c -o build/1_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rst.c -o build/1_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/rstgen.c -o build/1_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/rstgen.c -o build/1_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/highlite.c -o build/1_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/highlite.c -o build/1_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/algorithm.c -o build/1_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/algorithm.c -o build/1_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/aliases.c -o build/1_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/aliases.c -o build/1_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/patterns.c -o build/1_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/patterns.c -o build/1_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/cgen.c -o build/1_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/cgen.c -o build/1_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ccgutils.c -o build/1_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ccgutils.c -o build/1_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/cgendata.c -o build/1_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/cgendata.c -o build/1_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/ccgmerge.c -o build/1_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/ccgmerge.c -o build/1_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/jsgen.c -o build/1_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/jsgen.c -o build/1_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/json.c -o build/1_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/json.c -o build/1_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/lexbase.c -o build/1_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/lexbase.c -o build/1_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/unicode.c -o build/1_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/unicode.c -o build/1_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/passaux.c -o build/1_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/passaux.c -o build/1_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/depends.c -o build/1_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/depends.c -o build/1_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/docgen2.c -o build/1_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/docgen2.c -o build/1_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/service.c -o build/1_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/service.c -o build/1_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/1_1/parseopt.c -o build/1_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/1_1/parseopt.c -o build/1_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_1/nimrod.o \
build/1_1/system.o \
build/1_1/commands.o \
build/1_1/os.o \
build/1_1/strutils.o \
build/1_1/parseutils.o \
build/1_1/times.o \
build/1_1/winlean.o \
build/1_1/msgs.o \
build/1_1/options.o \
build/1_1/lists.o \
build/1_1/strtabs.o \
build/1_1/hashes.o \
build/1_1/tables.o \
build/1_1/math.o \
build/1_1/sockets.o \
build/1_1/ropes.o \
build/1_4/platform.o \
build/1_1/crc.o \
build/1_1/nversion.o \
build/1_1/condsyms.o \
build/1_1/ast.o \
build/1_1/idents.o \
build/1_1/intsets.o \
build/1_1/idgen.o \
build/1_1/astalgo.o \
build/1_1/rodutils.o \
build/1_1/extccomp.o \
build/1_1/osproc.o \
build/1_1/streams.o \
build/1_1/wordrecg.o \
build/1_1/babelcmd.o \
build/1_1/lexer.o \
build/1_1/nimlexbase.o \
build/1_1/llstream.o \
build/1_1/nimconf.o \
build/1_1/main.o \
build/1_1/syntaxes.o \
build/1_1/parser.o \
build/1_1/pbraces.o \
build/1_1/filters.o \
build/1_1/renderer.o \
build/1_1/filter_tmpl.o \
build/1_1/rodread.o \
build/1_1/types.o \
build/1_1/trees.o \
build/1_1/memfiles.o \
build/1_1/rodwrite.o \
build/1_1/passes.o \
build/1_1/magicsys.o \
build/1_1/nimsets.o \
build/1_1/bitsets.o \
build/1_1/semthreads.o \
build/1_1/importer.o \
build/1_1/lookups.o \
build/1_1/semdata.o \
build/1_1/treetab.o \
build/1_1/evals.o \
build/1_1/semfold.o \
build/1_1/saturate.o \
build/1_1/transf.o \
build/1_1/cgmeth.o \
build/1_1/sempass2.o \
build/1_1/lambdalifting.o \
build/1_1/evaltempl.o \
build/1_1/sem.o \
build/1_1/procfind.o \
build/1_1/pragmas.o \
build/1_1/semtypinst.o \
build/1_1/sigmatch.o \
build/1_1/parampatterns.o \
build/1_1/docgen.o \
build/1_1/rstast.o \
build/1_1/rst.o \
build/1_1/rstgen.o \
build/1_1/highlite.o \
build/1_1/algorithm.o \
build/1_1/aliases.o \
build/1_1/patterns.o \
build/1_1/cgen.o \
build/1_1/ccgutils.o \
build/1_1/cgendata.o \
build/1_1/ccgmerge.o \
build/1_1/jsgen.o \
build/1_1/json.o \
build/1_1/lexbase.o \
build/1_1/unicode.o \
build/1_1/passaux.o \
build/1_1/depends.o \
build/1_1/docgen2.o \
build/1_1/service.o \
build/1_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/1_1/nimrod.o \
build/1_1/system.o \
build/1_1/commands.o \
build/1_1/os.o \
build/1_1/strutils.o \
build/1_1/parseutils.o \
build/1_1/times.o \
build/1_1/winlean.o \
build/1_1/msgs.o \
build/1_1/options.o \
build/1_1/lists.o \
build/1_1/strtabs.o \
build/1_1/hashes.o \
build/1_1/tables.o \
build/1_1/math.o \
build/1_1/sockets.o \
build/1_1/ropes.o \
build/1_4/platform.o \
build/1_1/crc.o \
build/1_1/nversion.o \
build/1_1/condsyms.o \
build/1_1/ast.o \
build/1_1/idents.o \
build/1_1/intsets.o \
build/1_1/idgen.o \
build/1_1/astalgo.o \
build/1_1/rodutils.o \
build/1_1/extccomp.o \
build/1_1/osproc.o \
build/1_1/streams.o \
build/1_1/wordrecg.o \
build/1_1/babelcmd.o \
build/1_1/lexer.o \
build/1_1/nimlexbase.o \
build/1_1/llstream.o \
build/1_1/nimconf.o \
build/1_1/main.o \
build/1_1/syntaxes.o \
build/1_1/parser.o \
build/1_1/pbraces.o \
build/1_1/filters.o \
build/1_1/renderer.o \
build/1_1/filter_tmpl.o \
build/1_1/rodread.o \
build/1_1/types.o \
build/1_1/trees.o \
build/1_1/memfiles.o \
build/1_1/rodwrite.o \
build/1_1/passes.o \
build/1_1/magicsys.o \
build/1_1/nimsets.o \
build/1_1/bitsets.o \
build/1_1/semthreads.o \
build/1_1/importer.o \
build/1_1/lookups.o \
build/1_1/semdata.o \
build/1_1/treetab.o \
build/1_1/evals.o \
build/1_1/semfold.o \
build/1_1/saturate.o \
build/1_1/transf.o \
build/1_1/cgmeth.o \
build/1_1/sempass2.o \
build/1_1/lambdalifting.o \
build/1_1/evaltempl.o \
build/1_1/sem.o \
build/1_1/procfind.o \
build/1_1/pragmas.o \
build/1_1/semtypinst.o \
build/1_1/sigmatch.o \
build/1_1/parampatterns.o \
build/1_1/docgen.o \
build/1_1/rstast.o \
build/1_1/rst.o \
build/1_1/rstgen.o \
build/1_1/highlite.o \
build/1_1/algorithm.o \
build/1_1/aliases.o \
build/1_1/patterns.o \
build/1_1/cgen.o \
build/1_1/ccgutils.o \
build/1_1/cgendata.o \
build/1_1/ccgmerge.o \
build/1_1/jsgen.o \
build/1_1/json.o \
build/1_1/lexbase.o \
build/1_1/unicode.o \
build/1_1/passaux.o \
build/1_1/depends.o \
build/1_1/docgen2.o \
build/1_1/service.o \
build/1_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
linux) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nimrod.c -o build/2_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nimrod.c -o build/2_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/system.c -o build/2_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/system.c -o build/2_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/commands.c -o build/2_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/commands.c -o build/2_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/os.c -o build/2_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/os.c -o build/2_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/strutils.c -o build/2_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/strutils.c -o build/2_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseutils.c -o build/2_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseutils.c -o build/2_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/times.c -o build/2_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/times.c -o build/2_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/posix.c -o build/2_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/posix.c -o build/2_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/msgs.c -o build/2_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/msgs.c -o build/2_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/options.c -o build/2_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/options.c -o build/2_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/strtabs.c -o build/2_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/strtabs.c -o build/2_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/tables.c -o build/2_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/tables.c -o build/2_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/sockets.c -o build/2_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/sockets.c -o build/2_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/ropes.c -o build/2_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/ropes.c -o build/2_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/platform.c -o build/2_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/platform.c -o build/2_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/ast.c -o build/2_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/ast.c -o build/2_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idgen.c -o build/2_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idgen.c -o build/2_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/astalgo.c -o build/2_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/astalgo.c -o build/2_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rodutils.c -o build/2_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rodutils.c -o build/2_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/extccomp.c -o build/2_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/extccomp.c -o build/2_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/osproc.c -o build/2_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/osproc.c -o build/2_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/streams.c -o build/2_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/streams.c -o build/2_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/babelcmd.c -o build/2_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/babelcmd.c -o build/2_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexer.c -o build/2_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexer.c -o build/2_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nimlexbase.c -o build/2_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nimlexbase.c -o build/2_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/llstream.c -o build/2_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/llstream.c -o build/2_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nimconf.c -o build/2_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nimconf.c -o build/2_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/main.c -o build/2_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/main.c -o build/2_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/syntaxes.c -o build/2_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/syntaxes.c -o build/2_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parser.c -o build/2_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parser.c -o build/2_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/filters.c -o build/2_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/filters.c -o build/2_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/renderer.c -o build/2_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/renderer.c -o build/2_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/filter_tmpl.c -o build/2_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/filter_tmpl.c -o build/2_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rodread.c -o build/2_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rodread.c -o build/2_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/types.c -o build/2_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/types.c -o build/2_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/memfiles.c -o build/2_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/memfiles.c -o build/2_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rodwrite.c -o build/2_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rodwrite.c -o build/2_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/magicsys.c -o build/2_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/magicsys.c -o build/2_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nimsets.c -o build/2_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nimsets.c -o build/2_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/bitsets.c -o build/2_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/bitsets.c -o build/2_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/semthreads.c -o build/2_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/semthreads.c -o build/2_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/importer.c -o build/2_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/importer.c -o build/2_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lookups.c -o build/2_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lookups.c -o build/2_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/semdata.c -o build/2_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/semdata.c -o build/2_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/evals.c -o build/2_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/evals.c -o build/2_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/semfold.c -o build/2_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/semfold.c -o build/2_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/transf.c -o build/2_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/transf.c -o build/2_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgmeth.c -o build/2_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgmeth.c -o build/2_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/sempass2.c -o build/2_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/sempass2.c -o build/2_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lambdalifting.c -o build/2_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lambdalifting.c -o build/2_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/evaltempl.c -o build/2_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/evaltempl.c -o build/2_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/sem.c -o build/2_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/sem.c -o build/2_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/procfind.c -o build/2_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/procfind.c -o build/2_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pragmas.c -o build/2_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pragmas.c -o build/2_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/semtypinst.c -o build/2_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/semtypinst.c -o build/2_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/sigmatch.c -o build/2_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/sigmatch.c -o build/2_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parampatterns.c -o build/2_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parampatterns.c -o build/2_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/docgen.c -o build/2_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/docgen.c -o build/2_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rstast.c -o build/2_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rstast.c -o build/2_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rst.c -o build/2_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rst.c -o build/2_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rstgen.c -o build/2_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rstgen.c -o build/2_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/highlite.c -o build/2_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/highlite.c -o build/2_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/aliases.c -o build/2_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/aliases.c -o build/2_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/patterns.c -o build/2_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/patterns.c -o build/2_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgen.c -o build/2_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgen.c -o build/2_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/ccgutils.c -o build/2_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/ccgutils.c -o build/2_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/ccgmerge.c -o build/2_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/ccgmerge.c -o build/2_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/jsgen.c -o build/2_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/jsgen.c -o build/2_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/json.c -o build/2_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/json.c -o build/2_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passaux.c -o build/2_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passaux.c -o build/2_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/depends.c -o build/2_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/depends.c -o build/2_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/docgen2.c -o build/2_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/docgen2.c -o build/2_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/service.c -o build/2_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/service.c -o build/2_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_1/nimrod.o \
build/2_1/system.o \
build/2_1/commands.o \
build/2_1/os.o \
build/2_1/strutils.o \
build/2_1/parseutils.o \
build/2_1/times.o \
build/2_1/posix.o \
build/2_1/msgs.o \
build/2_1/options.o \
build/2_1/lists.o \
build/2_1/strtabs.o \
build/2_1/hashes.o \
build/2_1/tables.o \
build/2_1/math.o \
build/2_1/sockets.o \
build/2_1/ropes.o \
build/2_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/2_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/2_1/idgen.o \
build/2_1/astalgo.o \
build/2_1/rodutils.o \
build/2_1/extccomp.o \
build/2_1/osproc.o \
build/2_1/streams.o \
build/2_1/wordrecg.o \
build/2_1/babelcmd.o \
build/2_1/lexer.o \
build/2_1/nimlexbase.o \
build/2_1/llstream.o \
build/2_1/nimconf.o \
build/2_1/main.o \
build/2_1/syntaxes.o \
build/2_1/parser.o \
build/2_1/pbraces.o \
build/2_1/filters.o \
build/2_1/renderer.o \
build/2_1/filter_tmpl.o \
build/2_1/rodread.o \
build/2_1/types.o \
build/2_1/trees.o \
build/2_1/memfiles.o \
build/2_1/rodwrite.o \
build/2_1/passes.o \
build/2_1/magicsys.o \
build/2_1/nimsets.o \
build/2_1/bitsets.o \
build/2_1/semthreads.o \
build/2_1/importer.o \
build/2_1/lookups.o \
build/2_1/semdata.o \
build/2_1/treetab.o \
build/2_1/evals.o \
build/2_1/semfold.o \
build/2_1/saturate.o \
build/2_1/transf.o \
build/2_1/cgmeth.o \
build/2_1/sempass2.o \
build/2_1/lambdalifting.o \
build/2_1/evaltempl.o \
build/2_1/sem.o \
build/2_1/procfind.o \
build/2_1/pragmas.o \
build/2_1/semtypinst.o \
build/2_1/sigmatch.o \
build/2_1/parampatterns.o \
build/2_1/docgen.o \
build/2_1/rstast.o \
build/2_1/rst.o \
build/2_1/rstgen.o \
build/2_1/highlite.o \
build/2_1/algorithm.o \
build/2_1/aliases.o \
build/2_1/patterns.o \
build/2_1/cgen.o \
build/2_1/ccgutils.o \
build/2_1/cgendata.o \
build/2_1/ccgmerge.o \
build/2_1/jsgen.o \
build/2_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/2_1/passaux.o \
build/2_1/depends.o \
build/2_1/docgen2.o \
build/2_1/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_1/nimrod.o \
build/2_1/system.o \
build/2_1/commands.o \
build/2_1/os.o \
build/2_1/strutils.o \
build/2_1/parseutils.o \
build/2_1/times.o \
build/2_1/posix.o \
build/2_1/msgs.o \
build/2_1/options.o \
build/2_1/lists.o \
build/2_1/strtabs.o \
build/2_1/hashes.o \
build/2_1/tables.o \
build/2_1/math.o \
build/2_1/sockets.o \
build/2_1/ropes.o \
build/2_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/2_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/2_1/idgen.o \
build/2_1/astalgo.o \
build/2_1/rodutils.o \
build/2_1/extccomp.o \
build/2_1/osproc.o \
build/2_1/streams.o \
build/2_1/wordrecg.o \
build/2_1/babelcmd.o \
build/2_1/lexer.o \
build/2_1/nimlexbase.o \
build/2_1/llstream.o \
build/2_1/nimconf.o \
build/2_1/main.o \
build/2_1/syntaxes.o \
build/2_1/parser.o \
build/2_1/pbraces.o \
build/2_1/filters.o \
build/2_1/renderer.o \
build/2_1/filter_tmpl.o \
build/2_1/rodread.o \
build/2_1/types.o \
build/2_1/trees.o \
build/2_1/memfiles.o \
build/2_1/rodwrite.o \
build/2_1/passes.o \
build/2_1/magicsys.o \
build/2_1/nimsets.o \
build/2_1/bitsets.o \
build/2_1/semthreads.o \
build/2_1/importer.o \
build/2_1/lookups.o \
build/2_1/semdata.o \
build/2_1/treetab.o \
build/2_1/evals.o \
build/2_1/semfold.o \
build/2_1/saturate.o \
build/2_1/transf.o \
build/2_1/cgmeth.o \
build/2_1/sempass2.o \
build/2_1/lambdalifting.o \
build/2_1/evaltempl.o \
build/2_1/sem.o \
build/2_1/procfind.o \
build/2_1/pragmas.o \
build/2_1/semtypinst.o \
build/2_1/sigmatch.o \
build/2_1/parampatterns.o \
build/2_1/docgen.o \
build/2_1/rstast.o \
build/2_1/rst.o \
build/2_1/rstgen.o \
build/2_1/highlite.o \
build/2_1/algorithm.o \
build/2_1/aliases.o \
build/2_1/patterns.o \
build/2_1/cgen.o \
build/2_1/ccgutils.o \
build/2_1/cgendata.o \
build/2_1/ccgmerge.o \
build/2_1/jsgen.o \
build/2_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/2_1/passaux.o \
build/2_1/depends.o \
build/2_1/docgen2.o \
build/2_1/service.o \
build/2_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nimrod.c -o build/2_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nimrod.c -o build/2_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/system.c -o build/2_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/system.c -o build/2_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/commands.c -o build/2_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/commands.c -o build/2_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/os.c -o build/2_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/os.c -o build/2_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/strutils.c -o build/2_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/strutils.c -o build/2_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseutils.c -o build/2_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseutils.c -o build/2_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/times.c -o build/2_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/times.c -o build/2_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/posix.c -o build/2_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/posix.c -o build/2_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/msgs.c -o build/2_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/msgs.c -o build/2_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/options.c -o build/2_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/options.c -o build/2_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/strtabs.c -o build/2_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/strtabs.c -o build/2_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/tables.c -o build/2_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/tables.c -o build/2_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/sockets.c -o build/2_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/sockets.c -o build/2_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/ropes.c -o build/2_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/ropes.c -o build/2_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/platform.c -o build/2_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/platform.c -o build/2_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/ast.c -o build/2_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/ast.c -o build/2_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idgen.c -o build/2_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idgen.c -o build/2_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/astalgo.c -o build/2_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/astalgo.c -o build/2_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rodutils.c -o build/2_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rodutils.c -o build/2_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/extccomp.c -o build/2_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/extccomp.c -o build/2_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/osproc.c -o build/2_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/osproc.c -o build/2_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/streams.c -o build/2_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/streams.c -o build/2_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/babelcmd.c -o build/2_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/babelcmd.c -o build/2_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexer.c -o build/2_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexer.c -o build/2_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nimlexbase.c -o build/2_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nimlexbase.c -o build/2_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/llstream.c -o build/2_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/llstream.c -o build/2_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nimconf.c -o build/2_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nimconf.c -o build/2_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/main.c -o build/2_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/main.c -o build/2_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/syntaxes.c -o build/2_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/syntaxes.c -o build/2_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parser.c -o build/2_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parser.c -o build/2_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/filters.c -o build/2_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/filters.c -o build/2_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/renderer.c -o build/2_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/renderer.c -o build/2_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/filter_tmpl.c -o build/2_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/filter_tmpl.c -o build/2_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rodread.c -o build/2_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rodread.c -o build/2_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/types.c -o build/2_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/types.c -o build/2_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/memfiles.c -o build/2_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/memfiles.c -o build/2_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rodwrite.c -o build/2_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rodwrite.c -o build/2_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/magicsys.c -o build/2_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/magicsys.c -o build/2_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nimsets.c -o build/2_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nimsets.c -o build/2_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/bitsets.c -o build/2_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/bitsets.c -o build/2_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/semthreads.c -o build/2_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/semthreads.c -o build/2_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/importer.c -o build/2_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/importer.c -o build/2_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lookups.c -o build/2_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lookups.c -o build/2_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/semdata.c -o build/2_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/semdata.c -o build/2_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/evals.c -o build/2_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/evals.c -o build/2_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/semfold.c -o build/2_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/semfold.c -o build/2_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/transf.c -o build/2_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/transf.c -o build/2_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgmeth.c -o build/2_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgmeth.c -o build/2_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/sempass2.c -o build/2_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/sempass2.c -o build/2_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lambdalifting.c -o build/2_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lambdalifting.c -o build/2_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/evaltempl.c -o build/2_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/evaltempl.c -o build/2_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/sem.c -o build/2_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/sem.c -o build/2_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/procfind.c -o build/2_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/procfind.c -o build/2_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pragmas.c -o build/2_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pragmas.c -o build/2_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/semtypinst.c -o build/2_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/semtypinst.c -o build/2_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/sigmatch.c -o build/2_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/sigmatch.c -o build/2_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parampatterns.c -o build/2_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parampatterns.c -o build/2_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/docgen.c -o build/2_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/docgen.c -o build/2_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rstast.c -o build/2_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rstast.c -o build/2_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rst.c -o build/2_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rst.c -o build/2_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rstgen.c -o build/2_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rstgen.c -o build/2_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/highlite.c -o build/2_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/highlite.c -o build/2_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/aliases.c -o build/2_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/aliases.c -o build/2_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/patterns.c -o build/2_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/patterns.c -o build/2_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgen.c -o build/2_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgen.c -o build/2_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/ccgutils.c -o build/2_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/ccgutils.c -o build/2_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/ccgmerge.c -o build/2_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/ccgmerge.c -o build/2_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/jsgen.c -o build/2_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/jsgen.c -o build/2_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/json.c -o build/2_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/json.c -o build/2_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passaux.c -o build/2_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passaux.c -o build/2_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/depends.c -o build/2_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/depends.c -o build/2_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/docgen2.c -o build/2_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/docgen2.c -o build/2_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/service.c -o build/2_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/service.c -o build/2_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_2/nimrod.o \
build/2_2/system.o \
build/2_2/commands.o \
build/2_2/os.o \
build/2_2/strutils.o \
build/2_2/parseutils.o \
build/2_2/times.o \
build/2_2/posix.o \
build/2_2/msgs.o \
build/2_2/options.o \
build/2_2/lists.o \
build/2_2/strtabs.o \
build/2_2/hashes.o \
build/2_2/tables.o \
build/2_2/math.o \
build/2_2/sockets.o \
build/2_2/ropes.o \
build/2_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/2_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/2_2/idgen.o \
build/2_2/astalgo.o \
build/2_2/rodutils.o \
build/2_2/extccomp.o \
build/2_2/osproc.o \
build/2_2/streams.o \
build/2_2/wordrecg.o \
build/2_2/babelcmd.o \
build/2_2/lexer.o \
build/2_2/nimlexbase.o \
build/2_2/llstream.o \
build/2_2/nimconf.o \
build/2_2/main.o \
build/2_2/syntaxes.o \
build/2_2/parser.o \
build/2_2/pbraces.o \
build/2_2/filters.o \
build/2_2/renderer.o \
build/2_2/filter_tmpl.o \
build/2_2/rodread.o \
build/2_2/types.o \
build/2_2/trees.o \
build/2_2/memfiles.o \
build/2_2/rodwrite.o \
build/2_2/passes.o \
build/2_2/magicsys.o \
build/2_2/nimsets.o \
build/2_2/bitsets.o \
build/2_2/semthreads.o \
build/2_2/importer.o \
build/2_2/lookups.o \
build/2_2/semdata.o \
build/2_2/treetab.o \
build/2_2/evals.o \
build/2_2/semfold.o \
build/2_2/saturate.o \
build/2_2/transf.o \
build/2_2/cgmeth.o \
build/2_2/sempass2.o \
build/2_2/lambdalifting.o \
build/2_2/evaltempl.o \
build/2_2/sem.o \
build/2_2/procfind.o \
build/2_2/pragmas.o \
build/2_2/semtypinst.o \
build/2_2/sigmatch.o \
build/2_2/parampatterns.o \
build/2_2/docgen.o \
build/2_2/rstast.o \
build/2_2/rst.o \
build/2_2/rstgen.o \
build/2_2/highlite.o \
build/2_2/algorithm.o \
build/2_2/aliases.o \
build/2_2/patterns.o \
build/2_2/cgen.o \
build/2_2/ccgutils.o \
build/2_2/cgendata.o \
build/2_2/ccgmerge.o \
build/2_2/jsgen.o \
build/2_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/2_2/passaux.o \
build/2_2/depends.o \
build/2_2/docgen2.o \
build/2_2/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_2/nimrod.o \
build/2_2/system.o \
build/2_2/commands.o \
build/2_2/os.o \
build/2_2/strutils.o \
build/2_2/parseutils.o \
build/2_2/times.o \
build/2_2/posix.o \
build/2_2/msgs.o \
build/2_2/options.o \
build/2_2/lists.o \
build/2_2/strtabs.o \
build/2_2/hashes.o \
build/2_2/tables.o \
build/2_2/math.o \
build/2_2/sockets.o \
build/2_2/ropes.o \
build/2_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/2_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/2_2/idgen.o \
build/2_2/astalgo.o \
build/2_2/rodutils.o \
build/2_2/extccomp.o \
build/2_2/osproc.o \
build/2_2/streams.o \
build/2_2/wordrecg.o \
build/2_2/babelcmd.o \
build/2_2/lexer.o \
build/2_2/nimlexbase.o \
build/2_2/llstream.o \
build/2_2/nimconf.o \
build/2_2/main.o \
build/2_2/syntaxes.o \
build/2_2/parser.o \
build/2_2/pbraces.o \
build/2_2/filters.o \
build/2_2/renderer.o \
build/2_2/filter_tmpl.o \
build/2_2/rodread.o \
build/2_2/types.o \
build/2_2/trees.o \
build/2_2/memfiles.o \
build/2_2/rodwrite.o \
build/2_2/passes.o \
build/2_2/magicsys.o \
build/2_2/nimsets.o \
build/2_2/bitsets.o \
build/2_2/semthreads.o \
build/2_2/importer.o \
build/2_2/lookups.o \
build/2_2/semdata.o \
build/2_2/treetab.o \
build/2_2/evals.o \
build/2_2/semfold.o \
build/2_2/saturate.o \
build/2_2/transf.o \
build/2_2/cgmeth.o \
build/2_2/sempass2.o \
build/2_2/lambdalifting.o \
build/2_2/evaltempl.o \
build/2_2/sem.o \
build/2_2/procfind.o \
build/2_2/pragmas.o \
build/2_2/semtypinst.o \
build/2_2/sigmatch.o \
build/2_2/parampatterns.o \
build/2_2/docgen.o \
build/2_2/rstast.o \
build/2_2/rst.o \
build/2_2/rstgen.o \
build/2_2/highlite.o \
build/2_2/algorithm.o \
build/2_2/aliases.o \
build/2_2/patterns.o \
build/2_2/cgen.o \
build/2_2/ccgutils.o \
build/2_2/cgendata.o \
build/2_2/ccgmerge.o \
build/2_2/jsgen.o \
build/2_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/2_2/passaux.o \
build/2_2/depends.o \
build/2_2/docgen2.o \
build/2_2/service.o \
build/2_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/nimrod.c -o build/2_3/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/nimrod.c -o build/2_3/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/system.c -o build/2_3/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/system.c -o build/2_3/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/commands.c -o build/2_3/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/commands.c -o build/2_3/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/os.c -o build/2_3/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/os.c -o build/2_3/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/strutils.c -o build/2_3/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/strutils.c -o build/2_3/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/parseutils.c -o build/2_3/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/parseutils.c -o build/2_3/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/times.c -o build/2_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/times.c -o build/2_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/posix.c -o build/2_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/posix.c -o build/2_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/msgs.c -o build/2_3/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/msgs.c -o build/2_3/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/options.c -o build/2_3/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/options.c -o build/2_3/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/strtabs.c -o build/2_3/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/strtabs.c -o build/2_3/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/tables.c -o build/2_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/tables.c -o build/2_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/sockets.c -o build/2_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/sockets.c -o build/2_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/ropes.c -o build/2_3/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/ropes.c -o build/2_3/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/platform.c -o build/2_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/platform.c -o build/2_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/ast.c -o build/2_3/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/ast.c -o build/2_3/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idgen.c -o build/2_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idgen.c -o build/2_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/astalgo.c -o build/2_3/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/astalgo.c -o build/2_3/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/rodutils.c -o build/2_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/rodutils.c -o build/2_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/extccomp.c -o build/2_3/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/extccomp.c -o build/2_3/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/osproc.c -o build/2_3/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/osproc.c -o build/2_3/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/streams.c -o build/2_3/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/streams.c -o build/2_3/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/babelcmd.c -o build/2_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/babelcmd.c -o build/2_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lexer.c -o build/2_3/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lexer.c -o build/2_3/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nimlexbase.c -o build/2_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nimlexbase.c -o build/2_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/llstream.c -o build/2_3/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/llstream.c -o build/2_3/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/nimconf.c -o build/2_3/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/nimconf.c -o build/2_3/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/main.c -o build/2_3/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/main.c -o build/2_3/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/syntaxes.c -o build/2_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/syntaxes.c -o build/2_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/parser.c -o build/2_3/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/parser.c -o build/2_3/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/filters.c -o build/2_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/filters.c -o build/2_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/renderer.c -o build/2_3/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/renderer.c -o build/2_3/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/filter_tmpl.c -o build/2_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/filter_tmpl.c -o build/2_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/rodread.c -o build/2_3/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/rodread.c -o build/2_3/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/types.c -o build/2_3/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/types.c -o build/2_3/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/memfiles.c -o build/2_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/memfiles.c -o build/2_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/rodwrite.c -o build/2_3/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/rodwrite.c -o build/2_3/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/magicsys.c -o build/2_3/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/magicsys.c -o build/2_3/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/nimsets.c -o build/2_3/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/nimsets.c -o build/2_3/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/bitsets.c -o build/2_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/bitsets.c -o build/2_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/semthreads.c -o build/2_3/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/semthreads.c -o build/2_3/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/importer.c -o build/2_3/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/importer.c -o build/2_3/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lookups.c -o build/2_3/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lookups.c -o build/2_3/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/semdata.c -o build/2_3/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/semdata.c -o build/2_3/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/evals.c -o build/2_3/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/evals.c -o build/2_3/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/semfold.c -o build/2_3/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/semfold.c -o build/2_3/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/transf.c -o build/2_3/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/transf.c -o build/2_3/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgmeth.c -o build/2_3/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgmeth.c -o build/2_3/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/sempass2.c -o build/2_3/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/sempass2.c -o build/2_3/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lambdalifting.c -o build/2_3/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lambdalifting.c -o build/2_3/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/evaltempl.c -o build/2_3/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/evaltempl.c -o build/2_3/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/sem.c -o build/2_3/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/sem.c -o build/2_3/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/procfind.c -o build/2_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/procfind.c -o build/2_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/pragmas.c -o build/2_3/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/pragmas.c -o build/2_3/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/semtypinst.c -o build/2_3/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/semtypinst.c -o build/2_3/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/sigmatch.c -o build/2_3/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/sigmatch.c -o build/2_3/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/parampatterns.c -o build/2_3/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/parampatterns.c -o build/2_3/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/docgen.c -o build/2_3/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/docgen.c -o build/2_3/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/rstast.c -o build/2_3/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/rstast.c -o build/2_3/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/rst.c -o build/2_3/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/rst.c -o build/2_3/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/rstgen.c -o build/2_3/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/rstgen.c -o build/2_3/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/highlite.c -o build/2_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/highlite.c -o build/2_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/aliases.c -o build/2_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/aliases.c -o build/2_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/patterns.c -o build/2_3/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/patterns.c -o build/2_3/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgen.c -o build/2_3/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgen.c -o build/2_3/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/ccgutils.c -o build/2_3/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/ccgutils.c -o build/2_3/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/ccgmerge.c -o build/2_3/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/ccgmerge.c -o build/2_3/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/jsgen.c -o build/2_3/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/jsgen.c -o build/2_3/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/json.c -o build/2_3/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/json.c -o build/2_3/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/passaux.c -o build/2_3/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/passaux.c -o build/2_3/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/depends.c -o build/2_3/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/depends.c -o build/2_3/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/docgen2.c -o build/2_3/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/docgen2.c -o build/2_3/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/service.c -o build/2_3/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/service.c -o build/2_3/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_3/nimrod.o \
build/2_3/system.o \
build/2_3/commands.o \
build/2_3/os.o \
build/2_3/strutils.o \
build/2_3/parseutils.o \
build/2_2/times.o \
build/2_2/posix.o \
build/2_3/msgs.o \
build/2_3/options.o \
build/2_3/lists.o \
build/2_3/strtabs.o \
build/2_2/hashes.o \
build/2_2/tables.o \
build/2_2/math.o \
build/2_3/sockets.o \
build/2_3/ropes.o \
build/2_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/2_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/2_2/idgen.o \
build/2_3/astalgo.o \
build/2_2/rodutils.o \
build/2_3/extccomp.o \
build/2_3/osproc.o \
build/2_3/streams.o \
build/2_2/wordrecg.o \
build/2_2/babelcmd.o \
build/2_3/lexer.o \
build/2_2/nimlexbase.o \
build/2_3/llstream.o \
build/2_3/nimconf.o \
build/2_3/main.o \
build/2_2/syntaxes.o \
build/2_3/parser.o \
build/2_2/pbraces.o \
build/2_2/filters.o \
build/2_3/renderer.o \
build/2_2/filter_tmpl.o \
build/2_3/rodread.o \
build/2_3/types.o \
build/2_3/trees.o \
build/2_2/memfiles.o \
build/2_3/rodwrite.o \
build/2_2/passes.o \
build/2_3/magicsys.o \
build/2_3/nimsets.o \
build/2_2/bitsets.o \
build/2_3/semthreads.o \
build/2_3/importer.o \
build/2_3/lookups.o \
build/2_3/semdata.o \
build/2_3/treetab.o \
build/2_3/evals.o \
build/2_3/semfold.o \
build/2_2/saturate.o \
build/2_3/transf.o \
build/2_3/cgmeth.o \
build/2_3/sempass2.o \
build/2_3/lambdalifting.o \
build/2_3/evaltempl.o \
build/2_3/sem.o \
build/2_2/procfind.o \
build/2_3/pragmas.o \
build/2_3/semtypinst.o \
build/2_3/sigmatch.o \
build/2_3/parampatterns.o \
build/2_3/docgen.o \
build/2_3/rstast.o \
build/2_3/rst.o \
build/2_3/rstgen.o \
build/2_2/highlite.o \
build/2_2/algorithm.o \
build/2_2/aliases.o \
build/2_3/patterns.o \
build/2_3/cgen.o \
build/2_3/ccgutils.o \
build/2_3/cgendata.o \
build/2_3/ccgmerge.o \
build/2_3/jsgen.o \
build/2_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/2_3/passaux.o \
build/2_3/depends.o \
build/2_3/docgen2.o \
build/2_3/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_3/nimrod.o \
build/2_3/system.o \
build/2_3/commands.o \
build/2_3/os.o \
build/2_3/strutils.o \
build/2_3/parseutils.o \
build/2_2/times.o \
build/2_2/posix.o \
build/2_3/msgs.o \
build/2_3/options.o \
build/2_3/lists.o \
build/2_3/strtabs.o \
build/2_2/hashes.o \
build/2_2/tables.o \
build/2_2/math.o \
build/2_3/sockets.o \
build/2_3/ropes.o \
build/2_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/2_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/2_2/idgen.o \
build/2_3/astalgo.o \
build/2_2/rodutils.o \
build/2_3/extccomp.o \
build/2_3/osproc.o \
build/2_3/streams.o \
build/2_2/wordrecg.o \
build/2_2/babelcmd.o \
build/2_3/lexer.o \
build/2_2/nimlexbase.o \
build/2_3/llstream.o \
build/2_3/nimconf.o \
build/2_3/main.o \
build/2_2/syntaxes.o \
build/2_3/parser.o \
build/2_2/pbraces.o \
build/2_2/filters.o \
build/2_3/renderer.o \
build/2_2/filter_tmpl.o \
build/2_3/rodread.o \
build/2_3/types.o \
build/2_3/trees.o \
build/2_2/memfiles.o \
build/2_3/rodwrite.o \
build/2_2/passes.o \
build/2_3/magicsys.o \
build/2_3/nimsets.o \
build/2_2/bitsets.o \
build/2_3/semthreads.o \
build/2_3/importer.o \
build/2_3/lookups.o \
build/2_3/semdata.o \
build/2_3/treetab.o \
build/2_3/evals.o \
build/2_3/semfold.o \
build/2_2/saturate.o \
build/2_3/transf.o \
build/2_3/cgmeth.o \
build/2_3/sempass2.o \
build/2_3/lambdalifting.o \
build/2_3/evaltempl.o \
build/2_3/sem.o \
build/2_2/procfind.o \
build/2_3/pragmas.o \
build/2_3/semtypinst.o \
build/2_3/sigmatch.o \
build/2_3/parampatterns.o \
build/2_3/docgen.o \
build/2_3/rstast.o \
build/2_3/rst.o \
build/2_3/rstgen.o \
build/2_2/highlite.o \
build/2_2/algorithm.o \
build/2_2/aliases.o \
build/2_3/patterns.o \
build/2_3/cgen.o \
build/2_3/ccgutils.o \
build/2_3/cgendata.o \
build/2_3/ccgmerge.o \
build/2_3/jsgen.o \
build/2_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/2_3/passaux.o \
build/2_3/depends.o \
build/2_3/docgen2.o \
build/2_3/service.o \
build/2_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/nimrod.c -o build/2_4/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/nimrod.c -o build/2_4/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/system.c -o build/2_4/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/system.c -o build/2_4/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/commands.c -o build/2_4/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/commands.c -o build/2_4/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/os.c -o build/2_4/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/os.c -o build/2_4/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/strutils.c -o build/2_4/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/strutils.c -o build/2_4/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/parseutils.c -o build/2_4/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/parseutils.c -o build/2_4/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/times.c -o build/2_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/times.c -o build/2_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/posix.c -o build/2_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/posix.c -o build/2_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/msgs.c -o build/2_4/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/msgs.c -o build/2_4/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/options.c -o build/2_4/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/options.c -o build/2_4/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/strtabs.c -o build/2_4/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/strtabs.c -o build/2_4/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/tables.c -o build/2_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/tables.c -o build/2_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/sockets.c -o build/2_4/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/sockets.c -o build/2_4/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/ropes.c -o build/2_4/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/ropes.c -o build/2_4/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/platform.c -o build/2_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/platform.c -o build/2_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/ast.c -o build/2_4/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/ast.c -o build/2_4/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idgen.c -o build/2_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idgen.c -o build/2_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/astalgo.c -o build/2_4/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/astalgo.c -o build/2_4/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/rodutils.c -o build/2_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/rodutils.c -o build/2_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/extccomp.c -o build/2_4/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/extccomp.c -o build/2_4/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/osproc.c -o build/2_4/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/osproc.c -o build/2_4/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/streams.c -o build/2_4/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/streams.c -o build/2_4/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/babelcmd.c -o build/2_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/babelcmd.c -o build/2_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lexer.c -o build/2_4/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lexer.c -o build/2_4/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nimlexbase.c -o build/2_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nimlexbase.c -o build/2_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/llstream.c -o build/2_4/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/llstream.c -o build/2_4/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/nimconf.c -o build/2_4/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/nimconf.c -o build/2_4/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/main.c -o build/2_4/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/main.c -o build/2_4/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/syntaxes.c -o build/2_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/syntaxes.c -o build/2_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/parser.c -o build/2_4/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/parser.c -o build/2_4/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/filters.c -o build/2_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/filters.c -o build/2_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/renderer.c -o build/2_4/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/renderer.c -o build/2_4/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/filter_tmpl.c -o build/2_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/filter_tmpl.c -o build/2_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/rodread.c -o build/2_4/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/rodread.c -o build/2_4/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/types.c -o build/2_4/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/types.c -o build/2_4/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/memfiles.c -o build/2_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/memfiles.c -o build/2_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/rodwrite.c -o build/2_4/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/rodwrite.c -o build/2_4/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/magicsys.c -o build/2_4/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/magicsys.c -o build/2_4/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/nimsets.c -o build/2_4/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/nimsets.c -o build/2_4/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/bitsets.c -o build/2_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/bitsets.c -o build/2_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/semthreads.c -o build/2_4/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/semthreads.c -o build/2_4/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/importer.c -o build/2_4/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/importer.c -o build/2_4/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lookups.c -o build/2_4/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lookups.c -o build/2_4/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/semdata.c -o build/2_4/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/semdata.c -o build/2_4/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/evals.c -o build/2_4/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/evals.c -o build/2_4/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/semfold.c -o build/2_4/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/semfold.c -o build/2_4/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/transf.c -o build/2_4/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/transf.c -o build/2_4/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgmeth.c -o build/2_4/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgmeth.c -o build/2_4/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/sempass2.c -o build/2_4/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/sempass2.c -o build/2_4/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lambdalifting.c -o build/2_4/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lambdalifting.c -o build/2_4/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/evaltempl.c -o build/2_4/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/evaltempl.c -o build/2_4/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/sem.c -o build/2_4/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/sem.c -o build/2_4/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/procfind.c -o build/2_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/procfind.c -o build/2_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/pragmas.c -o build/2_4/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/pragmas.c -o build/2_4/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/semtypinst.c -o build/2_4/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/semtypinst.c -o build/2_4/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/sigmatch.c -o build/2_4/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/sigmatch.c -o build/2_4/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/parampatterns.c -o build/2_4/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/parampatterns.c -o build/2_4/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/docgen.c -o build/2_4/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/docgen.c -o build/2_4/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/rstast.c -o build/2_4/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/rstast.c -o build/2_4/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/rst.c -o build/2_4/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/rst.c -o build/2_4/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/rstgen.c -o build/2_4/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/rstgen.c -o build/2_4/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/highlite.c -o build/2_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/highlite.c -o build/2_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/aliases.c -o build/2_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/aliases.c -o build/2_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/patterns.c -o build/2_4/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/patterns.c -o build/2_4/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgen.c -o build/2_4/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgen.c -o build/2_4/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/ccgutils.c -o build/2_4/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/ccgutils.c -o build/2_4/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/ccgmerge.c -o build/2_4/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/ccgmerge.c -o build/2_4/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/jsgen.c -o build/2_4/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/jsgen.c -o build/2_4/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/json.c -o build/2_4/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/json.c -o build/2_4/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/passaux.c -o build/2_4/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/passaux.c -o build/2_4/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/depends.c -o build/2_4/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/depends.c -o build/2_4/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/docgen2.c -o build/2_4/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/docgen2.c -o build/2_4/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/service.c -o build/2_4/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/service.c -o build/2_4/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_4/nimrod.o \
build/2_4/system.o \
build/2_4/commands.o \
build/2_4/os.o \
build/2_4/strutils.o \
build/2_4/parseutils.o \
build/2_1/times.o \
build/2_1/posix.o \
build/2_4/msgs.o \
build/2_4/options.o \
build/2_4/lists.o \
build/2_4/strtabs.o \
build/2_1/hashes.o \
build/2_1/tables.o \
build/2_1/math.o \
build/2_4/sockets.o \
build/2_4/ropes.o \
build/2_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/2_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/2_1/idgen.o \
build/2_4/astalgo.o \
build/2_1/rodutils.o \
build/2_4/extccomp.o \
build/2_4/osproc.o \
build/2_4/streams.o \
build/2_1/wordrecg.o \
build/2_1/babelcmd.o \
build/2_4/lexer.o \
build/2_1/nimlexbase.o \
build/2_4/llstream.o \
build/2_4/nimconf.o \
build/2_4/main.o \
build/2_1/syntaxes.o \
build/2_4/parser.o \
build/2_1/pbraces.o \
build/2_1/filters.o \
build/2_4/renderer.o \
build/2_1/filter_tmpl.o \
build/2_4/rodread.o \
build/2_4/types.o \
build/2_4/trees.o \
build/2_1/memfiles.o \
build/2_4/rodwrite.o \
build/2_1/passes.o \
build/2_4/magicsys.o \
build/2_4/nimsets.o \
build/2_1/bitsets.o \
build/2_4/semthreads.o \
build/2_4/importer.o \
build/2_4/lookups.o \
build/2_4/semdata.o \
build/2_4/treetab.o \
build/2_4/evals.o \
build/2_4/semfold.o \
build/2_1/saturate.o \
build/2_4/transf.o \
build/2_4/cgmeth.o \
build/2_4/sempass2.o \
build/2_4/lambdalifting.o \
build/2_4/evaltempl.o \
build/2_4/sem.o \
build/2_1/procfind.o \
build/2_4/pragmas.o \
build/2_4/semtypinst.o \
build/2_4/sigmatch.o \
build/2_4/parampatterns.o \
build/2_4/docgen.o \
build/2_4/rstast.o \
build/2_4/rst.o \
build/2_4/rstgen.o \
build/2_1/highlite.o \
build/2_1/algorithm.o \
build/2_1/aliases.o \
build/2_4/patterns.o \
build/2_4/cgen.o \
build/2_4/ccgutils.o \
build/2_4/cgendata.o \
build/2_4/ccgmerge.o \
build/2_4/jsgen.o \
build/2_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/2_4/passaux.o \
build/2_4/depends.o \
build/2_4/docgen2.o \
build/2_4/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/2_4/nimrod.o \
build/2_4/system.o \
build/2_4/commands.o \
build/2_4/os.o \
build/2_4/strutils.o \
build/2_4/parseutils.o \
build/2_1/times.o \
build/2_1/posix.o \
build/2_4/msgs.o \
build/2_4/options.o \
build/2_4/lists.o \
build/2_4/strtabs.o \
build/2_1/hashes.o \
build/2_1/tables.o \
build/2_1/math.o \
build/2_4/sockets.o \
build/2_4/ropes.o \
build/2_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/2_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/2_1/idgen.o \
build/2_4/astalgo.o \
build/2_1/rodutils.o \
build/2_4/extccomp.o \
build/2_4/osproc.o \
build/2_4/streams.o \
build/2_1/wordrecg.o \
build/2_1/babelcmd.o \
build/2_4/lexer.o \
build/2_1/nimlexbase.o \
build/2_4/llstream.o \
build/2_4/nimconf.o \
build/2_4/main.o \
build/2_1/syntaxes.o \
build/2_4/parser.o \
build/2_1/pbraces.o \
build/2_1/filters.o \
build/2_4/renderer.o \
build/2_1/filter_tmpl.o \
build/2_4/rodread.o \
build/2_4/types.o \
build/2_4/trees.o \
build/2_1/memfiles.o \
build/2_4/rodwrite.o \
build/2_1/passes.o \
build/2_4/magicsys.o \
build/2_4/nimsets.o \
build/2_1/bitsets.o \
build/2_4/semthreads.o \
build/2_4/importer.o \
build/2_4/lookups.o \
build/2_4/semdata.o \
build/2_4/treetab.o \
build/2_4/evals.o \
build/2_4/semfold.o \
build/2_1/saturate.o \
build/2_4/transf.o \
build/2_4/cgmeth.o \
build/2_4/sempass2.o \
build/2_4/lambdalifting.o \
build/2_4/evaltempl.o \
build/2_4/sem.o \
build/2_1/procfind.o \
build/2_4/pragmas.o \
build/2_4/semtypinst.o \
build/2_4/sigmatch.o \
build/2_4/parampatterns.o \
build/2_4/docgen.o \
build/2_4/rstast.o \
build/2_4/rst.o \
build/2_4/rstgen.o \
build/2_1/highlite.o \
build/2_1/algorithm.o \
build/2_1/aliases.o \
build/2_4/patterns.o \
build/2_4/cgen.o \
build/2_4/ccgutils.o \
build/2_4/cgendata.o \
build/2_4/ccgmerge.o \
build/2_4/jsgen.o \
build/2_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/2_4/passaux.o \
build/2_4/depends.o \
build/2_4/docgen2.o \
build/2_4/service.o \
build/2_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
macosx) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/nimrod.c -o build/3_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/nimrod.c -o build/3_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/system.c -o build/3_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/system.c -o build/3_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/commands.c -o build/3_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/commands.c -o build/3_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/os.c -o build/3_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/os.c -o build/3_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/strutils.c -o build/3_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/strutils.c -o build/3_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/parseutils.c -o build/3_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/parseutils.c -o build/3_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/times.c -o build/3_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/times.c -o build/3_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/msgs.c -o build/3_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/msgs.c -o build/3_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/options.c -o build/3_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/options.c -o build/3_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/strtabs.c -o build/3_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/strtabs.c -o build/3_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/tables.c -o build/3_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/tables.c -o build/3_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/sockets.c -o build/3_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/sockets.c -o build/3_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/ropes.c -o build/3_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/ropes.c -o build/3_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/platform.c -o build/3_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/platform.c -o build/3_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/ast.c -o build/3_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/ast.c -o build/3_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/idgen.c -o build/3_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/idgen.c -o build/3_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/astalgo.c -o build/3_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/astalgo.c -o build/3_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rodutils.c -o build/3_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rodutils.c -o build/3_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/extccomp.c -o build/3_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/extccomp.c -o build/3_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/osproc.c -o build/3_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/osproc.c -o build/3_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/streams.c -o build/3_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/streams.c -o build/3_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/babelcmd.c -o build/3_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/babelcmd.c -o build/3_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/lexer.c -o build/3_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/lexer.c -o build/3_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/nimlexbase.c -o build/3_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/nimlexbase.c -o build/3_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/llstream.c -o build/3_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/llstream.c -o build/3_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/nimconf.c -o build/3_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/nimconf.c -o build/3_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/main.c -o build/3_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/main.c -o build/3_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/syntaxes.c -o build/3_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/syntaxes.c -o build/3_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/parser.c -o build/3_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/parser.c -o build/3_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/filters.c -o build/3_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/filters.c -o build/3_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/renderer.c -o build/3_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/renderer.c -o build/3_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/filter_tmpl.c -o build/3_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/filter_tmpl.c -o build/3_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rodread.c -o build/3_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rodread.c -o build/3_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/types.c -o build/3_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/types.c -o build/3_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/memfiles.c -o build/3_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/memfiles.c -o build/3_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rodwrite.c -o build/3_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rodwrite.c -o build/3_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/magicsys.c -o build/3_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/magicsys.c -o build/3_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/nimsets.c -o build/3_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/nimsets.c -o build/3_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/bitsets.c -o build/3_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/bitsets.c -o build/3_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/semthreads.c -o build/3_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/semthreads.c -o build/3_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/importer.c -o build/3_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/importer.c -o build/3_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/lookups.c -o build/3_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/lookups.c -o build/3_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/semdata.c -o build/3_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/semdata.c -o build/3_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/evals.c -o build/3_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/evals.c -o build/3_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/semfold.c -o build/3_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/semfold.c -o build/3_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/transf.c -o build/3_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/transf.c -o build/3_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/cgmeth.c -o build/3_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/cgmeth.c -o build/3_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/sempass2.c -o build/3_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/sempass2.c -o build/3_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/lambdalifting.c -o build/3_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/lambdalifting.c -o build/3_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/evaltempl.c -o build/3_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/evaltempl.c -o build/3_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/sem.c -o build/3_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/sem.c -o build/3_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/procfind.c -o build/3_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/procfind.c -o build/3_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/pragmas.c -o build/3_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/pragmas.c -o build/3_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/semtypinst.c -o build/3_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/semtypinst.c -o build/3_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/sigmatch.c -o build/3_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/sigmatch.c -o build/3_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/parampatterns.c -o build/3_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/parampatterns.c -o build/3_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/docgen.c -o build/3_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/docgen.c -o build/3_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rstast.c -o build/3_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rstast.c -o build/3_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rst.c -o build/3_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rst.c -o build/3_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rstgen.c -o build/3_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rstgen.c -o build/3_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/highlite.c -o build/3_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/highlite.c -o build/3_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/aliases.c -o build/3_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/aliases.c -o build/3_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/patterns.c -o build/3_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/patterns.c -o build/3_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/cgen.c -o build/3_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/cgen.c -o build/3_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/ccgutils.c -o build/3_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/ccgutils.c -o build/3_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/ccgmerge.c -o build/3_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/ccgmerge.c -o build/3_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/jsgen.c -o build/3_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/jsgen.c -o build/3_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/json.c -o build/3_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/json.c -o build/3_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/passaux.c -o build/3_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/passaux.c -o build/3_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/depends.c -o build/3_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/depends.c -o build/3_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/docgen2.c -o build/3_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/docgen2.c -o build/3_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/service.c -o build/3_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/service.c -o build/3_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_1/nimrod.o \
build/3_1/system.o \
build/3_1/commands.o \
build/3_1/os.o \
build/3_1/strutils.o \
build/3_1/parseutils.o \
build/3_1/times.o \
build/3_1/posix.o \
build/3_1/msgs.o \
build/3_1/options.o \
build/2_1/lists.o \
build/3_1/strtabs.o \
build/2_1/hashes.o \
build/3_1/tables.o \
build/2_1/math.o \
build/3_1/sockets.o \
build/3_1/ropes.o \
build/3_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/3_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/3_1/idgen.o \
build/3_1/astalgo.o \
build/3_1/rodutils.o \
build/3_1/extccomp.o \
build/3_1/osproc.o \
build/3_1/streams.o \
build/2_1/wordrecg.o \
build/3_1/babelcmd.o \
build/3_1/lexer.o \
build/3_1/nimlexbase.o \
build/3_1/llstream.o \
build/3_1/nimconf.o \
build/3_1/main.o \
build/3_1/syntaxes.o \
build/3_1/parser.o \
build/2_1/pbraces.o \
build/3_1/filters.o \
build/3_1/renderer.o \
build/3_1/filter_tmpl.o \
build/3_1/rodread.o \
build/3_1/types.o \
build/2_1/trees.o \
build/3_1/memfiles.o \
build/3_1/rodwrite.o \
build/2_1/passes.o \
build/3_1/magicsys.o \
build/3_1/nimsets.o \
build/3_1/bitsets.o \
build/3_1/semthreads.o \
build/3_1/importer.o \
build/3_1/lookups.o \
build/3_1/semdata.o \
build/2_1/treetab.o \
build/3_1/evals.o \
build/3_1/semfold.o \
build/2_1/saturate.o \
build/3_1/transf.o \
build/3_1/cgmeth.o \
build/3_1/sempass2.o \
build/3_1/lambdalifting.o \
build/3_1/evaltempl.o \
build/3_1/sem.o \
build/3_1/procfind.o \
build/3_1/pragmas.o \
build/3_1/semtypinst.o \
build/3_1/sigmatch.o \
build/3_1/parampatterns.o \
build/3_1/docgen.o \
build/3_1/rstast.o \
build/3_1/rst.o \
build/3_1/rstgen.o \
build/3_1/highlite.o \
build/2_1/algorithm.o \
build/3_1/aliases.o \
build/3_1/patterns.o \
build/3_1/cgen.o \
build/3_1/ccgutils.o \
build/2_1/cgendata.o \
build/3_1/ccgmerge.o \
build/3_1/jsgen.o \
build/3_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/3_1/passaux.o \
build/3_1/depends.o \
build/3_1/docgen2.o \
build/3_1/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_1/nimrod.o \
build/3_1/system.o \
build/3_1/commands.o \
build/3_1/os.o \
build/3_1/strutils.o \
build/3_1/parseutils.o \
build/3_1/times.o \
build/3_1/posix.o \
build/3_1/msgs.o \
build/3_1/options.o \
build/2_1/lists.o \
build/3_1/strtabs.o \
build/2_1/hashes.o \
build/3_1/tables.o \
build/2_1/math.o \
build/3_1/sockets.o \
build/3_1/ropes.o \
build/3_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/3_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/3_1/idgen.o \
build/3_1/astalgo.o \
build/3_1/rodutils.o \
build/3_1/extccomp.o \
build/3_1/osproc.o \
build/3_1/streams.o \
build/2_1/wordrecg.o \
build/3_1/babelcmd.o \
build/3_1/lexer.o \
build/3_1/nimlexbase.o \
build/3_1/llstream.o \
build/3_1/nimconf.o \
build/3_1/main.o \
build/3_1/syntaxes.o \
build/3_1/parser.o \
build/2_1/pbraces.o \
build/3_1/filters.o \
build/3_1/renderer.o \
build/3_1/filter_tmpl.o \
build/3_1/rodread.o \
build/3_1/types.o \
build/2_1/trees.o \
build/3_1/memfiles.o \
build/3_1/rodwrite.o \
build/2_1/passes.o \
build/3_1/magicsys.o \
build/3_1/nimsets.o \
build/3_1/bitsets.o \
build/3_1/semthreads.o \
build/3_1/importer.o \
build/3_1/lookups.o \
build/3_1/semdata.o \
build/2_1/treetab.o \
build/3_1/evals.o \
build/3_1/semfold.o \
build/2_1/saturate.o \
build/3_1/transf.o \
build/3_1/cgmeth.o \
build/3_1/sempass2.o \
build/3_1/lambdalifting.o \
build/3_1/evaltempl.o \
build/3_1/sem.o \
build/3_1/procfind.o \
build/3_1/pragmas.o \
build/3_1/semtypinst.o \
build/3_1/sigmatch.o \
build/3_1/parampatterns.o \
build/3_1/docgen.o \
build/3_1/rstast.o \
build/3_1/rst.o \
build/3_1/rstgen.o \
build/3_1/highlite.o \
build/2_1/algorithm.o \
build/3_1/aliases.o \
build/3_1/patterns.o \
build/3_1/cgen.o \
build/3_1/ccgutils.o \
build/2_1/cgendata.o \
build/3_1/ccgmerge.o \
build/3_1/jsgen.o \
build/3_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/3_1/passaux.o \
build/3_1/depends.o \
build/3_1/docgen2.o \
build/3_1/service.o \
build/2_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/nimrod.c -o build/3_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/nimrod.c -o build/3_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/system.c -o build/3_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/system.c -o build/3_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/commands.c -o build/3_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/commands.c -o build/3_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/os.c -o build/3_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/os.c -o build/3_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/strutils.c -o build/3_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/strutils.c -o build/3_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/parseutils.c -o build/3_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/parseutils.c -o build/3_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/times.c -o build/3_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/times.c -o build/3_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/msgs.c -o build/3_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/msgs.c -o build/3_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/options.c -o build/3_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/options.c -o build/3_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/strtabs.c -o build/3_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/strtabs.c -o build/3_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/tables.c -o build/3_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/tables.c -o build/3_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/sockets.c -o build/3_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/sockets.c -o build/3_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/ropes.c -o build/3_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/ropes.c -o build/3_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/platform.c -o build/3_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/platform.c -o build/3_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/ast.c -o build/3_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/ast.c -o build/3_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/idgen.c -o build/3_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/idgen.c -o build/3_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/astalgo.c -o build/3_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/astalgo.c -o build/3_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rodutils.c -o build/3_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rodutils.c -o build/3_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/extccomp.c -o build/3_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/extccomp.c -o build/3_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/osproc.c -o build/3_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/osproc.c -o build/3_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/streams.c -o build/3_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/streams.c -o build/3_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/babelcmd.c -o build/3_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/babelcmd.c -o build/3_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/lexer.c -o build/3_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/lexer.c -o build/3_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/nimlexbase.c -o build/3_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/nimlexbase.c -o build/3_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/llstream.c -o build/3_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/llstream.c -o build/3_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/nimconf.c -o build/3_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/nimconf.c -o build/3_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/main.c -o build/3_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/main.c -o build/3_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/syntaxes.c -o build/3_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/syntaxes.c -o build/3_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/parser.c -o build/3_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/parser.c -o build/3_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/filters.c -o build/3_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/filters.c -o build/3_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/renderer.c -o build/3_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/renderer.c -o build/3_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/filter_tmpl.c -o build/3_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/filter_tmpl.c -o build/3_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rodread.c -o build/3_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rodread.c -o build/3_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/types.c -o build/3_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/types.c -o build/3_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/memfiles.c -o build/3_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/memfiles.c -o build/3_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rodwrite.c -o build/3_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rodwrite.c -o build/3_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/magicsys.c -o build/3_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/magicsys.c -o build/3_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/nimsets.c -o build/3_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/nimsets.c -o build/3_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/bitsets.c -o build/3_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/bitsets.c -o build/3_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/semthreads.c -o build/3_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/semthreads.c -o build/3_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/importer.c -o build/3_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/importer.c -o build/3_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/lookups.c -o build/3_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/lookups.c -o build/3_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/semdata.c -o build/3_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/semdata.c -o build/3_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/evals.c -o build/3_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/evals.c -o build/3_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/semfold.c -o build/3_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/semfold.c -o build/3_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/transf.c -o build/3_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/transf.c -o build/3_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/cgmeth.c -o build/3_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/cgmeth.c -o build/3_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/sempass2.c -o build/3_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/sempass2.c -o build/3_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/lambdalifting.c -o build/3_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/lambdalifting.c -o build/3_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/evaltempl.c -o build/3_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/evaltempl.c -o build/3_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/sem.c -o build/3_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/sem.c -o build/3_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/procfind.c -o build/3_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/procfind.c -o build/3_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/pragmas.c -o build/3_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/pragmas.c -o build/3_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/semtypinst.c -o build/3_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/semtypinst.c -o build/3_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/sigmatch.c -o build/3_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/sigmatch.c -o build/3_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/parampatterns.c -o build/3_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/parampatterns.c -o build/3_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/docgen.c -o build/3_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/docgen.c -o build/3_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rstast.c -o build/3_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rstast.c -o build/3_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rst.c -o build/3_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rst.c -o build/3_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rstgen.c -o build/3_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rstgen.c -o build/3_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/highlite.c -o build/3_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/highlite.c -o build/3_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/aliases.c -o build/3_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/aliases.c -o build/3_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/patterns.c -o build/3_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/patterns.c -o build/3_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/cgen.c -o build/3_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/cgen.c -o build/3_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/ccgutils.c -o build/3_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/ccgutils.c -o build/3_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/ccgmerge.c -o build/3_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/ccgmerge.c -o build/3_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/jsgen.c -o build/3_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/jsgen.c -o build/3_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/json.c -o build/3_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/json.c -o build/3_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/passaux.c -o build/3_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/passaux.c -o build/3_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/depends.c -o build/3_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/depends.c -o build/3_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/docgen2.c -o build/3_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/docgen2.c -o build/3_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/service.c -o build/3_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/service.c -o build/3_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_2/nimrod.o \
build/3_2/system.o \
build/3_2/commands.o \
build/3_2/os.o \
build/3_2/strutils.o \
build/3_2/parseutils.o \
build/3_2/times.o \
build/3_2/posix.o \
build/3_2/msgs.o \
build/3_2/options.o \
build/2_2/lists.o \
build/3_2/strtabs.o \
build/2_2/hashes.o \
build/3_2/tables.o \
build/2_2/math.o \
build/3_2/sockets.o \
build/3_2/ropes.o \
build/3_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/3_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/3_2/idgen.o \
build/3_2/astalgo.o \
build/3_2/rodutils.o \
build/3_2/extccomp.o \
build/3_2/osproc.o \
build/3_2/streams.o \
build/2_2/wordrecg.o \
build/3_2/babelcmd.o \
build/3_2/lexer.o \
build/3_2/nimlexbase.o \
build/3_2/llstream.o \
build/3_2/nimconf.o \
build/3_2/main.o \
build/3_2/syntaxes.o \
build/3_2/parser.o \
build/2_2/pbraces.o \
build/3_2/filters.o \
build/3_2/renderer.o \
build/3_2/filter_tmpl.o \
build/3_2/rodread.o \
build/3_2/types.o \
build/2_2/trees.o \
build/3_2/memfiles.o \
build/3_2/rodwrite.o \
build/2_2/passes.o \
build/3_2/magicsys.o \
build/3_2/nimsets.o \
build/3_2/bitsets.o \
build/3_2/semthreads.o \
build/3_2/importer.o \
build/3_2/lookups.o \
build/3_2/semdata.o \
build/2_2/treetab.o \
build/3_2/evals.o \
build/3_2/semfold.o \
build/2_2/saturate.o \
build/3_2/transf.o \
build/3_2/cgmeth.o \
build/3_2/sempass2.o \
build/3_2/lambdalifting.o \
build/3_2/evaltempl.o \
build/3_2/sem.o \
build/3_2/procfind.o \
build/3_2/pragmas.o \
build/3_2/semtypinst.o \
build/3_2/sigmatch.o \
build/3_2/parampatterns.o \
build/3_2/docgen.o \
build/3_2/rstast.o \
build/3_2/rst.o \
build/3_2/rstgen.o \
build/3_2/highlite.o \
build/2_2/algorithm.o \
build/3_2/aliases.o \
build/3_2/patterns.o \
build/3_2/cgen.o \
build/3_2/ccgutils.o \
build/2_2/cgendata.o \
build/3_2/ccgmerge.o \
build/3_2/jsgen.o \
build/3_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/3_2/passaux.o \
build/3_2/depends.o \
build/3_2/docgen2.o \
build/3_2/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_2/nimrod.o \
build/3_2/system.o \
build/3_2/commands.o \
build/3_2/os.o \
build/3_2/strutils.o \
build/3_2/parseutils.o \
build/3_2/times.o \
build/3_2/posix.o \
build/3_2/msgs.o \
build/3_2/options.o \
build/2_2/lists.o \
build/3_2/strtabs.o \
build/2_2/hashes.o \
build/3_2/tables.o \
build/2_2/math.o \
build/3_2/sockets.o \
build/3_2/ropes.o \
build/3_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/3_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/3_2/idgen.o \
build/3_2/astalgo.o \
build/3_2/rodutils.o \
build/3_2/extccomp.o \
build/3_2/osproc.o \
build/3_2/streams.o \
build/2_2/wordrecg.o \
build/3_2/babelcmd.o \
build/3_2/lexer.o \
build/3_2/nimlexbase.o \
build/3_2/llstream.o \
build/3_2/nimconf.o \
build/3_2/main.o \
build/3_2/syntaxes.o \
build/3_2/parser.o \
build/2_2/pbraces.o \
build/3_2/filters.o \
build/3_2/renderer.o \
build/3_2/filter_tmpl.o \
build/3_2/rodread.o \
build/3_2/types.o \
build/2_2/trees.o \
build/3_2/memfiles.o \
build/3_2/rodwrite.o \
build/2_2/passes.o \
build/3_2/magicsys.o \
build/3_2/nimsets.o \
build/3_2/bitsets.o \
build/3_2/semthreads.o \
build/3_2/importer.o \
build/3_2/lookups.o \
build/3_2/semdata.o \
build/2_2/treetab.o \
build/3_2/evals.o \
build/3_2/semfold.o \
build/2_2/saturate.o \
build/3_2/transf.o \
build/3_2/cgmeth.o \
build/3_2/sempass2.o \
build/3_2/lambdalifting.o \
build/3_2/evaltempl.o \
build/3_2/sem.o \
build/3_2/procfind.o \
build/3_2/pragmas.o \
build/3_2/semtypinst.o \
build/3_2/sigmatch.o \
build/3_2/parampatterns.o \
build/3_2/docgen.o \
build/3_2/rstast.o \
build/3_2/rst.o \
build/3_2/rstgen.o \
build/3_2/highlite.o \
build/2_2/algorithm.o \
build/3_2/aliases.o \
build/3_2/patterns.o \
build/3_2/cgen.o \
build/3_2/ccgutils.o \
build/2_2/cgendata.o \
build/3_2/ccgmerge.o \
build/3_2/jsgen.o \
build/3_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/3_2/passaux.o \
build/3_2/depends.o \
build/3_2/docgen2.o \
build/3_2/service.o \
build/2_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/nimrod.c -o build/3_3/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/nimrod.c -o build/3_3/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/system.c -o build/3_3/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/system.c -o build/3_3/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/commands.c -o build/3_3/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/commands.c -o build/3_3/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/os.c -o build/3_3/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/os.c -o build/3_3/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/strutils.c -o build/3_3/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/strutils.c -o build/3_3/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/parseutils.c -o build/3_3/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/parseutils.c -o build/3_3/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/times.c -o build/3_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/times.c -o build/3_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/msgs.c -o build/3_3/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/msgs.c -o build/3_3/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/options.c -o build/3_3/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/options.c -o build/3_3/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/strtabs.c -o build/3_3/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/strtabs.c -o build/3_3/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/tables.c -o build/3_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/tables.c -o build/3_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/sockets.c -o build/3_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/sockets.c -o build/3_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/ropes.c -o build/3_3/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/ropes.c -o build/3_3/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/platform.c -o build/3_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/platform.c -o build/3_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/ast.c -o build/3_3/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/ast.c -o build/3_3/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/idgen.c -o build/3_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/idgen.c -o build/3_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/astalgo.c -o build/3_3/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/astalgo.c -o build/3_3/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/rodutils.c -o build/3_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/rodutils.c -o build/3_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/extccomp.c -o build/3_3/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/extccomp.c -o build/3_3/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/osproc.c -o build/3_3/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/osproc.c -o build/3_3/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/streams.c -o build/3_3/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/streams.c -o build/3_3/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/babelcmd.c -o build/3_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/babelcmd.c -o build/3_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/lexer.c -o build/3_3/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/lexer.c -o build/3_3/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/nimlexbase.c -o build/3_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/nimlexbase.c -o build/3_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/llstream.c -o build/3_3/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/llstream.c -o build/3_3/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/nimconf.c -o build/3_3/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/nimconf.c -o build/3_3/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/main.c -o build/3_3/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/main.c -o build/3_3/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/syntaxes.c -o build/3_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/syntaxes.c -o build/3_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/parser.c -o build/3_3/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/parser.c -o build/3_3/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/filters.c -o build/3_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/filters.c -o build/3_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/renderer.c -o build/3_3/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/renderer.c -o build/3_3/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/filter_tmpl.c -o build/3_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/filter_tmpl.c -o build/3_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/rodread.c -o build/3_3/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/rodread.c -o build/3_3/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/types.c -o build/3_3/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/types.c -o build/3_3/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/memfiles.c -o build/3_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/memfiles.c -o build/3_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/rodwrite.c -o build/3_3/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/rodwrite.c -o build/3_3/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/magicsys.c -o build/3_3/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/magicsys.c -o build/3_3/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/nimsets.c -o build/3_3/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/nimsets.c -o build/3_3/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/bitsets.c -o build/3_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/bitsets.c -o build/3_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/semthreads.c -o build/3_3/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/semthreads.c -o build/3_3/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/importer.c -o build/3_3/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/importer.c -o build/3_3/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/lookups.c -o build/3_3/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/lookups.c -o build/3_3/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/semdata.c -o build/3_3/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/semdata.c -o build/3_3/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/evals.c -o build/3_3/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/evals.c -o build/3_3/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/semfold.c -o build/3_3/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/semfold.c -o build/3_3/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/transf.c -o build/3_3/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/transf.c -o build/3_3/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/cgmeth.c -o build/3_3/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/cgmeth.c -o build/3_3/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/sempass2.c -o build/3_3/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/sempass2.c -o build/3_3/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/lambdalifting.c -o build/3_3/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/lambdalifting.c -o build/3_3/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/evaltempl.c -o build/3_3/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/evaltempl.c -o build/3_3/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/sem.c -o build/3_3/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/sem.c -o build/3_3/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/procfind.c -o build/3_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/procfind.c -o build/3_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/pragmas.c -o build/3_3/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/pragmas.c -o build/3_3/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/semtypinst.c -o build/3_3/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/semtypinst.c -o build/3_3/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/sigmatch.c -o build/3_3/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/sigmatch.c -o build/3_3/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/parampatterns.c -o build/3_3/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/parampatterns.c -o build/3_3/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/docgen.c -o build/3_3/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/docgen.c -o build/3_3/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/rstast.c -o build/3_3/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/rstast.c -o build/3_3/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/rst.c -o build/3_3/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/rst.c -o build/3_3/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/rstgen.c -o build/3_3/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/rstgen.c -o build/3_3/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/highlite.c -o build/3_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/highlite.c -o build/3_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/aliases.c -o build/3_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/aliases.c -o build/3_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/patterns.c -o build/3_3/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/patterns.c -o build/3_3/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/cgen.c -o build/3_3/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/cgen.c -o build/3_3/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/ccgutils.c -o build/3_3/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/ccgutils.c -o build/3_3/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/ccgmerge.c -o build/3_3/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/ccgmerge.c -o build/3_3/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/jsgen.c -o build/3_3/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/jsgen.c -o build/3_3/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/json.c -o build/3_3/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/json.c -o build/3_3/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/passaux.c -o build/3_3/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/passaux.c -o build/3_3/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/depends.c -o build/3_3/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/depends.c -o build/3_3/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/docgen2.c -o build/3_3/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/docgen2.c -o build/3_3/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_3/service.c -o build/3_3/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_3/service.c -o build/3_3/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_3/nimrod.o \
build/3_3/system.o \
build/3_3/commands.o \
build/3_3/os.o \
build/3_3/strutils.o \
build/3_3/parseutils.o \
build/3_2/times.o \
build/3_2/posix.o \
build/3_3/msgs.o \
build/3_3/options.o \
build/2_3/lists.o \
build/3_3/strtabs.o \
build/2_2/hashes.o \
build/3_2/tables.o \
build/2_2/math.o \
build/3_3/sockets.o \
build/3_3/ropes.o \
build/3_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/3_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/3_2/idgen.o \
build/3_3/astalgo.o \
build/3_2/rodutils.o \
build/3_3/extccomp.o \
build/3_3/osproc.o \
build/3_3/streams.o \
build/2_2/wordrecg.o \
build/3_2/babelcmd.o \
build/3_3/lexer.o \
build/3_2/nimlexbase.o \
build/3_3/llstream.o \
build/3_3/nimconf.o \
build/3_3/main.o \
build/3_2/syntaxes.o \
build/3_3/parser.o \
build/2_2/pbraces.o \
build/3_2/filters.o \
build/3_3/renderer.o \
build/3_2/filter_tmpl.o \
build/3_3/rodread.o \
build/3_3/types.o \
build/2_3/trees.o \
build/3_2/memfiles.o \
build/3_3/rodwrite.o \
build/2_2/passes.o \
build/3_3/magicsys.o \
build/3_3/nimsets.o \
build/3_2/bitsets.o \
build/3_3/semthreads.o \
build/3_3/importer.o \
build/3_3/lookups.o \
build/3_3/semdata.o \
build/2_3/treetab.o \
build/3_3/evals.o \
build/3_3/semfold.o \
build/2_2/saturate.o \
build/3_3/transf.o \
build/3_3/cgmeth.o \
build/3_3/sempass2.o \
build/3_3/lambdalifting.o \
build/3_3/evaltempl.o \
build/3_3/sem.o \
build/3_2/procfind.o \
build/3_3/pragmas.o \
build/3_3/semtypinst.o \
build/3_3/sigmatch.o \
build/3_3/parampatterns.o \
build/3_3/docgen.o \
build/3_3/rstast.o \
build/3_3/rst.o \
build/3_3/rstgen.o \
build/3_2/highlite.o \
build/2_2/algorithm.o \
build/3_2/aliases.o \
build/3_3/patterns.o \
build/3_3/cgen.o \
build/3_3/ccgutils.o \
build/2_3/cgendata.o \
build/3_3/ccgmerge.o \
build/3_3/jsgen.o \
build/3_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/3_3/passaux.o \
build/3_3/depends.o \
build/3_3/docgen2.o \
build/3_3/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_3/nimrod.o \
build/3_3/system.o \
build/3_3/commands.o \
build/3_3/os.o \
build/3_3/strutils.o \
build/3_3/parseutils.o \
build/3_2/times.o \
build/3_2/posix.o \
build/3_3/msgs.o \
build/3_3/options.o \
build/2_3/lists.o \
build/3_3/strtabs.o \
build/2_2/hashes.o \
build/3_2/tables.o \
build/2_2/math.o \
build/3_3/sockets.o \
build/3_3/ropes.o \
build/3_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/3_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/3_2/idgen.o \
build/3_3/astalgo.o \
build/3_2/rodutils.o \
build/3_3/extccomp.o \
build/3_3/osproc.o \
build/3_3/streams.o \
build/2_2/wordrecg.o \
build/3_2/babelcmd.o \
build/3_3/lexer.o \
build/3_2/nimlexbase.o \
build/3_3/llstream.o \
build/3_3/nimconf.o \
build/3_3/main.o \
build/3_2/syntaxes.o \
build/3_3/parser.o \
build/2_2/pbraces.o \
build/3_2/filters.o \
build/3_3/renderer.o \
build/3_2/filter_tmpl.o \
build/3_3/rodread.o \
build/3_3/types.o \
build/2_3/trees.o \
build/3_2/memfiles.o \
build/3_3/rodwrite.o \
build/2_2/passes.o \
build/3_3/magicsys.o \
build/3_3/nimsets.o \
build/3_2/bitsets.o \
build/3_3/semthreads.o \
build/3_3/importer.o \
build/3_3/lookups.o \
build/3_3/semdata.o \
build/2_3/treetab.o \
build/3_3/evals.o \
build/3_3/semfold.o \
build/2_2/saturate.o \
build/3_3/transf.o \
build/3_3/cgmeth.o \
build/3_3/sempass2.o \
build/3_3/lambdalifting.o \
build/3_3/evaltempl.o \
build/3_3/sem.o \
build/3_2/procfind.o \
build/3_3/pragmas.o \
build/3_3/semtypinst.o \
build/3_3/sigmatch.o \
build/3_3/parampatterns.o \
build/3_3/docgen.o \
build/3_3/rstast.o \
build/3_3/rst.o \
build/3_3/rstgen.o \
build/3_2/highlite.o \
build/2_2/algorithm.o \
build/3_2/aliases.o \
build/3_3/patterns.o \
build/3_3/cgen.o \
build/3_3/ccgutils.o \
build/2_3/cgendata.o \
build/3_3/ccgmerge.o \
build/3_3/jsgen.o \
build/3_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/3_3/passaux.o \
build/3_3/depends.o \
build/3_3/docgen2.o \
build/3_3/service.o \
build/2_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/nimrod.c -o build/3_4/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/nimrod.c -o build/3_4/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/system.c -o build/3_4/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/system.c -o build/3_4/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/commands.c -o build/3_4/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/commands.c -o build/3_4/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/os.c -o build/3_4/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/os.c -o build/3_4/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/strutils.c -o build/3_4/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/strutils.c -o build/3_4/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/parseutils.c -o build/3_4/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/parseutils.c -o build/3_4/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/times.c -o build/3_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/times.c -o build/3_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/msgs.c -o build/3_4/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/msgs.c -o build/3_4/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/options.c -o build/3_4/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/options.c -o build/3_4/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/strtabs.c -o build/3_4/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/strtabs.c -o build/3_4/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/tables.c -o build/3_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/tables.c -o build/3_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/sockets.c -o build/3_4/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/sockets.c -o build/3_4/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/ropes.c -o build/3_4/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/ropes.c -o build/3_4/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/platform.c -o build/3_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/platform.c -o build/3_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/ast.c -o build/3_4/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/ast.c -o build/3_4/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/idgen.c -o build/3_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/idgen.c -o build/3_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/astalgo.c -o build/3_4/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/astalgo.c -o build/3_4/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/rodutils.c -o build/3_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/rodutils.c -o build/3_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/extccomp.c -o build/3_4/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/extccomp.c -o build/3_4/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/osproc.c -o build/3_4/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/osproc.c -o build/3_4/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/streams.c -o build/3_4/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/streams.c -o build/3_4/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/babelcmd.c -o build/3_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/babelcmd.c -o build/3_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/lexer.c -o build/3_4/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/lexer.c -o build/3_4/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/nimlexbase.c -o build/3_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/nimlexbase.c -o build/3_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/llstream.c -o build/3_4/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/llstream.c -o build/3_4/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/nimconf.c -o build/3_4/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/nimconf.c -o build/3_4/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/main.c -o build/3_4/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/main.c -o build/3_4/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/syntaxes.c -o build/3_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/syntaxes.c -o build/3_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/parser.c -o build/3_4/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/parser.c -o build/3_4/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/filters.c -o build/3_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/filters.c -o build/3_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/renderer.c -o build/3_4/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/renderer.c -o build/3_4/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/filter_tmpl.c -o build/3_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/filter_tmpl.c -o build/3_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/rodread.c -o build/3_4/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/rodread.c -o build/3_4/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/types.c -o build/3_4/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/types.c -o build/3_4/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/memfiles.c -o build/3_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/memfiles.c -o build/3_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/rodwrite.c -o build/3_4/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/rodwrite.c -o build/3_4/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/magicsys.c -o build/3_4/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/magicsys.c -o build/3_4/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/nimsets.c -o build/3_4/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/nimsets.c -o build/3_4/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/bitsets.c -o build/3_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/bitsets.c -o build/3_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/semthreads.c -o build/3_4/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/semthreads.c -o build/3_4/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/importer.c -o build/3_4/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/importer.c -o build/3_4/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/lookups.c -o build/3_4/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/lookups.c -o build/3_4/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/semdata.c -o build/3_4/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/semdata.c -o build/3_4/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/evals.c -o build/3_4/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/evals.c -o build/3_4/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/semfold.c -o build/3_4/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/semfold.c -o build/3_4/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/transf.c -o build/3_4/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/transf.c -o build/3_4/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/cgmeth.c -o build/3_4/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/cgmeth.c -o build/3_4/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/sempass2.c -o build/3_4/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/sempass2.c -o build/3_4/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/lambdalifting.c -o build/3_4/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/lambdalifting.c -o build/3_4/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/evaltempl.c -o build/3_4/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/evaltempl.c -o build/3_4/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/sem.c -o build/3_4/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/sem.c -o build/3_4/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/procfind.c -o build/3_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/procfind.c -o build/3_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/pragmas.c -o build/3_4/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/pragmas.c -o build/3_4/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/semtypinst.c -o build/3_4/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/semtypinst.c -o build/3_4/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/sigmatch.c -o build/3_4/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/sigmatch.c -o build/3_4/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/parampatterns.c -o build/3_4/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/parampatterns.c -o build/3_4/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/docgen.c -o build/3_4/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/docgen.c -o build/3_4/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/rstast.c -o build/3_4/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/rstast.c -o build/3_4/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/rst.c -o build/3_4/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/rst.c -o build/3_4/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/rstgen.c -o build/3_4/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/rstgen.c -o build/3_4/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/highlite.c -o build/3_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/highlite.c -o build/3_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/aliases.c -o build/3_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/aliases.c -o build/3_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/patterns.c -o build/3_4/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/patterns.c -o build/3_4/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/cgen.c -o build/3_4/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/cgen.c -o build/3_4/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/ccgutils.c -o build/3_4/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/ccgutils.c -o build/3_4/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/ccgmerge.c -o build/3_4/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/ccgmerge.c -o build/3_4/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/jsgen.c -o build/3_4/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/jsgen.c -o build/3_4/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/json.c -o build/3_4/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/json.c -o build/3_4/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/passaux.c -o build/3_4/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/passaux.c -o build/3_4/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/depends.c -o build/3_4/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/depends.c -o build/3_4/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/docgen2.c -o build/3_4/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/docgen2.c -o build/3_4/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_4/service.c -o build/3_4/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_4/service.c -o build/3_4/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_4/nimrod.o \
build/3_4/system.o \
build/3_4/commands.o \
build/3_4/os.o \
build/3_4/strutils.o \
build/3_4/parseutils.o \
build/3_1/times.o \
build/3_1/posix.o \
build/3_4/msgs.o \
build/3_4/options.o \
build/2_4/lists.o \
build/3_4/strtabs.o \
build/2_1/hashes.o \
build/3_1/tables.o \
build/2_1/math.o \
build/3_4/sockets.o \
build/3_4/ropes.o \
build/3_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/3_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/3_1/idgen.o \
build/3_4/astalgo.o \
build/3_1/rodutils.o \
build/3_4/extccomp.o \
build/3_4/osproc.o \
build/3_4/streams.o \
build/2_1/wordrecg.o \
build/3_1/babelcmd.o \
build/3_4/lexer.o \
build/3_1/nimlexbase.o \
build/3_4/llstream.o \
build/3_4/nimconf.o \
build/3_4/main.o \
build/3_1/syntaxes.o \
build/3_4/parser.o \
build/2_1/pbraces.o \
build/3_1/filters.o \
build/3_4/renderer.o \
build/3_1/filter_tmpl.o \
build/3_4/rodread.o \
build/3_4/types.o \
build/2_4/trees.o \
build/3_1/memfiles.o \
build/3_4/rodwrite.o \
build/2_1/passes.o \
build/3_4/magicsys.o \
build/3_4/nimsets.o \
build/3_1/bitsets.o \
build/3_4/semthreads.o \
build/3_4/importer.o \
build/3_4/lookups.o \
build/3_4/semdata.o \
build/2_4/treetab.o \
build/3_4/evals.o \
build/3_4/semfold.o \
build/2_1/saturate.o \
build/3_4/transf.o \
build/3_4/cgmeth.o \
build/3_4/sempass2.o \
build/3_4/lambdalifting.o \
build/3_4/evaltempl.o \
build/3_4/sem.o \
build/3_1/procfind.o \
build/3_4/pragmas.o \
build/3_4/semtypinst.o \
build/3_4/sigmatch.o \
build/3_4/parampatterns.o \
build/3_4/docgen.o \
build/3_4/rstast.o \
build/3_4/rst.o \
build/3_4/rstgen.o \
build/3_1/highlite.o \
build/2_1/algorithm.o \
build/3_1/aliases.o \
build/3_4/patterns.o \
build/3_4/cgen.o \
build/3_4/ccgutils.o \
build/2_4/cgendata.o \
build/3_4/ccgmerge.o \
build/3_4/jsgen.o \
build/3_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/3_4/passaux.o \
build/3_4/depends.o \
build/3_4/docgen2.o \
build/3_4/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/3_4/nimrod.o \
build/3_4/system.o \
build/3_4/commands.o \
build/3_4/os.o \
build/3_4/strutils.o \
build/3_4/parseutils.o \
build/3_1/times.o \
build/3_1/posix.o \
build/3_4/msgs.o \
build/3_4/options.o \
build/2_4/lists.o \
build/3_4/strtabs.o \
build/2_1/hashes.o \
build/3_1/tables.o \
build/2_1/math.o \
build/3_4/sockets.o \
build/3_4/ropes.o \
build/3_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/3_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/3_1/idgen.o \
build/3_4/astalgo.o \
build/3_1/rodutils.o \
build/3_4/extccomp.o \
build/3_4/osproc.o \
build/3_4/streams.o \
build/2_1/wordrecg.o \
build/3_1/babelcmd.o \
build/3_4/lexer.o \
build/3_1/nimlexbase.o \
build/3_4/llstream.o \
build/3_4/nimconf.o \
build/3_4/main.o \
build/3_1/syntaxes.o \
build/3_4/parser.o \
build/2_1/pbraces.o \
build/3_1/filters.o \
build/3_4/renderer.o \
build/3_1/filter_tmpl.o \
build/3_4/rodread.o \
build/3_4/types.o \
build/2_4/trees.o \
build/3_1/memfiles.o \
build/3_4/rodwrite.o \
build/2_1/passes.o \
build/3_4/magicsys.o \
build/3_4/nimsets.o \
build/3_1/bitsets.o \
build/3_4/semthreads.o \
build/3_4/importer.o \
build/3_4/lookups.o \
build/3_4/semdata.o \
build/2_4/treetab.o \
build/3_4/evals.o \
build/3_4/semfold.o \
build/2_1/saturate.o \
build/3_4/transf.o \
build/3_4/cgmeth.o \
build/3_4/sempass2.o \
build/3_4/lambdalifting.o \
build/3_4/evaltempl.o \
build/3_4/sem.o \
build/3_1/procfind.o \
build/3_4/pragmas.o \
build/3_4/semtypinst.o \
build/3_4/sigmatch.o \
build/3_4/parampatterns.o \
build/3_4/docgen.o \
build/3_4/rstast.o \
build/3_4/rst.o \
build/3_4/rstgen.o \
build/3_1/highlite.o \
build/2_1/algorithm.o \
build/3_1/aliases.o \
build/3_4/patterns.o \
build/3_4/cgen.o \
build/3_4/ccgutils.o \
build/2_4/cgendata.o \
build/3_4/ccgmerge.o \
build/3_4/jsgen.o \
build/3_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/3_4/passaux.o \
build/3_4/depends.o \
build/3_4/docgen2.o \
build/3_4/service.o \
build/2_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
solaris) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimrod.c -o build/4_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimrod.c -o build/4_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/system.c -o build/4_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/system.c -o build/4_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/os.c -o build/4_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/os.c -o build/4_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/strutils.c -o build/4_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/strutils.c -o build/4_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/msgs.c -o build/4_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/msgs.c -o build/4_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/options.c -o build/4_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/options.c -o build/4_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/tables.c -o build/4_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/tables.c -o build/4_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/sockets.c -o build/4_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/sockets.c -o build/4_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ropes.c -o build/4_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ropes.c -o build/4_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/platform.c -o build/4_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/platform.c -o build/4_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/idgen.c -o build/4_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/idgen.c -o build/4_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/astalgo.c -o build/4_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/astalgo.c -o build/4_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodutils.c -o build/4_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodutils.c -o build/4_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/extccomp.c -o build/4_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/extccomp.c -o build/4_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/osproc.c -o build/4_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/osproc.c -o build/4_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/streams.c -o build/4_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/streams.c -o build/4_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/lexer.c -o build/4_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/lexer.c -o build/4_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/main.c -o build/4_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/main.c -o build/4_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/types.c -o build/4_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/types.c -o build/4_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodwrite.c -o build/4_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodwrite.c -o build/4_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/magicsys.c -o build/4_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/magicsys.c -o build/4_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semthreads.c -o build/4_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semthreads.c -o build/4_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/importer.c -o build/4_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/importer.c -o build/4_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/lookups.c -o build/4_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/lookups.c -o build/4_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semdata.c -o build/4_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semdata.c -o build/4_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/evals.c -o build/4_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/evals.c -o build/4_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semfold.c -o build/4_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semfold.c -o build/4_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/cgmeth.c -o build/4_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/cgmeth.c -o build/4_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/sempass2.c -o build/4_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/sempass2.c -o build/4_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/lambdalifting.c -o build/4_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/lambdalifting.c -o build/4_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/sem.c -o build/4_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/sem.c -o build/4_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/procfind.c -o build/4_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/procfind.c -o build/4_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/pragmas.c -o build/4_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/pragmas.c -o build/4_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/sigmatch.c -o build/4_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/sigmatch.c -o build/4_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parampatterns.c -o build/4_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parampatterns.c -o build/4_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/docgen.c -o build/4_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/docgen.c -o build/4_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rstgen.c -o build/4_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rstgen.c -o build/4_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/aliases.c -o build/4_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/aliases.c -o build/4_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/patterns.c -o build/4_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/patterns.c -o build/4_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/cgen.c -o build/4_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/cgen.c -o build/4_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ccgutils.c -o build/4_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ccgutils.c -o build/4_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ccgmerge.c -o build/4_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ccgmerge.c -o build/4_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/jsgen.c -o build/4_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/jsgen.c -o build/4_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/json.c -o build/4_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/json.c -o build/4_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/depends.c -o build/4_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/depends.c -o build/4_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/docgen2.c -o build/4_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/docgen2.c -o build/4_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/service.c -o build/4_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/service.c -o build/4_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_1/nimrod.o \
build/4_1/system.o \
build/4_1/commands.o \
build/4_1/os.o \
build/4_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/4_1/msgs.o \
build/4_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/4_1/tables.o \
build/2_1/math.o \
build/4_1/sockets.o \
build/4_1/ropes.o \
build/4_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/4_1/idgen.o \
build/4_1/astalgo.o \
build/4_1/rodutils.o \
build/4_1/extccomp.o \
build/4_1/osproc.o \
build/4_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/4_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/4_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/4_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/4_1/rodwrite.o \
build/2_1/passes.o \
build/4_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/4_1/semthreads.o \
build/4_1/importer.o \
build/4_1/lookups.o \
build/4_1/semdata.o \
build/2_1/treetab.o \
build/4_1/evals.o \
build/4_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/4_1/cgmeth.o \
build/4_1/sempass2.o \
build/4_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/4_1/sem.o \
build/4_1/procfind.o \
build/4_1/pragmas.o \
build/4_1/semtypinst.o \
build/4_1/sigmatch.o \
build/4_1/parampatterns.o \
build/4_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/4_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/4_1/aliases.o \
build/4_1/patterns.o \
build/4_1/cgen.o \
build/4_1/ccgutils.o \
build/2_1/cgendata.o \
build/4_1/ccgmerge.o \
build/4_1/jsgen.o \
build/4_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/4_1/depends.o \
build/4_1/docgen2.o \
build/4_1/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_1/nimrod.o \
build/4_1/system.o \
build/4_1/commands.o \
build/4_1/os.o \
build/4_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/4_1/msgs.o \
build/4_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/4_1/tables.o \
build/2_1/math.o \
build/4_1/sockets.o \
build/4_1/ropes.o \
build/4_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/4_1/idgen.o \
build/4_1/astalgo.o \
build/4_1/rodutils.o \
build/4_1/extccomp.o \
build/4_1/osproc.o \
build/4_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/4_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/4_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/4_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/4_1/rodwrite.o \
build/2_1/passes.o \
build/4_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/4_1/semthreads.o \
build/4_1/importer.o \
build/4_1/lookups.o \
build/4_1/semdata.o \
build/2_1/treetab.o \
build/4_1/evals.o \
build/4_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/4_1/cgmeth.o \
build/4_1/sempass2.o \
build/4_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/4_1/sem.o \
build/4_1/procfind.o \
build/4_1/pragmas.o \
build/4_1/semtypinst.o \
build/4_1/sigmatch.o \
build/4_1/parampatterns.o \
build/4_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/4_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/4_1/aliases.o \
build/4_1/patterns.o \
build/4_1/cgen.o \
build/4_1/ccgutils.o \
build/2_1/cgendata.o \
build/4_1/ccgmerge.o \
build/4_1/jsgen.o \
build/4_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/4_1/depends.o \
build/4_1/docgen2.o \
build/4_1/service.o \
build/2_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimrod.c -o build/4_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimrod.c -o build/4_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/system.c -o build/4_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/system.c -o build/4_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/os.c -o build/4_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/os.c -o build/4_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/strutils.c -o build/4_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/strutils.c -o build/4_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/msgs.c -o build/4_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/msgs.c -o build/4_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/options.c -o build/4_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/options.c -o build/4_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/tables.c -o build/4_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/tables.c -o build/4_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/sockets.c -o build/4_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/sockets.c -o build/4_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ropes.c -o build/4_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ropes.c -o build/4_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/platform.c -o build/4_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/platform.c -o build/4_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/idgen.c -o build/4_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/idgen.c -o build/4_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/astalgo.c -o build/4_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/astalgo.c -o build/4_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodutils.c -o build/4_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodutils.c -o build/4_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/extccomp.c -o build/4_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/extccomp.c -o build/4_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/osproc.c -o build/4_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/osproc.c -o build/4_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/streams.c -o build/4_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/streams.c -o build/4_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/lexer.c -o build/4_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/lexer.c -o build/4_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/main.c -o build/4_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/main.c -o build/4_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/types.c -o build/4_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/types.c -o build/4_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodwrite.c -o build/4_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodwrite.c -o build/4_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/magicsys.c -o build/4_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/magicsys.c -o build/4_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semthreads.c -o build/4_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semthreads.c -o build/4_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/importer.c -o build/4_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/importer.c -o build/4_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/lookups.c -o build/4_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/lookups.c -o build/4_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semdata.c -o build/4_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semdata.c -o build/4_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/evals.c -o build/4_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/evals.c -o build/4_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semfold.c -o build/4_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semfold.c -o build/4_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/cgmeth.c -o build/4_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/cgmeth.c -o build/4_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/sempass2.c -o build/4_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/sempass2.c -o build/4_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/lambdalifting.c -o build/4_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/lambdalifting.c -o build/4_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/sem.c -o build/4_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/sem.c -o build/4_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/procfind.c -o build/4_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/procfind.c -o build/4_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/pragmas.c -o build/4_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/pragmas.c -o build/4_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/sigmatch.c -o build/4_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/sigmatch.c -o build/4_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parampatterns.c -o build/4_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parampatterns.c -o build/4_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/docgen.c -o build/4_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/docgen.c -o build/4_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rstgen.c -o build/4_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rstgen.c -o build/4_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/aliases.c -o build/4_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/aliases.c -o build/4_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/patterns.c -o build/4_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/patterns.c -o build/4_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/cgen.c -o build/4_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/cgen.c -o build/4_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ccgutils.c -o build/4_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ccgutils.c -o build/4_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ccgmerge.c -o build/4_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ccgmerge.c -o build/4_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/jsgen.c -o build/4_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/jsgen.c -o build/4_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/json.c -o build/4_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/json.c -o build/4_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/depends.c -o build/4_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/depends.c -o build/4_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/docgen2.c -o build/4_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/docgen2.c -o build/4_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/service.c -o build/4_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/service.c -o build/4_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_2/nimrod.o \
build/4_2/system.o \
build/4_2/commands.o \
build/4_2/os.o \
build/4_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/4_2/msgs.o \
build/4_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/4_2/tables.o \
build/2_2/math.o \
build/4_2/sockets.o \
build/4_2/ropes.o \
build/4_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/4_2/idgen.o \
build/4_2/astalgo.o \
build/4_2/rodutils.o \
build/4_2/extccomp.o \
build/4_2/osproc.o \
build/4_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/4_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/4_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/4_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/4_2/rodwrite.o \
build/2_2/passes.o \
build/4_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/4_2/semthreads.o \
build/4_2/importer.o \
build/4_2/lookups.o \
build/4_2/semdata.o \
build/2_2/treetab.o \
build/4_2/evals.o \
build/4_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/4_2/cgmeth.o \
build/4_2/sempass2.o \
build/4_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/4_2/sem.o \
build/4_2/procfind.o \
build/4_2/pragmas.o \
build/4_2/semtypinst.o \
build/4_2/sigmatch.o \
build/4_2/parampatterns.o \
build/4_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/4_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/4_2/aliases.o \
build/4_2/patterns.o \
build/4_2/cgen.o \
build/4_2/ccgutils.o \
build/2_2/cgendata.o \
build/4_2/ccgmerge.o \
build/4_2/jsgen.o \
build/4_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/4_2/depends.o \
build/4_2/docgen2.o \
build/4_2/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_2/nimrod.o \
build/4_2/system.o \
build/4_2/commands.o \
build/4_2/os.o \
build/4_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/4_2/msgs.o \
build/4_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/4_2/tables.o \
build/2_2/math.o \
build/4_2/sockets.o \
build/4_2/ropes.o \
build/4_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/4_2/idgen.o \
build/4_2/astalgo.o \
build/4_2/rodutils.o \
build/4_2/extccomp.o \
build/4_2/osproc.o \
build/4_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/4_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/4_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/4_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/4_2/rodwrite.o \
build/2_2/passes.o \
build/4_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/4_2/semthreads.o \
build/4_2/importer.o \
build/4_2/lookups.o \
build/4_2/semdata.o \
build/2_2/treetab.o \
build/4_2/evals.o \
build/4_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/4_2/cgmeth.o \
build/4_2/sempass2.o \
build/4_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/4_2/sem.o \
build/4_2/procfind.o \
build/4_2/pragmas.o \
build/4_2/semtypinst.o \
build/4_2/sigmatch.o \
build/4_2/parampatterns.o \
build/4_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/4_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/4_2/aliases.o \
build/4_2/patterns.o \
build/4_2/cgen.o \
build/4_2/ccgutils.o \
build/2_2/cgendata.o \
build/4_2/ccgmerge.o \
build/4_2/jsgen.o \
build/4_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/4_2/depends.o \
build/4_2/docgen2.o \
build/4_2/service.o \
build/2_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimrod.c -o build/4_3/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimrod.c -o build/4_3/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/system.c -o build/4_3/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/system.c -o build/4_3/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/os.c -o build/4_3/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/os.c -o build/4_3/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/strutils.c -o build/4_3/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/strutils.c -o build/4_3/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/msgs.c -o build/4_3/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/msgs.c -o build/4_3/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/options.c -o build/4_3/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/options.c -o build/4_3/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/tables.c -o build/4_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/tables.c -o build/4_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/sockets.c -o build/4_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/sockets.c -o build/4_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ropes.c -o build/4_3/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ropes.c -o build/4_3/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/platform.c -o build/4_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/platform.c -o build/4_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/idgen.c -o build/4_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/idgen.c -o build/4_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/astalgo.c -o build/4_3/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/astalgo.c -o build/4_3/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodutils.c -o build/4_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodutils.c -o build/4_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/extccomp.c -o build/4_3/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/extccomp.c -o build/4_3/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/osproc.c -o build/4_3/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/osproc.c -o build/4_3/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/streams.c -o build/4_3/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/streams.c -o build/4_3/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/lexer.c -o build/4_3/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/lexer.c -o build/4_3/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/main.c -o build/4_3/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/main.c -o build/4_3/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/types.c -o build/4_3/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/types.c -o build/4_3/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rodwrite.c -o build/4_3/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rodwrite.c -o build/4_3/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/magicsys.c -o build/4_3/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/magicsys.c -o build/4_3/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semthreads.c -o build/4_3/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semthreads.c -o build/4_3/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/importer.c -o build/4_3/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/importer.c -o build/4_3/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/lookups.c -o build/4_3/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/lookups.c -o build/4_3/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semdata.c -o build/4_3/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semdata.c -o build/4_3/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/evals.c -o build/4_3/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/evals.c -o build/4_3/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semfold.c -o build/4_3/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semfold.c -o build/4_3/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/cgmeth.c -o build/4_3/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/cgmeth.c -o build/4_3/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/sempass2.c -o build/4_3/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/sempass2.c -o build/4_3/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/lambdalifting.c -o build/4_3/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/lambdalifting.c -o build/4_3/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/sem.c -o build/4_3/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/sem.c -o build/4_3/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/procfind.c -o build/4_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/procfind.c -o build/4_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/pragmas.c -o build/4_3/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/pragmas.c -o build/4_3/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/sigmatch.c -o build/4_3/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/sigmatch.c -o build/4_3/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parampatterns.c -o build/4_3/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parampatterns.c -o build/4_3/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/docgen.c -o build/4_3/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/docgen.c -o build/4_3/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rstgen.c -o build/4_3/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rstgen.c -o build/4_3/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/aliases.c -o build/4_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/aliases.c -o build/4_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/patterns.c -o build/4_3/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/patterns.c -o build/4_3/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/cgen.c -o build/4_3/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/cgen.c -o build/4_3/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ccgutils.c -o build/4_3/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ccgutils.c -o build/4_3/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ccgmerge.c -o build/4_3/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ccgmerge.c -o build/4_3/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/jsgen.c -o build/4_3/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/jsgen.c -o build/4_3/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/json.c -o build/4_3/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/json.c -o build/4_3/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/depends.c -o build/4_3/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/depends.c -o build/4_3/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/docgen2.c -o build/4_3/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/docgen2.c -o build/4_3/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/service.c -o build/4_3/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/service.c -o build/4_3/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_3/nimrod.o \
build/4_3/system.o \
build/4_3/commands.o \
build/4_3/os.o \
build/4_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/4_3/msgs.o \
build/4_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/4_2/tables.o \
build/2_2/math.o \
build/4_3/sockets.o \
build/4_3/ropes.o \
build/4_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/4_2/idgen.o \
build/4_3/astalgo.o \
build/4_2/rodutils.o \
build/4_3/extccomp.o \
build/4_3/osproc.o \
build/4_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/4_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/4_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/4_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/4_3/rodwrite.o \
build/2_2/passes.o \
build/4_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/4_3/semthreads.o \
build/4_3/importer.o \
build/4_3/lookups.o \
build/4_3/semdata.o \
build/2_3/treetab.o \
build/4_3/evals.o \
build/4_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/4_3/cgmeth.o \
build/4_3/sempass2.o \
build/4_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/4_3/sem.o \
build/4_2/procfind.o \
build/4_3/pragmas.o \
build/4_3/semtypinst.o \
build/4_3/sigmatch.o \
build/4_3/parampatterns.o \
build/4_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/4_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/4_2/aliases.o \
build/4_3/patterns.o \
build/4_3/cgen.o \
build/4_3/ccgutils.o \
build/2_3/cgendata.o \
build/4_3/ccgmerge.o \
build/4_3/jsgen.o \
build/4_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/4_3/depends.o \
build/4_3/docgen2.o \
build/4_3/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_3/nimrod.o \
build/4_3/system.o \
build/4_3/commands.o \
build/4_3/os.o \
build/4_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/4_3/msgs.o \
build/4_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/4_2/tables.o \
build/2_2/math.o \
build/4_3/sockets.o \
build/4_3/ropes.o \
build/4_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/4_2/idgen.o \
build/4_3/astalgo.o \
build/4_2/rodutils.o \
build/4_3/extccomp.o \
build/4_3/osproc.o \
build/4_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/4_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/4_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/4_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/4_3/rodwrite.o \
build/2_2/passes.o \
build/4_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/4_3/semthreads.o \
build/4_3/importer.o \
build/4_3/lookups.o \
build/4_3/semdata.o \
build/2_3/treetab.o \
build/4_3/evals.o \
build/4_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/4_3/cgmeth.o \
build/4_3/sempass2.o \
build/4_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/4_3/sem.o \
build/4_2/procfind.o \
build/4_3/pragmas.o \
build/4_3/semtypinst.o \
build/4_3/sigmatch.o \
build/4_3/parampatterns.o \
build/4_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/4_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/4_2/aliases.o \
build/4_3/patterns.o \
build/4_3/cgen.o \
build/4_3/ccgutils.o \
build/2_3/cgendata.o \
build/4_3/ccgmerge.o \
build/4_3/jsgen.o \
build/4_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/4_3/depends.o \
build/4_3/docgen2.o \
build/4_3/service.o \
build/2_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimrod.c -o build/4_4/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimrod.c -o build/4_4/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/system.c -o build/4_4/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/system.c -o build/4_4/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/os.c -o build/4_4/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/os.c -o build/4_4/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/strutils.c -o build/4_4/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/strutils.c -o build/4_4/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/msgs.c -o build/4_4/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/msgs.c -o build/4_4/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/options.c -o build/4_4/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/options.c -o build/4_4/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/tables.c -o build/4_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/tables.c -o build/4_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/sockets.c -o build/4_4/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/sockets.c -o build/4_4/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ropes.c -o build/4_4/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ropes.c -o build/4_4/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/platform.c -o build/4_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/platform.c -o build/4_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/idgen.c -o build/4_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/idgen.c -o build/4_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/astalgo.c -o build/4_4/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/astalgo.c -o build/4_4/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodutils.c -o build/4_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodutils.c -o build/4_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/extccomp.c -o build/4_4/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/extccomp.c -o build/4_4/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/osproc.c -o build/4_4/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/osproc.c -o build/4_4/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/streams.c -o build/4_4/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/streams.c -o build/4_4/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/lexer.c -o build/4_4/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/lexer.c -o build/4_4/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/main.c -o build/4_4/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/main.c -o build/4_4/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/types.c -o build/4_4/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/types.c -o build/4_4/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rodwrite.c -o build/4_4/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rodwrite.c -o build/4_4/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/magicsys.c -o build/4_4/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/magicsys.c -o build/4_4/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semthreads.c -o build/4_4/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semthreads.c -o build/4_4/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/importer.c -o build/4_4/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/importer.c -o build/4_4/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/lookups.c -o build/4_4/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/lookups.c -o build/4_4/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semdata.c -o build/4_4/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semdata.c -o build/4_4/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/evals.c -o build/4_4/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/evals.c -o build/4_4/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semfold.c -o build/4_4/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semfold.c -o build/4_4/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/cgmeth.c -o build/4_4/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/cgmeth.c -o build/4_4/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/sempass2.c -o build/4_4/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/sempass2.c -o build/4_4/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/lambdalifting.c -o build/4_4/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/lambdalifting.c -o build/4_4/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/sem.c -o build/4_4/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/sem.c -o build/4_4/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/procfind.c -o build/4_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/procfind.c -o build/4_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/pragmas.c -o build/4_4/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/pragmas.c -o build/4_4/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/sigmatch.c -o build/4_4/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/sigmatch.c -o build/4_4/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parampatterns.c -o build/4_4/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parampatterns.c -o build/4_4/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/docgen.c -o build/4_4/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/docgen.c -o build/4_4/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rstgen.c -o build/4_4/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rstgen.c -o build/4_4/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/aliases.c -o build/4_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/aliases.c -o build/4_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/patterns.c -o build/4_4/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/patterns.c -o build/4_4/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/cgen.c -o build/4_4/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/cgen.c -o build/4_4/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ccgutils.c -o build/4_4/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ccgutils.c -o build/4_4/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ccgmerge.c -o build/4_4/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ccgmerge.c -o build/4_4/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/jsgen.c -o build/4_4/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/jsgen.c -o build/4_4/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/json.c -o build/4_4/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/json.c -o build/4_4/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/depends.c -o build/4_4/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/depends.c -o build/4_4/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/docgen2.c -o build/4_4/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/docgen2.c -o build/4_4/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/service.c -o build/4_4/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/service.c -o build/4_4/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_4/nimrod.o \
build/4_4/system.o \
build/4_4/commands.o \
build/4_4/os.o \
build/4_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/4_4/msgs.o \
build/4_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/4_1/tables.o \
build/2_1/math.o \
build/4_4/sockets.o \
build/4_4/ropes.o \
build/4_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/4_1/idgen.o \
build/4_4/astalgo.o \
build/4_1/rodutils.o \
build/4_4/extccomp.o \
build/4_4/osproc.o \
build/4_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/4_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/4_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/4_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/4_4/rodwrite.o \
build/2_1/passes.o \
build/4_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/4_4/semthreads.o \
build/4_4/importer.o \
build/4_4/lookups.o \
build/4_4/semdata.o \
build/2_4/treetab.o \
build/4_4/evals.o \
build/4_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/4_4/cgmeth.o \
build/4_4/sempass2.o \
build/4_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/4_4/sem.o \
build/4_1/procfind.o \
build/4_4/pragmas.o \
build/4_4/semtypinst.o \
build/4_4/sigmatch.o \
build/4_4/parampatterns.o \
build/4_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/4_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/4_1/aliases.o \
build/4_4/patterns.o \
build/4_4/cgen.o \
build/4_4/ccgutils.o \
build/2_4/cgendata.o \
build/4_4/ccgmerge.o \
build/4_4/jsgen.o \
build/4_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/4_4/depends.o \
build/4_4/docgen2.o \
build/4_4/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/4_4/nimrod.o \
build/4_4/system.o \
build/4_4/commands.o \
build/4_4/os.o \
build/4_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/4_4/msgs.o \
build/4_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/4_1/tables.o \
build/2_1/math.o \
build/4_4/sockets.o \
build/4_4/ropes.o \
build/4_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/4_1/idgen.o \
build/4_4/astalgo.o \
build/4_1/rodutils.o \
build/4_4/extccomp.o \
build/4_4/osproc.o \
build/4_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/4_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/4_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/4_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/4_4/rodwrite.o \
build/2_1/passes.o \
build/4_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/4_4/semthreads.o \
build/4_4/importer.o \
build/4_4/lookups.o \
build/4_4/semdata.o \
build/2_4/treetab.o \
build/4_4/evals.o \
build/4_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/4_4/cgmeth.o \
build/4_4/sempass2.o \
build/4_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/4_4/sem.o \
build/4_1/procfind.o \
build/4_4/pragmas.o \
build/4_4/semtypinst.o \
build/4_4/sigmatch.o \
build/4_4/parampatterns.o \
build/4_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/4_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/4_1/aliases.o \
build/4_4/patterns.o \
build/4_4/cgen.o \
build/4_4/ccgutils.o \
build/2_4/cgendata.o \
build/4_4/ccgmerge.o \
build/4_4/jsgen.o \
build/4_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/4_4/depends.o \
build/4_4/docgen2.o \
build/4_4/service.o \
build/2_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
freebsd) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/nimrod.c -o build/5_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/nimrod.c -o build/5_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/system.c -o build/5_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/system.c -o build/5_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/os.c -o build/5_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/os.c -o build/5_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/strutils.c -o build/5_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/strutils.c -o build/5_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/msgs.c -o build/5_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/msgs.c -o build/5_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/options.c -o build/5_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/options.c -o build/5_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sockets.c -o build/5_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sockets.c -o build/5_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ropes.c -o build/5_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ropes.c -o build/5_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/platform.c -o build/5_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/platform.c -o build/5_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/astalgo.c -o build/5_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/astalgo.c -o build/5_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/extccomp.c -o build/5_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/extccomp.c -o build/5_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/osproc.c -o build/5_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/osproc.c -o build/5_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/streams.c -o build/5_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/streams.c -o build/5_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lexer.c -o build/5_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lexer.c -o build/5_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/main.c -o build/5_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/main.c -o build/5_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/types.c -o build/5_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/types.c -o build/5_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodwrite.c -o build/5_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodwrite.c -o build/5_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/magicsys.c -o build/5_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/magicsys.c -o build/5_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semthreads.c -o build/5_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semthreads.c -o build/5_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/importer.c -o build/5_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/importer.c -o build/5_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lookups.c -o build/5_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lookups.c -o build/5_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semdata.c -o build/5_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semdata.c -o build/5_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/evals.c -o build/5_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/evals.c -o build/5_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semfold.c -o build/5_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semfold.c -o build/5_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/cgmeth.c -o build/5_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/cgmeth.c -o build/5_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sempass2.c -o build/5_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sempass2.c -o build/5_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lambdalifting.c -o build/5_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lambdalifting.c -o build/5_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sem.c -o build/5_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sem.c -o build/5_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/pragmas.c -o build/5_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/pragmas.c -o build/5_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sigmatch.c -o build/5_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sigmatch.c -o build/5_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/parampatterns.c -o build/5_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/parampatterns.c -o build/5_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/docgen.c -o build/5_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/docgen.c -o build/5_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rstgen.c -o build/5_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rstgen.c -o build/5_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/patterns.c -o build/5_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/patterns.c -o build/5_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/cgen.c -o build/5_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/cgen.c -o build/5_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ccgutils.c -o build/5_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ccgutils.c -o build/5_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ccgmerge.c -o build/5_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ccgmerge.c -o build/5_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/jsgen.c -o build/5_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/jsgen.c -o build/5_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/json.c -o build/5_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/json.c -o build/5_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/depends.c -o build/5_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/depends.c -o build/5_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/docgen2.c -o build/5_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/docgen2.c -o build/5_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/service.c -o build/5_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/service.c -o build/5_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_1/nimrod.o \
build/5_1/system.o \
build/4_1/commands.o \
build/5_1/os.o \
build/5_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_1/msgs.o \
build/5_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_1/sockets.o \
build/5_1/ropes.o \
build/5_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/5_1/idgen.o \
build/5_1/astalgo.o \
build/5_1/rodutils.o \
build/5_1/extccomp.o \
build/5_1/osproc.o \
build/5_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/5_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/5_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/5_1/rodwrite.o \
build/2_1/passes.o \
build/5_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/5_1/semthreads.o \
build/5_1/importer.o \
build/5_1/lookups.o \
build/5_1/semdata.o \
build/2_1/treetab.o \
build/5_1/evals.o \
build/5_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/5_1/cgmeth.o \
build/5_1/sempass2.o \
build/5_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/5_1/sem.o \
build/5_1/procfind.o \
build/5_1/pragmas.o \
build/4_1/semtypinst.o \
build/5_1/sigmatch.o \
build/5_1/parampatterns.o \
build/5_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/5_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_1/patterns.o \
build/5_1/cgen.o \
build/5_1/ccgutils.o \
build/2_1/cgendata.o \
build/5_1/ccgmerge.o \
build/5_1/jsgen.o \
build/5_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/5_1/depends.o \
build/5_1/docgen2.o \
build/5_1/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_1/nimrod.o \
build/5_1/system.o \
build/4_1/commands.o \
build/5_1/os.o \
build/5_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_1/msgs.o \
build/5_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_1/sockets.o \
build/5_1/ropes.o \
build/5_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/5_1/idgen.o \
build/5_1/astalgo.o \
build/5_1/rodutils.o \
build/5_1/extccomp.o \
build/5_1/osproc.o \
build/5_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/5_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/5_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/5_1/rodwrite.o \
build/2_1/passes.o \
build/5_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/5_1/semthreads.o \
build/5_1/importer.o \
build/5_1/lookups.o \
build/5_1/semdata.o \
build/2_1/treetab.o \
build/5_1/evals.o \
build/5_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/5_1/cgmeth.o \
build/5_1/sempass2.o \
build/5_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/5_1/sem.o \
build/5_1/procfind.o \
build/5_1/pragmas.o \
build/4_1/semtypinst.o \
build/5_1/sigmatch.o \
build/5_1/parampatterns.o \
build/5_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/5_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_1/patterns.o \
build/5_1/cgen.o \
build/5_1/ccgutils.o \
build/2_1/cgendata.o \
build/5_1/ccgmerge.o \
build/5_1/jsgen.o \
build/5_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/5_1/depends.o \
build/5_1/docgen2.o \
build/5_1/service.o \
build/2_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/nimrod.c -o build/5_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/nimrod.c -o build/5_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/system.c -o build/5_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/system.c -o build/5_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/os.c -o build/5_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/os.c -o build/5_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/strutils.c -o build/5_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/strutils.c -o build/5_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/msgs.c -o build/5_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/msgs.c -o build/5_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/options.c -o build/5_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/options.c -o build/5_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sockets.c -o build/5_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sockets.c -o build/5_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ropes.c -o build/5_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ropes.c -o build/5_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/platform.c -o build/5_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/platform.c -o build/5_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/astalgo.c -o build/5_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/astalgo.c -o build/5_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/extccomp.c -o build/5_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/extccomp.c -o build/5_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/osproc.c -o build/5_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/osproc.c -o build/5_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/streams.c -o build/5_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/streams.c -o build/5_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lexer.c -o build/5_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lexer.c -o build/5_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/main.c -o build/5_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/main.c -o build/5_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/types.c -o build/5_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/types.c -o build/5_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodwrite.c -o build/5_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodwrite.c -o build/5_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/magicsys.c -o build/5_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/magicsys.c -o build/5_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semthreads.c -o build/5_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semthreads.c -o build/5_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/importer.c -o build/5_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/importer.c -o build/5_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lookups.c -o build/5_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lookups.c -o build/5_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semdata.c -o build/5_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semdata.c -o build/5_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/evals.c -o build/5_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/evals.c -o build/5_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semfold.c -o build/5_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semfold.c -o build/5_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/cgmeth.c -o build/5_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/cgmeth.c -o build/5_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sempass2.c -o build/5_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sempass2.c -o build/5_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lambdalifting.c -o build/5_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lambdalifting.c -o build/5_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sem.c -o build/5_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sem.c -o build/5_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/pragmas.c -o build/5_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/pragmas.c -o build/5_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sigmatch.c -o build/5_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sigmatch.c -o build/5_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/parampatterns.c -o build/5_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/parampatterns.c -o build/5_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/docgen.c -o build/5_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/docgen.c -o build/5_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rstgen.c -o build/5_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rstgen.c -o build/5_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/patterns.c -o build/5_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/patterns.c -o build/5_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/cgen.c -o build/5_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/cgen.c -o build/5_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ccgutils.c -o build/5_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ccgutils.c -o build/5_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ccgmerge.c -o build/5_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ccgmerge.c -o build/5_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/jsgen.c -o build/5_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/jsgen.c -o build/5_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/json.c -o build/5_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/json.c -o build/5_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/depends.c -o build/5_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/depends.c -o build/5_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/docgen2.c -o build/5_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/docgen2.c -o build/5_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/service.c -o build/5_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/service.c -o build/5_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_2/nimrod.o \
build/5_2/system.o \
build/4_2/commands.o \
build/5_2/os.o \
build/5_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_2/msgs.o \
build/5_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_2/sockets.o \
build/5_2/ropes.o \
build/5_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/5_2/idgen.o \
build/5_2/astalgo.o \
build/5_2/rodutils.o \
build/5_2/extccomp.o \
build/5_2/osproc.o \
build/5_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/5_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/5_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/5_2/rodwrite.o \
build/2_2/passes.o \
build/5_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/5_2/semthreads.o \
build/5_2/importer.o \
build/5_2/lookups.o \
build/5_2/semdata.o \
build/2_2/treetab.o \
build/5_2/evals.o \
build/5_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/5_2/cgmeth.o \
build/5_2/sempass2.o \
build/5_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/5_2/sem.o \
build/5_2/procfind.o \
build/5_2/pragmas.o \
build/4_2/semtypinst.o \
build/5_2/sigmatch.o \
build/5_2/parampatterns.o \
build/5_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/5_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_2/patterns.o \
build/5_2/cgen.o \
build/5_2/ccgutils.o \
build/2_2/cgendata.o \
build/5_2/ccgmerge.o \
build/5_2/jsgen.o \
build/5_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/5_2/depends.o \
build/5_2/docgen2.o \
build/5_2/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_2/nimrod.o \
build/5_2/system.o \
build/4_2/commands.o \
build/5_2/os.o \
build/5_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_2/msgs.o \
build/5_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_2/sockets.o \
build/5_2/ropes.o \
build/5_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/5_2/idgen.o \
build/5_2/astalgo.o \
build/5_2/rodutils.o \
build/5_2/extccomp.o \
build/5_2/osproc.o \
build/5_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/5_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/5_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/5_2/rodwrite.o \
build/2_2/passes.o \
build/5_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/5_2/semthreads.o \
build/5_2/importer.o \
build/5_2/lookups.o \
build/5_2/semdata.o \
build/2_2/treetab.o \
build/5_2/evals.o \
build/5_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/5_2/cgmeth.o \
build/5_2/sempass2.o \
build/5_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/5_2/sem.o \
build/5_2/procfind.o \
build/5_2/pragmas.o \
build/4_2/semtypinst.o \
build/5_2/sigmatch.o \
build/5_2/parampatterns.o \
build/5_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/5_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_2/patterns.o \
build/5_2/cgen.o \
build/5_2/ccgutils.o \
build/2_2/cgendata.o \
build/5_2/ccgmerge.o \
build/5_2/jsgen.o \
build/5_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/5_2/depends.o \
build/5_2/docgen2.o \
build/5_2/service.o \
build/2_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/nimrod.c -o build/5_3/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/nimrod.c -o build/5_3/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/system.c -o build/5_3/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/system.c -o build/5_3/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/os.c -o build/5_3/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/os.c -o build/5_3/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/strutils.c -o build/5_3/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/strutils.c -o build/5_3/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/msgs.c -o build/5_3/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/msgs.c -o build/5_3/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/options.c -o build/5_3/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/options.c -o build/5_3/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sockets.c -o build/5_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sockets.c -o build/5_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ropes.c -o build/5_3/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ropes.c -o build/5_3/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/platform.c -o build/5_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/platform.c -o build/5_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/astalgo.c -o build/5_3/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/astalgo.c -o build/5_3/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/extccomp.c -o build/5_3/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/extccomp.c -o build/5_3/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/osproc.c -o build/5_3/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/osproc.c -o build/5_3/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/streams.c -o build/5_3/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/streams.c -o build/5_3/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lexer.c -o build/5_3/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lexer.c -o build/5_3/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/main.c -o build/5_3/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/main.c -o build/5_3/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/types.c -o build/5_3/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/types.c -o build/5_3/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/rodwrite.c -o build/5_3/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/rodwrite.c -o build/5_3/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/magicsys.c -o build/5_3/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/magicsys.c -o build/5_3/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semthreads.c -o build/5_3/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semthreads.c -o build/5_3/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/importer.c -o build/5_3/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/importer.c -o build/5_3/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lookups.c -o build/5_3/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lookups.c -o build/5_3/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semdata.c -o build/5_3/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semdata.c -o build/5_3/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/evals.c -o build/5_3/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/evals.c -o build/5_3/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semfold.c -o build/5_3/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semfold.c -o build/5_3/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/cgmeth.c -o build/5_3/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/cgmeth.c -o build/5_3/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sempass2.c -o build/5_3/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sempass2.c -o build/5_3/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lambdalifting.c -o build/5_3/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lambdalifting.c -o build/5_3/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sem.c -o build/5_3/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sem.c -o build/5_3/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/pragmas.c -o build/5_3/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/pragmas.c -o build/5_3/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sigmatch.c -o build/5_3/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sigmatch.c -o build/5_3/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/parampatterns.c -o build/5_3/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/parampatterns.c -o build/5_3/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/docgen.c -o build/5_3/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/docgen.c -o build/5_3/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/rstgen.c -o build/5_3/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/rstgen.c -o build/5_3/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/patterns.c -o build/5_3/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/patterns.c -o build/5_3/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/cgen.c -o build/5_3/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/cgen.c -o build/5_3/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ccgutils.c -o build/5_3/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ccgutils.c -o build/5_3/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ccgmerge.c -o build/5_3/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ccgmerge.c -o build/5_3/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/jsgen.c -o build/5_3/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/jsgen.c -o build/5_3/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/json.c -o build/5_3/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/json.c -o build/5_3/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/depends.c -o build/5_3/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/depends.c -o build/5_3/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/docgen2.c -o build/5_3/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/docgen2.c -o build/5_3/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/service.c -o build/5_3/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/service.c -o build/5_3/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_3/nimrod.o \
build/5_3/system.o \
build/4_3/commands.o \
build/5_3/os.o \
build/5_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_3/msgs.o \
build/5_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_3/sockets.o \
build/5_3/ropes.o \
build/5_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/5_2/idgen.o \
build/5_3/astalgo.o \
build/5_2/rodutils.o \
build/5_3/extccomp.o \
build/5_3/osproc.o \
build/5_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/5_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/5_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/5_3/rodwrite.o \
build/2_2/passes.o \
build/5_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/5_3/semthreads.o \
build/5_3/importer.o \
build/5_3/lookups.o \
build/5_3/semdata.o \
build/2_3/treetab.o \
build/5_3/evals.o \
build/5_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/5_3/cgmeth.o \
build/5_3/sempass2.o \
build/5_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/5_3/sem.o \
build/5_2/procfind.o \
build/5_3/pragmas.o \
build/4_3/semtypinst.o \
build/5_3/sigmatch.o \
build/5_3/parampatterns.o \
build/5_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/5_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_3/patterns.o \
build/5_3/cgen.o \
build/5_3/ccgutils.o \
build/2_3/cgendata.o \
build/5_3/ccgmerge.o \
build/5_3/jsgen.o \
build/5_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/5_3/depends.o \
build/5_3/docgen2.o \
build/5_3/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_3/nimrod.o \
build/5_3/system.o \
build/4_3/commands.o \
build/5_3/os.o \
build/5_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_3/msgs.o \
build/5_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_3/sockets.o \
build/5_3/ropes.o \
build/5_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/5_2/idgen.o \
build/5_3/astalgo.o \
build/5_2/rodutils.o \
build/5_3/extccomp.o \
build/5_3/osproc.o \
build/5_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/5_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/5_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/5_3/rodwrite.o \
build/2_2/passes.o \
build/5_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/5_3/semthreads.o \
build/5_3/importer.o \
build/5_3/lookups.o \
build/5_3/semdata.o \
build/2_3/treetab.o \
build/5_3/evals.o \
build/5_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/5_3/cgmeth.o \
build/5_3/sempass2.o \
build/5_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/5_3/sem.o \
build/5_2/procfind.o \
build/5_3/pragmas.o \
build/4_3/semtypinst.o \
build/5_3/sigmatch.o \
build/5_3/parampatterns.o \
build/5_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/5_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_3/patterns.o \
build/5_3/cgen.o \
build/5_3/ccgutils.o \
build/2_3/cgendata.o \
build/5_3/ccgmerge.o \
build/5_3/jsgen.o \
build/5_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/5_3/depends.o \
build/5_3/docgen2.o \
build/5_3/service.o \
build/2_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/nimrod.c -o build/5_4/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/nimrod.c -o build/5_4/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/system.c -o build/5_4/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/system.c -o build/5_4/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/os.c -o build/5_4/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/os.c -o build/5_4/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/strutils.c -o build/5_4/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/strutils.c -o build/5_4/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/msgs.c -o build/5_4/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/msgs.c -o build/5_4/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/options.c -o build/5_4/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/options.c -o build/5_4/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sockets.c -o build/5_4/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sockets.c -o build/5_4/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ropes.c -o build/5_4/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ropes.c -o build/5_4/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/platform.c -o build/5_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/platform.c -o build/5_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/astalgo.c -o build/5_4/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/astalgo.c -o build/5_4/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/extccomp.c -o build/5_4/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/extccomp.c -o build/5_4/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/osproc.c -o build/5_4/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/osproc.c -o build/5_4/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/streams.c -o build/5_4/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/streams.c -o build/5_4/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lexer.c -o build/5_4/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lexer.c -o build/5_4/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/main.c -o build/5_4/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/main.c -o build/5_4/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/types.c -o build/5_4/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/types.c -o build/5_4/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/rodwrite.c -o build/5_4/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/rodwrite.c -o build/5_4/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/magicsys.c -o build/5_4/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/magicsys.c -o build/5_4/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semthreads.c -o build/5_4/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semthreads.c -o build/5_4/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/importer.c -o build/5_4/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/importer.c -o build/5_4/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lookups.c -o build/5_4/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lookups.c -o build/5_4/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semdata.c -o build/5_4/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semdata.c -o build/5_4/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/evals.c -o build/5_4/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/evals.c -o build/5_4/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semfold.c -o build/5_4/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semfold.c -o build/5_4/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/cgmeth.c -o build/5_4/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/cgmeth.c -o build/5_4/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sempass2.c -o build/5_4/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sempass2.c -o build/5_4/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lambdalifting.c -o build/5_4/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lambdalifting.c -o build/5_4/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sem.c -o build/5_4/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sem.c -o build/5_4/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/pragmas.c -o build/5_4/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/pragmas.c -o build/5_4/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sigmatch.c -o build/5_4/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sigmatch.c -o build/5_4/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/parampatterns.c -o build/5_4/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/parampatterns.c -o build/5_4/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/docgen.c -o build/5_4/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/docgen.c -o build/5_4/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/rstgen.c -o build/5_4/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/rstgen.c -o build/5_4/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/patterns.c -o build/5_4/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/patterns.c -o build/5_4/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/cgen.c -o build/5_4/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/cgen.c -o build/5_4/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ccgutils.c -o build/5_4/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ccgutils.c -o build/5_4/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ccgmerge.c -o build/5_4/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ccgmerge.c -o build/5_4/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/jsgen.c -o build/5_4/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/jsgen.c -o build/5_4/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/json.c -o build/5_4/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/json.c -o build/5_4/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/depends.c -o build/5_4/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/depends.c -o build/5_4/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/docgen2.c -o build/5_4/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/docgen2.c -o build/5_4/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/service.c -o build/5_4/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/service.c -o build/5_4/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_4/nimrod.o \
build/5_4/system.o \
build/4_4/commands.o \
build/5_4/os.o \
build/5_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_4/msgs.o \
build/5_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_4/sockets.o \
build/5_4/ropes.o \
build/5_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/5_1/idgen.o \
build/5_4/astalgo.o \
build/5_1/rodutils.o \
build/5_4/extccomp.o \
build/5_4/osproc.o \
build/5_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/5_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/5_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/5_4/rodwrite.o \
build/2_1/passes.o \
build/5_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/5_4/semthreads.o \
build/5_4/importer.o \
build/5_4/lookups.o \
build/5_4/semdata.o \
build/2_4/treetab.o \
build/5_4/evals.o \
build/5_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/5_4/cgmeth.o \
build/5_4/sempass2.o \
build/5_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/5_4/sem.o \
build/5_1/procfind.o \
build/5_4/pragmas.o \
build/4_4/semtypinst.o \
build/5_4/sigmatch.o \
build/5_4/parampatterns.o \
build/5_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/5_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_4/patterns.o \
build/5_4/cgen.o \
build/5_4/ccgutils.o \
build/2_4/cgendata.o \
build/5_4/ccgmerge.o \
build/5_4/jsgen.o \
build/5_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/5_4/depends.o \
build/5_4/docgen2.o \
build/5_4/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_4/nimrod.o \
build/5_4/system.o \
build/4_4/commands.o \
build/5_4/os.o \
build/5_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_4/msgs.o \
build/5_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_4/sockets.o \
build/5_4/ropes.o \
build/5_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/5_1/idgen.o \
build/5_4/astalgo.o \
build/5_1/rodutils.o \
build/5_4/extccomp.o \
build/5_4/osproc.o \
build/5_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/5_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/5_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/5_4/rodwrite.o \
build/2_1/passes.o \
build/5_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/5_4/semthreads.o \
build/5_4/importer.o \
build/5_4/lookups.o \
build/5_4/semdata.o \
build/2_4/treetab.o \
build/5_4/evals.o \
build/5_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/5_4/cgmeth.o \
build/5_4/sempass2.o \
build/5_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/5_4/sem.o \
build/5_1/procfind.o \
build/5_4/pragmas.o \
build/4_4/semtypinst.o \
build/5_4/sigmatch.o \
build/5_4/parampatterns.o \
build/5_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/5_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_4/patterns.o \
build/5_4/cgen.o \
build/5_4/ccgutils.o \
build/2_4/cgendata.o \
build/5_4/ccgmerge.o \
build/5_4/jsgen.o \
build/5_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/5_4/depends.o \
build/5_4/docgen2.o \
build/5_4/service.o \
build/2_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
netbsd) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/nimrod.c -o build/5_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/nimrod.c -o build/5_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/system.c -o build/5_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/system.c -o build/5_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_1/os.c -o build/6_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_1/os.c -o build/6_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/strutils.c -o build/5_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/strutils.c -o build/5_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/msgs.c -o build/5_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/msgs.c -o build/5_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/options.c -o build/5_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/options.c -o build/5_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sockets.c -o build/5_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sockets.c -o build/5_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ropes.c -o build/5_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ropes.c -o build/5_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_1/platform.c -o build/6_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_1/platform.c -o build/6_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/astalgo.c -o build/5_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/astalgo.c -o build/5_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/extccomp.c -o build/5_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/extccomp.c -o build/5_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/osproc.c -o build/5_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/osproc.c -o build/5_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/streams.c -o build/5_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/streams.c -o build/5_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lexer.c -o build/5_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lexer.c -o build/5_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/main.c -o build/5_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/main.c -o build/5_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/types.c -o build/5_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/types.c -o build/5_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodwrite.c -o build/5_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodwrite.c -o build/5_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/magicsys.c -o build/5_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/magicsys.c -o build/5_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semthreads.c -o build/5_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semthreads.c -o build/5_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/importer.c -o build/5_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/importer.c -o build/5_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lookups.c -o build/5_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lookups.c -o build/5_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semdata.c -o build/5_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semdata.c -o build/5_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/evals.c -o build/5_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/evals.c -o build/5_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semfold.c -o build/5_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semfold.c -o build/5_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/cgmeth.c -o build/5_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/cgmeth.c -o build/5_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sempass2.c -o build/5_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sempass2.c -o build/5_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lambdalifting.c -o build/5_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lambdalifting.c -o build/5_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sem.c -o build/5_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sem.c -o build/5_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/pragmas.c -o build/5_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/pragmas.c -o build/5_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sigmatch.c -o build/5_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sigmatch.c -o build/5_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/parampatterns.c -o build/5_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/parampatterns.c -o build/5_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/docgen.c -o build/5_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/docgen.c -o build/5_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rstgen.c -o build/5_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rstgen.c -o build/5_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/patterns.c -o build/5_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/patterns.c -o build/5_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/cgen.c -o build/5_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/cgen.c -o build/5_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ccgutils.c -o build/5_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ccgutils.c -o build/5_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ccgmerge.c -o build/5_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ccgmerge.c -o build/5_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/jsgen.c -o build/5_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/jsgen.c -o build/5_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/json.c -o build/5_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/json.c -o build/5_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/depends.c -o build/5_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/depends.c -o build/5_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/docgen2.c -o build/5_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/docgen2.c -o build/5_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/service.c -o build/5_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/service.c -o build/5_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_1/nimrod.o \
build/5_1/system.o \
build/4_1/commands.o \
build/6_1/os.o \
build/5_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_1/msgs.o \
build/5_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_1/sockets.o \
build/5_1/ropes.o \
build/6_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/5_1/idgen.o \
build/5_1/astalgo.o \
build/5_1/rodutils.o \
build/5_1/extccomp.o \
build/5_1/osproc.o \
build/5_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/5_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/5_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/5_1/rodwrite.o \
build/2_1/passes.o \
build/5_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/5_1/semthreads.o \
build/5_1/importer.o \
build/5_1/lookups.o \
build/5_1/semdata.o \
build/2_1/treetab.o \
build/5_1/evals.o \
build/5_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/5_1/cgmeth.o \
build/5_1/sempass2.o \
build/5_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/5_1/sem.o \
build/5_1/procfind.o \
build/5_1/pragmas.o \
build/4_1/semtypinst.o \
build/5_1/sigmatch.o \
build/5_1/parampatterns.o \
build/5_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/5_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_1/patterns.o \
build/5_1/cgen.o \
build/5_1/ccgutils.o \
build/2_1/cgendata.o \
build/5_1/ccgmerge.o \
build/5_1/jsgen.o \
build/5_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/5_1/depends.o \
build/5_1/docgen2.o \
build/5_1/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_1/nimrod.o \
build/5_1/system.o \
build/4_1/commands.o \
build/6_1/os.o \
build/5_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_1/msgs.o \
build/5_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_1/sockets.o \
build/5_1/ropes.o \
build/6_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/5_1/idgen.o \
build/5_1/astalgo.o \
build/5_1/rodutils.o \
build/5_1/extccomp.o \
build/5_1/osproc.o \
build/5_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/5_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/5_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/5_1/rodwrite.o \
build/2_1/passes.o \
build/5_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/5_1/semthreads.o \
build/5_1/importer.o \
build/5_1/lookups.o \
build/5_1/semdata.o \
build/2_1/treetab.o \
build/5_1/evals.o \
build/5_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/5_1/cgmeth.o \
build/5_1/sempass2.o \
build/5_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/5_1/sem.o \
build/5_1/procfind.o \
build/5_1/pragmas.o \
build/4_1/semtypinst.o \
build/5_1/sigmatch.o \
build/5_1/parampatterns.o \
build/5_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/5_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_1/patterns.o \
build/5_1/cgen.o \
build/5_1/ccgutils.o \
build/2_1/cgendata.o \
build/5_1/ccgmerge.o \
build/5_1/jsgen.o \
build/5_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/5_1/depends.o \
build/5_1/docgen2.o \
build/5_1/service.o \
build/2_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/nimrod.c -o build/5_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/nimrod.c -o build/5_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/system.c -o build/5_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/system.c -o build/5_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_2/os.c -o build/6_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_2/os.c -o build/6_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/strutils.c -o build/5_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/strutils.c -o build/5_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/msgs.c -o build/5_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/msgs.c -o build/5_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/options.c -o build/5_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/options.c -o build/5_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sockets.c -o build/5_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sockets.c -o build/5_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ropes.c -o build/5_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ropes.c -o build/5_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_2/platform.c -o build/6_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_2/platform.c -o build/6_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/astalgo.c -o build/5_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/astalgo.c -o build/5_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/extccomp.c -o build/5_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/extccomp.c -o build/5_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/osproc.c -o build/5_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/osproc.c -o build/5_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/streams.c -o build/5_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/streams.c -o build/5_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lexer.c -o build/5_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lexer.c -o build/5_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/main.c -o build/5_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/main.c -o build/5_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/types.c -o build/5_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/types.c -o build/5_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodwrite.c -o build/5_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodwrite.c -o build/5_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/magicsys.c -o build/5_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/magicsys.c -o build/5_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semthreads.c -o build/5_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semthreads.c -o build/5_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/importer.c -o build/5_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/importer.c -o build/5_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lookups.c -o build/5_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lookups.c -o build/5_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semdata.c -o build/5_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semdata.c -o build/5_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/evals.c -o build/5_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/evals.c -o build/5_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semfold.c -o build/5_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semfold.c -o build/5_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/cgmeth.c -o build/5_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/cgmeth.c -o build/5_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sempass2.c -o build/5_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sempass2.c -o build/5_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lambdalifting.c -o build/5_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lambdalifting.c -o build/5_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sem.c -o build/5_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sem.c -o build/5_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/pragmas.c -o build/5_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/pragmas.c -o build/5_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sigmatch.c -o build/5_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sigmatch.c -o build/5_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/parampatterns.c -o build/5_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/parampatterns.c -o build/5_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/docgen.c -o build/5_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/docgen.c -o build/5_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rstgen.c -o build/5_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rstgen.c -o build/5_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/patterns.c -o build/5_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/patterns.c -o build/5_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/cgen.c -o build/5_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/cgen.c -o build/5_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ccgutils.c -o build/5_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ccgutils.c -o build/5_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ccgmerge.c -o build/5_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ccgmerge.c -o build/5_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/jsgen.c -o build/5_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/jsgen.c -o build/5_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/json.c -o build/5_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/json.c -o build/5_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/depends.c -o build/5_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/depends.c -o build/5_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/docgen2.c -o build/5_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/docgen2.c -o build/5_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/service.c -o build/5_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/service.c -o build/5_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_2/nimrod.o \
build/5_2/system.o \
build/4_2/commands.o \
build/6_2/os.o \
build/5_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_2/msgs.o \
build/5_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_2/sockets.o \
build/5_2/ropes.o \
build/6_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/5_2/idgen.o \
build/5_2/astalgo.o \
build/5_2/rodutils.o \
build/5_2/extccomp.o \
build/5_2/osproc.o \
build/5_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/5_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/5_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/5_2/rodwrite.o \
build/2_2/passes.o \
build/5_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/5_2/semthreads.o \
build/5_2/importer.o \
build/5_2/lookups.o \
build/5_2/semdata.o \
build/2_2/treetab.o \
build/5_2/evals.o \
build/5_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/5_2/cgmeth.o \
build/5_2/sempass2.o \
build/5_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/5_2/sem.o \
build/5_2/procfind.o \
build/5_2/pragmas.o \
build/4_2/semtypinst.o \
build/5_2/sigmatch.o \
build/5_2/parampatterns.o \
build/5_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/5_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_2/patterns.o \
build/5_2/cgen.o \
build/5_2/ccgutils.o \
build/2_2/cgendata.o \
build/5_2/ccgmerge.o \
build/5_2/jsgen.o \
build/5_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/5_2/depends.o \
build/5_2/docgen2.o \
build/5_2/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_2/nimrod.o \
build/5_2/system.o \
build/4_2/commands.o \
build/6_2/os.o \
build/5_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_2/msgs.o \
build/5_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_2/sockets.o \
build/5_2/ropes.o \
build/6_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/5_2/idgen.o \
build/5_2/astalgo.o \
build/5_2/rodutils.o \
build/5_2/extccomp.o \
build/5_2/osproc.o \
build/5_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/5_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/5_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/5_2/rodwrite.o \
build/2_2/passes.o \
build/5_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/5_2/semthreads.o \
build/5_2/importer.o \
build/5_2/lookups.o \
build/5_2/semdata.o \
build/2_2/treetab.o \
build/5_2/evals.o \
build/5_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/5_2/cgmeth.o \
build/5_2/sempass2.o \
build/5_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/5_2/sem.o \
build/5_2/procfind.o \
build/5_2/pragmas.o \
build/4_2/semtypinst.o \
build/5_2/sigmatch.o \
build/5_2/parampatterns.o \
build/5_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/5_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_2/patterns.o \
build/5_2/cgen.o \
build/5_2/ccgutils.o \
build/2_2/cgendata.o \
build/5_2/ccgmerge.o \
build/5_2/jsgen.o \
build/5_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/5_2/depends.o \
build/5_2/docgen2.o \
build/5_2/service.o \
build/2_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/nimrod.c -o build/5_3/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/nimrod.c -o build/5_3/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/system.c -o build/5_3/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/system.c -o build/5_3/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_3/os.c -o build/6_3/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_3/os.c -o build/6_3/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/strutils.c -o build/5_3/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/strutils.c -o build/5_3/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/msgs.c -o build/5_3/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/msgs.c -o build/5_3/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/options.c -o build/5_3/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/options.c -o build/5_3/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sockets.c -o build/5_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sockets.c -o build/5_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ropes.c -o build/5_3/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ropes.c -o build/5_3/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_3/platform.c -o build/6_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_3/platform.c -o build/6_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/astalgo.c -o build/5_3/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/astalgo.c -o build/5_3/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/extccomp.c -o build/5_3/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/extccomp.c -o build/5_3/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/osproc.c -o build/5_3/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/osproc.c -o build/5_3/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/streams.c -o build/5_3/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/streams.c -o build/5_3/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lexer.c -o build/5_3/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lexer.c -o build/5_3/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/main.c -o build/5_3/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/main.c -o build/5_3/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/types.c -o build/5_3/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/types.c -o build/5_3/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/rodwrite.c -o build/5_3/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/rodwrite.c -o build/5_3/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/magicsys.c -o build/5_3/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/magicsys.c -o build/5_3/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semthreads.c -o build/5_3/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semthreads.c -o build/5_3/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/importer.c -o build/5_3/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/importer.c -o build/5_3/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lookups.c -o build/5_3/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lookups.c -o build/5_3/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semdata.c -o build/5_3/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semdata.c -o build/5_3/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/evals.c -o build/5_3/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/evals.c -o build/5_3/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semfold.c -o build/5_3/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semfold.c -o build/5_3/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/cgmeth.c -o build/5_3/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/cgmeth.c -o build/5_3/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sempass2.c -o build/5_3/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sempass2.c -o build/5_3/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lambdalifting.c -o build/5_3/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lambdalifting.c -o build/5_3/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sem.c -o build/5_3/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sem.c -o build/5_3/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/pragmas.c -o build/5_3/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/pragmas.c -o build/5_3/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sigmatch.c -o build/5_3/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sigmatch.c -o build/5_3/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/parampatterns.c -o build/5_3/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/parampatterns.c -o build/5_3/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/docgen.c -o build/5_3/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/docgen.c -o build/5_3/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/rstgen.c -o build/5_3/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/rstgen.c -o build/5_3/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/patterns.c -o build/5_3/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/patterns.c -o build/5_3/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/cgen.c -o build/5_3/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/cgen.c -o build/5_3/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ccgutils.c -o build/5_3/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ccgutils.c -o build/5_3/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ccgmerge.c -o build/5_3/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ccgmerge.c -o build/5_3/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/jsgen.c -o build/5_3/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/jsgen.c -o build/5_3/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/json.c -o build/5_3/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/json.c -o build/5_3/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/depends.c -o build/5_3/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/depends.c -o build/5_3/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/docgen2.c -o build/5_3/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/docgen2.c -o build/5_3/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/service.c -o build/5_3/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/service.c -o build/5_3/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_3/nimrod.o \
build/5_3/system.o \
build/4_3/commands.o \
build/6_3/os.o \
build/5_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_3/msgs.o \
build/5_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_3/sockets.o \
build/5_3/ropes.o \
build/6_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/5_2/idgen.o \
build/5_3/astalgo.o \
build/5_2/rodutils.o \
build/5_3/extccomp.o \
build/5_3/osproc.o \
build/5_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/5_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/5_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/5_3/rodwrite.o \
build/2_2/passes.o \
build/5_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/5_3/semthreads.o \
build/5_3/importer.o \
build/5_3/lookups.o \
build/5_3/semdata.o \
build/2_3/treetab.o \
build/5_3/evals.o \
build/5_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/5_3/cgmeth.o \
build/5_3/sempass2.o \
build/5_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/5_3/sem.o \
build/5_2/procfind.o \
build/5_3/pragmas.o \
build/4_3/semtypinst.o \
build/5_3/sigmatch.o \
build/5_3/parampatterns.o \
build/5_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/5_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_3/patterns.o \
build/5_3/cgen.o \
build/5_3/ccgutils.o \
build/2_3/cgendata.o \
build/5_3/ccgmerge.o \
build/5_3/jsgen.o \
build/5_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/5_3/depends.o \
build/5_3/docgen2.o \
build/5_3/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_3/nimrod.o \
build/5_3/system.o \
build/4_3/commands.o \
build/6_3/os.o \
build/5_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_3/msgs.o \
build/5_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_3/sockets.o \
build/5_3/ropes.o \
build/6_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/5_2/idgen.o \
build/5_3/astalgo.o \
build/5_2/rodutils.o \
build/5_3/extccomp.o \
build/5_3/osproc.o \
build/5_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/5_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/5_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/5_3/rodwrite.o \
build/2_2/passes.o \
build/5_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/5_3/semthreads.o \
build/5_3/importer.o \
build/5_3/lookups.o \
build/5_3/semdata.o \
build/2_3/treetab.o \
build/5_3/evals.o \
build/5_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/5_3/cgmeth.o \
build/5_3/sempass2.o \
build/5_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/5_3/sem.o \
build/5_2/procfind.o \
build/5_3/pragmas.o \
build/4_3/semtypinst.o \
build/5_3/sigmatch.o \
build/5_3/parampatterns.o \
build/5_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/5_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_3/patterns.o \
build/5_3/cgen.o \
build/5_3/ccgutils.o \
build/2_3/cgendata.o \
build/5_3/ccgmerge.o \
build/5_3/jsgen.o \
build/5_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/5_3/depends.o \
build/5_3/docgen2.o \
build/5_3/service.o \
build/2_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/nimrod.c -o build/5_4/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/nimrod.c -o build/5_4/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/system.c -o build/5_4/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/system.c -o build/5_4/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_4/os.c -o build/6_4/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_4/os.c -o build/6_4/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/strutils.c -o build/5_4/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/strutils.c -o build/5_4/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/msgs.c -o build/5_4/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/msgs.c -o build/5_4/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/options.c -o build/5_4/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/options.c -o build/5_4/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sockets.c -o build/5_4/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sockets.c -o build/5_4/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ropes.c -o build/5_4/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ropes.c -o build/5_4/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_4/platform.c -o build/6_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_4/platform.c -o build/6_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/astalgo.c -o build/5_4/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/astalgo.c -o build/5_4/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/extccomp.c -o build/5_4/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/extccomp.c -o build/5_4/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/osproc.c -o build/5_4/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/osproc.c -o build/5_4/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/streams.c -o build/5_4/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/streams.c -o build/5_4/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lexer.c -o build/5_4/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lexer.c -o build/5_4/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/main.c -o build/5_4/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/main.c -o build/5_4/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/types.c -o build/5_4/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/types.c -o build/5_4/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/rodwrite.c -o build/5_4/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/rodwrite.c -o build/5_4/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/magicsys.c -o build/5_4/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/magicsys.c -o build/5_4/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semthreads.c -o build/5_4/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semthreads.c -o build/5_4/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/importer.c -o build/5_4/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/importer.c -o build/5_4/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lookups.c -o build/5_4/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lookups.c -o build/5_4/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semdata.c -o build/5_4/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semdata.c -o build/5_4/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/evals.c -o build/5_4/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/evals.c -o build/5_4/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semfold.c -o build/5_4/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semfold.c -o build/5_4/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/cgmeth.c -o build/5_4/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/cgmeth.c -o build/5_4/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sempass2.c -o build/5_4/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sempass2.c -o build/5_4/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lambdalifting.c -o build/5_4/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lambdalifting.c -o build/5_4/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sem.c -o build/5_4/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sem.c -o build/5_4/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/pragmas.c -o build/5_4/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/pragmas.c -o build/5_4/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sigmatch.c -o build/5_4/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sigmatch.c -o build/5_4/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/parampatterns.c -o build/5_4/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/parampatterns.c -o build/5_4/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/docgen.c -o build/5_4/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/docgen.c -o build/5_4/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/rstgen.c -o build/5_4/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/rstgen.c -o build/5_4/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/patterns.c -o build/5_4/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/patterns.c -o build/5_4/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/cgen.c -o build/5_4/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/cgen.c -o build/5_4/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ccgutils.c -o build/5_4/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ccgutils.c -o build/5_4/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ccgmerge.c -o build/5_4/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ccgmerge.c -o build/5_4/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/jsgen.c -o build/5_4/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/jsgen.c -o build/5_4/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/json.c -o build/5_4/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/json.c -o build/5_4/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/depends.c -o build/5_4/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/depends.c -o build/5_4/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/docgen2.c -o build/5_4/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/docgen2.c -o build/5_4/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/service.c -o build/5_4/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/service.c -o build/5_4/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_4/nimrod.o \
build/5_4/system.o \
build/4_4/commands.o \
build/6_4/os.o \
build/5_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_4/msgs.o \
build/5_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_4/sockets.o \
build/5_4/ropes.o \
build/6_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/5_1/idgen.o \
build/5_4/astalgo.o \
build/5_1/rodutils.o \
build/5_4/extccomp.o \
build/5_4/osproc.o \
build/5_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/5_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/5_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/5_4/rodwrite.o \
build/2_1/passes.o \
build/5_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/5_4/semthreads.o \
build/5_4/importer.o \
build/5_4/lookups.o \
build/5_4/semdata.o \
build/2_4/treetab.o \
build/5_4/evals.o \
build/5_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/5_4/cgmeth.o \
build/5_4/sempass2.o \
build/5_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/5_4/sem.o \
build/5_1/procfind.o \
build/5_4/pragmas.o \
build/4_4/semtypinst.o \
build/5_4/sigmatch.o \
build/5_4/parampatterns.o \
build/5_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/5_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_4/patterns.o \
build/5_4/cgen.o \
build/5_4/ccgutils.o \
build/2_4/cgendata.o \
build/5_4/ccgmerge.o \
build/5_4/jsgen.o \
build/5_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/5_4/depends.o \
build/5_4/docgen2.o \
build/5_4/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_4/nimrod.o \
build/5_4/system.o \
build/4_4/commands.o \
build/6_4/os.o \
build/5_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_4/msgs.o \
build/5_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_4/sockets.o \
build/5_4/ropes.o \
build/6_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/5_1/idgen.o \
build/5_4/astalgo.o \
build/5_1/rodutils.o \
build/5_4/extccomp.o \
build/5_4/osproc.o \
build/5_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/5_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/5_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/5_4/rodwrite.o \
build/2_1/passes.o \
build/5_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/5_4/semthreads.o \
build/5_4/importer.o \
build/5_4/lookups.o \
build/5_4/semdata.o \
build/2_4/treetab.o \
build/5_4/evals.o \
build/5_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/5_4/cgmeth.o \
build/5_4/sempass2.o \
build/5_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/5_4/sem.o \
build/5_1/procfind.o \
build/5_4/pragmas.o \
build/4_4/semtypinst.o \
build/5_4/sigmatch.o \
build/5_4/parampatterns.o \
build/5_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/5_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_4/patterns.o \
build/5_4/cgen.o \
build/5_4/ccgutils.o \
build/2_4/cgendata.o \
build/5_4/ccgmerge.o \
build/5_4/jsgen.o \
build/5_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/5_4/depends.o \
build/5_4/docgen2.o \
build/5_4/service.o \
build/2_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
openbsd) 
  case $mycpu in
  i386)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/nimrod.c -o build/5_1/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/nimrod.c -o build/5_1/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/system.c -o build/5_1/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/system.c -o build/5_1/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/commands.c -o build/4_1/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_1/os.c -o build/6_1/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_1/os.c -o build/6_1/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/strutils.c -o build/5_1/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/strutils.c -o build/5_1/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parseutils.c -o build/4_1/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/msgs.c -o build/5_1/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/msgs.c -o build/5_1/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/options.c -o build/5_1/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/options.c -o build/5_1/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lists.c -o build/2_1/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/strtabs.c -o build/4_1/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sockets.c -o build/5_1/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sockets.c -o build/5_1/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ropes.c -o build/5_1/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ropes.c -o build/5_1/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/7_1/platform.c -o build/7_1/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/7_1/platform.c -o build/7_1/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/condsyms.c -o build/2_1/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/ast.c -o build/4_1/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/idents.c -o build/2_1/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/intsets.c -o build/2_1/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/astalgo.c -o build/5_1/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/astalgo.c -o build/5_1/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/extccomp.c -o build/5_1/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/extccomp.c -o build/5_1/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/osproc.c -o build/5_1/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/osproc.c -o build/5_1/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/streams.c -o build/5_1/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/streams.c -o build/5_1/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lexer.c -o build/5_1/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lexer.c -o build/5_1/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/llstream.c -o build/4_1/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimconf.c -o build/4_1/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/main.c -o build/5_1/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/main.c -o build/5_1/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/parser.c -o build/4_1/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/renderer.c -o build/4_1/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rodread.c -o build/4_1/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/types.c -o build/5_1/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/types.c -o build/5_1/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/trees.c -o build/2_1/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodwrite.c -o build/5_1/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodwrite.c -o build/5_1/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/magicsys.c -o build/5_1/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/magicsys.c -o build/5_1/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimsets.c -o build/4_1/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semthreads.c -o build/5_1/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semthreads.c -o build/5_1/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/importer.c -o build/5_1/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/importer.c -o build/5_1/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lookups.c -o build/5_1/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lookups.c -o build/5_1/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semdata.c -o build/5_1/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semdata.c -o build/5_1/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/treetab.c -o build/2_1/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/evals.c -o build/5_1/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/evals.c -o build/5_1/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/semfold.c -o build/5_1/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/semfold.c -o build/5_1/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/transf.c -o build/4_1/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/cgmeth.c -o build/5_1/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/cgmeth.c -o build/5_1/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sempass2.c -o build/5_1/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sempass2.c -o build/5_1/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/lambdalifting.c -o build/5_1/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/lambdalifting.c -o build/5_1/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/evaltempl.c -o build/4_1/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sem.c -o build/5_1/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sem.c -o build/5_1/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/pragmas.c -o build/5_1/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/pragmas.c -o build/5_1/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/semtypinst.c -o build/4_1/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/sigmatch.c -o build/5_1/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/sigmatch.c -o build/5_1/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/parampatterns.c -o build/5_1/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/parampatterns.c -o build/5_1/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/docgen.c -o build/5_1/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/docgen.c -o build/5_1/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rstast.c -o build/4_1/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/rst.c -o build/4_1/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rstgen.c -o build/5_1/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rstgen.c -o build/5_1/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/patterns.c -o build/5_1/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/patterns.c -o build/5_1/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/cgen.c -o build/5_1/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/cgen.c -o build/5_1/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ccgutils.c -o build/5_1/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ccgutils.c -o build/5_1/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/cgendata.c -o build/2_1/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/ccgmerge.c -o build/5_1/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/ccgmerge.c -o build/5_1/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/jsgen.c -o build/5_1/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/jsgen.c -o build/5_1/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/json.c -o build/5_1/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/json.c -o build/5_1/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/passaux.c -o build/4_1/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/depends.c -o build/5_1/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/depends.c -o build/5_1/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/docgen2.c -o build/5_1/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/docgen2.c -o build/5_1/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/service.c -o build/5_1/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/service.c -o build/5_1/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_1/nimrod.o \
build/5_1/system.o \
build/4_1/commands.o \
build/6_1/os.o \
build/5_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_1/msgs.o \
build/5_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_1/sockets.o \
build/5_1/ropes.o \
build/7_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/5_1/idgen.o \
build/5_1/astalgo.o \
build/5_1/rodutils.o \
build/5_1/extccomp.o \
build/5_1/osproc.o \
build/5_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/5_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/5_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/5_1/rodwrite.o \
build/2_1/passes.o \
build/5_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/5_1/semthreads.o \
build/5_1/importer.o \
build/5_1/lookups.o \
build/5_1/semdata.o \
build/2_1/treetab.o \
build/5_1/evals.o \
build/5_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/5_1/cgmeth.o \
build/5_1/sempass2.o \
build/5_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/5_1/sem.o \
build/5_1/procfind.o \
build/5_1/pragmas.o \
build/4_1/semtypinst.o \
build/5_1/sigmatch.o \
build/5_1/parampatterns.o \
build/5_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/5_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_1/patterns.o \
build/5_1/cgen.o \
build/5_1/ccgutils.o \
build/2_1/cgendata.o \
build/5_1/ccgmerge.o \
build/5_1/jsgen.o \
build/5_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/5_1/depends.o \
build/5_1/docgen2.o \
build/5_1/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_1/nimrod.o \
build/5_1/system.o \
build/4_1/commands.o \
build/6_1/os.o \
build/5_1/strutils.o \
build/4_1/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_1/msgs.o \
build/5_1/options.o \
build/2_1/lists.o \
build/4_1/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_1/sockets.o \
build/5_1/ropes.o \
build/7_1/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_1/condsyms.o \
build/4_1/ast.o \
build/2_1/idents.o \
build/2_1/intsets.o \
build/5_1/idgen.o \
build/5_1/astalgo.o \
build/5_1/rodutils.o \
build/5_1/extccomp.o \
build/5_1/osproc.o \
build/5_1/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_1/lexer.o \
build/4_1/nimlexbase.o \
build/4_1/llstream.o \
build/4_1/nimconf.o \
build/5_1/main.o \
build/4_1/syntaxes.o \
build/4_1/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_1/renderer.o \
build/4_1/filter_tmpl.o \
build/4_1/rodread.o \
build/5_1/types.o \
build/2_1/trees.o \
build/4_1/memfiles.o \
build/5_1/rodwrite.o \
build/2_1/passes.o \
build/5_1/magicsys.o \
build/4_1/nimsets.o \
build/4_1/bitsets.o \
build/5_1/semthreads.o \
build/5_1/importer.o \
build/5_1/lookups.o \
build/5_1/semdata.o \
build/2_1/treetab.o \
build/5_1/evals.o \
build/5_1/semfold.o \
build/2_1/saturate.o \
build/4_1/transf.o \
build/5_1/cgmeth.o \
build/5_1/sempass2.o \
build/5_1/lambdalifting.o \
build/4_1/evaltempl.o \
build/5_1/sem.o \
build/5_1/procfind.o \
build/5_1/pragmas.o \
build/4_1/semtypinst.o \
build/5_1/sigmatch.o \
build/5_1/parampatterns.o \
build/5_1/docgen.o \
build/4_1/rstast.o \
build/4_1/rst.o \
build/5_1/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_1/patterns.o \
build/5_1/cgen.o \
build/5_1/ccgutils.o \
build/2_1/cgendata.o \
build/5_1/ccgmerge.o \
build/5_1/jsgen.o \
build/5_1/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_1/passaux.o \
build/5_1/depends.o \
build/5_1/docgen2.o \
build/5_1/service.o \
build/2_1/parseopt.o
    ;;
  amd64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/nimrod.c -o build/5_2/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/nimrod.c -o build/5_2/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/system.c -o build/5_2/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/system.c -o build/5_2/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/commands.c -o build/4_2/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_2/os.c -o build/6_2/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_2/os.c -o build/6_2/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/strutils.c -o build/5_2/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/strutils.c -o build/5_2/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parseutils.c -o build/4_2/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/msgs.c -o build/5_2/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/msgs.c -o build/5_2/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/options.c -o build/5_2/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/options.c -o build/5_2/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lists.c -o build/2_2/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/strtabs.c -o build/4_2/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sockets.c -o build/5_2/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sockets.c -o build/5_2/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ropes.c -o build/5_2/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ropes.c -o build/5_2/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/7_2/platform.c -o build/7_2/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/7_2/platform.c -o build/7_2/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/condsyms.c -o build/2_2/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/ast.c -o build/4_2/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/idents.c -o build/2_2/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/intsets.c -o build/2_2/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/astalgo.c -o build/5_2/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/astalgo.c -o build/5_2/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/extccomp.c -o build/5_2/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/extccomp.c -o build/5_2/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/osproc.c -o build/5_2/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/osproc.c -o build/5_2/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/streams.c -o build/5_2/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/streams.c -o build/5_2/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lexer.c -o build/5_2/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lexer.c -o build/5_2/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/llstream.c -o build/4_2/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimconf.c -o build/4_2/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/main.c -o build/5_2/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/main.c -o build/5_2/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/parser.c -o build/4_2/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/renderer.c -o build/4_2/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rodread.c -o build/4_2/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/types.c -o build/5_2/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/types.c -o build/5_2/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/trees.c -o build/2_2/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodwrite.c -o build/5_2/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodwrite.c -o build/5_2/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/magicsys.c -o build/5_2/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/magicsys.c -o build/5_2/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimsets.c -o build/4_2/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semthreads.c -o build/5_2/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semthreads.c -o build/5_2/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/importer.c -o build/5_2/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/importer.c -o build/5_2/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lookups.c -o build/5_2/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lookups.c -o build/5_2/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semdata.c -o build/5_2/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semdata.c -o build/5_2/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/treetab.c -o build/2_2/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/evals.c -o build/5_2/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/evals.c -o build/5_2/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/semfold.c -o build/5_2/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/semfold.c -o build/5_2/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/transf.c -o build/4_2/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/cgmeth.c -o build/5_2/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/cgmeth.c -o build/5_2/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sempass2.c -o build/5_2/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sempass2.c -o build/5_2/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/lambdalifting.c -o build/5_2/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/lambdalifting.c -o build/5_2/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/evaltempl.c -o build/4_2/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sem.c -o build/5_2/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sem.c -o build/5_2/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/pragmas.c -o build/5_2/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/pragmas.c -o build/5_2/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/semtypinst.c -o build/4_2/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/sigmatch.c -o build/5_2/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/sigmatch.c -o build/5_2/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/parampatterns.c -o build/5_2/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/parampatterns.c -o build/5_2/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/docgen.c -o build/5_2/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/docgen.c -o build/5_2/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rstast.c -o build/4_2/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/rst.c -o build/4_2/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rstgen.c -o build/5_2/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rstgen.c -o build/5_2/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/patterns.c -o build/5_2/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/patterns.c -o build/5_2/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/cgen.c -o build/5_2/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/cgen.c -o build/5_2/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ccgutils.c -o build/5_2/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ccgutils.c -o build/5_2/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/cgendata.c -o build/2_2/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/ccgmerge.c -o build/5_2/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/ccgmerge.c -o build/5_2/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/jsgen.c -o build/5_2/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/jsgen.c -o build/5_2/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/json.c -o build/5_2/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/json.c -o build/5_2/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/passaux.c -o build/4_2/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/depends.c -o build/5_2/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/depends.c -o build/5_2/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/docgen2.c -o build/5_2/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/docgen2.c -o build/5_2/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/service.c -o build/5_2/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/service.c -o build/5_2/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_2/nimrod.o \
build/5_2/system.o \
build/4_2/commands.o \
build/6_2/os.o \
build/5_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_2/msgs.o \
build/5_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_2/sockets.o \
build/5_2/ropes.o \
build/7_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/5_2/idgen.o \
build/5_2/astalgo.o \
build/5_2/rodutils.o \
build/5_2/extccomp.o \
build/5_2/osproc.o \
build/5_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/5_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/5_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/5_2/rodwrite.o \
build/2_2/passes.o \
build/5_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/5_2/semthreads.o \
build/5_2/importer.o \
build/5_2/lookups.o \
build/5_2/semdata.o \
build/2_2/treetab.o \
build/5_2/evals.o \
build/5_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/5_2/cgmeth.o \
build/5_2/sempass2.o \
build/5_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/5_2/sem.o \
build/5_2/procfind.o \
build/5_2/pragmas.o \
build/4_2/semtypinst.o \
build/5_2/sigmatch.o \
build/5_2/parampatterns.o \
build/5_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/5_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_2/patterns.o \
build/5_2/cgen.o \
build/5_2/ccgutils.o \
build/2_2/cgendata.o \
build/5_2/ccgmerge.o \
build/5_2/jsgen.o \
build/5_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/5_2/depends.o \
build/5_2/docgen2.o \
build/5_2/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_2/nimrod.o \
build/5_2/system.o \
build/4_2/commands.o \
build/6_2/os.o \
build/5_2/strutils.o \
build/4_2/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_2/msgs.o \
build/5_2/options.o \
build/2_2/lists.o \
build/4_2/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_2/sockets.o \
build/5_2/ropes.o \
build/7_2/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_2/condsyms.o \
build/4_2/ast.o \
build/2_2/idents.o \
build/2_2/intsets.o \
build/5_2/idgen.o \
build/5_2/astalgo.o \
build/5_2/rodutils.o \
build/5_2/extccomp.o \
build/5_2/osproc.o \
build/5_2/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_2/lexer.o \
build/4_2/nimlexbase.o \
build/4_2/llstream.o \
build/4_2/nimconf.o \
build/5_2/main.o \
build/4_2/syntaxes.o \
build/4_2/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_2/renderer.o \
build/4_2/filter_tmpl.o \
build/4_2/rodread.o \
build/5_2/types.o \
build/2_2/trees.o \
build/4_2/memfiles.o \
build/5_2/rodwrite.o \
build/2_2/passes.o \
build/5_2/magicsys.o \
build/4_2/nimsets.o \
build/4_2/bitsets.o \
build/5_2/semthreads.o \
build/5_2/importer.o \
build/5_2/lookups.o \
build/5_2/semdata.o \
build/2_2/treetab.o \
build/5_2/evals.o \
build/5_2/semfold.o \
build/2_2/saturate.o \
build/4_2/transf.o \
build/5_2/cgmeth.o \
build/5_2/sempass2.o \
build/5_2/lambdalifting.o \
build/4_2/evaltempl.o \
build/5_2/sem.o \
build/5_2/procfind.o \
build/5_2/pragmas.o \
build/4_2/semtypinst.o \
build/5_2/sigmatch.o \
build/5_2/parampatterns.o \
build/5_2/docgen.o \
build/4_2/rstast.o \
build/4_2/rst.o \
build/5_2/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_2/patterns.o \
build/5_2/cgen.o \
build/5_2/ccgutils.o \
build/2_2/cgendata.o \
build/5_2/ccgmerge.o \
build/5_2/jsgen.o \
build/5_2/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_2/passaux.o \
build/5_2/depends.o \
build/5_2/docgen2.o \
build/5_2/service.o \
build/2_2/parseopt.o
    ;;
  powerpc64)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/nimrod.c -o build/5_3/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/nimrod.c -o build/5_3/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/system.c -o build/5_3/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/system.c -o build/5_3/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/commands.c -o build/4_3/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_3/os.c -o build/6_3/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_3/os.c -o build/6_3/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/strutils.c -o build/5_3/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/strutils.c -o build/5_3/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parseutils.c -o build/4_3/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/times.c -o build/4_2/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_2/posix.c -o build/3_2/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/msgs.c -o build/5_3/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/msgs.c -o build/5_3/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/options.c -o build/5_3/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/options.c -o build/5_3/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/lists.c -o build/2_3/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/strtabs.c -o build/4_3/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/hashes.c -o build/2_2/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/tables.c -o build/5_2/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/math.c -o build/2_2/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sockets.c -o build/5_3/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sockets.c -o build/5_3/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ropes.c -o build/5_3/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ropes.c -o build/5_3/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/7_3/platform.c -o build/7_3/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/7_3/platform.c -o build/7_3/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/crc.c -o build/2_2/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/nversion.c -o build/2_2/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/condsyms.c -o build/2_3/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/ast.c -o build/4_3/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/idents.c -o build/2_3/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/intsets.c -o build/2_3/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/idgen.c -o build/5_2/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/astalgo.c -o build/5_3/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/astalgo.c -o build/5_3/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/rodutils.c -o build/5_2/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/extccomp.c -o build/5_3/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/extccomp.c -o build/5_3/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/osproc.c -o build/5_3/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/osproc.c -o build/5_3/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/streams.c -o build/5_3/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/streams.c -o build/5_3/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/wordrecg.c -o build/2_2/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/babelcmd.c -o build/4_2/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lexer.c -o build/5_3/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lexer.c -o build/5_3/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/nimlexbase.c -o build/4_2/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/llstream.c -o build/4_3/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimconf.c -o build/4_3/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/main.c -o build/5_3/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/main.c -o build/5_3/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/syntaxes.c -o build/4_2/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/parser.c -o build/4_3/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/pbraces.c -o build/2_2/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filters.c -o build/4_2/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/renderer.c -o build/4_3/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/filter_tmpl.c -o build/4_2/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rodread.c -o build/4_3/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/types.c -o build/5_3/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/types.c -o build/5_3/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/trees.c -o build/2_3/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/memfiles.c -o build/4_2/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/rodwrite.c -o build/5_3/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/rodwrite.c -o build/5_3/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/passes.c -o build/2_2/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/magicsys.c -o build/5_3/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/magicsys.c -o build/5_3/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/nimsets.c -o build/4_3/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/bitsets.c -o build/4_2/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semthreads.c -o build/5_3/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semthreads.c -o build/5_3/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/importer.c -o build/5_3/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/importer.c -o build/5_3/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lookups.c -o build/5_3/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lookups.c -o build/5_3/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semdata.c -o build/5_3/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semdata.c -o build/5_3/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/treetab.c -o build/2_3/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/evals.c -o build/5_3/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/evals.c -o build/5_3/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/semfold.c -o build/5_3/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/semfold.c -o build/5_3/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/saturate.c -o build/2_2/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/transf.c -o build/4_3/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/cgmeth.c -o build/5_3/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/cgmeth.c -o build/5_3/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sempass2.c -o build/5_3/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sempass2.c -o build/5_3/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/lambdalifting.c -o build/5_3/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/lambdalifting.c -o build/5_3/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/evaltempl.c -o build/4_3/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sem.c -o build/5_3/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sem.c -o build/5_3/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/procfind.c -o build/5_2/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/pragmas.c -o build/5_3/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/pragmas.c -o build/5_3/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/semtypinst.c -o build/4_3/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/sigmatch.c -o build/5_3/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/sigmatch.c -o build/5_3/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/parampatterns.c -o build/5_3/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/parampatterns.c -o build/5_3/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/docgen.c -o build/5_3/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/docgen.c -o build/5_3/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rstast.c -o build/4_3/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/rst.c -o build/4_3/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/rstgen.c -o build/5_3/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/rstgen.c -o build/5_3/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_2/highlite.c -o build/4_2/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/algorithm.c -o build/2_2/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_2/aliases.c -o build/5_2/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/patterns.c -o build/5_3/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/patterns.c -o build/5_3/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/cgen.c -o build/5_3/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/cgen.c -o build/5_3/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ccgutils.c -o build/5_3/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ccgutils.c -o build/5_3/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_3/cgendata.c -o build/2_3/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/ccgmerge.c -o build/5_3/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/ccgmerge.c -o build/5_3/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/jsgen.c -o build/5_3/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/jsgen.c -o build/5_3/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/json.c -o build/5_3/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/json.c -o build/5_3/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/lexbase.c -o build/2_2/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/unicode.c -o build/2_2/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_3/passaux.c -o build/4_3/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/depends.c -o build/5_3/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/depends.c -o build/5_3/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/docgen2.c -o build/5_3/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/docgen2.c -o build/5_3/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_3/service.c -o build/5_3/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_3/service.c -o build/5_3/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_2/parseopt.c -o build/2_2/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_3/nimrod.o \
build/5_3/system.o \
build/4_3/commands.o \
build/6_3/os.o \
build/5_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_3/msgs.o \
build/5_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_3/sockets.o \
build/5_3/ropes.o \
build/7_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/5_2/idgen.o \
build/5_3/astalgo.o \
build/5_2/rodutils.o \
build/5_3/extccomp.o \
build/5_3/osproc.o \
build/5_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/5_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/5_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/5_3/rodwrite.o \
build/2_2/passes.o \
build/5_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/5_3/semthreads.o \
build/5_3/importer.o \
build/5_3/lookups.o \
build/5_3/semdata.o \
build/2_3/treetab.o \
build/5_3/evals.o \
build/5_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/5_3/cgmeth.o \
build/5_3/sempass2.o \
build/5_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/5_3/sem.o \
build/5_2/procfind.o \
build/5_3/pragmas.o \
build/4_3/semtypinst.o \
build/5_3/sigmatch.o \
build/5_3/parampatterns.o \
build/5_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/5_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_3/patterns.o \
build/5_3/cgen.o \
build/5_3/ccgutils.o \
build/2_3/cgendata.o \
build/5_3/ccgmerge.o \
build/5_3/jsgen.o \
build/5_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/5_3/depends.o \
build/5_3/docgen2.o \
build/5_3/service.o \
build/2_2/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_3/nimrod.o \
build/5_3/system.o \
build/4_3/commands.o \
build/6_3/os.o \
build/5_3/strutils.o \
build/4_3/parseutils.o \
build/4_2/times.o \
build/3_2/posix.o \
build/5_3/msgs.o \
build/5_3/options.o \
build/2_3/lists.o \
build/4_3/strtabs.o \
build/2_2/hashes.o \
build/5_2/tables.o \
build/2_2/math.o \
build/5_3/sockets.o \
build/5_3/ropes.o \
build/7_3/platform.o \
build/2_2/crc.o \
build/2_2/nversion.o \
build/2_3/condsyms.o \
build/4_3/ast.o \
build/2_3/idents.o \
build/2_3/intsets.o \
build/5_2/idgen.o \
build/5_3/astalgo.o \
build/5_2/rodutils.o \
build/5_3/extccomp.o \
build/5_3/osproc.o \
build/5_3/streams.o \
build/2_2/wordrecg.o \
build/4_2/babelcmd.o \
build/5_3/lexer.o \
build/4_2/nimlexbase.o \
build/4_3/llstream.o \
build/4_3/nimconf.o \
build/5_3/main.o \
build/4_2/syntaxes.o \
build/4_3/parser.o \
build/2_2/pbraces.o \
build/4_2/filters.o \
build/4_3/renderer.o \
build/4_2/filter_tmpl.o \
build/4_3/rodread.o \
build/5_3/types.o \
build/2_3/trees.o \
build/4_2/memfiles.o \
build/5_3/rodwrite.o \
build/2_2/passes.o \
build/5_3/magicsys.o \
build/4_3/nimsets.o \
build/4_2/bitsets.o \
build/5_3/semthreads.o \
build/5_3/importer.o \
build/5_3/lookups.o \
build/5_3/semdata.o \
build/2_3/treetab.o \
build/5_3/evals.o \
build/5_3/semfold.o \
build/2_2/saturate.o \
build/4_3/transf.o \
build/5_3/cgmeth.o \
build/5_3/sempass2.o \
build/5_3/lambdalifting.o \
build/4_3/evaltempl.o \
build/5_3/sem.o \
build/5_2/procfind.o \
build/5_3/pragmas.o \
build/4_3/semtypinst.o \
build/5_3/sigmatch.o \
build/5_3/parampatterns.o \
build/5_3/docgen.o \
build/4_3/rstast.o \
build/4_3/rst.o \
build/5_3/rstgen.o \
build/4_2/highlite.o \
build/2_2/algorithm.o \
build/5_2/aliases.o \
build/5_3/patterns.o \
build/5_3/cgen.o \
build/5_3/ccgutils.o \
build/2_3/cgendata.o \
build/5_3/ccgmerge.o \
build/5_3/jsgen.o \
build/5_3/json.o \
build/2_2/lexbase.o \
build/2_2/unicode.o \
build/4_3/passaux.o \
build/5_3/depends.o \
build/5_3/docgen2.o \
build/5_3/service.o \
build/2_2/parseopt.o
    ;;
  arm)
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/nimrod.c -o build/5_4/nimrod.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/nimrod.c -o build/5_4/nimrod.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/system.c -o build/5_4/system.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/system.c -o build/5_4/system.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/commands.c -o build/4_4/commands.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/6_4/os.c -o build/6_4/os.o"
    $CC $COMP_FLAGS -Ibuild -c build/6_4/os.c -o build/6_4/os.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/strutils.c -o build/5_4/strutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/strutils.c -o build/5_4/strutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parseutils.c -o build/4_4/parseutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/times.c -o build/4_1/times.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o"
    $CC $COMP_FLAGS -Ibuild -c build/3_1/posix.c -o build/3_1/posix.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/msgs.c -o build/5_4/msgs.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/msgs.c -o build/5_4/msgs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/options.c -o build/5_4/options.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/options.c -o build/5_4/options.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/lists.c -o build/2_4/lists.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/strtabs.c -o build/4_4/strtabs.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/hashes.c -o build/2_1/hashes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/tables.c -o build/5_1/tables.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/math.c -o build/2_1/math.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sockets.c -o build/5_4/sockets.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sockets.c -o build/5_4/sockets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ropes.c -o build/5_4/ropes.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ropes.c -o build/5_4/ropes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/7_4/platform.c -o build/7_4/platform.o"
    $CC $COMP_FLAGS -Ibuild -c build/7_4/platform.c -o build/7_4/platform.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/crc.c -o build/2_1/crc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/nversion.c -o build/2_1/nversion.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/condsyms.c -o build/2_4/condsyms.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/ast.c -o build/4_4/ast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/idents.c -o build/2_4/idents.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/intsets.c -o build/2_4/intsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/idgen.c -o build/5_1/idgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/astalgo.c -o build/5_4/astalgo.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/astalgo.c -o build/5_4/astalgo.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/rodutils.c -o build/5_1/rodutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/extccomp.c -o build/5_4/extccomp.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/extccomp.c -o build/5_4/extccomp.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/osproc.c -o build/5_4/osproc.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/osproc.c -o build/5_4/osproc.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/streams.c -o build/5_4/streams.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/streams.c -o build/5_4/streams.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/wordrecg.c -o build/2_1/wordrecg.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/babelcmd.c -o build/4_1/babelcmd.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lexer.c -o build/5_4/lexer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lexer.c -o build/5_4/lexer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/nimlexbase.c -o build/4_1/nimlexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/llstream.c -o build/4_4/llstream.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimconf.c -o build/4_4/nimconf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/main.c -o build/5_4/main.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/main.c -o build/5_4/main.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/syntaxes.c -o build/4_1/syntaxes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/parser.c -o build/4_4/parser.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/pbraces.c -o build/2_1/pbraces.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filters.c -o build/4_1/filters.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/renderer.c -o build/4_4/renderer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/filter_tmpl.c -o build/4_1/filter_tmpl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rodread.c -o build/4_4/rodread.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/types.c -o build/5_4/types.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/types.c -o build/5_4/types.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/trees.c -o build/2_4/trees.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/memfiles.c -o build/4_1/memfiles.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/rodwrite.c -o build/5_4/rodwrite.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/rodwrite.c -o build/5_4/rodwrite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/passes.c -o build/2_1/passes.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/magicsys.c -o build/5_4/magicsys.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/magicsys.c -o build/5_4/magicsys.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/nimsets.c -o build/4_4/nimsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/bitsets.c -o build/4_1/bitsets.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semthreads.c -o build/5_4/semthreads.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semthreads.c -o build/5_4/semthreads.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/importer.c -o build/5_4/importer.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/importer.c -o build/5_4/importer.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lookups.c -o build/5_4/lookups.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lookups.c -o build/5_4/lookups.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semdata.c -o build/5_4/semdata.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semdata.c -o build/5_4/semdata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/treetab.c -o build/2_4/treetab.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/evals.c -o build/5_4/evals.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/evals.c -o build/5_4/evals.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/semfold.c -o build/5_4/semfold.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/semfold.c -o build/5_4/semfold.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/saturate.c -o build/2_1/saturate.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/transf.c -o build/4_4/transf.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/cgmeth.c -o build/5_4/cgmeth.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/cgmeth.c -o build/5_4/cgmeth.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sempass2.c -o build/5_4/sempass2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sempass2.c -o build/5_4/sempass2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/lambdalifting.c -o build/5_4/lambdalifting.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/lambdalifting.c -o build/5_4/lambdalifting.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/evaltempl.c -o build/4_4/evaltempl.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sem.c -o build/5_4/sem.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sem.c -o build/5_4/sem.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/procfind.c -o build/5_1/procfind.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/pragmas.c -o build/5_4/pragmas.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/pragmas.c -o build/5_4/pragmas.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/semtypinst.c -o build/4_4/semtypinst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/sigmatch.c -o build/5_4/sigmatch.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/sigmatch.c -o build/5_4/sigmatch.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/parampatterns.c -o build/5_4/parampatterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/parampatterns.c -o build/5_4/parampatterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/docgen.c -o build/5_4/docgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/docgen.c -o build/5_4/docgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rstast.c -o build/4_4/rstast.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/rst.c -o build/4_4/rst.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/rstgen.c -o build/5_4/rstgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/rstgen.c -o build/5_4/rstgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_1/highlite.c -o build/4_1/highlite.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/algorithm.c -o build/2_1/algorithm.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_1/aliases.c -o build/5_1/aliases.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/patterns.c -o build/5_4/patterns.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/patterns.c -o build/5_4/patterns.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/cgen.c -o build/5_4/cgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/cgen.c -o build/5_4/cgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ccgutils.c -o build/5_4/ccgutils.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ccgutils.c -o build/5_4/ccgutils.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_4/cgendata.c -o build/2_4/cgendata.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/ccgmerge.c -o build/5_4/ccgmerge.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/ccgmerge.c -o build/5_4/ccgmerge.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/jsgen.c -o build/5_4/jsgen.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/jsgen.c -o build/5_4/jsgen.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/json.c -o build/5_4/json.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/json.c -o build/5_4/json.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/lexbase.c -o build/2_1/lexbase.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/unicode.c -o build/2_1/unicode.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o"
    $CC $COMP_FLAGS -Ibuild -c build/4_4/passaux.c -o build/4_4/passaux.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/depends.c -o build/5_4/depends.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/depends.c -o build/5_4/depends.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/docgen2.c -o build/5_4/docgen2.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/docgen2.c -o build/5_4/docgen2.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/5_4/service.c -o build/5_4/service.o"
    $CC $COMP_FLAGS -Ibuild -c build/5_4/service.c -o build/5_4/service.o
    echo "$CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o"
    $CC $COMP_FLAGS -Ibuild -c build/2_1/parseopt.c -o build/2_1/parseopt.o
    echo "$LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_4/nimrod.o \
build/5_4/system.o \
build/4_4/commands.o \
build/6_4/os.o \
build/5_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_4/msgs.o \
build/5_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_4/sockets.o \
build/5_4/ropes.o \
build/7_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/5_1/idgen.o \
build/5_4/astalgo.o \
build/5_1/rodutils.o \
build/5_4/extccomp.o \
build/5_4/osproc.o \
build/5_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/5_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/5_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/5_4/rodwrite.o \
build/2_1/passes.o \
build/5_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/5_4/semthreads.o \
build/5_4/importer.o \
build/5_4/lookups.o \
build/5_4/semdata.o \
build/2_4/treetab.o \
build/5_4/evals.o \
build/5_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/5_4/cgmeth.o \
build/5_4/sempass2.o \
build/5_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/5_4/sem.o \
build/5_1/procfind.o \
build/5_4/pragmas.o \
build/4_4/semtypinst.o \
build/5_4/sigmatch.o \
build/5_4/parampatterns.o \
build/5_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/5_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_4/patterns.o \
build/5_4/cgen.o \
build/5_4/ccgutils.o \
build/2_4/cgendata.o \
build/5_4/ccgmerge.o \
build/5_4/jsgen.o \
build/5_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/5_4/depends.o \
build/5_4/docgen2.o \
build/5_4/service.o \
build/2_1/parseopt.o"
    $LINKER $LINK_FLAGS -o bin/nimrod  \
build/5_4/nimrod.o \
build/5_4/system.o \
build/4_4/commands.o \
build/6_4/os.o \
build/5_4/strutils.o \
build/4_4/parseutils.o \
build/4_1/times.o \
build/3_1/posix.o \
build/5_4/msgs.o \
build/5_4/options.o \
build/2_4/lists.o \
build/4_4/strtabs.o \
build/2_1/hashes.o \
build/5_1/tables.o \
build/2_1/math.o \
build/5_4/sockets.o \
build/5_4/ropes.o \
build/7_4/platform.o \
build/2_1/crc.o \
build/2_1/nversion.o \
build/2_4/condsyms.o \
build/4_4/ast.o \
build/2_4/idents.o \
build/2_4/intsets.o \
build/5_1/idgen.o \
build/5_4/astalgo.o \
build/5_1/rodutils.o \
build/5_4/extccomp.o \
build/5_4/osproc.o \
build/5_4/streams.o \
build/2_1/wordrecg.o \
build/4_1/babelcmd.o \
build/5_4/lexer.o \
build/4_1/nimlexbase.o \
build/4_4/llstream.o \
build/4_4/nimconf.o \
build/5_4/main.o \
build/4_1/syntaxes.o \
build/4_4/parser.o \
build/2_1/pbraces.o \
build/4_1/filters.o \
build/4_4/renderer.o \
build/4_1/filter_tmpl.o \
build/4_4/rodread.o \
build/5_4/types.o \
build/2_4/trees.o \
build/4_1/memfiles.o \
build/5_4/rodwrite.o \
build/2_1/passes.o \
build/5_4/magicsys.o \
build/4_4/nimsets.o \
build/4_1/bitsets.o \
build/5_4/semthreads.o \
build/5_4/importer.o \
build/5_4/lookups.o \
build/5_4/semdata.o \
build/2_4/treetab.o \
build/5_4/evals.o \
build/5_4/semfold.o \
build/2_1/saturate.o \
build/4_4/transf.o \
build/5_4/cgmeth.o \
build/5_4/sempass2.o \
build/5_4/lambdalifting.o \
build/4_4/evaltempl.o \
build/5_4/sem.o \
build/5_1/procfind.o \
build/5_4/pragmas.o \
build/4_4/semtypinst.o \
build/5_4/sigmatch.o \
build/5_4/parampatterns.o \
build/5_4/docgen.o \
build/4_4/rstast.o \
build/4_4/rst.o \
build/5_4/rstgen.o \
build/4_1/highlite.o \
build/2_1/algorithm.o \
build/5_1/aliases.o \
build/5_4/patterns.o \
build/5_4/cgen.o \
build/5_4/ccgutils.o \
build/2_4/cgendata.o \
build/5_4/ccgmerge.o \
build/5_4/jsgen.o \
build/5_4/json.o \
build/2_1/lexbase.o \
build/2_1/unicode.o \
build/4_4/passaux.o \
build/5_4/depends.o \
build/5_4/docgen2.o \
build/5_4/service.o \
build/2_1/parseopt.o
    ;;
  *)
    echo "Error: no C code generated for: [$myos: $mycpu]"
    exit 1
    ;;
  esac
  ;;
*) 
  echo "Error: no C code generated for: [$myos: $mycpu]"
  exit 1
  ;;
esac

echo "SUCCESS"

