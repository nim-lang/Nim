discard """
  targets: "c cpp"
  joinable: false
"""

#[
runs tests that depend on 3rd party code and requires special treatment.
]#

import std/[strformat,os]
import stdtest/specialpaths

const
  nim = getCurrentCompilerExe()
  mode =
    when defined(c): "c"
    elif defined(cpp): "cpp"
    else: static: doAssert false

proc runCmd(cmd: string) =
  let ret = execShellCmd(cmd)
  doAssert ret == 0

proc main =
  let options = fmt"-b:{mode} --hints:off"
  block: # SSL nimDisableCertificateValidation integration tests
    runCmd fmt"{nim} r {options} -d:nimDisableCertificateValidation -d:ssl {testsDir}/untestable/thttpclient_ssl_disabled.nim"
  block: # SSL certificate check integration tests
    when not defined(windows): # Not supported on Windows due to old openssl version
      runCmd fmt"{nim} r {options} -d:ssl --threads:on {testsDir}/untestable/thttpclient_ssl.nim"

main()
