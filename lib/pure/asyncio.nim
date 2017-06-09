import asyncfutures, nativesockets

export asyncfutures.Future
export nativesockets.SocketHandle

# Asynchronous I/O

type
  Output* = concept x
    ## Writes data from view into the output. Returns the number of bytes written.
    x.write(ByteView) is Future[int]

    ## Closes the output.
    x.close

  Input* = concept x
    ## Reads data into the buffer. Returns the number of bytes read.
    x.read(ByteView) is Future[int]

    ## Closes the input.
    x.close

  IO* = concept x
    x is Output
    x is Input

# TODO: ByteStream should also automatically be SyncByteStream, but for that we need to have loop-independent ``waitFor``.
# For that we need runtime polymorphism for AsyncLoop.

type
  AsyncLoop* = concept x
    ## Perform some work on the event loop
    x.runOnce

    ## These function wrap native (OS) handle in an async stream.
    x.wrapHandleAsInput(SocketHandle) is Input
    x.wrapHandleAsOutput(SocketHandle) is Output
    x.wrapHandleAsStream(SocketHandle) is IO
