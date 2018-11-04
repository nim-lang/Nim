import unicode

proc addSubstrExcl(self: var string, str: string; a,b: int) =
  ## equivalent to ``self.add str.substr(a,b-1)``. Exclusive upper bound.
  if a > b:
    echo a, " ", b
  assert a <= b

  if a < b:
    let idx = self.len
    self.setLen idx + b - a
    copyMem(self[idx].addr, str[a].unsafeAddr, b - a)

let tmp ="Наши исследования позволяют сделать вывод о том, что субъект выбирает uiaetudtiraeüöätpghiacodöeronfdquiahgoüöädoiaqofhgiaeotrnuiaßqzfgiaoeurnudtitraenuitenruitarenitarenuitarentduiranetduiranetdruianetrnuiaertnuiatdenruiatdrne институциональный психоз. Важность этой функции подчеркивается тем фактом, что объект вызывает эгоцентризм. Самоактуализация аннигилирует генезис. Анима аннигилирует возрастной код. Закон просветляет аутотренинг. Наши исследования позволяют сделать вывод о том, что воспитание заметно осознаёт инсайт."

proc wordWrap*(s: string, maxLineWidth = 80,
               splitLongWords = true,
               newLine = "\n"): string  =

  var currentWordLength: int = 0
  var currentWord: string = newStringOfCap(32)
  var currentLineLength: int = 0
  var currentWordLineEndMark: int = -1
  var currentWordLengthAtLineEnd: int = -1

  template handleWhitespace(): untyped =
    if currentWord.len > 0:

      if currentLineLength + 1 + currentWordLength > maxLineWidth:
        var splitWord = splitLongWords
        if splitLongWords:
          # arbitrary minimum length of words to split
          splitWord = currentWordLength > maxLineWidth div 2
          if currentWordLengthAtLineEnd <= 3:
            # does the current word fit in the next line?
            if currentWordLength <= maxLineWidth:
              splitWord = false

        if splitWord:
          result.addSubstrExcl(currentWord, 0, currentWordLineEndMark)
          result.add newLine
          result.addSubstrExcl(currentWord, currentWordLineEndMark, currentWord.len)
          currentLineLength = currentWordLength - currentWordLengthAtLineEnd
        else:
          result.add newLine
          currentLineLength = 0

      if currentLineLength > 0:
        result.add ' '
        currentLineLength += 1

      result.add currentWord
      currentLineLength += currentWordLength

      currentWord.setlen 0
      currentWordLength = 0

      currentWordLineEndMark = -1

  for rune in s.runes:
    if rune.isWhiteSpace:
      handleWhitespace()
    else:
      currentWord.add rune
      inc currentWordLength

      if splitLongWords:
        # the word reached the end of the current line
        if currentLineLength + 1 + currentWordLength == maxLineWidth:
          assert(currentWordLineEndMark == -1)
          currentWordLineEndMark = currentWord.len
          currentWordLengthAtLineEnd = currentWordLength

        # the word reached the end of the next line
        if currentWordLength - currentWordLengthAtLineEnd == maxLineWidth:
          # superlong word, stop being smart.
          result.addSubstrExcl(currentWord, 0, currentWordLineEndMark)
          result.add newLine

          currentWord.
currentWordLineEndMark()
          currentWordLength = currentWordLength - currentWordLengthAtLineEnd

          handleWhitespace()
          currentWordLineEndMark = maxLineWidth

  handleWhitespace()

echo wordWrap(tmp)


import strutils

echo strutils.wordWrap(tmp, splitLongWords=true)
echo strutils.wordWrap(tmp, splitLongWords=false)

  # result = newStringOfCap(s.len + s.len shr 6)
  # var spaceLeft = maxLineWidth
  # var lastSep = ""
  # for word, isSep in tokenize(s, seps):
  #   if isSep:
  #     lastSep = word
  #     spaceLeft = spaceLeft - len(word)
  #     continue
  #   if len(word) > spaceLeft:
  #     if splitLongWords and len(word) > maxLineWidth:
  #       result.add(substr(word, 0, spaceLeft-1))
  #       var w = spaceLeft
  #       var wordLeft = len(word) - spaceLeft
  #       while wordLeft > 0:
  #         result.add(newLine)
  #         var L = min(maxLineWidth, wordLeft)
  #         spaceLeft = maxLineWidth - L
  #         result.add(substr(word, w, w+L-1))
  #         inc(w, L)
  #         dec(wordLeft, L)
  #     else:
  #       spaceLeft = maxLineWidth - len(word)
  #       result.add(newLine)
  #       result.add(word)
  #   else:
  #     spaceLeft = spaceLeft - len(word)
  #     result.add(lastSep & word)
  #     lastSep.setLen(0)
