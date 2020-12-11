discard """
  targets: "c cpp"
  joinable: false
"""

#[
Runs tests that require special treatment, e.g. because they rely on 3rd party code
or require external networking.

xxx test all tests/untestable/* here, possibly with adjustments to make running times reasonable
]#

import std/[strformat,os,unittest]
import stdtest/specialpaths

const
  nim = getCurrentCompilerExe()
  mode =
    when defined(c): "c"
    elif defined(cpp): "cpp"
    else: static: doAssert false

proc runCmd(cmd: string) =
  let ret = execShellCmd(cmd)
  check ret == 0 # allows more than 1 failure

proc main =
  let options = fmt"-b:{mode} --hints:off"
  block: # SSL nimDisableCertificateValidation integration tests
    when not defined(openbsd):
      runCmd fmt"{nim} r {options} -d:nimDisableCertificateValidation -d:ssl {testsDir}/untestable/thttpclient_ssl_disabled.nim"
  block: # SSL certificate check integration tests
    when not defined(windows) and not defined(openbsd): # Not supported on Windows due to old openssl version
      runCmd fmt"{nim} r {options} -d:ssl --threads:on {testsDir}/untestable/thttpclient_ssl.nim"

main()
