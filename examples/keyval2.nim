# Filter key=value pairs from "myfile.txt"
import pegs

for x in lines("myfile.txt"):
  if x =~ peg"{\ident} \s* '=' \s* {.*}":
    echo "Key: ", matches[1], 
         " Value: ", matches[2]
