from strutils import parseInt

echo " Welcome to calculator \n"
echo "Choose your operation :- \n"

echo "a - Addition \n"
echo "b - Subtraction \n"
echo "c - Multiplication \n"
echo "d - Division \n"

echo "Select :- "
var choice:string = readLine(stdin)

echo "\n"

echo "Enter a :-"
let a = parseInt(readline(stdin))
echo "\nEnter b:-"
let b = parseInt(readline(stdin))

echo "\n"

if choice == "a":
 echo "The result is ,", a+b
elif choice == "b":
 echo "The result is ,", a-b
elif choice == "c":
 echo "The result is ,", a*b
elif choice == "d":
 echo "The result is ,",a/b
else:
 echo "Invalid operation selected"


