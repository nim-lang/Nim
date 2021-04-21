set -e

. ci/funs.sh
sh ci/deps.sh

nimBuildCsourcesIfNeeded

# Add Nim to the PATH
export PATH=$(pwd)/bin${PATH:+:$PATH}
# Bootstrap.
nim -v
nim c koch
./koch boot
cp bin/nim bin/nimd
./koch boot -d:release
