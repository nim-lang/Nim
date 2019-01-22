# Filter key=value pairs from "myfile.txt"
import pegs

for x in lines("myfile.txt"):
  if x =~ peg"{\ident} \s* '=' \s* {.*}":
    echo "Key: ", matches[0],
         " Value: ", matches[1]
