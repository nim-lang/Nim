import zmq

var connection = zmq.open("tcp://*:5555", server=true)

while True:
  var request = receive(connection)
  echo("Received: ", request)
  send(connection, "World")
  
close(connection)

