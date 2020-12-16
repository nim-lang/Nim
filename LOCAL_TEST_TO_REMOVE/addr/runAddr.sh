#!/bin/bash

for file in `ls addr*.nim`
do
  echo "********************"
  echo "$file"
  echo "********************"
  echo ""
  ../../bin/nim r "$file"
  echo ""
  echo "DONE !"
  echo ""
done
