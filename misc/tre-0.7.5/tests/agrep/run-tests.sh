#! /bin/sh

set -e

agrep="$top_builddir/src/agrep"

echo "$builddir $top_builddir $srcdir"

num_cases=0
num_expanded=0
num_tests=0
num_fail=0
num_ok=0

SIFS="$IFS"

for args in $srcdir/*.args; do
  dir=`dirname $args`
  base=`basename $args .args`
  orig_input=$dir/$base.input
  input=$base.in
  ok=$dir/$base.ok
  out=$base.out

  rm -f $out
  IFS="
"
  for arg in `cat $args`; do
    IFS="$SIFS"
    case "$arg" in
      \#*) continue;;
    esac

    num_cases=`expr $num_cases + 1`
    cp "$orig_input" $input

    for extra in "" -c -H -l -n -s -M --show-position --color \
                 "-H -n -s --color --show-position"; do
      num_expanded=`expr $num_expanded + 1`
      # Note that `echo' cannot be used since it works differently on
      # different platforms with regards to expanding \n (IRIX expands
      # it, others typically do not).  `cat' doesn't process its output.
      cat >> $out <<EOF
#### TEST: agrep $extra $arg $input
EOF
      cat <<EOF
agrep $extra $arg $input
EOF
      set +e
      $agrep $extra $arg $input >> $out
      status=$?
      set -e
      cat >> $out <<EOF

Exit status $status.
EOF

      num_expanded=`expr $num_expanded + 1`
      cat >> $out <<EOF
#### TEST: agrep $extra $arg < $input
EOF
      cat <<EOF
agrep $extra $arg < $input
EOF
      set +e
      $agrep $extra $arg < $input >> $out
      status=$?
      set -e
      cat >> $out <<EOF

Exit status $status.
EOF
    done
  done
  num_tests=`expr $num_tests + 1`
  case $host_triplet in
    *-mingw*)
      # On MinGW something causes \r\n newlines to be output to $out,
      # and our reference results don't have them.
      tr -d '\015' < $out > $out.tmp
      mv $out.tmp $out
      ;;
  esac
  if diff $ok $out; then
    num_ok=`expr $num_ok + 1`
  else
    echo "FAILED (see above)"
    num_fail=`expr $num_fail + 1`
  fi
done

echo "Ran $num_cases tests ($num_expanded expanded) from $num_tests suites."
echo "$num_ok/$num_tests tests OK"

test $num_fail -eq 0
exit $?
