#!/bin/sh
set -e
set -x

if [ ! -d "csources" ]; then
	git clone --depth 1 https://github.com/nim-lang/csources.git
fi

cd "csources"
sh build.sh
cd ".."

./bin/nim c koch
./koch boot -d:release --stacktrace:on -d:useGnuReadline

cp -f install.sh.template install.sh
chmod +x install.sh

exit 0
