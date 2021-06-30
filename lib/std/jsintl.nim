## * `Internationalization API <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl>`_
when not defined(js): {.error: "This module only works for JavaScript targets".}

type
  Intl* = ref object of JsRoot
  Collator* = ref object of JsRoot           ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator
  ListFormat* = ref object of JsRoot         ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/ListFormat
  NumberFormat* = ref object of JsRoot       ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat
  PluralRules* = ref object of JsRoot        ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/PluralRules
  RelativeTimeFormat* = ref object of JsRoot ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/RelativeTimeFormat

func getCanonicalLocales*(self: Intl; locales: cstring): seq[cstring] {.importjs: "#.$1(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/getCanonicalLocales
  runnableExamples: assert intl.getCanonicalLocales("eN-us".cstring) == @["en-US".cstring]

func getCanonicalLocales*(self: Intl; locales: openArray[cstring]): seq[cstring] {.importjs: "#.$1(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/getCanonicalLocales
  runnableExamples: assert intl.getCanonicalLocales(["eN-us".cstring]) == @["en-US".cstring]

func newCollator*(self: Intl): Collator {.importjs: "new #.Collator()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/Collator

func newCollator*(self: Intl; locales: cstring): Collator {.importjs: "new #.Collator(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/Collator
  runnableExamples: assert intl.newCollator("en".cstring) is Collator

func newCollator*(self: Intl; locales: openArray[cstring]): Collator {.importjs: "new #.Collator(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/Collator
  runnableExamples: assert intl.newCollator(["en".cstring, "es".cstring]) is Collator

func compare*(self: Collator; string1, string2: cstring): int {.importjs: "#.$1(#, #)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/compare
  runnableExamples:
    let deCollator: Collator = intl.newCollator("de".cstring)
    let svCollator: Collator = intl.newCollator("sv".cstring)
    assert deCollator.compare("z", "ä") > 0
    assert svCollator.compare("z", "ä") < 0

func format*(self: ListFormat; list: openArray[cstring]): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/ListFormat/format

func newListFormat*(self: Intl): ListFormat {.importjs: "new #.ListFormat()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/ListFormat/ListFormat

func newListFormat*(self: Intl; locales: openArray[cstring]): ListFormat {.importjs: "new #.ListFormat(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/ListFormat/ListFormat
  runnableExamples:
    let enFormat: ListFormat = intl.newListFormat(["en".cstring])
    let esFormat: ListFormat = intl.newListFormat(["es".cstring])
    assert enFormat.format(["bike".cstring, "bus", "car"]) == "bike, bus, and car".cstring
    assert esFormat.format(["bike".cstring, "bus", "car"]) == "bike, bus y car".cstring

func newNumberFormat*(self: Intl): NumberFormat {.importjs: "new #.NumberFormat()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat/NumberFormat

func newNumberFormat*(self: Intl; locales: openArray[cstring]): NumberFormat {.importjs: "new #.NumberFormat(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat/NumberFormat
  runnableExamples:
    let enFormat: NumberFormat = intl.newNumberFormat(["en".cstring])
    let esFormat: NumberFormat = intl.newNumberFormat(["es".cstring])
    assert enFormat.format(123456.789) == "123,456.789".cstring
    assert esFormat.format(123456.789) == "123.456,789".cstring

func format*(self: NumberFormat; number: SomeNumber): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat/format

func newPluralRules*(self: Intl): PluralRules {.importjs: "new #.PluralRules()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/PluralRules/PluralRules

func newPluralRules*(self: Intl; locales: openArray[cstring]): PluralRules {.importjs: "new #.PluralRules(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/PluralRules/PluralRules
  runnableExamples:
    let enFormat: PluralRules = intl.newPluralRules(["en".cstring])
    assert enFormat.select(0) == "other".cstring
    assert enFormat.select(1) == "one".cstring

func select*(self: PluralRules; number: SomeInteger): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/PluralRules/select

func newRelativeTimeFormat*(self: Intl): RelativeTimeFormat {.importjs: "new #.RelativeTimeFormat()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/RelativeTimeFormat/RelativeTimeFormat

func newRelativeTimeFormat*(self: Intl; locales: openArray[cstring]): RelativeTimeFormat {.importjs: "new #.RelativeTimeFormat(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/RelativeTimeFormat/RelativeTimeFormat
  runnableExamples:
    let enFormat: RelativeTimeFormat = intl.newRelativeTimeFormat(["en".cstring])
    assert enFormat.format(-9, "day") == "9 days ago".cstring
    assert enFormat.format(9, "day") == "in 9 days".cstring
    assert enFormat.format(0, "day") == "in 0 days".cstring
    assert enFormat.format(123456789, "second") == "in 123,456,789 seconds".cstring

func format*(self: RelativeTimeFormat; value: SomeNumber; unit: cstring): cstring {.importjs: "#.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/RelativeTimeFormat/format

var intl* {.importjs: "Intl", nodecl.}: Intl
