#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the SMTP client protocol as specified by RFC 5321,
## this can be used to send mail to any SMTP Server.
##
## This module also implements the protocol used to format messages,
## as specified by RFC 2822.
##
## Example gmail use:
##
##
## .. code-block:: Nim
##   var msg = createMessage("Hello from Nim's SMTP",
##                           "Hello!.\n Is this awesome or what?",
##                           @["foo@gmail.com"])
##   var smtp = connect("smtp.gmail.com", 465, true, true)
##   smtp.auth("username", "password")
##   smtp.sendmail("username@gmail.com", @["foo@gmail.com"], $msg)
##
##
## For SSL support this module relies on OpenSSL. If you want to
## enable SSL, compile with ``-d:ssl``.

import net, strutils, strtabs, base64, os, mimetypes, sequtils
import asyncnet, asyncdispatch
import mersenne , times ## we need randomness for the boundary

type
  Smtp* = object
    sock: Socket
    debug: bool

  Attachment* = object ## this is a mail attachment
    mimeType: string ## the mime type of our attachement
    filename: string ## the user spezified name of the attached file
    contentB64 : string ## the actual content of the file base 64ed
    #description : string ## a description of this attachement


  Message* = object
    msgTo: seq[string]
    msgFrom: string
    msgCc: seq[string]
    msgSubject: string
    msgOtherHeaders: StringTableRef
    msgBody: string
    attachements : seq[Attachment] 
    boundary : string  ## this is a (randomly) generated string


  ReplyError* = object of IOError

  AsyncSmtp* = ref object
    sock: AsyncSocket
    address: string
    port: Port
    useSsl: bool
    debug: bool

{.deprecated: [EInvalidReply: ReplyError, TMessage: Message, TSMTP: Smtp].}

proc debugSend(smtp: Smtp, cmd: string) =
  if smtp.debug:
    echo("C:" & cmd)
  smtp.sock.send(cmd)

proc debugRecv(smtp: var Smtp): TaintedString =
  var line = TaintedString""
  smtp.sock.readLine(line)

  if smtp.debug:
    echo("S:" & line.string)
  return line

proc quitExcpt(smtp: Smtp, msg: string) =
  smtp.debugSend("QUIT")
  raise newException(ReplyError, msg)

proc checkReply(smtp: var Smtp, reply: string) =
  var line = smtp.debugRecv()
  if not line.string.startswith(reply):
    quitExcpt(smtp, "Expected " & reply & " reply, got: " & line.string)

const compiledWithSsl = defined(ssl)

when not defined(ssl):
  type PSSLContext = ref object
  let defaultSSLContext: PSSLContext = nil
else:
  let defaultSSLContext = newContext(verifyMode = CVerifyNone)

proc connect*(address: string, port = Port(25),
              ssl = false, debug = false,
              sslContext = defaultSSLContext): Smtp =
  ## Establishes a connection with a SMTP server.
  ## May fail with ReplyError or with a socket error.
  result.sock = newSocket()
  if ssl:
    when compiledWithSsl:
      sslContext.wrapSocket(result.sock)
    else:
      raise newException(ESystem,
                         "SMTP module compiled without SSL support")
  result.sock.connect(address, port)
  result.debug = debug

  result.checkReply("220")
  result.debugSend("HELO " & address & "\c\L")
  result.checkReply("250")

proc auth*(smtp: var Smtp, username, password: string) =
  ## Sends an AUTH command to the server to login as the `username`
  ## using `password`.
  ## May fail with ReplyError.

  smtp.debugSend("AUTH LOGIN\c\L")
  smtp.checkReply("334") # TODO: Check whether it's asking for the "Username:"
                         # i.e "334 VXNlcm5hbWU6"
  smtp.debugSend(encode(username) & "\c\L")
  smtp.checkReply("334") # TODO: Same as above, only "Password:" (I think?)

  smtp.debugSend(encode(password) & "\c\L")
  smtp.checkReply("235") # Check whether the authentification was successful.

proc sendmail*(smtp: var Smtp, fromaddr: string,
               toaddrs: seq[string], msg: string) =
  ## Sends `msg` from `fromaddr` to `toaddr`.
  ## Messages may be formed using ``createMessage`` by converting the
  ## Message into a string.

  smtp.debugSend("MAIL FROM:<" & fromaddr & ">\c\L")
  smtp.checkReply("250")
  for address in items(toaddrs):
    smtp.debugSend("RCPT TO:<" & address & ">\c\L")
    smtp.checkReply("250")

  # Send the message
  smtp.debugSend("DATA " & "\c\L")
  smtp.checkReply("354")
  smtp.debugSend(msg & "\c\L")
  smtp.debugSend(".\c\L")
  smtp.checkReply("250")

proc close*(smtp: Smtp) =
  ## Disconnects from the SMTP server and closes the socket.
  smtp.debugSend("QUIT\c\L")
  smtp.sock.close()


proc getMimeTypeOfFile(pathToFile:string): string =
  ## This will return the mimetype
  var mimeDB = newMimetypes()
  var ext = extractExt(pathToFile) # 

  ## we choose "application/octet-stream" 
  ## if no extension is given
  ## TODO what about linux? or files without extension.
  ## Do we have to have something like `file` magic?
  return mimeDB.getMimetype(ext,"bin") 



proc composeAttachement(attachement:Attachment,boundary:string) : string=
  ## this generates an attachement
  result =""

  var ContentDisposition :string = "Content-Disposition: attachment;"
  if attachement.filename != nil:
    ContentDisposition &= " filename=" & attachement.filename & ";"

  result.add("\c\L")
  result.add("Content-Type: " & attachement.mimeType & "\c\L")
  result.add( ContentDisposition & "\c\L")
  result.add("MIME-Version: 1.0\c\L")
  result.add("Content-Transfer-Encoding: base64 \c\L")
  result.add("" & "\c\L")
  result.add(attachement.contentB64 & "\c\L")
  result.add("\c\L")
  result.add("--" & boundary )


proc attach*(msg:var Message,pathToFile:string,
              myFilename:string) =
  ## this will attach a file to the message
  var attachement = Attachment()
  attachement.mimeType    = getMimeTypeOfFile(pathToFile)
  let content             = readFile(pathToFile)
  attachement.contentB64  = encode(content)
  attachement.filename    = myFilename
  #attachement.description = description
  add(msg.attachements,attachement)


proc getRandomBoundary():string = 
  var mt = newMersenneTwister( int( epochTime() )  ) #we dont need stong random
  return $mt.getNum()


proc createMessage*(mSubject, mBody: string, mFrom:string, 
                mTo, mCc: seq[string],
                otherHeaders: openarray[tuple[name, value: string]]): Message =
  ## Creates a new MIME compliant message.
  result.msgFrom = mFrom
  result.msgTo = mTo
  result.msgCc = mCc
  result.msgSubject = mSubject
  result.msgBody = mBody
  result.attachements = newSeq[Attachment]()
  result.msgOtherHeaders = newStringTable()
  result.boundary = getRandomBoundary()
  for n, v in items(otherHeaders):
    result.msgOtherHeaders[n] = v

proc createMessage*(mSubject, mBody: string, mFrom:string , mTo,
                    mCc: seq[string] = @[]): Message =
  ## Alternate version of the above.
  result.msgFrom = mFrom
  result.msgTo = mTo
  result.msgCc = mCc
  result.msgSubject = mSubject
  result.msgBody = mBody
  result.attachements = newSeq[Attachment]()
  result.msgOtherHeaders = newStringTable()
  result.boundary = getRandomBoundary()

proc `$`*(msg: Message): string =
  ## stringify for ``Message``.
  result = ""
  if msg.attachements.len() > 0:
    result.add(
      "Content-Type: multipart/mixed; boundary=" & msg.boundary & "\"\c\L" )
  result.add("FROM: "& msg.msgFrom & "\c\L")
  if msg.msgTo.len() > 0:
    result.add("TO: " & msg.msgTo.join(", ") & "\c\L")
  if msg.msgCc.len() > 0:
    result.add("CC: " & msg.msgCc.join(", ") & "\c\L")
  # TODO: Folding? i.e when a line is too long, shorten it...
  result.add("Subject: " & msg.msgSubject & "\c\L")
  for key, value in pairs(msg.msgOtherHeaders):
    result.add(key & ": " & value & "\c\L")

  result.add("\c\L")
  result.add("--" & msg.boundary & "\c\L") #boundary before the txt message
  result.add("\c\L")
  result.add(msg.msgBody)
  result.add("\c\L")

  if msg.attachements.len() > 0: # if we have some attachements
    result.add("\c\L")
    result.add("--" & msg.boundary) # we start with a boundary

    for attachement in msg.attachements:
      # echo "FOOOOO"
      result.add(composeAttachement(attachement,msg.boundary)) 
      # result.add("\c\L")
  result.add("\c\L")
  result.add("--" & msg.boundary & "--" & "\c\L\c\L" ) #last msg has -- suffix!
  

proc newAsyncSmtp*(address: string, port: Port, useSsl = false,
                   sslContext = defaultSslContext): AsyncSmtp =
  ## Creates a new ``AsyncSmtp`` instance.
  new result
  result.address = address
  result.port = port
  result.useSsl = useSsl

  result.sock = newAsyncSocket()
  if useSsl:
    when compiledWithSsl:
      sslContext.wrapSocket(result.sock)
    else:
      raise newException(ESystem,
                         "SMTP module compiled without SSL support")

proc quitExcpt(smtp: AsyncSmtp, msg: string): Future[void] =
  var retFuture = newFuture[void]()
  var sendFut = smtp.sock.send("QUIT")
  sendFut.callback =
    proc () =
      # TODO: Fix this in async procs.
      raise newException(ReplyError, msg)
  return retFuture

proc checkReply(smtp: AsyncSmtp, reply: string) {.async.} =
  var line = await smtp.sock.recvLine()
  if not line.string.startswith(reply):
    await quitExcpt(smtp, "Expected " & reply & " reply, got: " & line.string)

proc connect*(smtp: AsyncSmtp) {.async.} =
  ## Establishes a connection with a SMTP server.
  ## May fail with ReplyError or with a socket error.
  await smtp.sock.connect(smtp.address, smtp.port)

  await smtp.checkReply("220")
  await smtp.sock.send("HELO " & smtp.address & "\c\L")
  await smtp.checkReply("250")

proc auth*(smtp: AsyncSmtp, username, password: string) {.async.} =
  ## Sends an AUTH command to the server to login as the `username`
  ## using `password`.
  ## May fail with ReplyError.

  await smtp.sock.send("AUTH LOGIN\c\L")
  await smtp.checkReply("334") # TODO: Check whether it's asking for the 
                               # "Username:"
                               # i.e "334 VXNlcm5hbWU6"
  await smtp.sock.send(encode(username) & "\c\L")
  await smtp.checkReply("334") # TODO: Same as above, only 
                               # "Password:" (I think?)

  await smtp.sock.send(encode(password) & "\c\L")
  await smtp.checkReply("235") # Check whether the authentification 
                               # was successful.

proc sendMail*(smtp: AsyncSmtp, fromAddr: string,
               toAddrs: seq[string], msg: string) {.async.} =
  ## Sends ``msg`` from ``fromAddr`` to the addresses specified in ``toAddrs``.
  ## Messages may be formed using ``createMessage`` by converting the
  ## Message into a string.
  await smtp.sock.send("MAIL FROM:<" & fromAddr & ">\c\L")
  await smtp.checkReply("250")
  for address in items(toAddrs):
    await smtp.sock.send("RCPT TO:<" & address & ">\c\L")
    await smtp.checkReply("250")

  # Send the message
  await smtp.sock.send("DATA " & "\c\L")
  await smtp.checkReply("354")
  await smtp.sock.send(msg & "\c\L")
  await smtp.sock.send(".\c\L")
  await smtp.checkReply("250")

proc close*(smtp: AsyncSmtp) {.async.} =
  ## Disconnects from the SMTP server and closes the socket.
  await smtp.sock.send("QUIT\c\L")
  smtp.sock.close()

when not defined(testing) and isMainModule:
  
  proc main() {.async.} =

    #var msg = createMessage("Test subject!",
    #     "Hello, my name is dom96.\n What\'s yours?", @["dominik@localhost"])
    #echo(msg)

    #var smtp = connect("localhost", 25, False, True)
    #smtp.sendmail("root@localhost", @["dominik@localhost"], $msg)

    #echo(decode("a17sm3701420wbe.12"))

    # var client = newAsyncSmtp("smtp.gmail.com", Port(465), true)
    # await client.connect()
    # await client.auth("johndoe", "foo")

    var client = newAsyncSmtp("mail.server.de", Port(587), false)
    await client.connect()
    await client.auth("mymail@server.de", "xxx")

    var msg = createMessage("Hello from Nim's SMTP!",
                            "Hello!!!!.\nIs this awesome or what?\n\n",
                            "mymail@server.de",
                            @["friend@otherserver.nl"])

    # png test
    msg.attach(r"C:\tmp\test1.png",
               r"test1.png",
              "fooobaabaz"
              )

    # pdf test
    msg.attach(r"C:\tmp\wget-man.pdf",
               r"wget-man.pdf",
              "fooobaabaz"
              )

    # echo msg.attachements.len()
    # echo msg.attachements[0].filename

    echo(msg)
    await client.sendMail("mymail@server.de", @["friend@otherserver.nl"], $msg)
    await client.close()

  waitFor main()


