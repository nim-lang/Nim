#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the SMTP client protocol as specified by RFC 5321, 
## this can be used to send mail to any SMTP Server.
## 
## This module also implements the protocol used to format messages, as specified by RFC 2822.
## 
## Example gmail use:
## 
## 
## .. code-block:: Nimrod
##   var msg = createMessage("Hello from Nimrod's SMTP", 
##                           "Hello!.\n Is this awesome or what?", 
##                           @["foo@gmail.com"])
##   var smtp = connect("smtp.gmail.com", 465, True, True)
##   smtp.auth("username", "password")
##   smtp.sendmail("username@gmail.com", @["foo@gmail.com"], $msg)
##   

import sockets, strutils, strtabs, ssl, base64

type
  TSMTP* = object
    sock: TSocket
    sslSock: TSecureSocket
    ssl: Bool
    debug: Bool
  
  TMessage* = object
    msgTo: seq[String]
    msgCc: seq[String]
    msgSubject: String
    msgOtherHeaders: PStringTable
    msgBody: String
  
  EInvalidReply* = object of EBase
  
proc debugSend(smtp: TSMTP, cmd: String) =
  if smtp.debug:
    echo("C:" & cmd)
  if not smtp.ssl:
    smtp.sock.send(cmd)
  else:
    smtp.sslSock.send(cmd)

proc debugRecv(smtp: TSMTP): String =
  var line = ""
  var ret = False
  if not smtp.ssl:
    ret = smtp.sock.recvLine(line)
  else:
    ret = smtp.sslSock.recvLine(line)
  if ret:
    if smtp.debug:
      echo("S:" & line)
    return line
  else:
    echo("S-Warning: recvLine failed.")
    return ""

proc quitExcpt(smtp: TSMTP, msg: String) =
  smtp.debugSend("QUIT")
  raise newException(EInvalidReply, msg)

proc checkReply(smtp: TSMTP, reply: string) =
  var line = smtp.debugRecv()
  if not line.startswith(reply):
    quitExcpt(smtp, "Expected " & reply & " reply, got: " & line)

proc connect*(address: String, port: int = 25, 
              ssl: bool = False, debug: bool = False): TSMTP =
  ## Establishes a connection with a SMTP server.
  ## May fail with EInvalidReply or with a socket errors.

  if not ssl:
    result.sock = socket()
    result.sock.connect(address, TPort(port))
  else:
    result.ssl = True
    var certResult: int
    result.sslSock.connect(address, port, certResult)
  
  result.debug = debug
  
  result.checkReply("220")
  result.debugSend("HELO " & address & "\c\L")
  result.checkReply("250")

proc auth*(smtp: TSMTP, username, password: string) =
  ## Sends an AUTH command to the server to login as the `username` using `password`.
  ## May fail with EInvalidReply.

  smtp.debugSend("AUTH LOGIN\c\L")
  smtp.checkReply("334") # TODO: Check whether it's asking for the "Username:"
                         # i.e "334 VXNlcm5hbWU6"
  smtp.debugSend(encode(username) & "\c\L")
  smtp.checkReply("334") # TODO: Same as above, only "Password:" (I think?)
  
  smtp.debugSend(encode(password) & "\c\L")
  smtp.checkReply("235") # Check whether the authentification was successful.

proc sendmail*(smtp: TSMTP, fromaddr: string,
               toaddrs: seq[string], msg: string) =
  ## Sends `msg` from `fromaddr` to `toaddr`. 
  ## Messages may be formed using ``createMessage`` by converting the TMessage into a string.

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
  
  # quit
  smtp.debugSend("QUIT\c\L")

proc createMessage*(mSubject, mBody: String, mTo, mCc: seq[String],
                otherHeaders: openarray[tuple[name, value: String]]): TMessage =
  ## Creates a new MIME compliant message.
  result.msgTo = mTo
  result.msgCc = mCc
  result.msgSubject = mSubject
  result.msgBody = mBody
  result.msgOtherHeaders = newStringTable()
  for n, v in items(otherHeaders):
    result.msgOtherHeaders[n] = v

proc createMessage*(mSubject, mBody: String, mTo,
                    mCc: seq[String] = @[]): TMessage =
  ## Alternate version of the above.
  result.msgTo = mTo
  result.msgCc = mCc
  result.msgSubject = mSubject
  result.msgBody = mBody
  result.msgOtherHeaders = newStringTable()

proc `$`*(msg: TMessage): String =
  result = ""
  if msg.msgTo.len() > 0:
    result = "TO: " & msg.msgTo.join(", ") & "\c\L"
  if msg.msgCc.len() > 0:
    result.add("CC: " & msg.msgTo.join(", ") & "\c\L")
  # TODO: Folding? i.e when a line is too long, shorten it...
  result.add("Subject: " & msg.msgSubject & "\c\L")
  for key, value in pairs(msg.msgOtherHeaders):
    result.add(key & ": " & value & "\c\L")

  result.add("\c\L" & msg.msgBody)
  

when isMainModule:
  #var msg = createMessage("Test subject!", 
  #     "Hello, my name is dom96.\n What\'s yours?", @["dominik@localhost"])
  #echo(msg)

  #var smtp = connect("localhost", 25, False, True)
  #smtp.sendmail("root@localhost", @["dominik@localhost"], $msg)
  
  #echo(decode("a17sm3701420wbe.12"))
  
  var msg = createMessage("Hello from Nimrod's SMTP!", 
                          "Hello!!!!.\n Is this awesome or what?", 
                          @["someone@yahoo.com", "someone@gmail.com"])
  echo(msg)

  var smtp = connect("smtp.gmail.com", 465, True, True)
  smtp.auth("someone", "password")
  smtp.sendmail("someone@gmail.com", 
                @["someone@yahoo.com", "someone@gmail.com"], $msg)
  
  

