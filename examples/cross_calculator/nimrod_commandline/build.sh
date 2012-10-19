#!/bin/sh

rm -f nimcalculator
nimrod c --path:../nimrod_backend nimcalculator.nim
echo "Done"
