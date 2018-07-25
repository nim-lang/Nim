when defined(genode):
  include genode/tcpip
else:
  include bsdsockets/net
