import unicode

proc wordWrap*(s: string, maxLineWidth = 80,
               splitLongWords = true,
               newLine = "\n"): string  =
  ## This function breaks all words that reach over `maxLineWidth`
  ## measured in number of runes. When `splitLongWords` is `true`
  ## words that are longer than `maxLineWidth` are splitted. Multiple spaces and newlines are converted to a single space. All
  ## whitespace is treated equally. Non-breaking whitespace is ignored.

  var currentWordLength: int = 0
  var currentWord: string = newStringOfCap(32)
  var currentLineLength: int = 0
  var currentWordLengthAtLineEnd: int = -1
  var longWordMode = false

  template handleWhitespace(): untyped =
    if currentWord.len > 0:

      if currentLineLength + 1 + currentWordLength > maxLineWidth:
        result.add newLine
        currentLineLength = 0

      if currentLineLength > 0:
        result.add ' '
        currentLineLength += 1

      result.add currentWord
      currentLineLength += currentWordLength

      currentWord.setlen 0
      currentWordLength = 0

  for rune in s.runes:
    if rune.isWhiteSpace:
      handleWhitespace()
    else:
      if splitLongWords and currentWordLength >= maxLineWidth:
        handleWhitespace()

      currentWord.add rune
      inc currentWordLength

  handleWhitespace()


when isMainModule:
  import strutils


  proc checkLineLength(arg: string): void =
    for line in splitlines(arg):
      var numRunes = 0
      for rune in runes(line):
        numRunes += 1

      assert numRunes <= 80

  let longlongword = "abc uitdaeröägfßhydüäpydqfü,träpydqgpmüdträpydföägpydörztdüöäfguiaeowäzjdtrüöäp psnrtuiydrözenrüöäpyfdqazpesnrtulocjtüöäzydgyqgfqfgprtnwjlcydkqgfüöezmäzydydqüüöäpdtrnvwfhgckdumböäpydfgtdgfhtdrntdrntydfogiayqfguiatrnydrntüöärtniaoeydfgaoeiqfglwcßqfgxvlcwgtfhiaoenrsüöäapmböäptdrniaoydfglckqfhouenrtsüöäptrniaoeyqfgulocfqclgwxßqflgcwßqfxglcwrniatrnmüböäpmöäbpümöäbpüöämpbaoestnriaesnrtdiaesrtdniaesdrtnaetdriaoenvlcyfglwckßqfgvwkßqgfvlwkßqfgvlwckßqvlwkgfUIαοιαοιαχολωχσωχνωκψρχκψρτιεαοσηζϵηζιοεννκεωνιαλωσωκνκψρκγτφγτχκγτεκργτιχνκιωχσιλωσλωχξλξλξωχωχξχλωωχαοεοιαεοαεοιαεοαεοιαοεσναοεκνρκψγκψφϵιηαααοε"

  checkLineLength(longlongword.wordWrap)

  let tmp ="Наши исследования позволяют сделать вывод о том, что субъект выбирает xxxuiaetudtiraeüöätpghiacodöeronfdquiahgoüöädoiaqofhgiaeotrnuiaßqzfgiaoeurnudtitraenuitenruitarenitarenuitarentduiranetduiranetdruianetrnuiaertnuiatdenruiatdrne институциональный психоз. Важность этой функции подчеркивается тем фактом, что объект вызывает эгоцентризм. Самоактуализация аннигилирует генезис. Анима аннигилирует возрастной код. Закон просветляет аутотренинг. Наши исследования позволяют сделать вывод о том, что воспитание заметно осознаёт инсайт."

  checkLineLength(tmp.wordWrap)
