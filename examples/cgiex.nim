# Test/show CGI module
import strtabs, cgi

var myData = readData()
validateData(myData, "name", "password")
writeContentType()

write(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n")
write(stdout, "<html><head><title>Test</title></head><body>\n")
writeLine(stdout, "name: " & myData["name"])
writeLine(stdout, "password: " & myData["password"])
writeLine(stdout, "</body></html>")
