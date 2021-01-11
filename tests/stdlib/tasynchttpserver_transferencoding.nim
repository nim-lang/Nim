import httpclient, asynchttpserver, asyncdispatch, asyncfutures
import net

const postBegin = """
POST / HTTP/1.1
Host: 127.0.0.1:64123
Accept: */*
Transfer-Encoding:chunked
Content-Type: application/x-www-form-urlencoded

"""
var
    sanitySimpleHelloWorldTest = false
    sanitySimpleEncodingTest = false
    sanitySimpleChunksTest = false
    sanityComplexChunksTest = false

proc testSimpleHelloWorld() =
    let exampleWorld = ("b\r\n" &
                        "hello=world\r\n" &
                        "0\r\n" &
                        "\r\n")
    let expected = "hello=world"

    proc handler(request: Request) {.async.} =
        doAssert(request.body == expected)
        doAssert(request.headers.hasKey("Transfer-Encoding"))
        doAssert(not request.headers.hasKey("Content-Length"))
        sanitySimpleHelloWorldTest = true
        await request.respond(Http200, "Good")

    let server = newAsyncHttpServer()
    discard server.serve(Port(64123), handler)

    let data = postBegin & exampleWorld

    var socket = newSocket()
    socket.connect("127.0.0.1", Port(64123))
    socket.send(data)

    waitFor sleepAsync(10)

    socket.close()
    server.close()

proc testSimpleEncoding() =
    let exampleWorld = ("e\r\n" &
                        "hello=encoding\r\n" &
                        "0\r\n" &
                        "\r\n")
    let expected = "hello=encoding"

    proc handler(request: Request) {.async.} =
        doAssert(request.body == expected)
        doAssert(request.headers.hasKey("Transfer-Encoding"))
        doAssert(not request.headers.hasKey("Content-Length"))
        sanitySimpleEncodingTest = true
        await request.respond(Http200, "Good")

    let server = newAsyncHttpServer()
    discard server.serve(Port(64123), handler)

    let data = postBegin & exampleWorld

    var socket = newSocket()
    socket.connect("127.0.0.1", Port(64123))
    socket.send(data)

    waitFor sleepAsync(10)

    socket.close()
    server.close()

proc testSimpleChunks() =
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding
    let exampleMozilla = ("7\r\n" &
                         "Mozilla\r\n" &
                         "9\r\n" &
                         "Developer\r\n" &
                         "7\r\n" &
                         "Network\r\n" &
                         "0\r\n" &
                         "\r\n")
    let expected = "MozillaDeveloperNetwork"

    proc handler(request: Request) {.async.} =
        doAssert(request.body == expected)
        doAssert(request.headers.hasKey("Transfer-Encoding"))
        doAssert(not request.headers.hasKey("Content-Length"))
        sanitySimpleChunksTest = true
        await request.respond(Http200, "Good")

    let server = newAsyncHttpServer()
    discard server.serve(Port(64123), handler)

    let data = postBegin & exampleMozilla

    var socket = newSocket()
    socket.connect("127.0.0.1", Port(64123))
    socket.send(data)

    waitFor sleepAsync(10)

    socket.close()
    server.close()

proc testComplexChunks() =
    # https://en.wikipedia.org/wiki/Chunked_transfer_encoding#Example
    let exampleWikipedia = ("4\r\n" &
                            "Wiki\r\n" &
                            "6\r\n" &
                            "pedia \r\n" &
                            "E\r\n" &
                            "in \r\n" &
                            "\r\n" &
                            "chunks.\r\n" &
                            "0\r\n" &
                            "\r\n")
    let expected = "Wikipedia in \r\n\r\nchunks."

    proc handler(request: Request) {.async.} =
        doAssert(request.body == expected)
        doAssert(request.headers.hasKey("Transfer-Encoding"))
        doAssert(not request.headers.hasKey("Content-Length"))
        sanityComplexChunksTest = true
        await request.respond(Http200, "Good")

    let server = newAsyncHttpServer()
    discard server.serve(Port(64123), handler)

    let data = postBegin & exampleWikipedia

    var socket = newSocket()
    socket.connect("127.0.0.1", Port(64123))
    socket.send(data)

    waitFor sleepAsync(10)

    socket.close()
    server.close()

testSimpleHelloWorld()
testSimpleEncoding()
testSimpleChunks()
testComplexChunks()

doAssert(sanitySimpleHelloWorldTest)
doAssert(sanitySimpleEncodingTest)
doAssert(sanitySimpleChunksTest)
doAssert(sanityComplexChunksTest)
