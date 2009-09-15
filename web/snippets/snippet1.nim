import strutils
echo "Give a list of integers (separated by spaces): ", 
     stdin.readLine.splitSeq.each(parseInt).max,
     " is the maximum!"
