import cgi

write(stdout, "Content-type: text/html\N\N")
write(stdout, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\N")
write(stdout, "<html><head><title>Test</title></head><body>\N")
write(stdout, "Hello!")
writeln(stdout, "</body></html>")
