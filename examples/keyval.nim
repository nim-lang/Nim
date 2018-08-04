# Filter key=value pairs from "myfile.txt"
import re

for x in lines("myfile.txt"):
  if x =~ re"(\w+)=(.*)":
    echo "Key: ", matches[0], " Value: ", matches[1]


