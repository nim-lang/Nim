#!/bin/bash
cd simple
./runSimple.sh
res+=$(echo $?)
cd ..
cd addr
./runAddr.sh
res+=$(echo $?)
cd ..
cd cast
./runCast.sh
res+=$(echo $?)
cd ..
cd cffi
./runFfi.sh
res+=$(echo $?)
cd ..
echo "RESULT"
echo "************************"
echo "simple, addr, cast, ffi"
echo $res
echo "************************"
