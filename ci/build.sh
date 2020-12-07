sh ci/deps.sh

# Build from C sources.
git clone --depth 1 https://github.com/nim-lang/csources_v1.git csources
cd csources
sh build.sh
cd ..
# Add Nim to the PATH
export PATH=$(pwd)/bin${PATH:+:$PATH}
# Bootstrap.
nim -v
nim c koch
./koch boot
cp bin/nim bin/nimd
./koch boot -d:release
