when defined(genode):
  include genode/asynctcpip
else:
  include bsdsockets/asyncnet
