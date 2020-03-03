discard """
action: compile
"""

import asyncdispatch, asyncnet

type
  Client = ref object
    socket: AsyncSocket
    netAddr: string
    id: int
    connected: bool

  Server = ref object
    socket: AsyncSocket
    clients: seq[Client]

proc newServer(): Server =
  ## Constructor for creating a new ``Server``.
  Server(socket: newAsyncSocket(), clients: @[])

proc `$`(client: Client): string =
  ## Converts a ``Client``'s information into a string.
  $client.id & "(" & client.netAddr & ")"

proc processMessages(server: Server, client: Client) {.async.} =
  ## Loops while ``client`` is connected to this server, and checks
  ## whether as message has been received from ``client``.
  while true:
    # Pause execution of this procedure until a line of data is received from
    # ``client``.
    let line = await client.socket.recvLine()

    # The ``recvLine`` procedure returns ``""`` (i.e. a string of length 0)
    # when ``client`` has disconnected.
    if line.len == 0:
      echo(client, " disconnected!")
      client.connected = false
      # When a socket disconnects it must be closed.
      client.socket.close()
      return

    # Display the message that was sent by the client.
    echo(client, " sent: ", line)

    # Send the message to other clients.
    for c in server.clients:
      # Don't send it to the client that sent this or to a client that is
      # disconnected.
      if c.id != client.id and c.connected:
        await c.socket.send(line & "\c\l")

proc loop(server: Server, port = 7687) {.async.} =
  ## Loops forever and checks for new connections.

  # Bind the port number specified by ``port``.
  server.socket.bindAddr(port.Port)
  # Ready the server socket for new connections.
  server.socket.listen()
  echo("Listening on localhost:", port)

  while true:
    # Pause execution of this procedure until a new connection is accepted.
    let (netAddr, clientSocket) = await server.socket.acceptAddr()
    echo("Accepted connection from ", netAddr)

    # Create a new instance of Client.
    let client = Client(
      socket: clientSocket,
      netAddr: netAddr,
      id: server.clients.len,
      connected: true
    )
    # Add this new instance to the server's list of clients.
    server.clients.add(client)
    # Run the ``processMessages`` procedure asynchronously in the background,
    # this procedure will continuously check for new messages from the client.
    asyncCheck processMessages(server, client)

# Check whether this module has been imported as a dependency to another
# module, or whether this module is the main module.
when true:
  # Initialise a new server.
  var server = newServer()
  echo("Server initialised!")
  # Execute the ``loop`` procedure. The ``waitFor`` procedure will run the
  # asyncdispatch event loop until the ``loop`` procedure finishes executing.
  waitFor loop(server)
