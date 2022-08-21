import punycode, std/unicode

doAssert(decode(encode("", "bücher")) == "bücher")
doAssert(decode(encode("münchen")) == "münchen")
doAssert encode("xn--", "münchen") == "xn--mnchen-3ya"

# source: https://datatracker.ietf.org/doc/html/rfc3492.html#section-7
let punycode_testcases = [
  # (A) Arabic (Egyptian):
  (
    input:
      "\u0644\u064A\u0647\u0645\u0627\u0628\u062A\u0643\u0644" &
      "\u0645\u0648\u0634\u0639\u0631\u0628\u064A\u061F",
    output:
      "egbpdaj6bu4bxfgehfvwxn"
  ),

  # (B) Chinese (simplified):
  (
    input:
      "\u4ED6\u4EEC\u4E3A\u4EC0\u4E48\u4E0D\u8BF4\u4E2D\u6587",
    output:
      "ihqwcrb4cv8a8dqg056pqjye"
  ),

  # (C) Chinese (traditional):
  (
    input:
      "\u4ED6\u5011\u7232\u4EC0\u9EBD\u4E0D\u8AAA\u4E2D\u6587",
    output:
      "ihqwctvzc91f659drss3x8bo0yb"
  ),

  # (D) Czech: Pro<ccaron>prost<ecaron>nemluv<iacute><ccaron>esky
  (
    input:
      "\u0050\u0072\u006F\u010D\u0070\u0072\u006F\u0073\u0074" &
      "\u011B\u006E\u0065\u006D\u006C\u0075\u0076\u00ED\u010D" &
      "\u0065\u0073\u006B\u0079",
    output:
      "Proprostnemluvesky-uyb24dma41a"
  ),

  # (E) Hebrew:
  (
    input:
      "\u05DC\u05DE\u05D4\u05D4\u05DD\u05E4\u05E9\u05D5\u05D8" &
      "\u05DC\u05D0\u05DE\u05D3\u05D1\u05E8\u05D9\u05DD\u05E2" &
      "\u05D1\u05E8\u05D9\u05EA",
    output:
      "4dbcagdahymbxekheh6e0a7fei0b"
  ),

  # (F) Hindi (Devanagari):
  (
    input:
      "\u092F\u0939\u0932\u094B\u0917\u0939\u093F\u0928\u094D" &
      "\u0926\u0940\u0915\u094D\u092F\u094B\u0902\u0928\u0939" &
      "\u0940\u0902\u092C\u094B\u0932\u0938\u0915\u0924\u0947" &
      "\u0939\u0948\u0902",
    output:
      "i1baa7eci9glrd9b2ae1bj0hfcgg6iyaf8o0a1dig0cd"
  ),

  # (G) Japanese (kanji and hiragana):
  (
    input:
      "\u306A\u305C\u307F\u3093\u306A\u65E5\u672C\u8A9E\u3092" &
      "\u8A71\u3057\u3066\u304F\u308C\u306A\u3044\u306E\u304B",
    output:
      "n8jok5ay5dzabd5bym9f0cm5685rrjetr6pdxa"
  ),

  # (H) Korean (Hangul syllables):
  (
    input:
      "\uC138\uACC4\uC758\uBAA8\uB4E0\uC0AC\uB78C\uB4E4\uC774" &
      "\uD55C\uAD6D\uC5B4\uB97C\uC774\uD574\uD55C\uB2E4\uBA74" &
      "\uC5BC\uB9C8\uB098\uC88B\uC744\uAE4C",
    output:
      "989aomsvi5e83db1d2a355cv1e0vak1dwrv93d5xbh15a0dt30a5jpsd879ccm6fea98c"
  ),

  # (I) Russian (Cyrillic):
  (
    input:
      "\u043F\u043E\u0447\u0435\u043C\u0443\u0436\u0435\u043E" &
      "\u043D\u0438\u043D\u0435\u0433\u043E\u0432\u043E\u0440" &
      "\u044F\u0442\u043F\u043E\u0440\u0443\u0441\u0441\u043A" &
      "\u0438",
    output:
      "b1abfaaepdrnnbgefbaDotcwatmq2g4l"
  ),

  # (J) Spanish: Porqu<eacute>nopuedensimplementehablarenEspa<ntilde>ol
  (
    input:
      "\u0050\u006F\u0072\u0071\u0075\u00E9\u006E\u006F\u0070" &
      "\u0075\u0065\u0064\u0065\u006E\u0073\u0069\u006D\u0070" &
      "\u006C\u0065\u006D\u0065\u006E\u0074\u0065\u0068\u0061" &
      "\u0062\u006C\u0061\u0072\u0065\u006E\u0045\u0073\u0070" &
      "\u0061\u00F1\u006F\u006C",
    output:
      "PorqunopuedensimplementehablarenEspaol-fmd56a"
  ),

  # (K) Vietnamese:
  #  T<adotbelow>isaoh<odotbelow>kh<ocirc>ngth<ecirchookabove>ch\
  #   <ihookabove>n<oacute>iti<ecircacute>ngVi<ecircdotbelow>t
  (
    input:
      "\u0054\u1EA1\u0069\u0073\u0061\u006F\u0068\u1ECD\u006B" &
      "\u0068\u00F4\u006E\u0067\u0074\u0068\u1EC3\u0063\u0068" &
      "\u1EC9\u006E\u00F3\u0069\u0074\u0069\u1EBF\u006E\u0067" &
      "\u0056\u0069\u1EC7\u0074",
    output:
      "TisaohkhngthchnitingVit-kjcr8268qyxafd2f1b9g"
  ),

  # (L) 3<nen>B<gumi><kinpachi><sensei>
  (
    input:
      "\u0033\u5E74\u0042\u7D44\u91D1\u516B\u5148\u751F",
    output:
      "3B-ww4c5e180e575a65lsy2b"
  ),

  # (M) <amuro><namie>-with-SUPER-MONKEYS
  (
    input:
      "\u5B89\u5BA4\u5948\u7F8E\u6075\u002D\u0077\u0069\u0074" &
      "\u0068\u002D\u0053\u0055\u0050\u0045\u0052\u002D\u004D" &
      "\u004F\u004E\u004B\u0045\u0059\u0053",
    output:
      "-with-SUPER-MONKEYS-pc58ag80a8qai00g7n9n"
  ),

  # (N) Hello-Another-Way-<sorezore><no><basho>
  (
    input:
      "\u0048\u0065\u006C\u006C\u006F\u002D\u0041\u006E\u006F" &
      "\u0074\u0068\u0065\u0072\u002D\u0057\u0061\u0079\u002D" &
      "\u305D\u308C\u305E\u308C\u306E\u5834\u6240",
    output:
      "Hello-Another-Way--fc4qua05auwb3674vfr0b"
  ),

  # (O) <hitotsu><yane><no><shita>2
  (
    input:
      "\u3072\u3068\u3064\u5C4B\u6839\u306E\u4E0B\u0032",
    output:
      "2-u9tlzr9756bt3uc0v"
  ),

  # (P) Maji<de>Koi<suru>5<byou><mae>
  (
    input:
      "\u004D\u0061\u006A\u0069\u3067\u004B\u006F\u0069\u3059" &
      "\u308B\u0035\u79D2\u524D",
    output:
      "MajiKoi5-783gue6qz075azm5e"
  ),

    # (Q) <pafii>de<runba>
  (
    input:
      "\u30D1\u30D5\u30A3\u30FC\u0064\u0065\u30EB\u30F3\u30D0",
    output:
      "de-jg4avhby1noc0d"
  ),

  # (R) <sono><supiido><de>
  (
    input:
      "\u305D\u306E\u30B9\u30D4\u30FC\u30C9\u3067",
    output:
      "d9juau41awczczp"
  ),

  # (S) -> $1.00 <-
  (
    input:
      "\u002D\u003E\u0020\u0024\u0031\u002E\u0030\u0030\u0020" &
      "\u003C\u002D",
    output:
      "-> $1.00 <--"
  )
]

block encodeTests:
  for (uni, puny) in punycode_testcases:
    # Need to convert both strings to lower case, since
    # some of the extended encodings use upper case, but our
    # code produces only lower case. Converting just puny to
    # lower is also insufficient, since some of the input characters
    # are upper case.
    doAssert encode(uni).toLower() == puny.toLower()

block decodeTests:
  for (uni, puny) in punycode_testcases:
    doAssert decode(puny) == uni

block decodeInvalidTest:
  doAssertRaises(PunyError): discard decode("xn--w&")
