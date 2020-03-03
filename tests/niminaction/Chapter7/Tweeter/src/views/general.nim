#? stdtmpl(subsChar = '$', metaChar = '#')
#import "../database"
#import user
#import xmltree
#
#proc `$!`(text: string): string = escape(text)
#end proc
#
#proc renderMain*(body: string): string =
#  result = ""
<!DOCTYPE html>
<html>
  <head>
    <title>Tweeter written in Nim</title>
    <link rel="stylesheet" type="text/css" href="style.css">
  </head>

  <body>
    ${body}
  </body>

</html>
#end proc
#
#proc renderLogin*(): string =
#  result = ""
<div id="login">
  <span>Login</span>
  <span class="small">Please type in your username...</span>
  <form action="login" method="post">
    <input type="text" name="username">
    <input type="submit" value="Login">
  </form>
</div>
#end proc
#
#proc renderTimeline*(username: string, messages: seq[Message]): string =
#  result = ""
<div id="user">
  <h1>${$!username}'s timeline</h1>
</div>
<div id="newMessage">
  <span>New message</span>
  <form action="createMessage" method="post">
    <input type="text" name="message">
    <input type="hidden" name="username" value="${$!username}">
    <input type="submit" value="Tweet">
  </form>
</div>
${renderMessages(messages)}
#end proc