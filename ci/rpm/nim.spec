# Based on OpenSuse and Arch Linux packaging
# https://build.opensuse.org/projects/openSUSE:Factory/packages/nim/files/nim.spec
# https://gitlab.archlinux.org/archlinux/packaging/packages/nim/-/blob/main/PKGBUILD
%define __nim_harden_config() \
  for file in %*; do \
    echo "gcc.options.always %= \\"\\${gcc.options.always} ${CFLAGS:-%optflags}\\"" >> $file; \
    echo "gcc.options.linker %= \\"\\${gcc.options.linker} ${LDFLAGS:-%__global_ldflags}\\"" >> $file; \
  done

%global bashcompdir     %(pkg-config --variable=completionsdir bash-completion 2>/dev/null)
%global bashcomproot    %(dirname %{bashcompdir} 2>/dev/null)

Name:           nim
Version:        2.2.6
Release:        %{autorelease}
Summary:        A statically typed compiled systems programming language

License:        MIT
URL:            https://nim-lang.org/
Source0:        %{url}/download/nim-%{version}.tar.xz
Source1:        %{url}/download/nim-%{version}.tar.xz.sha256

BuildRequires:  pkgconfig(bash-completion)
BuildRequires:  gcc
BuildRequires:  gc-devel
BuildRequires:  openssl-devel
BuildRequires:  pcre-devel
# Test dependencies
BuildRequires:  gcc-c++
BuildRequires:  git
BuildRequires:  nodejs, /usr/bin/node, /usr/bin/npm
BuildRequires:  nodejs-devel
BuildRequires:  sqlite-devel
BuildRequires:  tzdata
BuildRequires:  valgrind
BuildRequires:  SFML-devel
Requires:       gcc
Recommends:     gcc-c++
Recommends:     nodejs, /usr/bin/node, /usr/bin/npm

%description
Nim is a statically typed compiled systems programming language. It combines
successful concepts from mature languages like Python, Ada and Modula.

%prep
cp %{SOURCE0} .
sha256sum --check %{SOURCE1}
%autosetup


%build
export NIMFLAGS="$(echo '%{optflags}' | sed 's/\([^[:space:]]\+\)/--passC:\1/g')"
export NIMFLAGS="$NIMFLAGS %{?jobs:--parallelBuild:%{jobs}}"

%__nim_harden_config compiler/nim.cfg
%__nim_harden_config config/nim.cfg

# Bootstrap compiler
./build.sh

# Build management tool
./bin/nim c $NIMFLAGS koch
# Build compiler
./koch boot $NIMFLAGS -d:release -d:nativeStacktrace -d:useGnuReadline
# Build tools
./koch toolsNoExternal
# Requires further external dependencies
#koch doc

%install

sed -i "s|bindir=\"\${DESTDIR}\${bindir}\"|bindir=\"\${DESTDIR}%{_bindir}\"|g" install.sh
sed -i "s|configdir=\"\${DESTDIR}\${configdir}\"|configdir=\"\${DESTDIR}%{_sysconfdir}/nim\"|g" install.sh
sed -i "s|libdir=\"\${DESTDIR}\${libdir}\"|libdir=\"\${DESTDIR}%{_libdir}/nim\"|g" install.sh
sed -i "s|docdir=\"\${DESTDIR}\${docdir}\"|docdir=\"\${DESTDIR}%{_docdir}\"|g" install.sh
sed -i "s|datadir=\"\${DESTDIR}\${datadir}\"|datadir=\"\${DESTDIR}%{_datadir}\"|g" install.sh
sed -i "s|nimbleDir=\"\${DESTDIR}\${nimbleDir}\"|nimbleDir=\"\${DESTDIR}%{_libdir}/nim\"|g" install.sh

DESTDIR=%{buildroot} sh install.sh %{_bindir}
 
install -Dp -m755 bin/nim{grep,suggest,pretty,-gdb,_dbg} %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{bashcompdir}/nim
install -Dp -m644 tools/ni{m,mgrep,msuggest,mpretty}.bash-completion %{buildroot}%{bashcompdir}/nim
mkdir -p %{buildroot}%{bashcompdir}/nimble
install -Dp -m644 dist/nimble/nimble.bash-completion %{buildroot}%{bashcompdir}/nimble

%check
cat << EOT >> tests_to_skip
tests/cpp/tasync_cpp.nim
tests/destructor/tv2_raise.nim
tests/errmsgs/tinvalidinout.nim
tests/exception/t13115.nim
tests/ic/tgenerics_temp.nim
tests/lent/tbasic_lent_check.nim
tests/lent/tlents.nim
tests/manyloc/keineschweine/keineschweine.nim
tests/manyloc/nake/nakefile.nim
tests/misc/tstrace.nim
tests/navigator/tincludefile.nim
tests/navigator/tnav1.nim
tests/nimdoc/trunnableexamples.nim
tests/shouldfail/tccodecheck.nim
tests/shouldfail/tcolumn.nim
tests/shouldfail/tcolumn.nim
tests/shouldfail/terrormsg.nim
tests/shouldfail/texitcode1.nim
tests/shouldfail/tfile.nim
tests/shouldfail/tline.nim
tests/shouldfail/tmaxcodesize.nim
tests/shouldfail/tnimout.nim
tests/shouldfail/tnimoutfull.nim
tests/shouldfail/tnotenoughretries.nim
tests/shouldfail/toutput.nim
tests/shouldfail/toutputsub.nim
tests/shouldfail/treject.nim
tests/shouldfail/tsortoutput.nim
tests/shouldfail/ttimeout.nim
tests/shouldfail/tvalgrind.nim
tests/stdlib/concurrency/tatomics.nim
tests/stdlib/tosproc.nim
tests/stdlib/tssl.nim
tests/testament/tshould_not_work.nim
tests/valgrind/tleak_arc.nim
tests/vm/tslow_tables.nim
EOT

%ifarch %ix86
cat << EOT >> tests_to_skip
tests/async/tasyncssl.nim
tests/async/tioselectors.nim
tests/compiler/tasm2.nim
tests/destructor/tv2_raise.nim
tests/errmsgs/t22852.nim
tests/errmsgs/t23435.nim
tests/errmsgs/tinvalidinout.nim
tests/errmsgs/tinvalidinout.nim
tests/int/tunsignedinc.nim
tests/iter/t20891.nim
tests/misc/trunner.nim
tests/misc/tstrace.nim
tests/stdlib/t9754.nim
tests/stdlib/tcasts.nim
tests/stdlib/tmarshal.nim
tests/stdlib/trandom.nim
tests/template/t13426.nim
EOT
%endif

%ifarch aarch64
cat << EOT >> tests_to_skip
tests/coroutines/tgc.nim
tests/coroutines/twait.nim
tests/destructor/tv2_raise.nim
tests/dll/nimhcr_basic.nim
tests/dll/nimhcr_unit.nim
tests/misc/trunner.nim
tests/range/tcompiletime_range_checks.nim
tests/vm/tslow_tables.nim
EOT
%endif

%ifarch ppc64le
cat << EOT >> tests_to_skip
tests/arc/thard_alignment.nim
tests/compiler/tasm.nim
tests/compiler/tasm2.nim
tests/destructor/tv2_raise.nim
tests/dll/nimhcr_basic.nim
tests/dll/nimhcr_unit.nim
tests/lent/tlents.nim
tests/misc/trunner.nim
tests/misc/tsizeof4.nim
tests/misc/tstrace.nim
tests/range/tcompiletime_range_checks.nim
tests/vm/t19075.nim
tests/vm/t20746.nim
tests/vm/tslow_tables.nim
EOT
%endif

%ifarch s390x
cat << EOT >> tests_to_skip
tests/arc/thard_alignment.nim
tests/async/t12221.nim
tests/ccgbugs/t7079.nim
tests/compiler/tasm.nim
tests/compiler/tasm2.nim
tests/destructor/tnewruntime_strutils.nim
tests/destructor/tv2_cast.nim
tests/dll/nimhcr_basic.nim
tests/dll/nimhcr_unit.nim
tests/float/tfloatnan.nim
tests/float/tfloatrange.nim
tests/js/tdollar_float.nim
tests/js/trepr.nim
tests/iter/titer_issues.nim
tests/lent/tlents.nim
tests/lexer/tunary_minus.nim
tests/metatype/tstaticvector.nim
tests/misc/t8404.nim
tests/misc/tconv.nim
tests/misc/trunner.nim
tests/misc/tstrace.nim
tests/objects/tobject_default_value.nim
tests/parallel/tpi.nim
tests/range/tcompiletime_range_checks.nim
tests/stdlib/thashes.nim
tests/stdlib/tcasts.nim
tests/stdlib/tcomplex.nim
tests/stdlib/tjson.nim
tests/stdlib/tjsonmacro.nim
tests/stdlib/tjsonutils.nim
tests/stdlib/tmath.nim
tests/stdlib/tnet_ll.nim
tests/stdlib/tnre.nim
tests/stdlib/tparseutils.nim
tests/stdlib/tpegs.nim
tests/stdlib/trandom.nim
tests/stdlib/trationals.nim
tests/stdlib/tsequtils.nim
tests/stdlib/tstats.nim
tests/stdlib/tstrformat.nim
tests/stdlib/tstrutils.nim
tests/stdlib/tsums.nim
tests/stdlib/tsystem.nim
tests/system/tdollars.nim
EOT
%endif

./koch tests \
  --nim:$PWD/bin/nim \
  --failing \
  --colors:off \
  --megatest:on \
  --skipFrom:tests_to_skip \
  --targets:"c c++ js" \
  all

%files
%license copying.txt
%doc changelogs
%doc doc

%{_bindir}/nim
%{_bindir}/nim-gdb
%{_bindir}/nim_dbg
%{_bindir}/nimgrep
%{_bindir}/nimpretty
%{_bindir}/nimsuggest

%dir %{_sysconfdir}/nim
%config %{_sysconfdir}/nim/*

%{_libdir}/nim/

%{bashcompdir}/nim/
%{bashcompdir}/nimble/

%changelog
%autochangelog
