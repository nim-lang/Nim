#! /bin/sh
#
# Helper script to build the RPM packages.  Just run this from the root
# of an unconfigured source tree:
#  $ ./utils/build-rpm.sh
#


# Create the RPM build environment.
rm -rf rpm/dist
for dir in rpm rpm/RPMS rpm/SRPMS rpm/BUILD rpm/SOURCES rpm/dist; do
  if test ! -d $dir; then
    mkdir $dir
  fi
done

# Create the source distribution tarball.
cd rpm/dist
../../configure
make dist
gunzip tre-*.tar.gz
bzip2 tre-*.tar
mv tre-*.tar.bz2 ../SOURCES
cd ..

# Build the packages.
rm -f RPMS/*/*.rpm SRPMS/*.rpm
rpmbuild --define "_topdir `pwd`" dist/tre.spec -ba
cp RPMS/*/*.rpm SRPMS/*.rpm ..
cd ..
ls -l *.rpm
