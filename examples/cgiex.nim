# Test/show CGI module
import strtabs, cgi

var myData = readData()
validateData(myData, "name", "password")
writeContentType()

write(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\N")
write(stdout, "<html><head><title>Test</title></head><body>\N")
writeln(stdout, "name: " & myData["name"])
writeln(stdout, "password: " & myData["password"])
writeln(stdout, "</body></html>")
