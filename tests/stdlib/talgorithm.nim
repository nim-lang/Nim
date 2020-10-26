discard """
  output:'''@["3", "2", "1"]
  '''
"""
#12928,10456
import sequtils, strutils, algorithm, json

proc test() = 
  try: 
    let info = parseJson("""
    {"a": ["1", "2", "3"]}
    """)
    let prefixes = info["a"].getElems().mapIt(it.getStr()).sortedByIt(it).reversed()
    echo prefixes
  except:
    discard
  
test()
