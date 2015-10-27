import strutils
echo "Give a list of integers (separated by spaces): ",
     stdin.readLine.split.each(parseInt).max,
     " is the maximum!"
