import zmq

var connection = zmq.open("tcp://localhost:5555", server=false)

echo("Connecting...")

for i in 0..10:
  echo("Sending hello...", i)
  send(connection, "Hello")
  
  var reply = receive(connection)
  echo("Received ...", reply)

close(connection)
