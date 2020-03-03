discard """
outputsub: "All tests finished successfully!"
"""

import database, os, times

when true:
  removeFile("tweeter_test.db")
  var db = newDatabase("tweeter_test.db")
  db.setup()

  db.create(User(username: "d0m96"))
  db.create(User(username: "nim_lang"))

  db.post(Message(username: "nim_lang", time: getTime() - 4.seconds,
      msg: "Hello Nim in Action readers"))
  db.post(Message(username: "nim_lang", time: getTime(),
      msg: "99.9% off Nim in Action for everyone, for the next minute only!"))

  var dom: User
  doAssert db.findUser("d0m96", dom)
  var nim: User
  doAssert db.findUser("nim_lang", nim)
  db.follow(dom, nim)

  doAssert db.findUser("d0m96", dom)

  let messages = db.findMessages(dom.following)
  echo(messages)
  doAssert(messages[0].msg == "99.9% off Nim in Action for everyone, for the next minute only!")
  doAssert(messages[1].msg == "Hello Nim in Action readers")
  echo("All tests finished successfully!")
