discard """
  file: "tasyncstreams.nim"
  cmd: "nim $target --hints:on --threads:on $options $file"
  exitcode: 0
"""
import unittest, asyncdispatch, asyncstreams, asyncnet, threadpool, os, strutils

const PORT = Port(39752)

suite "asyncstreams":

  test "AsyncSocketStream":
    proc runSocketServer =
      proc serve {.async.} =
        var s = newAsyncSocket()
        s.bindAddr(PORT)
        s.listen
        let c = newAsyncSocketStream(await s.accept)
        let ch = await c.readChar
        await c.writeChar(ch)
        let line = await c.readLine
        await c.writeLine("Hello, " & line)
        c.close
        s.close

      proc run {.gcsafe.} =
        waitFor serve()

      spawn run()

    runSocketServer()

    proc doTest {.async.} =
      let s = newAsyncSocket()
      await s.connect("localhost", PORT)
      let c = newAsyncSocketStream(s)

      await c.writeChar('A')
      let ch = await c.readChar
      check: ch == 'A'

      await c.writeLine("World!")
      let line = await c.readLine
      check: line == "Hello, World!"
    waitFor doTest()

  test "AsyncFileStream":
    proc doTest {.async.} =
      let fname = getTempDir() / "asyncstreamstest.nim"
      var s = newAsyncFileStream(fname, fmReadWrite)
      await s.writeLine("Hello, world!")
      s.setPosition(0)
      let line = await s.readLine
      check: line == "Hello, world!"
      check: not s.atEnd
      discard await s.readLine
      check: s.atEnd
      fname.removeFile
    waitFor doTest()

  test "AsyncStringStream":
    proc doTest {.async.} =
      let s = newAsyncStringStream()
      await s.writeLine("Hello, world!")
      s.setPosition(0)
      let line = await s.readLine
      check: line == "Hello, world!"
      check: not s.atEnd
      discard await s.readLine
      check: s.atEnd
    waitFor doTest()

  test "Operations":
    proc doTest {.async.} =
      let s = newAsyncStringStream()

      await s.writeChar('H')
      s.setPosition(0)
      let ch = await s.readChar
      check: ch == 'H'

      s.setPosition(0)
      await s.writeLine("Hello, world!")
      s.setPosition(0)
      let line = await s.readLine
      check: line == "Hello, world!"

      s.setPosition(0)
      let all = await s.readAll
      check: all == "Hello, world!\n"

      s.setPosition(0)
      await s.writeByte(42)
      s.setPosition(0)
      let b = await s.readByte
      check: b == 42

      s.setPosition(0)
      await s.writeFloat(1.0)
      s.setPosition(0)
      let f = await s.readFloat
      check: f == 1.0

      s.setPosition(0)
      await s.writeBool(true)
      s.setPosition(0)
      let bo = await s.readBool
      check: bo

      s.setPosition(1000)
      try:
        discard await s.readBool
      except IOError:
        return
      check: false
    waitFor doTest()

  test "Example for the documentation":
    proc main {.async.} =
      var s = newAsyncStringStream("""Hello
world!""")
      var res = newSeq[string]()
      while true:
        let l = await s.readLine()
        if l == "":
          break
        res.add(l)
      doAssert(res.join(", ") == "Hello, world!")
    waitFor main()
