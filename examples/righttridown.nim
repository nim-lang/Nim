from strutils import parseInt


echo "Enter the number of rows:-"
let row = parseInt(readLine(stdin))

echo "\nThe pattern is :-\n"

for i in countdown(row,1):
 for j in countup(1,i):
  echo "*"
 echo "\n"

#if we replace * with j , it will print numbers in the order
#123456
#12345
#1234
#123
#12
#1
