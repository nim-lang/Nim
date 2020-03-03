discard """
action: compile
"""

import os, threadpool, asyncdispatch, asyncnet
import protocol

proc connect(socket: AsyncSocket, serverAddr: string) {.async.} =
  ## Connects the specified AsyncSocket to the specified address.
  ## Then receives messages from the server continuously.
  echo("Connecting to ", serverAddr)
  # Pause the execution of this procedure until the socket connects to
  # the specified server.
  await socket.connect(serverAddr, 7687.Port)
  echo("Connected!")
  while true:
    # Pause the execution of this procedure until a new message is received
    # from the server.
    let line = await socket.recvLine()
    # Parse the received message using ``parseMessage`` defined in the
    # protocol module.
    let parsed = parseMessage(line)
    # Display the message to the user.
    echo(parsed.username, " said ", parsed.message)

echo("Chat application started")
# Ensure that the correct amount of command line arguments was specified.
if paramCount() < 2:
  # Terminate the client early with an error message if there was not
  # enough command line arguments specified by the user.
  quit("Please specify the server address, e.g. ./client localhost username")

# Retrieve the first command line argument.
let serverAddr = paramStr(1)
# Retrieve the second command line argument.
let username = paramStr(2)
# Initialise a new asynchronous socket.
var socket = newAsyncSocket()

# Execute the ``connect`` procedure in the background asynchronously.
asyncCheck connect(socket, serverAddr)
# Execute the ``readInput`` procedure in the background in a new thread.
var messageFlowVar = spawn stdin.readLine()
while true:
  # Check if the ``readInput`` procedure returned a new line of input.
  if messageFlowVar.isReady():
    # If a new line of input was returned, we can safely retrieve it
    # without blocking.
    # The ``createMessage`` is then used to create a message based on the
    # line of input. The message is then sent in the background asynchronously.
    asyncCheck socket.send(createMessage(username, ^messageFlowVar))
    # Execute the ``readInput`` procedure again, in the background in a
    # new thread.
    messageFlowVar = spawn stdin.readLine()

  # Execute the asyncdispatch event loop, to continue the execution of
  # asynchronous procedures.
  asyncdispatch.poll()
