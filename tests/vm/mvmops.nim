import os
proc fun1() = writeFile("nonexistant/bar.txt".unixToNativePath, "foo")
proc fun2()=fun1()
static: fun2()
echo "fook"