import unittest
import sets

doAssert(toSet(@[1,2,3]) <= toSet(@[1,2,3,4]), "equivalent or subset")
doAssert(toSet(@[1,2,3]) <= toSet(@[1,2,3]), "equivalent or subset")
doAssert((not(toSet(@[1,2,3]) <= toSet(@[1,2]))), "equivalent or subset")
doAssert(toSet(@[1,2,3]) <= toSet(@[1,2,3,4]), "strict subset")
doAssert((not(toSet(@[1,2,3]) < toSet(@[1,2,3]))), "strict subset")
doAssert((not(toSet(@[1,2,3]) < toSet(@[1,2]))), "strict subset")
doAssert((not(toSet(@[1,2,3]) == toSet(@[1,2,3,4]))), "==")
doAssert(toSet(@[1,2,3]) == toSet(@[1,2,3]), "==")
doAssert((not(toSet(@[1,2,3]) == toSet(@[1,2]))), "==")
