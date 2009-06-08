# Filter key=value pairs from "myfile.txt"
import regexprs

for x in lines("myfile.txt"):
  if x =~ r"(\w+)=(.*)":
    echo "Key: ", matches[1], 
         " Value: ", matches[2]


