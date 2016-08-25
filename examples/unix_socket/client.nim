import net

let sock = newSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)

sock.connectUnix("sock")
sock.send("hello\n")
