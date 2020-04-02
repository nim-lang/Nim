sh ci/deps.sh

# Build from C sources.
NIMBUILD_ACTION=action_build_koch sh build_all.sh

# Add Nim to the PATH
export PATH=$(pwd)/bin${PATH:+:$PATH}
# Bootstrap.
./koch boot
cp bin/nim bin/nimd
./koch boot -d:release
