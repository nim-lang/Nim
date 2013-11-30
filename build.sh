git submodule update --init

cd csources
./build.sh
cd ..

bin/nimrod c koch
./koch boot -d:release
