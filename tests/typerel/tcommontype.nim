type
  TAnimal {.inheritable.}=object
  PAnimal=ref TAnimal

  TDog=object of TAnimal
  PDog=ref TDog

  TCat=object of TAnimal
  PCat=ref TCat

  TAnimalArray=array[0..2,PAnimal]

proc newDog():PDog = new(result)
proc newCat():PCat = new(result)
proc test(a:openArray[PAnimal])=
  echo("dummy")

#test(newDog(),newCat()) #does not work
var myarray:TAnimalArray=[newDog(),newCat(),newDog()] #does not work
#var myarray2:TAnimalArray=[newDog(),newDog(),newDog()] #does not work either
