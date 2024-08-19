# issue #23854

import std/bitops

const WordBitWidth = sizeof(pointer) * 8

func wordsRequired*(bits: int): int {.inline.} =
  const divShiftor = fastLog2(uint32(WordBitWidth))
  result = (bits + WordBitWidth - 1) shr divShiftor

type
  Algebra* = enum
    BLS12_381

  BigInt*[bits: static int] = object
    limbs*: array[wordsRequired(bits), uint]

  Fr*[Name: static Algebra] = object
    residue_form*: BigInt[255]

  Fp*[Name: static Algebra] = object
    residue_form*: BigInt[381]

  FF*[Name: static Algebra] = Fp[Name] or Fr[Name]

type
  EC_ShortW_Aff*[F] = object
    ## Elliptic curve point for a curve in Short Weierstrass form
    ##   y² = x³ + a x + b
    ##
    ## over a field F
    x*, y*: F

type FieldKind* = enum
  kBaseField
  kScalarField

template getBigInt*[Name: static Algebra](T: type FF[Name]): untyped =
  ## Get the underlying BigInt type.
  BigInt[123]

func bits*[Name: static Algebra](T: type FF[Name]): static int =
  T.getBigInt().bits

template getScalarField*(EC: type EC_ShortW_Aff): untyped =
  Fr[EC.F.Name]

# ------------------------------------------------------------------------------

type
  ECFFT_Descriptor*[EC] = object
    ## Metadata for FFT on Elliptic Curve
    order*: int
    rootsOfUnity1*: ptr UncheckedArray[BigInt[EC.getScalarField().bits()]]  # Error: in expression 'EC.getScalarField()': identifier expected, but found 'EC.getScalarField'
    rootsOfUnity2*: ptr UncheckedArray[BigInt[getScalarField(EC).bits()]] # Compiler SIGSEGV: Illegal Storage Access

func new*(T: type ECFFT_Descriptor): T =
  discard

# ------------------------------------------------------------------------------

proc main() =
  let ctx = ECFFT_Descriptor[EC_ShortW_Aff[Fp[BLS12_381]]].new()

main()
