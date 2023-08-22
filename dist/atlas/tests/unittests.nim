

import std/[unittest, os, strutils]

import context, osutils
from nameresolver import resolveUrl

let
  basicExamples = {
    "balls": (
      # input: "https://github.com/disruptek/balls/tree/master",
      input: "https://github.com/disruptek/balls",
      output: "https://github.com/disruptek/balls",
    ),
    "npeg": (
      input: "https://github.com/zevv/npeg",
      output: "https://github.com/zevv/npeg",
    ),
    "sync": (
      input: "https://github.com/planetis-m/sync",
      output: "https://github.com/planetis-m/sync",
    ),
    "bytes2human": (
      input: "https://github.com/juancarlospaco/nim-bytes2human",
      output: "https://github.com/juancarlospaco/nim-bytes2human",
    )
  }

proc initBasicWorkspace(typ: type AtlasContext): AtlasContext =
  result.workspace = currentSourcePath().parentDir / "ws_basic"

suite "urls and naming":

  test "basic urls":

    var c = AtlasContext.initBasicWorkspace()

    for name, url in basicExamples.items:
      let ures = resolveUrl(c, url.input)
      check ures.hostname == "github.com"
      check $ures == url.output

      let nres = resolveUrl(c, name)
      check nres.hostname == "github.com"
      check $nres == url.output

template v(x): untyped = Version(x)

suite "versions":

  setup:
    let lines {.used.} = dedent"""
    24870f48c40da2146ce12ff1e675e6e7b9748355 1.6.12
    b54236aaee2fc90200cb3a4e7070820ced9ce605 1.6.10
    f06dc8ee3baf8f64cce67a28a6e6e8a8cd9bf04b 1.6.8
    2f85924354af35278a801079b7ff3f8805ff1f5a 1.6.6
    007bf1cb52eac412bc88b3ca2283127ad578ec04 1.6.4
    ee18eda86eef2db0a49788bf0fc8e35996ba7f0d 1.6.2
    1a2a82e94269741b0d8ba012994dd85a53f36f2d 1.6.0
    074f7159752b0da5306bdedb3a4e0470af1f85c0 1.4.8
    4eb05ebab2b4d8b0cd00b19a72af35a2d767819a 1.4.6
    944c8e6d04a044611ed723391272f3c86781eadd 1.4.4
    cd090a6151b452b99d65c5173400d4685916f970 1.4.2
    01dd8c7a959adac4aa4d73abdf62cbc53ffed11b 1.4.0
    1420d508dc4a3e51137647926d4db2f3fa62f43c 1.2.18
    726e3bb1ffc6bacfaab0a0abf0209640acbac807 1.2.16
    80d2206e68cd74020f61e23065c7a22376af8de5 1.2.14
    ddfe3905964fe3db33d7798c6c6c4a493cbda6a3 1.2.12
    6d914b7e6edc29c3b8ab8c0e255bd3622bc58bba 1.2.10
    0d1a9f5933eab686ab3b527b36d0cebd3949a503 1.2.8
    a5a0a9e3cb14e79d572ba377b6116053fc621f6d 1.2.6
    f9829089b36806ac0129c421bf601cbb30c2842c 1.2.4
    8b03d39fd387f6a59c97c2acdec2518f0b18a230 1.2.2
    a8a4725850c443158f9cab38eae3e54a78a523fb 1.2.0
    8b5888e0545ee3d931b7dd45d15a1d8f3d6426ef 1.0.10
    7282e53cad6664d09e8c9efd0d7f263521eda238 1.0.8
    283a4137b6868f1c5bbf0dd9c36d850d086fa007 1.0.6
    e826ff9b48af376fdc65ba22f7aa1c56dc169b94 1.0.4
    4c33037ef9d01905130b22a37ddb13748e27bb7c 1.0.2
    0b6866c0dc48b5ba06a4ce57758932fbc71fe4c2 1.0.0
    a202715d182ce6c47e19b3202e0c4011bece65d8 0.20.2
    8ea451196bd8d77b3592b8b34e7a2c49eed784c9 0.20.0
    1b512cc259b262d06143c4b34d20ebe220d7fb5c 0.19.6
    be22a1f4e04b0fec14f7a668cbaf4e6d0be313cb 0.19.4
    5cbc7f6322de8460cc4d395ed0df6486ae68004e 0.19.2
    79934561e8dde609332239fbc8b410633e490c61 0.19.0
    9c53787087e36b1c38ffd670a077903640d988a8 0.18.0
    a713ffd346c376cc30f8cc13efaee7be1b8dfab9 0.17.2
    2084650f7bf6f0db6003920f085e1a86f1ea2d11 0.17.0
    f7f68de78e9f286b704304836ed8f20d65acc906 0.16.0
    48bd4d72c45f0f0202a0ab5ad9d851b05d363988 0.15.2
    dbee7d55bc107b2624ecb6acde7cabe4cb3f5de4 0.15.0
    0a4854a0b7bcef184f060632f756f83454e9f9de 0.14.2
    5333f2e4cb073f9102f30aacc7b894c279393318 0.14.0
    7e50c5b56d5b5b7b96e56b6c7ab5e104124ae81b 0.13.0
    49bce0ebe941aafe19314438fb724c081ae891aa 0.12.0
    70789ef9c8c4a0541ba24927f2d99e106a6fe6cc 0.11.2
    79cc0cc6e501c8984aeb5b217a274877ec5726bc 0.11.0
    46d829f65086b487c08d522b8d0d3ad36f9a2197 0.10.2
    9354d3de2e1ecc1747d6c42fbfa209fb824837c0 0.9.6
    6bf5b3d78c97ce4212e2dd4cf827d40800650c48 0.9.4
    220d35d9e19b0eae9e7cd1f1cac6e77e798dbc72 0.9.2
    7a70058005c6c76c92addd5fc21b9706717c75e3 0.9.0
    32b4192b3f0771af11e9d850046e5f3dd42a9a5f 0.8.14
    """

  test "basics":
    check v"1.0" < v"1.0.1"
    check v"1.0" < v"1.1"
    check v"1.2.3" < v"1.2.4"
    check v"2.0.0" < v"2.0.0.1"
    check v"2.0.0" < v"20.0"
    check not (v"1.10.0" < v"1.2.0")

  test "hashes":
    check v"1.0" < v"#head"
    check v"#branch" < v"#head"
    check v"#branch" < v"1.0"
    check not (v"#head" < v"#head")
    check not (v"#head" < v"10.0")

  test "version expressions":

    proc p(s: string): VersionInterval =
      var err = false
      result = parseVersionInterval(s, 0, err)
      assert not err

    let tags = parseTaggedVersions(lines)
    let query = p">= 1.2 & < 1.4"
    assert selectBestCommitMinVer(tags, query) == "a8a4725850c443158f9cab38eae3e54a78a523fb"

    let query2 = p">= 1.2 & < 1.4"
    assert selectBestCommitMaxVer(tags, query2) == "1420d508dc4a3e51137647926d4db2f3fa62f43c"

    let query3 = p">= 0.20.0"
    assert selectBestCommitSemVer(tags, query3) == "a202715d182ce6c47e19b3202e0c4011bece65d8"

    let query4 = p"#head"
    assert selectBestCommitSemVer(tags, query4) == "24870f48c40da2146ce12ff1e675e6e7b9748355"

  test "lastPathComponent":
    assert lastPathComponent("/a/bc///") == "bc"
    assert lastPathComponent("a/b") == "b"
    assert lastPathComponent("meh/longer/here/") == "here"
    assert lastPathComponent("meh/longer/here") == "here"
