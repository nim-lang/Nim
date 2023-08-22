--threads:on
--d:ssl
when defined(freebsd) or defined(netbsd):
  # See https://github.com/nim-lang/Nim/pull/15066#issuecomment-665541265 and https://github.com/nim-lang/Nim/issues/15493
  --tlsEmulation:off
