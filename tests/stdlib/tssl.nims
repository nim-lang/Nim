--threads:on
--d:ssl
when defined(freebsd):
  # See https://github.com/nim-lang/Nim/pull/15066#issuecomment-665541265
  --tlsEmulation:off
