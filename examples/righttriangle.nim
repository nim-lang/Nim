from strutils import parseInt


echo "Enter the number of rows:-"
let row = parseInt(readLine(stdin))

echo "\nThe pattern is :-\n"

for i in countup(1,row):
 for j in countup(1,i):
  echo "*"
 echo "\n"

#if we replace * with j , it will print numbers in the order
#1
#12
#123
#1234
#12345
