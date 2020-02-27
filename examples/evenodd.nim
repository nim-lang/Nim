from strutils import parseInt

echo "Enter a number to check whether it is even or odd :-"
let a = parseInt(readLine(stdin))
echo "\n"

if a mod 2 == 0:
 echo "This number is an even number"
else:
 echo "This number is not an even number"
