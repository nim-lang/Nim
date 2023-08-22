#
#            Nim - SSL integration tests
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Warning: this test performs external networking.
##
## Test with:
## ./bin/nim c -d:ssl -p:. -r tests/untestable/tssl.nim
## ./bin/nim c -d:ssl -p:. --dynlibOverride:ssl --passL:-lcrypto --passL:-lssl -r tests/untestable/tssl.nim
## The compilation is expected to succeed with any new/old version of OpenSSL,
## both with dynamic and static linking.
## The "howsmyssl" test is known to fail with OpenSSL < 1.1 due to insecure
## cypher suites being used.

import httpclient, os
from strutils import contains, toHex

from openssl import getOpenSSLVersion

when true:
  echo "version: 0x" & $getOpenSSLVersion().toHex()

  let client = newHttpClient()
  # hacky SSL check
  const url = "https://www.howsmyssl.com"
  let report = client.getContent(url)
  if not report.contains(">Probably Okay</span>"):
    let fn = getTempDir() / "sslreport.html"
    echo "SSL CHECK ERROR, see " & fn
    writeFile(fn, report)
    quit(1)

  echo "done"
