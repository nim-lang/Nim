discard """
  targets: "c cpp"
  joinable: false
"""

#[
Runs tests that require special treatment, e.g. because they rely on 3rd party code
or require external networking.

xxx test all tests/untestable/* here, possibly with adjustments to make running times reasonable
]#

import std/[strformat,os,unittest,compilesettings]
import stdtest/specialpaths

const
  nim = getCurrentCompilerExe()
  mode = querySetting(backend)

proc runCmd(cmd: string) =
  let ret = execShellCmd(cmd)
  check ret == 0 # allows more than 1 failure

proc main =
  let options = fmt"-b:{mode} --hints:off"
  block: # SSL nimDisableCertificateValidation integration tests
    runCmd fmt"{nim} r {options} -d:nimDisableCertificateValidation -d:ssl {testsDir}/untestable/thttpclient_ssl_disabled.nim"
  block: # SSL certificate check integration tests
    runCmd fmt"{nim} r {options} -d:ssl --threads:on {testsDir}/untestable/thttpclient_ssl_remotenetwork.nim"

main()
