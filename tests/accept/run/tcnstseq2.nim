discard """
  output: "AngelikaAnneAnnaAnkaAnja"
"""

const
  myWords = @["Angelika", "Anne", "Anna", "Anka", "Anja"]
  
for i in 0 .. high(myWords): 
  write(stdout, myWords[i]) #OUT AngelikaAnneAnnaAnkaAnja



