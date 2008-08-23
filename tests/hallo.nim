# Hallo world program

echo("Hi! What's your name?")
var name = readLine(stdin)

if name == "Andreas":
  echo("What a nice name!")
elif name == "":
  echo("Don't you have a name?")
else:
  echo("Your name is not Andreas...")

for i in 0..name.len-1:
  if name[i] == 'm':
    echo("hey, there is an *m* in your name!")

echo("Please give your password: (12345)")
var pw = readLine(stdin)

while pw != "12345":
  echo("Wrong password! Next try: ")
  pw = readLine(stdin)

echo("""Login complete!
What do you want to do?
delete-everything
restart-computer
go-for-a-walk""")

case readline(stdin)
of "delete-everything", "restart-computer":
  echo("permission denied")
of "go-for-a-walk":     echo("please yourself")
else:                   echo("unknown command")
