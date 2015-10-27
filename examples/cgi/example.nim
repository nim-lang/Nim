import cgi

write(stdout, "Content-type: text/html\n\n")
write(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n")
write(stdout, "<html><head><title>Test</title></head><body>\n")
write(stdout, "Hello!")
writeLine(stdout, "</body></html>")
