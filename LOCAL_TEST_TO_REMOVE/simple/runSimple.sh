#!/bin/bash

filelist=$(ls *.nim)

for file in $filelist
do
  echo "********************"
  echo "$file"
  echo "********************"
  echo ""
  ../../bin/nim r "$file"
  res+=$(echo $?)
  echo ""
  echo "DONE !"
  echo ""
done
echo "result should be 0010"
echo $filelist
echo $res

if [[ $res == 0010 ]]; then
  exit 0
else
  exit 1
fi
