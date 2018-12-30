# Shows how the method call syntax can be used to chain calls conveniently.

import strutils, sequtils

echo "Give a list of numbers (separated by spaces): "
stdin.readLine.split.map(parseInt).max.`$`.echo(" is the maximum!")
