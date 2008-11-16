# Lexer generator for Nimrod
#   (c) 2008 Andreas Rumpf

# Stress testing for the macro feature

# the syntax that should be supported is:

# template numpostfix = 
#   '\'' & 'F'|'f'|'i'|'I' & "32"|"64"|"8"|"16"
# template edigits = 
#   'e'|'E' & +digits
# tokens(
#   tkIdent: +UniIdentStart & *UniIdentRest,
#   tkHexNumber: '0' & ('x'|'X') & +hexDigits & ?( numpostfix ),
#   tkOctNumber: '0' & ('c'|'C') & +octDigits & ?( numpostfix ),
#   tkBinNumber: '0' & ('b'|'B') & +binDigits & ?( numpostfix ),
#   tkIntNumber: +digits & ?( numpostfix ), 
#   tkFloatNumber: +digits & ('.' & +digits & ?(edigits) | edigits) & ?(numpostfix),
#   
# )
# actions(
#   tkIdent: lookup
# ) 
# 

#
#  match inputstream
#  of +('A'..'Z' | '_' | 'a'..'z') *('A'..'Z' | '_' | 'a'..'z' | '0'..'9') :
#    
#    x = inputstream[pos..length]
#  of '0' 'x' +('0'..'9' | 'a'..'f' | '_' | 'A'..'F') : 
#    y = ...

const
  AsciiLetter = {'A'..'Z', 'a'..'z'}
  uniLetter = AsciiLetter + {'\128'..'\255'}
  digits = {'0'..'9'}
  hexDigits = {'0'..'9', 'a'..'f', 'A'..'F'}
  octDigits = {'0'..'7'}
  binDigits = {'0'..'1'}
  AsciiIdentStart = AsciiLetter + {'_'} 
  AsciiIdentRest = AsciiIdentStart + Digits
  UniIdentStart = UniLetter + {'_'} 
  UniIdentRest = UniIdentStart + Digits

# --> if match(s, +AsciiIdentStart & *AsciiIdentRest): 

#  Regular expressions in Nimrod itself!
#  -------------------------------------
#  
#  'a' -- matches the character a
#  'a'..'z'  -- range operator '-'
#  'A' | 'B' -- alternative operator |
#  * 'a' -- prefix * is needed
#  + 'a' -- prefix + is needed
#  ? 'a' -- prefix ? is needed
#  *? prefix is needed
#  +? prefix is needed
#  letter  -- character classes with real names!
#  letters
#  white
#  whites
#  any   -- any character
#  ()    -- are Nimrod syntax
#  ! 'a'-'z'
#  
#  -- concatentation via proc call:
#  
#  re('A' 'Z' *word  )

macro re(n: expr): expr = 
  
  result = newCall("magic_re", x)
