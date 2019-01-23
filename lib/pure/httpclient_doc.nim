## This module implements a simple HTTP client that can be used to retrieve
## webpages and other data.
##
## # Basic usage
##
## ## Retrieving a website
##
## This example uses HTTP GET to retrieve
## ``http://google.com``:
##
## .. code-block:: Nim
##   var client = newHttpClient()
##   echo client.getContent("http://google.com")
##
## The same action can also be performed asynchronously, simply use the
## ``AsyncHttpClient``:
##
## .. code-block:: Nim
##   var client = newAsyncHttpClient()
##   echo await client.getContent("http://google.com")
##
## The functionality implemented by ``HttpClient`` and ``AsyncHttpClient``
## is the same, so you can use whichever one suits you best in the examples
## shown here.
##
## **Note:** You will need to run asynchronous examples in an async proc
## otherwise you will get an ``Undeclared identifier: 'await'`` error.
##
##
##
## ## Using HTTP POST
##
## This example demonstrates the usage of the W3 HTML Validator, it
## uses ``multipart/form-data`` as the ``Content-Type`` to send the HTML to be
## validated to the server.
##
## .. code-block:: Nim
##   var client = newHttpClient()
##   var data = newMultipartData()
##   data["output"] = "soap12"
##   data["uploaded_file"] = ("test.html", "text/html",
##     "<html><head></head><body><p>test</p></body></html>")
##
##   echo client.postContent("http://validator.w3.org/check", multipart=data)
##
## You can also make post requests with custom headers.
## This example sets ``Content-Type`` to ``application/json``
## and uses a json object for the body
##
## .. code-block:: Nim
##   import httpclient, json
##
##   let client = newHttpClient()
##   client.headers = newHttpHeaders({ "Content-Type": "application/json" })
##   let body = %*{
##       "data": "some text"
##   }
##   let response = client.request("http://some.api", httpMethod = HttpPost, body = $body)
##   echo response.status
##
##
##
## ## Progress reporting
##
## You may specify a callback procedure to be called during an HTTP request.
## This callback will be executed every second with information about the
## progress of the HTTP request.
##
## .. code-block:: Nim
##    import asyncdispatch, httpclient
##
##    proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
##      echo("Downloaded ", progress, " of ", total)
##      echo("Current rate: ", speed div 1000, "kb/s")
##
##    proc asyncProc() {.async.} =
##      var client = newAsyncHttpClient()
##      client.onProgressChanged = onProgressChanged
##      discard await client.getContent("http://speedtest-ams2.digitalocean.com/100mb.test")
##
##    waitFor asyncProc()
##
## If you would like to remove the callback simply set it to ``nil``.
##
## .. code-block:: Nim
##   client.onProgressChanged = nil
##
## **Warning:** The ``total`` reported by httpclient may be 0 in some cases.
##
##
##
## ## SSL/TLS support
##
## This requires the OpenSSL library, fortunately it's widely used and installed
## on many operating systems. httpclient will use SSL automatically if you give
## any of the functions a url with the ``https`` schema, for example:
## ``https://github.com/``.
##
## You will also have to compile with ``ssl`` defined like so:
## ``nim c -d:ssl ...``.
##
##
##
## ## Timeouts
##
## Currently only the synchronous functions support a timeout.
## The timeout is
## measured in milliseconds, once it is set any call on a socket which may
## block will be susceptible to this timeout.
##
## It may be surprising but the
## function as a whole can take longer than the specified timeout, only
## individual internal calls on the socket are affected. In practice this means
## that as long as the server is sending data an exception will not be raised,
## if however data does not reach the client within the specified timeout a
## ``TimeoutError`` exception will be raised.
##
##
##
## ## Proxy
##
## A proxy can be specified as a param to any of the procedures defined in
## this module. To do this, use the ``newProxy`` constructor. Unfortunately,
## only basic authentication is supported at the moment.
