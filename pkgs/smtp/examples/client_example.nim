# To test with a real SMTP service, create a smtp.ini file, e.g.:
# username = ""
# password = ""
# smtphost = "smtp.gmail.com"
# port = 465
# use_tls = true
# sender = ""
# recipient = ""

import smtp, asyncdispatch, strutils, parsecfg

proc `[]`(c: Config, key: string): string = c.getSectionValue("", key)

let
  conf = loadConfig("smtp.ini")
  msg = createMessage("Hello from Nim's SMTP!",
    "Hello!\n Is this awesome or what?", @[conf["recipient"]])

assert conf["smtphost"] != ""

proc async_test() {.async.} =
  let client = newAsyncSmtp(
    conf["use_tls"].parseBool,
    debug = true
  )
  await client.connect(conf["smtphost"], conf["port"].parseInt.Port)
  await client.auth(conf["username"], conf["password"])
  await client.sendMail(conf["sender"], @[conf["recipient"]], $msg)
  await client.close()
  echo "async email sent"

proc sync_test() =
  var smtpConn = newSmtp(
    conf["use_tls"].parseBool,
    debug = true
  )
  smtpConn.connect(conf["smtphost"], conf["port"].parseInt.Port)
  smtpConn.auth(conf["username"], conf["password"])
  smtpConn.sendMail(conf["sender"], @[conf["recipient"]], $msg)
  smtpConn.close()
  echo "sync email sent"

waitFor async_test()
sync_test()
