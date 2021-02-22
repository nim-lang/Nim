#[
bug #16338
reduced from `thttpclient_ssl_remotenetwork`
]#

when defined nimTestsT16338Case1:
  import
    httpclient,
    net,
    strutils,
    threadpool,
    unittest

  type
    Category = enum
      good, bad, dubious, good_broken, bad_broken, dubious_broken
    CertTest = tuple[url:string, category:Category, desc: string]

  const certificate_tests: array[0..55, CertTest] = [
    ("https://wrong.host.badssl.com/", bad, "wrong.host"),
    ("https://captive-portal.badssl.com/", bad, "captive-portal"),
    ("https://expired.badssl.com/", bad, "expired"),
    ("https://google.com/", good, "good"),
    ("https://self-signed.badssl.com/", bad, "self-signed"),
    ("https://untrusted-root.badssl.com/", bad, "untrusted-root"),
    ("https://revoked.badssl.com/", bad_broken, "revoked"),
    ("https://pinning-test.badssl.com/", bad_broken, "pinning-test"),
    ("https://no-common-name.badssl.com/", dubious_broken, "no-common-name"),
    ("https://no-subject.badssl.com/", dubious_broken, "no-subject"),
    ("https://incomplete-chain.badssl.com/", dubious_broken, "incomplete-chain"),
    ("https://sha1-intermediate.badssl.com/", bad, "sha1-intermediate"),
    ("https://sha256.badssl.com/", good, "sha256"),
    ("https://sha384.badssl.com/", good, "sha384"),
    ("https://sha512.badssl.com/", good, "sha512"),
    ("https://1000-sans.badssl.com/", good, "1000-sans"),
    ("https://10000-sans.badssl.com/", good_broken, "10000-sans"),
    ("https://ecc256.badssl.com/", good, "ecc256"),
    ("https://ecc384.badssl.com/", good, "ecc384"),
    ("https://rsa2048.badssl.com/", good, "rsa2048"),
    ("https://rsa8192.badssl.com/", dubious_broken, "rsa8192"),
    ("http://http.badssl.com/", good, "regular http"),
    ("https://http.badssl.com/", bad_broken, "http on https URL"),  # FIXME
    ("https://cbc.badssl.com/", dubious, "cbc"),
    ("https://rc4-md5.badssl.com/", bad, "rc4-md5"),
    ("https://rc4.badssl.com/", bad, "rc4"),
    ("https://3des.badssl.com/", bad, "3des"),
    ("https://null.badssl.com/", bad, "null"),
    ("https://mozilla-old.badssl.com/", bad_broken, "mozilla-old"),
    ("https://mozilla-intermediate.badssl.com/", dubious_broken, "mozilla-intermediate"),
    ("https://mozilla-modern.badssl.com/", good, "mozilla-modern"),
    ("https://dh480.badssl.com/", bad, "dh480"),
    ("https://dh512.badssl.com/", bad, "dh512"),
    ("https://dh1024.badssl.com/", dubious_broken, "dh1024"),
    ("https://dh2048.badssl.com/", good, "dh2048"),
    ("https://dh-small-subgroup.badssl.com/", bad_broken, "dh-small-subgroup"),
    ("https://dh-composite.badssl.com/", bad_broken, "dh-composite"),
    ("https://static-rsa.badssl.com/", dubious, "static-rsa"),
    ("https://tls-v1-0.badssl.com:1010/", dubious, "tls-v1-0"),
    ("https://tls-v1-1.badssl.com:1011/", dubious, "tls-v1-1"),
    ("https://invalid-expected-sct.badssl.com/", bad, "invalid-expected-sct"),
    ("https://hsts.badssl.com/", good, "hsts"),
    ("https://upgrade.badssl.com/", good, "upgrade"),
    ("https://preloaded-hsts.badssl.com/", good, "preloaded-hsts"),
    ("https://subdomain.preloaded-hsts.badssl.com/", bad, "subdomain.preloaded-hsts"),
    ("https://https-everywhere.badssl.com/", good, "https-everywhere"),
    ("https://long-extended-subdomain-name-containing-many-letters-and-dashes.badssl.com/", good,
      "long-extended-subdomain-name-containing-many-letters-and-dashes"),
    ("https://longextendedsubdomainnamewithoutdashesinordertotestwordwrapping.badssl.com/", good,
      "longextendedsubdomainnamewithoutdashesinordertotestwordwrapping"),
    ("https://superfish.badssl.com/", bad, "(Lenovo) Superfish"),
    ("https://edellroot.badssl.com/", bad, "(Dell) eDellRoot"),
    ("https://dsdtestprovider.badssl.com/", bad, "(Dell) DSD Test Provider"),
    ("https://preact-cli.badssl.com/", bad, "preact-cli"),
    ("https://webpack-dev-server.badssl.com/", bad, "webpack-dev-server"),
    ("https://mitm-software.badssl.com/", bad, "mitm-software"),
    ("https://sha1-2016.badssl.com/", dubious, "sha1-2016"),
    ("https://sha1-2017.badssl.com/", bad, "sha1-2017"),
  ]

  type
    TTOutcome = ref object
      desc, exception_msg: string
      category: Category

  proc run_t_test(ct: CertTest): TTOutcome {.thread.} =
    result = TTOutcome(desc:ct.desc, exception_msg:"", category: ct.category)
    try:
      var ctx = newContext(verifyMode=CVerifyPeer)
      var client = newHttpClient(sslContext=ctx)
      let a = $client.getContent(ct.url)
    except:
      result.exception_msg = getCurrentExceptionMsg()

  proc main =
    var outcomes = newSeq[FlowVar[TTOutcome]](certificate_tests.len)
    for i, ct in certificate_tests:
      let t = spawn run_t_test(ct)
      outcomes[i] = t

    var count = 0
    for t in outcomes:
      count.inc
      echo ("count", count, certificate_tests[count].url)
      let outcome = ^t

  for i in 0..<10:
    echo (i, "D20210219T180743")
    main()

else:
  import std/[os, strformat]
  const nim = getCurrentCompilerExe()
  const file = currentSourcePath
  for i2 in 0..<15:
    let cmd = fmt"{nim} r -d:nimTestsT16338Case1 --threads -d:ssl {file}"
    let status = execShellCmd(cmd)
    echo (i2, status == 0, status, "D20210219T180250")
