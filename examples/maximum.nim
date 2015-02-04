# Test high level features

import strutils

echo "Give a list of numbers (separated by spaces): "
stdin.readLine.split.map(parseInt).max.`$`.echo(" is the maximum!")
