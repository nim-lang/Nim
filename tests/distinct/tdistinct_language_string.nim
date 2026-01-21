type
  Language = enum
    English
    German

  LanguageString[L: static Language] = string

  english = LanguageString[English]
  german = LanguageString[German]

proc checkValid(str: english): auto =
  return "got english"

proc checkValid(str: german): auto =
  return "got german"

var text = "hello! ".english
text &= "how are you?".english

doAssert checkValid(text) == "got english"

doAssert checkValid("hallo".german) == "got german"
