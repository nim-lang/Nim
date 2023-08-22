discard """
  output: '''@[(username: "user", role: "admin", description: "desc", email_addr: "email"), (username: "user", role: "admin", description: "desc", email_addr: "email")]'''
"""

type
  User = object of RootObj
    username, role, description, email_addr: string

# bug 5055
let us4 = @[
  User(username:"user", role:"admin", description:"desc", email_addr:"email"),
  User(username:"user", role:"admin", description:"desc", email_addr:"email"),
]
echo us4
