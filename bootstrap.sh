#!/bin/sh
set -e
set -x

if [ ! -e csources/.git ]; then
	git clone --depth 1 git://github.com/nim-lang/csources.git csources
fi

cd "csources"
sh build.sh
cd ".."

./bin/nim c koch
./koch boot -d:release

cp -f install.sh.template install.sh
chmod +x install.sh

exit 0
