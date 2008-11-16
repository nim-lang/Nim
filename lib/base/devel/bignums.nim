#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements big integers for Nimrod.
## This module is an adaptation of the FGInt module for Pascal by Walied
## Othman: http://triade.studentenweb.org


# License, info, etc
# ------------------
#
# This implementation is made by me, Walied Othman, to contact me
# mail to Walied.Othman@belgacom.net or Triade@ulyssis.org,
# always mention wether it 's about the FGInt for Delphi or for
# FreePascal, or wether it 's about the 6xs, preferably in the subject line.
# If you 're going to use these implementations, at least mention my
# name or something and notify me so I may even put a link on my page.
# This implementation is freeware and according to the coderpunks'
# manifesto it should remain so, so don 't use these implementations
# in commercial software.  Encryption, as a tool to ensure privacy
# should be free and accessible for anyone.  If you plan to use these
# implementations in a commercial application, contact me before
# doing so, that way you can license the software to use it in commercial
# Software.  If any algorithm is patented in your country, you should
# acquire a license before using this software.  Modified versions of this
# software must contain an acknowledgement of the original author (=me).
# This implementation is available at
# http://triade.studentenweb.org
#
# copyright 2000, Walied Othman
# This header may not be removed.
#

type
  TBigInt* {.final.} = object ## type that represent an arbitrary long
                              ## signed integer
    s: int       # sign: -1 or 1
    n: seq[int]  # the number part

proc len(x: TBigInt): int {.inline.} = return x.n.len

proc CompareAbs(a, b: TBigInt): int = 
  result = a.len - b.len
  if result == 0:
    var i = b.len-1
    while (i > 0) and a.n[i] == b.n[i]: dec(i)
    result = a.n[i] - b.n[i]
  
const
  bitMask = high(int)
  bitshift = sizeof(int)*8 - 1
  
proc cutZeros(a: var TBigInt) =
  var L = a.len
  while a.len > 0 and a[L-1] == 0: dec(L)
  setLen(a.n, L)
  
proc addAux(a, b: TBigInt, bSign: int): TBigInt
  if a.len < b.len:
    result = addAux(b, a, bSign)
  elif a.s == bSign:
    result.s = a.s
    result.n = []
    setlen(result.n, a.len+1)
    var rest = 0
    for i in 0..b.len-1:
      var trest = a.n[i]
      trest = trest +% b.n[i] +% rest
      result.n[i] = trest and bitMask
      rest = trest shr bitshift
    for i in b.len .. a.len-1:
      var trest = a.n[i] +% rest
      result.n[i] = trest and bitMask
      rest = trest shr bitshift
    result.n[a.len] = rest
    cutZeros(result)
  elif compareAbs(a, b) > 0:
    result = addAux(b, a, bSign)
  else:
    setlen(result.n, a.len+1)
    result.s = a.s
    var rest = 0
    for i in 0..b.len-1: 
      var Trest = low(int)
      TRest = Trest +% a.n[i] -% b.n[i] -% rest
      result.n[i] = Trest and bitmask
      if Trest >% bitMask: rest = 0 else: rest = 1
    for i in b.len .. a.len-1: 
      var Trest = low(int)
      TRest = Trest +% a.n[i] -% rest
      result.n[i] = Trest and bitmask
      if (Trest >% bitmask): rest = 0 else: rest = 1
    cutZeros(result)

proc `+` *(a, b: TBigInt): TBigInt =
  ## the `+` operator for bigints
  result = addAux(a, b, +1)

proc `-` *(a, b: TBigInt): TBigInt =
  ## the `-` operator for bigints
  result = addAux(a, b, -1)

proc mulInPlace(a: var TBigInt, b: int) = 
  var 
    size, rest: int32
    Trest: int64
  size = FGInt.Number[0]
  setlen(FGInt.Number, size + 2)
  rest = 0
  for i in countup(1, size): 
    Trest = FGInt.Number[i]
    TRest = Trest * by
    TRest = Trest + rest
    FGInt.Number[i] = Trest And 2147483647
    rest = Trest Shr 31
  if rest != 0: 
    size = size + 1
    FGInt.Number[size] = rest
  else: 
    setlen(FGInt.Number, size + 1)
  FGInt.Number[0] = size


import 
  SysUtils, Math

type 
  TCompare* = enum 
    Lt, St, Eq, Er
  TSign = enum 
    negative, positive
  TBigInt* {.final.} = object 
    Sign: TSign
    Number: seq[int32]


proc zeronetochar8*(g: var char, x: String)
proc zeronetochar6*(g: var int, x: String)
proc initialize8*(trans: var openarray[String])
proc initialize6*(trans: var openarray[String])
proc initialize6PGP*(trans: var openarray[String])
proc ConvertBase256to64*(str256: String, str64: var String)
proc ConvertBase64to256*(str64: String, str256: var String)
proc ConvertBase256to2*(str256: String, str2: var String)
proc ConvertBase64to2*(str64: String, str2: var String)
proc ConvertBase2to256*(str2: String, str256: var String)
proc ConvertBase2to64*(str2: String, str64: var String)
proc ConvertBase256StringToHexString*(Str256: String, HexStr: var String)
proc ConvertHexStringToBase256String*(HexStr: String, Str256: var String)
proc PGPConvertBase256to64*(str256, str64: var String)
proc PGPConvertBase64to256*(str64: String, str256: var String)
proc PGPConvertBase64to2*(str64: String, str2: var String)
proc FGIntToBase2String*(FGInt: TBigInt, S: var String)
proc Base2StringToFGInt*(S: String, FGInt: var TBigInt)
proc FGIntToBase256String*(FGInt: TBigInt, str256: var String)
proc Base256StringToFGInt*(str256: String, FGInt: var TBigInt)
proc PGPMPIToFGInt*(PGPMPI: String, FGInt: var TBigInt)
proc FGIntToPGPMPI*(FGInt: TBigInt, PGPMPI: var String)
proc Base10StringToFGInt*(Base10: String, FGInt: var TBigInt)
proc FGIntToBase10String*(FGInt: TBigInt, Base10: var String)
proc FGIntDestroy*(FGInt: var TBigInt)
proc FGIntCompareAbs*(FGInt1, FGInt2: TBigInt): TCompare
proc FGIntAdd*(FGInt1, FGInt2: TBigInt, Sum: var TBigInt)
proc FGIntChangeSign*(FGInt: var TBigInt)
proc FGIntSub*(FGInt1, FGInt2, dif: var TBigInt)
proc FGIntMulByInt*(FGInt: TBigInt, res: var TBigInt, by: int32)
proc FGIntMulByIntbis*(FGInt: var TBigInt, by: int32)
proc FGIntDivByInt*(FGInt: TBigInt, res: var TBigInt, by: int32, modres: var int32)
proc FGIntDivByIntBis*(FGInt: var TBigInt, by: int32, modres: var int32)
proc FGIntModByInt*(FGInt: TBigInt, by: int32, modres: var int32)
proc FGIntAbs*(FGInt: var TBigInt)
proc FGIntCopy*(FGInt1: TBigInt, FGInt2: var TBigInt)
proc FGIntShiftLeft*(FGInt: var TBigInt)
proc FGIntShiftRight*(FGInt: var TBigInt)
proc FGIntShiftRightBy31*(FGInt: var TBigInt)
proc FGIntAddBis*(FGInt1: var TBigInt, FGInt2: TBigInt)
proc FGIntSubBis*(FGInt1: var TBigInt, FGInt2: TBigInt)
proc FGIntMul*(FGInt1, FGInt2: TBigInt, Prod: var TBigInt)
proc FGIntSquare*(FGInt: TBigInt, Square: var TBigInt)
proc FGIntExp*(FGInt, exp: TBigInt, res: var TBigInt)
proc FGIntFac*(FGInt: TBigInt, res: var TBigInt)
proc FGIntShiftLeftBy31*(FGInt: var TBigInt)
proc FGIntDivMod*(FGInt1, FGInt2, QFGInt, MFGInt: var TBigInt)
proc FGIntDiv*(FGInt1, FGInt2, QFGInt: var TBigInt)
proc FGIntMod*(FGInt1, FGInt2, MFGInt: var TBigInt)
proc FGIntSquareMod*(FGInt, Modb, FGIntSM: var TBigInt)
proc FGIntAddMod*(FGInt1, FGInt2, base, FGIntres: var TBigInt)
proc FGIntMulMod*(FGInt1, FGInt2, base, FGIntres: var TBigInt)
proc FGIntModExp*(FGInt, exp, modb, res: var TBigInt)
proc FGIntModBis*(FGInt: TBigInt, FGIntOut: var TBigInt, b, head: int32)
proc FGIntMulModBis*(FGInt1, FGInt2: TBigInt, Prod: var TBigInt, b, head: int32)
proc FGIntMontgomeryMod*(GInt, base, baseInv: TBigInt, MGInt: var TBigInt, 
                         b: int32, head: int32)
proc FGIntMontgomeryModExp*(FGInt, exp, modb, res: var TBigInt)
proc FGIntGCD*(FGInt1, FGInt2: TBigInt, GCD: var TBigInt)
proc FGIntLCM*(FGInt1, FGInt2: TBigInt, LCM: var TBigInt)
proc FGIntTrialDiv9999*(FGInt: TBigInt, ok: var bool)
proc FGIntRandom1*(Seed, RandomFGInt: var TBigInt)
proc FGIntRabinMiller*(FGIntp: var TBigInt, nrtest: int32, ok: var bool)
proc FGIntBezoutBachet*(FGInt1, FGInt2, a, b: var TBigInt)
proc FGIntModInv*(FGInt1, base: TBigInt, Inverse: var TBigInt)
proc FGIntPrimetest*(FGIntp: var TBigInt, nrRMtests: int, ok: var bool)
proc FGIntLegendreSymbol*(a, p: var TBigInt, L: var int)
proc FGIntSquareRootModP*(Square, Prime: TBigInt, SquareRoot: var TBigInt)
# implementation

var 
  primes: array[1..1228, int] = [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 
                                 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 
                                 101, 103, 107, 109, 113, 127, 131, 137, 139, 
                                 149, 151, 157, 163, 167, 173, 179, 181, 191, 
                                 193, 197, 199, 211, 223, 227, 229, 233, 239, 
                                 241, 251, 257, 263, 269, 271, 277, 281, 283, 
                                 293, 307, 311, 313, 317, 331, 337, 347, 349, 
                                 353, 359, 367, 373, 379, 383, 389, 397, 401, 
                                 409, 419, 421, 431, 433, 439, 443, 449, 457, 
                                 461, 463, 467, 479, 487, 491, 499, 503, 509, 
                                 521, 523, 541, 547, 557, 563, 569, 571, 577, 
                                 587, 593, 599, 601, 607, 613, 617, 619, 631, 
                                 641, 643, 647, 653, 659, 661, 673, 677, 683, 
                                 691, 701, 709, 719, 727, 733, 739, 743, 751, 
                                 757, 761, 769, 773, 787, 797, 809, 811, 821, 
                                 823, 827, 829, 839, 853, 857, 859, 863, 877, 
                                 881, 883, 887, 907, 911, 919, 929, 937, 941, 
                                 947, 953, 967, 971, 977, 983, 991, 997, 1009, 
                                 1013, 1019, 1021, 1031, 1033, 1039, 1049, 1051, 
                                 1061, 1063, 1069, 1087, 1091, 1093, 1097, 1103, 
                                 1109, 1117, 1123, 1129, 1151, 1153, 1163, 1171, 
                                 1181, 1187, 1193, 1201, 1213, 1217, 1223, 1229, 
                                 1231, 1237, 1249, 1259, 1277, 1279, 1283, 1289, 
                                 1291, 1297, 1301, 1303, 1307, 1319, 1321, 1327, 
                                 1361, 1367, 1373, 1381, 1399, 1409, 1423, 1427, 
                                 1429, 1433, 1439, 1447, 1451, 1453, 1459, 1471, 
                                 1481, 1483, 1487, 1489, 1493, 1499, 1511, 1523, 
                                 1531, 1543, 1549, 1553, 1559, 1567, 1571, 1579, 
                                 1583, 1597, 1601, 1607, 1609, 1613, 1619, 1621, 
                                 1627, 1637, 1657, 1663, 1667, 1669, 1693, 1697, 
                                 1699, 1709, 1721, 1723, 1733, 1741, 1747, 1753, 
                                 1759, 1777, 1783, 1787, 1789, 1801, 1811, 1823, 
                                 1831, 1847, 1861, 1867, 1871, 1873, 1877, 1879, 
                                 1889, 1901, 1907, 1913, 1931, 1933, 1949, 1951, 
                                 1973, 1979, 1987, 1993, 1997, 1999, 2003, 2011, 
                                 2017, 2027, 2029, 2039, 2053, 2063, 2069, 2081, 
                                 2083, 2087, 2089, 2099, 2111, 2113, 2129, 2131, 
                                 2137, 2141, 2143, 2153, 2161, 2179, 2203, 2207, 
                                 2213, 2221, 2237, 2239, 2243, 2251, 2267, 2269, 
                                 2273, 2281, 2287, 2293, 2297, 2309, 2311, 2333, 
                                 2339, 2341, 2347, 2351, 2357, 2371, 2377, 2381, 
                                 2383, 2389, 2393, 2399, 2411, 2417, 2423, 2437, 
                                 2441, 2447, 2459, 2467, 2473, 2477, 2503, 2521, 
                                 2531, 2539, 2543, 2549, 2551, 2557, 2579, 2591, 
                                 2593, 2609, 2617, 2621, 2633, 2647, 2657, 2659, 
                                 2663, 2671, 2677, 2683, 2687, 2689, 2693, 2699, 
                                 2707, 2711, 2713, 2719, 2729, 2731, 2741, 2749, 
                                 2753, 2767, 2777, 2789, 2791, 2797, 2801, 2803, 
                                 2819, 2833, 2837, 2843, 2851, 2857, 2861, 2879, 
                                 2887, 2897, 2903, 2909, 2917, 2927, 2939, 2953, 
                                 2957, 2963, 2969, 2971, 2999, 3001, 3011, 3019, 
                                 3023, 3037, 3041, 3049, 3061, 3067, 3079, 3083, 
                                 3089, 3109, 3119, 3121, 3137, 3163, 3167, 3169, 
                                 3181, 3187, 3191, 3203, 3209, 3217, 3221, 3229, 
                                 3251, 3253, 3257, 3259, 3271, 3299, 3301, 3307, 
                                 3313, 3319, 3323, 3329, 3331, 3343, 3347, 3359, 
                                 3361, 3371, 3373, 3389, 3391, 3407, 3413, 3433, 
                                 3449, 3457, 3461, 3463, 3467, 3469, 3491, 3499, 
                                 3511, 3517, 3527, 3529, 3533, 3539, 3541, 3547, 
                                 3557, 3559, 3571, 3581, 3583, 3593, 3607, 3613, 
                                 3617, 3623, 3631, 3637, 3643, 3659, 3671, 3673, 
                                 3677, 3691, 3697, 3701, 3709, 3719, 3727, 3733, 
                                 3739, 3761, 3767, 3769, 3779, 3793, 3797, 3803, 
                                 3821, 3823, 3833, 3847, 3851, 3853, 3863, 3877, 
                                 3881, 3889, 3907, 3911, 3917, 3919, 3923, 3929, 
                                 3931, 3943, 3947, 3967, 3989, 4001, 4003, 4007, 
                                 4013, 4019, 4021, 4027, 4049, 4051, 4057, 4073, 
                                 4079, 4091, 4093, 4099, 4111, 4127, 4129, 4133, 
                                 4139, 4153, 4157, 4159, 4177, 4201, 4211, 4217, 
                                 4219, 4229, 4231, 4241, 4243, 4253, 4259, 4261, 
                                 4271, 4273, 4283, 4289, 4297, 4327, 4337, 4339, 
                                 4349, 4357, 4363, 4373, 4391, 4397, 4409, 4421, 
                                 4423, 4441, 4447, 4451, 4457, 4463, 4481, 4483, 
                                 4493, 4507, 4513, 4517, 4519, 4523, 4547, 4549, 
                                 4561, 4567, 4583, 4591, 4597, 4603, 4621, 4637, 
                                 4639, 4643, 4649, 4651, 4657, 4663, 4673, 4679, 
                                 4691, 4703, 4721, 4723, 4729, 4733, 4751, 4759, 
                                 4783, 4787, 4789, 4793, 4799, 4801, 4813, 4817, 
                                 4831, 4861, 4871, 4877, 4889, 4903, 4909, 4919, 
                                 4931, 4933, 4937, 4943, 4951, 4957, 4967, 4969, 
                                 4973, 4987, 4993, 4999, 5003, 5009, 5011, 5021, 
                                 5023, 5039, 5051, 5059, 5077, 5081, 5087, 5099, 
                                 5101, 5107, 5113, 5119, 5147, 5153, 5167, 5171, 
                                 5179, 5189, 5197, 5209, 5227, 5231, 5233, 5237, 
                                 5261, 5273, 5279, 5281, 5297, 5303, 5309, 5323, 
                                 5333, 5347, 5351, 5381, 5387, 5393, 5399, 5407, 
                                 5413, 5417, 5419, 5431, 5437, 5441, 5443, 5449, 
                                 5471, 5477, 5479, 5483, 5501, 5503, 5507, 5519, 
                                 5521, 5527, 5531, 5557, 5563, 5569, 5573, 5581, 
                                 5591, 5623, 5639, 5641, 5647, 5651, 5653, 5657, 
                                 5659, 5669, 5683, 5689, 5693, 5701, 5711, 5717, 
                                 5737, 5741, 5743, 5749, 5779, 5783, 5791, 5801, 
                                 5807, 5813, 5821, 5827, 5839, 5843, 5849, 5851, 
                                 5857, 5861, 5867, 5869, 5879, 5881, 5897, 5903, 
                                 5923, 5927, 5939, 5953, 5981, 5987, 6007, 6011, 
                                 6029, 6037, 6043, 6047, 6053, 6067, 6073, 6079, 
                                 6089, 6091, 6101, 6113, 6121, 6131, 6133, 6143, 
                                 6151, 6163, 6173, 6197, 6199, 6203, 6211, 6217, 
                                 6221, 6229, 6247, 6257, 6263, 6269, 6271, 6277, 
                                 6287, 6299, 6301, 6311, 6317, 6323, 6329, 6337, 
                                 6343, 6353, 6359, 6361, 6367, 6373, 6379, 6389, 
                                 6397, 6421, 6427, 6449, 6451, 6469, 6473, 6481, 
                                 6491, 6521, 6529, 6547, 6551, 6553, 6563, 6569, 
                                 6571, 6577, 6581, 6599, 6607, 6619, 6637, 6653, 
                                 6659, 6661, 6673, 6679, 6689, 6691, 6701, 6703, 
                                 6709, 6719, 6733, 6737, 6761, 6763, 6779, 6781, 
                                 6791, 6793, 6803, 6823, 6827, 6829, 6833, 6841, 
                                 6857, 6863, 6869, 6871, 6883, 6899, 6907, 6911, 
                                 6917, 6947, 6949, 6959, 6961, 6967, 6971, 6977, 
                                 6983, 6991, 6997, 7001, 7013, 7019, 7027, 7039, 
                                 7043, 7057, 7069, 7079, 7103, 7109, 7121, 7127, 
                                 7129, 7151, 7159, 7177, 7187, 7193, 7207, 7211, 
                                 7213, 7219, 7229, 7237, 7243, 7247, 7253, 7283, 
                                 7297, 7307, 7309, 7321, 7331, 7333, 7349, 7351, 
                                 7369, 7393, 7411, 7417, 7433, 7451, 7457, 7459, 
                                 7477, 7481, 7487, 7489, 7499, 7507, 7517, 7523, 
                                 7529, 7537, 7541, 7547, 7549, 7559, 7561, 7573, 
                                 7577, 7583, 7589, 7591, 7603, 7607, 7621, 7639, 
                                 7643, 7649, 7669, 7673, 7681, 7687, 7691, 7699, 
                                 7703, 7717, 7723, 7727, 7741, 7753, 7757, 7759, 
                                 7789, 7793, 7817, 7823, 7829, 7841, 7853, 7867, 
                                 7873, 7877, 7879, 7883, 7901, 7907, 7919, 7927, 
                                 7933, 7937, 7949, 7951, 7963, 7993, 8009, 8011, 
                                 8017, 8039, 8053, 8059, 8069, 8081, 8087, 8089, 
                                 8093, 8101, 8111, 8117, 8123, 8147, 8161, 8167, 
                                 8171, 8179, 8191, 8209, 8219, 8221, 8231, 8233, 
                                 8237, 8243, 8263, 8269, 8273, 8287, 8291, 8293, 
                                 8297, 8311, 8317, 8329, 8353, 8363, 8369, 8377, 
                                 8387, 8389, 8419, 8423, 8429, 8431, 8443, 8447, 
                                 8461, 8467, 8501, 8513, 8521, 8527, 8537, 8539, 
                                 8543, 8563, 8573, 8581, 8597, 8599, 8609, 8623, 
                                 8627, 8629, 8641, 8647, 8663, 8669, 8677, 8681, 
                                 8689, 8693, 8699, 8707, 8713, 8719, 8731, 8737, 
                                 8741, 8747, 8753, 8761, 8779, 8783, 8803, 8807, 
                                 8819, 8821, 8831, 8837, 8839, 8849, 8861, 8863, 
                                 8867, 8887, 8893, 8923, 8929, 8933, 8941, 8951, 
                                 8963, 8969, 8971, 8999, 9001, 9007, 9011, 9013, 
                                 9029, 9041, 9043, 9049, 9059, 9067, 9091, 9103, 
                                 9109, 9127, 9133, 9137, 9151, 9157, 9161, 9173, 
                                 9181, 9187, 9199, 9203, 9209, 9221, 9227, 9239, 
                                 9241, 9257, 9277, 9281, 9283, 9293, 9311, 9319, 
                                 9323, 9337, 9341, 9343, 9349, 9371, 9377, 9391, 
                                 9397, 9403, 9413, 9419, 9421, 9431, 9433, 9437, 
                                 9439, 9461, 9463, 9467, 9473, 9479, 9491, 9497, 
                                 9511, 9521, 9533, 9539, 9547, 9551, 9587, 9601, 
                                 9613, 9619, 9623, 9629, 9631, 9643, 9649, 9661, 
                                 9677, 9679, 9689, 9697, 9719, 9721, 9733, 9739, 
                                 9743, 9749, 9767, 9769, 9781, 9787, 9791, 9803, 
                                 9811, 9817, 9829, 9833, 9839, 9851, 9857, 9859, 
                                 9871, 9883, 9887, 9901, 9907, 9923, 9929, 9931, 
                                 9941, 9949, 9967, 9973]
  chr64: array[1..64, char] = ['a', 'A', 'b', 'B', 'c', 'C', 'd', 'D', 'e', 'E', 
                               'f', 'F', 'g', 'G', 'h', 'H', 'i', 'I', 'j', 'J', 
                               'k', 'K', 'l', 'L', 'm', 'M', 'n', 'N', 'o', 'O', 
                               'p', 'P', 'q', 'Q', 'r', 'R', 's', 'S', 't', 'T', 
                               'u', 'U', 'v', 'V', 'w', 'W', 'x', 'X', 'y', 'Y', 
                               'z', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', 
                               '8', '9', '+', '=']
  PGPchr64: array[1..64, char] = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 
                                  'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 
                                  'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 
                                  'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 
                                  'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 
                                  't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', 
                                  '2', '3', '4', '5', '6', '7', '8', '9', '+', 
                                  '/']

proc zeronetochar8(g: var char, x: String) = 
  var b: int8
  b = 0
  for i in countup(1, 8): 
    if copy(x, i, 1) == '1': b = b Or (1 Shl (8 - I))
  g = chr(b)

proc zeronetochar6(g: var int, x: String) = 
  G = 0
  for I in countup(1, len(X)): 
    if I > 6: break 
    if X[I] != '0': G = G Or (1 Shl (6 - I))
  Inc(G)

proc initialize8(trans: var openarray[String]) = 
  var 
    x: String
    g: char
  for c1 in countup(0, 1): 
    for c2 in countup(0, 1): 
      for c3 in countup(0, 1): 
        for c4 in countup(0, 1): 
          for c5 in countup(0, 1): 
            for c6 in countup(0, 1): 
              for c7 in countup(0, 1): 
                for c8 in countup(0, 1): 
                  x = chr(48 + c1) + chr(48 + c2) + chr(48 + c3) + chr(48 + c4) +
                      chr(48 + c5) + chr(48 + c6) + chr(48 + c7) + chr(48 + c8)
                  zeronetochar8(g, x)
                  trans[ord(g)] = x
  
proc initialize6(trans: var openarray[String]) = 
  var 
    x: String
    g: int
  for c1 in countup(0, 1): 
    for c2 in countup(0, 1): 
      for c3 in countup(0, 1): 
        for c4 in countup(0, 1): 
          for c5 in countup(0, 1): 
            for c6 in countup(0, 1): 
              x = chr(48 + c1) + chr(48 + c2) + chr(48 + c3) + chr(48 + c4) +
                  chr(48 + c5) + chr(48 + c6)
              zeronetochar6(g, x)
              trans[ord(chr64[g])] = x
  
proc initialize6PGP(trans: var openarray[String]) = 
  var 
    x: String
    g: int
  for c1 in countup(0, 1): 
    for c2 in countup(0, 1): 
      for c3 in countup(0, 1): 
        for c4 in countup(0, 1): 
          for c5 in countup(0, 1): 
            for c6 in countup(0, 1): 
              x = chr(48 + c1) + chr(48 + c2) + chr(48 + c3) + chr(48 + c4) +
                  chr(48 + c5) + chr(48 + c6)
              zeronetochar6(g, x)
              trans[ord(PGPchr64[g])] = x
  
proc ConvertBase256to64(str256: String, str64: var String) = 
  var 
    temp: String
    trans: array[0..255, String]
    len6: int32
    g: int
  initialize8(trans)
  temp = ""
  for i in countup(1, len(str256)): temp = temp + trans[ord(str256[i])]
  while (len(temp) Mod 6) != 0: temp = temp & '0'
  len6 = len(temp) Div 6
  str64 = ""
  for i in countup(1, len6): 
    zeronetochar6(g, copy(temp, 1, 6))
    str64 = str64 + chr64[g]
    delete(temp, 1, 6)

proc ConvertBase64to256(str64: String, str256: var String) = 
  var 
    temp: String
    trans: array[0..255, String]
    len8: int32
    g: char
  initialize6(trans)
  temp = ""
  for i in countup(1, len(str64)): temp = temp + trans[ord(str64[i])]
  str256 = ""
  len8 = len(temp) Div 8
  for i in countup(1, len8): 
    zeronetochar8(g, copy(temp, 1, 8))
    str256 = str256 + g
    delete(temp, 1, 8)

proc ConvertBase256to2(str256: String, str2: var String) = 
  var trans: array[0..255, String]
  str2 = ""
  initialize8(trans)
  for i in countup(1, len(str256)): str2 = str2 + trans[ord(str256[i])]
  
proc ConvertBase64to2(str64: String, str2: var String) = 
  var trans: array[0..255, String]
  str2 = ""
  initialize6(trans)
  for i in countup(1, len(str64)): str2 = str2 + trans[ord(str64[i])]
  
proc ConvertBase2to256(str2: String, str256: var String) = 
  var 
    len8: int32
    g: char
  str256 = ""
  while (len(str2) Mod 8) != 0: str2 = '0' & str2
  len8 = len(str2) Div 8
  for i in countup(1, len8): 
    zeronetochar8(g, copy(str2, 1, 8))
    str256 = str256 + g
    delete(str2, 1, 8)

proc ConvertBase2to64(str2: String, str64: var String) = 
  var 
    len6: int32
    g: int
  str64 = ""
  while (len(str2) Mod 6) != 0: str2 = '0' & str2
  len6 = len(str2) Div 6
  for i in countup(1, len6): 
    zeronetochar6(g, copy(str2, 1, 6))
    str64 = str64 + chr64[g]
    delete(str2, 1, 6)

proc ConvertBase256StringToHexString(Str256: String, HexStr: var String) = 
  var b: int8
  HexStr = ""
  for i in countup(1, len(str256)): 
    b = ord(str256[i])
    if (b Shr 4) < 10: HexStr = HexStr + chr(48 + (b Shr 4))
    else: HexStr = HexStr + chr(55 + (b Shr 4))
    if (b And 15) < 10: HexStr = HexStr + chr(48 + (b And 15))
    else: HexStr = HexStr + chr(55 + (b And 15))
  
proc ConvertHexStringToBase256String(HexStr: String, Str256: var String) = 
  var 
    b, h1, h2: int8
    temp: string
  Str256 = ""
  if (len(Hexstr) mod 2) == 1: temp = '0' & HexStr
  else: temp = HexStr
  for i in countup(1, (len(temp) Div 2)): 
    h2 = ord(temp[2 * i])
    h1 = ord(temp[2 * i - 1])
    if h1 < 58: b = ((h1 - 48) Shl 4)
    else: b = ((h1 - 55) Shl 4)
    if h2 < 58: b = (b Or (h2 - 48))
    else: b = (b Or ((h2 - 55) and 15))
    Str256 = Str256 + chr(b)

proc PGPConvertBase256to64(str256, str64: var String) = 
  var 
    temp, x, a: String
    len6: int32
    g: int
    trans: array[0..255, String]
  initialize8(trans)
  temp = ""
  for i in countup(1, len(str256)): temp = temp + trans[ord(str256[i])]
  if (len(temp) Mod 6) == 0: 
    a = ""
  elif (len(temp) Mod 6) == 4: 
    temp = temp & "00"
    a = '='
  else: 
    temp = temp & "0000"
    a = "=="
  str64 = ""
  len6 = len(temp) Div 6
  for i in countup(1, len6): 
    x = copy(temp, 1, 6)
    zeronetochar6(g, x)
    str64 = str64 + PGPchr64[g]
    delete(temp, 1, 6)
  str64 = str64 + a

proc PGPConvertBase64to256(str64: String, str256: var String) = 
  var 
    temp, x: String
    j, len8: int32
    g: char
    trans: array[0..255, String]
  initialize6PGP(trans)
  temp = ""
  str256 = ""
  if str64[len(str64) - 1] == '=': j = 2
  elif str64[len(str64)] == '=': j = 1
  else: j = 0
  for i in countup(1, (len(str64) - j)): temp = temp + trans[ord(str64[i])]
  if j != 0: delete(temp, len(temp) - 2 * j + 1, 2 * j)
  len8 = len(temp) Div 8
  for i in countup(1, len8): 
    x = copy(temp, 1, 8)
    zeronetochar8(g, x)
    str256 = str256 + g
    delete(temp, 1, 8)

proc PGPConvertBase64to2(str64: String, str2: var String) = 
  var 
    j: int32
    trans: array[0..255, String]
  str2 = ""
  initialize6(trans)
  if str64[len(str64) - 1] == '=': j = 2
  elif str64[len(str64)] == '=': j = 1
  else: j = 0
  for i in countup(1, (len(str64) - j)): str2 = str2 + trans[ord(str64[i])]
  delete(str2, len(str2) - 2 * j + 1, 2 * j)

proc FGIntToBase2String(FGInt: TBigInt, S: var String) = 
  S = ""
  for i in countup(1, FGInt.Number[0]): 
    for j in countup(0, 30): 
      if (1 And (FGInt.Number[i] Shr j)) == 1: S = '1' & S
      else: S = '0' & S
  while (len(S) > 1) And (S[1] == '0'): delete(S, 1, 1)
  if S == "": S = '0'
  
proc Base2StringToFGInt(S: String, FGInt: var TBigInt) = 
  var i, j, size: int32
  while (S[1] == '0') And (len(S) > 1): delete(S, 1, 1)
  size = len(S) Div 31
  if (len(S) Mod 31) != 0: size = size + 1
  setlen(FGInt.Number, (size + 1))
  FGInt.Number[0] = size
  j = 1
  FGInt.Number[j] = 0
  i = 0
  while len(S) > 0: 
    if S[len(S)] == '1': FGInt.Number[j] = FGInt.Number[j] Or (1 Shl i)
    i = i + 1
    if i == 31: 
      i = 0
      j = j + 1
      if j <= size: FGInt.Number[j] = 0
    delete(S, len(S), 1)
  FGInt.Sign = positive

proc FGIntToBase256String(FGInt: TBigInt, str256: var String) = 
  var 
    temp1: String
    len8: int32
    g: char
  FGIntToBase2String(FGInt, temp1)
  while (len(temp1) Mod 8) != 0: temp1 = '0' & temp1
  len8 = len(temp1) Div 8
  str256 = ""
  for i in countup(1, len8): 
    zeronetochar8(g, copy(temp1, 1, 8))
    str256 = str256 + g
    delete(temp1, 1, 8)

proc Base256StringToFGInt(str256: String, FGInt: var TBigInt) = 
  var 
    temp1: String
    trans: array[0..255, String]
  temp1 = ""
  initialize8(trans)
  for i in countup(1, len(str256)): temp1 = temp1 + trans[ord(str256[i])]
  while (temp1[1] == '0') And (temp1 != '0'): delete(temp1, 1, 1)
  Base2StringToFGInt(temp1, FGInt)

proc PGPMPIToFGInt(PGPMPI: String, FGInt: var TBigInt) = 
  var temp: String
  temp = PGPMPI
  delete(temp, 1, 2)
  Base256StringToFGInt(temp, FGInt)

proc FGIntToPGPMPI(FGInt: TBigInt, PGPMPI: var String) = 
  var 
    length: int16
    c: char
    b: int8
  FGIntToBase256String(FGInt, PGPMPI)
  length = len(PGPMPI) * 8
  c = PGPMPI[1]
  for i in countdown(7, 0): 
    if (ord(c) Shr i) == 0: length = length - 1
    else: break 
  b = length Mod 256
  PGPMPI = chr(b) + PGPMPI
  b = length Div 256
  PGPMPI = chr(b) + PGPMPI

proc GIntDivByIntBis1(GInt: var TBigInt, by: int32, modres: var int16) = 
  var size, rest, temp: int32
  size = GInt.Number[0]
  temp = 0
  for i in countdown(size, 1): 
    temp = temp * 10000
    rest = temp + GInt.Number[i]
    GInt.Number[i] = rest Div by
    temp = rest Mod by
  modres = temp
  while (GInt.Number[size] == 0) And (size > 1): size = size - 1
  if size != GInt.Number[0]: 
    setlen(GInt.Number, size + 1)
    GInt.Number[0] = size

proc Base10StringToFGInt(Base10: String, FGInt: var TBigInt) = 
  var 
    size: int32
    j: int16
    S, x: String
    sign: TSign
  while (Not (Base10[1] In {'-', '0'..'9'})) And (len(Base10) > 1): 
    delete(Base10, 1, 1)
  if copy(Base10, 1, 1) == '-': 
    Sign = negative
    delete(Base10, 1, 1)
  else: 
    Sign = positive
  while (len(Base10) > 1) And (copy(Base10, 1, 1) == '0'): delete(Base10, 1, 1)
  size = len(Base10) Div 4
  if (len(Base10) Mod 4) != 0: size = size + 1
  setlen(FGInt.Number, size + 1)
  FGInt.Number[0] = size
  for i in countup(1, (size - 1)): 
    x = copy(Base10, len(Base10) - 3, 4)
    FGInt.Number[i] = StrToInt(x)
    delete(Base10, len(Base10) - 3, 4)
  FGInt.Number[size] = StrToInt(Base10)
  S = ""
  while (FGInt.Number[0] != 1) Or (FGInt.Number[1] != 0): 
    GIntDivByIntBis1(FGInt, 2, j)
    S = inttostr(j) + S
  if S == "": S = '0'
  FGIntDestroy(FGInt)
  Base2StringToFGInt(S, FGInt)
  FGInt.Sign = sign

proc FGIntToBase10String(FGInt: TBigInt, Base10: var String) = 
  var 
    S: String
    j: int32
    temp: TBigInt
  FGIntCopy(FGInt, temp)
  Base10 = ""
  while (temp.Number[0] > 1) Or (temp.Number[1] > 0): 
    FGIntDivByIntBis(temp, 10000, j)
    S = IntToStr(j)
    while len(S) < 4: S = '0' & S
    Base10 = S + Base10
  Base10 = '0' & Base10
  while (len(Base10) > 1) And (Base10[1] == '0'): delete(Base10, 1, 1)
  if FGInt.Sign == negative: Base10 = '-' & Base10
  
proc FGIntDestroy(FGInt: var TBigInt) = 
  FGInt.Number = nil

proc FGIntCompareAbs(FGInt1, FGInt2: TBigInt): TCompare = 
  var size1, size2, i: int32
  FGIntCompareAbs = Er
  size1 = FGInt1.Number[0]
  size2 = FGInt2.Number[0]
  if size1 > size2: 
    FGIntCompareAbs = Lt
  elif size1 < size2: 
    FGIntCompareAbs = St
  else: 
    i = size2
    while (FGInt1.Number[i] == FGInt2.Number[i]) And (i > 1): i = i - 1
    if FGInt1.Number[i] == FGInt2.Number[i]: FGIntCompareAbs = Eq
    elif FGInt1.Number[i] < FGInt2.Number[i]: FGIntCompareAbs = St
    elif FGInt1.Number[i] > FGInt2.Number[i]: FGIntCompareAbs = Lt
  
proc FGIntAdd(FGInt1, FGInt2: TBigInt, Sum: var TBigInt) = 
  var size1, size2, size, rest, Trest: int32
  size1 = FGInt1.Number[0]
  size2 = FGInt2.Number[0]
  if size1 < size2: 
    FGIntAdd(FGInt2, FGInt1, Sum)
  else: 
    if FGInt1.Sign == FGInt2.Sign: 
      Sum.Sign = FGInt1.Sign
      setlen(Sum.Number, (size1 + 2))
      rest = 0
      for i in countup(1, size2): 
        Trest = FGInt1.Number[i]
        Trest = Trest + FGInt2.Number[i]
        Trest = Trest + rest
        Sum.Number[i] = Trest And 2147483647
        rest = Trest Shr 31
      for i in countup((size2 + 1), size1): 
        Trest = FGInt1.Number[i] + rest
        Sum.Number[i] = Trest And 2147483647
        rest = Trest Shr 31
      size = size1 + 1
      Sum.Number[0] = size
      Sum.Number[size] = rest
      while (Sum.Number[size] == 0) And (size > 1): size = size - 1
      if Sum.Number[0] != size: setlen(Sum.Number, size + 1)
      Sum.Number[0] = size
    else: 
      if FGIntCompareAbs(FGInt2, FGInt1) == Lt: 
        FGIntAdd(FGInt2, FGInt1, Sum)
      else: 
        setlen(Sum.Number, (size1 + 1))
        rest = 0
        for i in countup(1, size2): 
          Trest = 0x80000000  # 2147483648;
          TRest = Trest + FGInt1.Number[i]
          TRest = Trest - FGInt2.Number[i]
          TRest = Trest - rest
          Sum.Number[i] = Trest And 2147483647
          if (Trest > 2147483647): rest = 0
          else: rest = 1
        for i in countup((size2 + 1), size1): 
          Trest = 0x80000000
          TRest = Trest + FGInt1.Number[i]
          TRest = Trest - rest
          Sum.Number[i] = Trest And 2147483647
          if (Trest > 2147483647): rest = 0
          else: rest = 1
        size = size1
        while (Sum.Number[size] == 0) And (size > 1): size = size - 1
        if size != size1: setlen(Sum.Number, size + 1)
        Sum.Number[0] = size
        Sum.Sign = FGInt1.Sign

proc FGIntChangeSign(FGInt: var TBigInt) = 
  if FGInt.Sign == negative: FGInt.Sign = positive
  else: FGInt.Sign = negative
  
proc FGIntSub(FGInt1, FGInt2, dif: var TBigInt) = 
  FGIntChangeSign(FGInt2)
  FGIntAdd(FGInt1, FGInt2, dif)
  FGIntChangeSign(FGInt2)

proc FGIntMulByInt(FGInt: TBigInt, res: var TBigInt, by: int32) = 
  var 
    size, rest: int32
    Trest: int64
  size = FGInt.Number[0]
  setlen(res.Number, (size + 2))
  rest = 0
  for i in countup(1, size): 
    Trest = FGInt.Number[i]
    TRest = Trest * by
    TRest = Trest + rest
    res.Number[i] = Trest And 2147483647
    rest = Trest Shr 31
  if rest != 0: 
    size = size + 1
    Res.Number[size] = rest
  else: 
    setlen(Res.Number, size + 1)
  Res.Number[0] = size
  Res.Sign = FGInt.Sign

proc FGIntMulByIntbis(FGInt: var TBigInt, by: int32) = 
  var 
    size, rest: int32
    Trest: int64
  size = FGInt.Number[0]
  setlen(FGInt.Number, size + 2)
  rest = 0
  for i in countup(1, size): 
    Trest = FGInt.Number[i]
    TRest = Trest * by
    TRest = Trest + rest
    FGInt.Number[i] = Trest And 2147483647
    rest = Trest Shr 31
  if rest != 0: 
    size = size + 1
    FGInt.Number[size] = rest
  else: 
    setlen(FGInt.Number, size + 1)
  FGInt.Number[0] = size

proc FGIntDivByInt(FGInt: TBigInt, res: var TBigInt, by: int32, modres: var int32) = 
  var 
    size: int32
    rest: int64
  size = FGInt.Number[0]
  setlen(res.Number, (size + 1))
  modres = 0
  for i in countdown(size, 1): 
    rest = modres
    rest = rest Shl 31
    rest = rest Or FGInt.Number[i]
    res.Number[i] = rest Div by
    modres = rest Mod by
  while (res.Number[size] == 0) And (size > 1): size = size - 1
  if size != FGInt.Number[0]: setlen(res.Number, size + 1)
  res.Number[0] = size
  Res.Sign = FGInt.Sign
  if FGInt.sign == negative: modres = by - modres
  
proc FGIntDivByIntBis(FGInt: var TBigInt, by: int32, modres: var int32) = 
  var 
    size: int32
    temp, rest: int64
  size = FGInt.Number[0]
  temp = 0
  for i in countdown(size, 1): 
    temp = temp Shl 31
    rest = temp Or FGInt.Number[i]
    FGInt.Number[i] = rest Div by
    temp = rest Mod by
  modres = temp
  while (FGInt.Number[size] == 0) And (size > 1): size = size - 1
  if size != FGInt.Number[0]: 
    setlen(FGInt.Number, size + 1)
    FGInt.Number[0] = size

proc FGIntModByInt(FGInt: TBigInt, by: int32, modres: var int32) = 
  var 
    size: int32
    temp, rest: int64
  size = FGInt.Number[0]
  temp = 0
  for i in countdown(size, 1): 
    temp = temp Shl 31
    rest = temp Or FGInt.Number[i]
    temp = rest Mod by
  modres = temp
  if FGInt.sign == negative: modres = by - modres
  
proc FGIntAbs(FGInt: var TBigInt) = 
  FGInt.Sign = positive

proc FGIntCopy(FGInt1: TBigInt, FGInt2: var TBigInt) = 
  FGInt2.Sign = FGInt1.Sign
  FGInt2.Number = nil
  FGInt2.Number = Copy(FGInt1.Number, 0, FGInt1.Number[0] + 1)

proc FGIntShiftLeft(FGInt: var TBigInt) = 
  var l, m, size: int32
  size = FGInt.Number[0]
  l = 0
  for i in countup(1, Size): 
    m = FGInt.Number[i] Shr 30
    FGInt.Number[i] = ((FGInt.Number[i] Shl 1) Or l) And 2147483647
    l = m
  if l != 0: 
    setlen(FGInt.Number, size + 2)
    FGInt.Number[size + 1] = l
    FGInt.Number[0] = size + 1

proc FGIntShiftRight(FGInt: var TBigInt) = 
  var l, m, size: int32
  size = FGInt.Number[0]
  l = 0
  for i in countdown(size, 1): 
    m = FGInt.Number[i] And 1
    FGInt.Number[i] = (FGInt.Number[i] Shr 1) Or l
    l = m Shl 30
  if (FGInt.Number[size] == 0) And (size > 1): 
    setlen(FGInt.Number, size)
    FGInt.Number[0] = size - 1

proc FGIntShiftRightBy31(FGInt: var TBigInt) = 
  var size: int32
  size = FGInt.Number[0]
  if size > 1: 
    for i in countup(1, size - 1): 
      FGInt.Number[i] = FGInt.Number[i + 1]
    setlen(FGInt.Number, Size)
    FGInt.Number[0] = size - 1
  else: 
    FGInt.Number[1] = 0
  
proc FGIntAddBis(FGInt1: var TBigInt, FGInt2: TBigInt) = 
  var size1, size2, Trest, rest: int32
  size1 = FGInt1.Number[0]
  size2 = FGInt2.Number[0]
  rest = 0
  for i in countup(1, size2): 
    Trest = FGInt1.Number[i] + FGInt2.Number[i] + rest
    rest = Trest Shr 31
    FGInt1.Number[i] = Trest And 2147483647
  for i in countup(size2 + 1, size1): 
    Trest = FGInt1.Number[i] + rest
    rest = Trest Shr 31
    FGInt1.Number[i] = Trest And 2147483647
  if rest != 0: 
    setlen(FGInt1.Number, size1 + 2)
    FGInt1.Number[0] = size1 + 1
    FGInt1.Number[size1 + 1] = rest

proc FGIntSubBis(FGInt1: var TBigInt, FGInt2: TBigInt) = 
  var size1, size2, rest, Trest: int32
  size1 = FGInt1.Number[0]
  size2 = FGInt2.Number[0]
  rest = 0
  for i in countup(1, size2): 
    Trest = (0x80000000 Or FGInt1.Number[i]) - FGInt2.Number[i] - rest
    if (Trest > 2147483647): rest = 0
    else: rest = 1
    FGInt1.Number[i] = Trest And 2147483647
  for i in countup(size2 + 1, size1): 
    Trest = (0x80000000 Or FGInt1.Number[i]) - rest
    if (Trest > 2147483647): rest = 0
    else: rest = 1
    FGInt1.Number[i] = Trest And 2147483647
  i = size1
  while (FGInt1.Number[i] == 0) And (i > 1): i = i - 1
  if i != size1: 
    setlen(FGInt1.Number, i + 1)
    FGInt1.Number[0] = i

proc FGIntMul(FGInt1, FGInt2: TBigInt, Prod: var TBigInt) = 
  var 
    size, size1, size2, rest: int32
    Trest: int64
  size1 = FGInt1.Number[0]
  size2 = FGInt2.Number[0]
  size = size1 + size2
  setlen(Prod.Number, (size + 1))
  for i in countup(1, size): Prod.Number[i] = 0
  for i in countup(1, size2): 
    rest = 0
    for j in countup(1, size1): 
      Trest = FGInt1.Number[j]
      Trest = Trest * FGInt2.Number[i]
      Trest = Trest + Prod.Number[j + i - 1]
      Trest = Trest + rest
      Prod.Number[j + i - 1] = Trest And 2147483647
      rest = Trest Shr 31
    Prod.Number[i + size1] = rest
  Prod.Number[0] = size
  while (Prod.Number[size] == 0) And (size > 1): size = size - 1
  if size != Prod.Number[0]: 
    setlen(Prod.Number, size + 1)
    Prod.Number[0] = size
  if FGInt1.Sign == FGInt2.Sign: Prod.Sign = Positive
  else: prod.Sign = negative
  
proc FGIntSquare(FGInt: TBigInt, Square: var TBigInt) = 
  var 
    size, size1, rest: int32
    Trest: int64
  size1 = FGInt.Number[0]
  size = 2 * size1
  setlen(Square.Number, (size + 1))
  Square.Number[0] = size
  for i in countup(1, size): Square.Number[i] = 0
  for i in countup(1, size1): 
    Trest = FGInt.Number[i]
    Trest = Trest * FGInt.Number[i]
    Trest = Trest + Square.Number[2 * i - 1]
    Square.Number[2 * i - 1] = Trest And 2147483647
    rest = Trest Shr 31
    for j in countup(i + 1, size1): 
      Trest = FGInt.Number[i] Shl 1
      Trest = Trest * FGInt.Number[j]
      Trest = Trest + Square.Number[i + j - 1]
      Trest = Trest + rest
      Square.Number[i + j - 1] = Trest And 2147483647
      rest = Trest Shr 31
    Square.Number[i + size1] = rest
  Square.Sign = positive
  while (Square.Number[size] == 0) And (size > 1): size = size - 1
  if size != (2 * size1): 
    setlen(Square.Number, size + 1)
    Square.Number[0] = size

proc FGIntExp(FGInt, exp: TBigInt, res: var TBigInt) = 
  var 
    temp2, temp3: TBigInt
    S: String
  FGIntToBase2String(exp, S)
  if S[len(S)] == '0': Base10StringToFGInt('1', res)
  else: FGIntCopy(FGInt, res)
  FGIntCopy(FGInt, temp2)
  if len(S) > 1: 
    for i in countdown((len(S) - 1), 1): 
      FGIntSquare(temp2, temp3)
      FGIntCopy(temp3, temp2)
      if S[i] == '1': 
        FGIntMul(res, temp2, temp3)
        FGIntCopy(temp3, res)
  
proc FGIntFac(FGInt: TBigInt, res: var TBigInt) = 
  var one, temp, temp1: TBigInt
  FGIntCopy(FGInt, temp)
  Base10StringToFGInt('1', res)
  Base10StringToFGInt('1', one)
  while Not (FGIntCompareAbs(temp, one) == Eq): 
    FGIntMul(temp, res, temp1)
    FGIntCopy(temp1, res)
    FGIntSubBis(temp, one)
  FGIntDestroy(one)
  FGIntDestroy(temp)

proc FGIntShiftLeftBy31(FGInt: var TBigInt) = 
  var 
    f1, f2: int32
    size: int32
  size = FGInt.Number[0]
  setlen(FGInt.Number, size + 2)
  f1 = 0
  for i in countup(1, (size + 1)): 
    f2 = FGInt.Number[i]
    FGInt.Number[i] = f1
    f1 = f2
  FGInt.Number[0] = size + 1

proc FGIntDivMod(FGInt1, FGInt2, QFGInt, MFGInt: var TBigInt) = 
  var 
    one, zero, temp1, temp2: TBigInt
    s1, s2: TSign
    j, s: int32
    i: int64
  s1 = FGInt1.Sign
  s2 = FGInt2.Sign
  FGIntAbs(FGInt1)
  FGIntAbs(FGInt2)
  FGIntCopy(FGInt1, MFGInt)
  FGIntCopy(FGInt2, temp1)
  if FGIntCompareAbs(FGInt1, FGInt2) != St: 
    s = FGInt1.Number[0] - FGInt2.Number[0]
    setlen(QFGInt.Number, (s + 2))
    QFGInt.Number[0] = s + 1
    for t in countup(1, s): 
      FGIntShiftLeftBy31(temp1)
      QFGInt.Number[t] = 0
    j = s + 1
    QFGInt.Number[j] = 0
    while FGIntCompareAbs(MFGInt, FGInt2) != St: 
      while FGIntCompareAbs(MFGInt, temp1) != St: 
        if MFGInt.Number[0] > temp1.Number[0]: 
          i = MFGInt.Number[MFGInt.Number[0]]
          i = i Shl 31
          i = i + MFGInt.Number[MFGInt.Number[0] - 1]
          i = i Div (temp1.Number[temp1.Number[0]] + 1)
        else: 
          i = MFGInt.Number[MFGInt.Number[0]] Div
              (temp1.Number[temp1.Number[0]] + 1)
        if (i != 0): 
          FGIntCopy(temp1, temp2)
          FGIntMulByIntBis(temp2, i)
          FGIntSubBis(MFGInt, temp2)
          QFGInt.Number[j] = QFGInt.Number[j] + i
          if FGIntCompareAbs(MFGInt, temp2) != St: 
            QFGInt.Number[j] = QFGInt.Number[j] + i
            FGIntSubBis(MFGInt, temp2)
          FGIntDestroy(temp2)
        else: 
          QFGInt.Number[j] = QFGInt.Number[j] + 1
          FGIntSubBis(MFGInt, temp1)
      if MFGInt.Number[0] <= temp1.Number[0]: 
        if FGIntCompareAbs(temp1, FGInt2) != Eq: 
          FGIntShiftRightBy31(temp1)
          j = j - 1
  else: 
    Base10StringToFGInt('0', QFGInt)
  s = QFGInt.Number[0]
  while (s > 1) And (QFGInt.Number[s] == 0): s = s - 1
  if s < QFGInt.Number[0]: 
    setlen(QFGInt.Number, s + 1)
    QFGInt.Number[0] = s
  QFGInt.Sign = positive
  FGIntDestroy(temp1)
  Base10StringToFGInt('0', zero)
  Base10StringToFGInt('1', one)
  if s1 == negative: 
    if FGIntCompareAbs(MFGInt, zero) != Eq: 
      FGIntadd(QFGInt, one, temp1)
      FGIntDestroy(QFGInt)
      FGIntCopy(temp1, QFGInt)
      FGIntDestroy(temp1)
      FGIntsub(FGInt2, MFGInt, temp1)
      FGIntDestroy(MFGInt)
      FGIntCopy(temp1, MFGInt)
      FGIntDestroy(temp1)
    if s2 == positive: QFGInt.Sign = negative
  else: 
    QFGInt.Sign = s2
  FGIntDestroy(one)
  FGIntDestroy(zero)
  FGInt1.Sign = s1
  FGInt2.Sign = s2

proc FGIntDiv(FGInt1, FGInt2, QFGInt: var TBigInt) = 
  var 
    one, zero, temp1, temp2, MFGInt: TBigInt
    s1, s2: TSign
    j, s: int32
    i: int64
  s1 = FGInt1.Sign
  s2 = FGInt2.Sign
  FGIntAbs(FGInt1)
  FGIntAbs(FGInt2)
  FGIntCopy(FGInt1, MFGInt)
  FGIntCopy(FGInt2, temp1)
  if FGIntCompareAbs(FGInt1, FGInt2) != St: 
    s = FGInt1.Number[0] - FGInt2.Number[0]
    setlen(QFGInt.Number, (s + 2))
    QFGInt.Number[0] = s + 1
    for t in countup(1, s): 
      FGIntShiftLeftBy31(temp1)
      QFGInt.Number[t] = 0
    j = s + 1
    QFGInt.Number[j] = 0
    while FGIntCompareAbs(MFGInt, FGInt2) != St: 
      while FGIntCompareAbs(MFGInt, temp1) != St: 
        if MFGInt.Number[0] > temp1.Number[0]: 
          i = MFGInt.Number[MFGInt.Number[0]]
          i = i Shl 31
          i = i + MFGInt.Number[MFGInt.Number[0] - 1]
          i = i Div (temp1.Number[temp1.Number[0]] + 1)
        else: 
          i = MFGInt.Number[MFGInt.Number[0]] Div
              (temp1.Number[temp1.Number[0]] + 1)
        if (i != 0): 
          FGIntCopy(temp1, temp2)
          FGIntMulByIntBis(temp2, i)
          FGIntSubBis(MFGInt, temp2)
          QFGInt.Number[j] = QFGInt.Number[j] + i
          if FGIntCompareAbs(MFGInt, temp2) != St: 
            QFGInt.Number[j] = QFGInt.Number[j] + i
            FGIntSubBis(MFGInt, temp2)
          FGIntDestroy(temp2)
        else: 
          QFGInt.Number[j] = QFGInt.Number[j] + 1
          FGIntSubBis(MFGInt, temp1)
      if MFGInt.Number[0] <= temp1.Number[0]: 
        if FGIntCompareAbs(temp1, FGInt2) != Eq: 
          FGIntShiftRightBy31(temp1)
          j = j - 1
  else: 
    Base10StringToFGInt('0', QFGInt)
  s = QFGInt.Number[0]
  while (s > 1) And (QFGInt.Number[s] == 0): s = s - 1
  if s < QFGInt.Number[0]: 
    setlen(QFGInt.Number, s + 1)
    QFGInt.Number[0] = s
  QFGInt.Sign = positive
  FGIntDestroy(temp1)
  Base10StringToFGInt('0', zero)
  Base10StringToFGInt('1', one)
  if s1 == negative: 
    if FGIntCompareAbs(MFGInt, zero) != Eq: 
      FGIntadd(QFGInt, one, temp1)
      FGIntDestroy(QFGInt)
      FGIntCopy(temp1, QFGInt)
      FGIntDestroy(temp1)
      FGIntsub(FGInt2, MFGInt, temp1)
      FGIntDestroy(MFGInt)
      FGIntCopy(temp1, MFGInt)
      FGIntDestroy(temp1)
    if s2 == positive: QFGInt.Sign = negative
  else: 
    QFGInt.Sign = s2
  FGIntDestroy(one)
  FGIntDestroy(zero)
  FGIntDestroy(MFGInt)
  FGInt1.Sign = s1
  FGInt2.Sign = s2

proc FGIntMod(FGInt1, FGInt2, MFGInt: var TBigInt) = 
  var 
    one, zero, temp1, temp2: TBigInt
    s1, s2: TSign
    s: int32
    i: int64
  s1 = FGInt1.Sign
  s2 = FGInt2.Sign
  FGIntAbs(FGInt1)
  FGIntAbs(FGInt2)
  FGIntCopy(FGInt1, MFGInt)
  FGIntCopy(FGInt2, temp1)
  if FGIntCompareAbs(FGInt1, FGInt2) != St: 
    s = FGInt1.Number[0] - FGInt2.Number[0]
    for t in countup(1, s): FGIntShiftLeftBy31(temp1)
    while FGIntCompareAbs(MFGInt, FGInt2) != St: 
      while FGIntCompareAbs(MFGInt, temp1) != St: 
        if MFGInt.Number[0] > temp1.Number[0]: 
          i = MFGInt.Number[MFGInt.Number[0]]
          i = i Shl 31
          i = i + MFGInt.Number[MFGInt.Number[0] - 1]
          i = i Div (temp1.Number[temp1.Number[0]] + 1)
        else: 
          i = MFGInt.Number[MFGInt.Number[0]] Div
              (temp1.Number[temp1.Number[0]] + 1)
        if (i != 0): 
          FGIntCopy(temp1, temp2)
          FGIntMulByIntBis(temp2, i)
          FGIntSubBis(MFGInt, temp2)
          if FGIntCompareAbs(MFGInt, temp2) != St: FGIntSubBis(MFGInt, temp2)
          FGIntDestroy(temp2)
        else: 
          FGIntSubBis(MFGInt, temp1) #         If FGIntCompareAbs(MFGInt, temp1) <> St Then FGIntSubBis(MFGInt,temp1);
      if MFGInt.Number[0] <= temp1.Number[0]: 
        if FGIntCompareAbs(temp1, FGInt2) != Eq: FGIntShiftRightBy31(temp1)
  FGIntDestroy(temp1)
  Base10StringToFGInt('0', zero)
  Base10StringToFGInt('1', one)
  if s1 == negative: 
    if FGIntCompareAbs(MFGInt, zero) != Eq: 
      FGIntSub(FGInt2, MFGInt, temp1)
      FGIntDestroy(MFGInt)
      FGIntCopy(temp1, MFGInt)
      FGIntDestroy(temp1)
  FGIntDestroy(one)
  FGIntDestroy(zero)
  FGInt1.Sign = s1
  FGInt2.Sign = s2

proc FGIntSquareMod(FGInt, Modb, FGIntSM: var TBigInt) = 
  var temp: TBigInt
  FGIntSquare(FGInt, temp)
  FGIntMod(temp, Modb, FGIntSM)
  FGIntDestroy(temp)

proc FGIntAddMod(FGInt1, FGInt2, base, FGIntres: var TBigInt) = 
  var temp: TBigInt
  FGIntadd(FGInt1, FGInt2, temp)
  FGIntMod(temp, base, FGIntres)
  FGIntDestroy(temp)

proc FGIntMulMod(FGInt1, FGInt2, base, FGIntres: var TBigInt) = 
  var temp: TBigInt
  FGIntMul(FGInt1, FGInt2, temp)
  FGIntMod(temp, base, FGIntres)
  FGIntDestroy(temp)

proc FGIntModExp(FGInt, exp, modb, res: var TBigInt) = 
  var 
    temp2, temp3: TBigInt
    S: String
  if (Modb.Number[1] Mod 2) == 1: 
    FGIntMontgomeryModExp(FGInt, exp, modb, res)
    return 
  FGIntToBase2String(exp, S)
  Base10StringToFGInt('1', res)
  FGIntcopy(FGInt, temp2)
  for i in countdown(len(S), 1): 
    if S[i] == '1': 
      FGIntmulMod(res, temp2, modb, temp3)
      FGIntCopy(temp3, res)
    FGIntSquareMod(temp2, Modb, temp3)
    FGIntCopy(temp3, temp2)
  FGIntDestroy(temp2)

proc FGIntModBis(FGInt: TBigInt, FGIntOut: var TBigInt, b, head: int32) = 
  if b <= FGInt.Number[0]: 
    setlen(FGIntOut.Number, (b + 1))
    for i in countup(0, b): FGIntOut.Number[i] = FGInt.Number[i]
    FGIntOut.Number[b] = FGIntOut.Number[b] And head
    i = b
    while (FGIntOut.Number[i] == 0) And (i > 1): i = i - 1
    if i < b: setlen(FGIntOut.Number, i + 1)
    FGIntOut.Number[0] = i
    FGIntOut.Sign = positive
  else: 
    FGIntCopy(FGInt, FGIntOut)
  
proc FGIntMulModBis(FGInt1, FGInt2: TBigInt, Prod: var TBigInt, b, head: int32) = 
  var 
    size, size1, size2, t, rest: int32
    Trest: int64
  size1 = FGInt1.Number[0]
  size2 = FGInt2.Number[0]
  size = min(b, size1 + size2)
  setlen(Prod.Number, (size + 1))
  for i in countup(1, size): Prod.Number[i] = 0
  for i in countup(1, size2): 
    rest = 0
    t = min(size1, b - i + 1)
    for j in countup(1, t): 
      Trest = FGInt1.Number[j]
      Trest = Trest * FGInt2.Number[i]
      Trest = Trest + Prod.Number[j + i - 1]
      Trest = Trest + rest
      Prod.Number[j + i - 1] = Trest And 2147483647
      rest = Trest Shr 31
    if (i + size1) <= b: Prod.Number[i + size1] = rest
  Prod.Number[0] = size
  if size == b: Prod.Number[b] = Prod.Number[b] And head
  while (Prod.Number[size] == 0) And (size > 1): size = size - 1
  if size < Prod.Number[0]: 
    setlen(Prod.Number, size + 1)
    Prod.Number[0] = size
  if FGInt1.Sign == FGInt2.Sign: Prod.Sign = Positive
  else: prod.Sign = negative
  
proc FGIntMontgomeryMod(GInt, base, baseInv: TBigInt, MGInt: var TBigInt, 
                        b: int32, head: int32) = 
  var 
    m, temp, temp1: TBigInt
    r: int32
  FGIntModBis(GInt, temp, b, head)
  FGIntMulModBis(temp, baseInv, m, b, head)
  FGIntMul(m, base, temp1)
  FGIntDestroy(temp)
  FGIntAdd(temp1, GInt, temp)
  FGIntDestroy(temp1)
  MGInt.Number = copy(temp.Number, b - 1, temp.Number[0] - b + 2)
  MGInt.Sign = positive
  MGInt.Number[0] = temp.Number[0] - b + 1
  FGIntDestroy(temp)
  if (head Shr 30) == 0: FGIntDivByIntBis(MGInt, head + 1, r)
  else: FGIntShiftRightBy31(MGInt)
  if FGIntCompareAbs(MGInt, base) != St: FGIntSubBis(MGInt, base)
  FGIntDestroy(temp)
  FGIntDestroy(m)

proc FGIntMontgomeryModExp(FGInt, exp, modb, res: var TBigInt) = 
  var 
    temp2, temp3, baseInv, r, zero: TBigInt
    t, b, head: int32
    S: String
  Base2StringToFGInt('0', zero)
  FGIntMod(FGInt, modb, res)
  if FGIntCompareAbs(res, zero) == Eq: 
    FGIntDestroy(zero)
    return 
  else: 
    FGIntDestroy(res)
  FGIntDestroy(zero)
  FGIntToBase2String(exp, S)
  t = modb.Number[0]
  b = t
  if (modb.Number[t] Shr 30) == 1: t = t + 1
  setlen(r.Number, (t + 1))
  r.Number[0] = t
  r.Sign = positive
  for i in countup(1, t): r.Number[i] = 0
  if t == modb.Number[0]: 
    head = 2147483647
    for j in countdown(29, 0): 
      head = head Shr 1
      if (modb.Number[t] Shr j) == 1: 
        r.Number[t] = 1 Shl (j + 1)
        break 
  else: 
    r.Number[t] = 1
    head = 2147483647
  FGIntModInv(modb, r, temp2)
  if temp2.Sign == negative: 
    FGIntCopy(temp2, BaseInv)
  else: 
    FGIntCopy(r, BaseInv)
    FGIntSubBis(BaseInv, temp2)
  FGIntAbs(BaseInv)
  FGIntDestroy(temp2)
  FGIntMod(r, modb, res)
  FGIntMulMod(FGInt, res, modb, temp2)
  FGIntDestroy(r)
  for i in countdown(len(S), 1): 
    if S[i] == '1': 
      FGIntmul(res, temp2, temp3)
      FGIntDestroy(res)
      FGIntMontgomeryMod(temp3, modb, baseinv, res, b, head)
      FGIntDestroy(temp3)
    FGIntSquare(temp2, temp3)
    FGIntDestroy(temp2)
    FGIntMontgomeryMod(temp3, modb, baseinv, temp2, b, head)
    FGIntDestroy(temp3)
  FGIntDestroy(temp2)
  FGIntMontgomeryMod(res, modb, baseinv, temp3, b, head)
  FGIntCopy(temp3, res)
  FGIntDestroy(temp3)
  FGIntDestroy(baseinv)

proc FGIntGCD(FGInt1, FGInt2: TBigInt, GCD: var TBigInt) = 
  var 
    k: TCompare
    zero, temp1, temp2, temp3: TBigInt
  k = FGIntCompareAbs(FGInt1, FGInt2)
  if (k == Eq): 
    FGIntCopy(FGInt1, GCD)
  elif (k == St): 
    FGIntGCD(FGInt2, FGInt1, GCD)
  else: 
    Base10StringToFGInt('0', zero)
    FGIntCopy(FGInt1, temp1)
    FGIntCopy(FGInt2, temp2)
    while (temp2.Number[0] != 1) Or (temp2.Number[1] != 0): 
      FGIntMod(temp1, temp2, temp3)
      FGIntCopy(temp2, temp1)
      FGIntCopy(temp3, temp2)
      FGIntDestroy(temp3)
    FGIntCopy(temp1, GCD)
    FGIntDestroy(temp2)
    FGIntDestroy(zero)

proc FGIntLCM(FGInt1, FGInt2: TBigInt, LCM: var TBigInt) = 
  var temp1, temp2: TBigInt
  FGIntGCD(FGInt1, FGInt2, temp1)
  FGIntmul(FGInt1, FGInt2, temp2)
  FGIntdiv(temp2, temp1, LCM)
  FGIntDestroy(temp1)
  FGIntDestroy(temp2)

proc FGIntTrialDiv9999(FGInt: TBigInt, ok: var bool) = 
  var 
    j: int32
    i: int
  if ((FGInt.Number[1] Mod 2) == 0): 
    ok = false
  else: 
    i = 0
    ok = true
    while ok And (i < 1228): 
      i = i + 1
      FGIntmodbyint(FGInt, primes[i], j)
      if j == 0: ok = false
  
proc FGIntRandom1(Seed, RandomFGInt: var TBigInt) = 
  var temp, base: TBigInt
  Base10StringToFGInt("281474976710656", base)
  Base10StringToFGInt("44485709377909", temp)
  FGIntMulMod(seed, temp, base, RandomFGInt)
  FGIntDestroy(temp)
  FGIntDestroy(base)

proc FGIntRabinMiller(FGIntp: var TBigInt, nrtest: int32, ok: var bool) = 
  var 
    j, b, i: int32
    m, z, temp1, temp2, temp3, zero, one, two, pmin1: TBigInt
    ok1, ok2: bool
  randomize
  j = 0
  Base10StringToFGInt('0', zero)
  Base10StringToFGInt('1', one)
  Base10StringToFGInt('2', two)
  FGIntsub(FGIntp, one, temp1)
  FGIntsub(FGIntp, one, pmin1)
  b = 0
  while (temp1.Number[1] Mod 2) == 0: 
    b = b + 1
    FGIntShiftRight(temp1)
  m = temp1
  i = 0
  ok = true
  Randomize
  while (i < nrtest) And ok: 
    i = i + 1
    Base10StringToFGInt(inttostr(Primes[Random(1227) + 1]), temp2)
    FGIntMontGomeryModExp(temp2, m, FGIntp, z)
    FGIntDestroy(temp2)
    ok1 = (FGIntCompareAbs(z, one) == Eq)
    ok2 = (FGIntCompareAbs(z, pmin1) == Eq)
    if Not (ok1 Or ok2): 
      while (ok And (j < b)): 
        if (j > 0) And ok1: 
          ok = false
        else: 
          j = j + 1
          if (j < b) And (Not ok2): 
            FGIntSquaremod(z, FGIntp, temp3)
            FGIntCopy(temp3, z)
            ok1 = (FGIntCompareAbs(z, one) == Eq)
            ok2 = (FGIntCompareAbs(z, pmin1) == Eq)
            if ok2: j = b
          elif (Not ok2) And (j >= b): 
            ok = false
  FGIntDestroy(zero)
  FGIntDestroy(one)
  FGIntDestroy(two)
  FGIntDestroy(m)
  FGIntDestroy(z)
  FGIntDestroy(pmin1)

proc FGIntBezoutBachet(FGInt1, FGInt2, a, b: var TBigInt) = 
  var zero, r1, r2, r3, ta, gcd, temp, temp1, temp2: TBigInt
  if FGIntCompareAbs(FGInt1, FGInt2) != St: 
    FGIntcopy(FGInt1, r1)
    FGIntcopy(FGInt2, r2)
    Base10StringToFGInt('0', zero)
    Base10StringToFGInt('1', a)
    Base10StringToFGInt('0', ta)
    while true: 
      FGIntdivmod(r1, r2, temp, r3)
      FGIntDestroy(r1)
      r1 = r2
      r2 = r3
      FGIntmul(ta, temp, temp1)
      FGIntsub(a, temp1, temp2)
      FGIntCopy(ta, a)
      FGIntCopy(temp2, ta)
      FGIntDestroy(temp1)
      FGIntDestroy(temp)
      if FGIntCompareAbs(r3, zero) == Eq: break 
    FGIntGCD(FGInt1, FGInt2, gcd)
    FGIntmul(a, FGInt1, temp1)
    FGIntsub(gcd, temp1, temp2)
    FGIntDestroy(temp1)
    FGIntdiv(temp2, FGInt2, b)
    FGIntDestroy(temp2)
    FGIntDestroy(ta)
    FGIntDestroy(r1)
    FGIntDestroy(r2)
    FGIntDestroy(gcd)
  else: 
    FGIntBezoutBachet(FGInt2, FGInt1, b, a)
  
proc FGIntModInv(FGInt1, base: TBigInt, Inverse: var TBigInt) = 
  var zero, one, r1, r2, r3, tb, gcd, temp, temp1, temp2: TBigInt
  Base10StringToFGInt('1', one)
  FGIntGCD(FGInt1, base, gcd)
  if FGIntCompareAbs(one, gcd) == Eq: 
    FGIntcopy(base, r1)
    FGIntcopy(FGInt1, r2)
    Base10StringToFGInt('0', zero)
    Base10StringToFGInt('0', inverse)
    Base10StringToFGInt('1', tb)
    while true: 
      FGIntDestroy(r3)
      FGIntdivmod(r1, r2, temp, r3)
      FGIntCopy(r2, r1)
      FGIntCopy(r3, r2)
      FGIntmul(tb, temp, temp1)
      FGIntsub(inverse, temp1, temp2)
      FGIntDestroy(inverse)
      FGIntDestroy(temp1)
      FGIntCopy(tb, inverse)
      FGIntCopy(temp2, tb)
      FGIntDestroy(temp)
      if FGIntCompareAbs(r3, zero) == Eq: break 
    if inverse.Sign == negative: 
      FGIntadd(base, inverse, temp)
      FGIntCopy(temp, inverse)
    FGIntDestroy(tb)
    FGIntDestroy(r1)
    FGIntDestroy(r2)
  FGIntDestroy(gcd)
  FGIntDestroy(one)

proc FGIntPrimetest(FGIntp: var TBigInt, nrRMtests: int, ok: var bool) = 
  FGIntTrialdiv9999(FGIntp, ok)
  if ok: FGIntRabinMiller(FGIntp, nrRMtests, ok)
  
proc FGIntLegendreSymbol(a, p: var TBigInt, L: var int) = 
  var 
    temp1, temp2, temp3, temp4, temp5, zero, one: TBigInt
    i: int32
    ok1, ok2: bool
  Base10StringToFGInt('0', zero)
  Base10StringToFGInt('1', one)
  FGIntMod(a, p, temp1)
  if FGIntCompareAbs(zero, temp1) == Eq: 
    FGIntDestroy(temp1)
    L = 0
  else: 
    FGIntDestroy(temp1)
    FGIntCopy(p, temp1)
    FGIntCopy(a, temp2)
    L = 1
    while FGIntCompareAbs(temp2, one) != Eq: 
      if (temp2.Number[1] Mod 2) == 0: 
        FGIntSquare(temp1, temp3)
        FGIntSub(temp3, one, temp4)
        FGIntDestroy(temp3)
        FGIntDivByInt(temp4, temp3, 8, i)
        if (temp3.Number[1] Mod 2) == 0: ok1 = false
        else: ok1 = true
        FGIntDestroy(temp3)
        FGIntDestroy(temp4)
        if ok1 == true: L = L * (- 1)
        FGIntDivByIntBis(temp2, 2, i)
      else: 
        FGIntSub(temp1, one, temp3)
        FGIntSub(temp2, one, temp4)
        FGIntMul(temp3, temp4, temp5)
        FGIntDestroy(temp3)
        FGIntDestroy(temp4)
        FGIntDivByInt(temp5, temp3, 4, i)
        if (temp3.Number[1] Mod 2) == 0: ok2 = false
        else: ok2 = true
        FGIntDestroy(temp5)
        FGIntDestroy(temp3)
        if ok2 == true: L = L * (- 1)
        FGIntMod(temp1, temp2, temp3)
        FGIntCopy(temp2, temp1)
        FGIntCopy(temp3, temp2)
    FGIntDestroy(temp1)
    FGIntDestroy(temp2)
  FGIntDestroy(zero)
  FGIntDestroy(one)

proc FGIntSquareRootModP(Square, Prime: TBigInt, SquareRoot: var TBigInt) = 
  var 
    one, n, b, s, r, temp, temp1, temp2, temp3: TBigInt
    a: int32
    L: int
  Base2StringToFGInt('1', one)
  Base2StringToFGInt("10", n)
  a = 0
  FGIntLegendreSymbol(n, Prime, L)
  while L != - 1: 
    FGIntAddBis(n, one)
    FGIntLegendreSymbol(n, Prime, L)
  FGIntCopy(Prime, s)
  s.Number[1] = s.Number[1] - 1
  while (s.Number[1] Mod 2) == 0: 
    FGIntShiftRight(s)
    a = a + 1
  FGIntMontgomeryModExp(n, s, Prime, b)
  FGIntAdd(s, one, temp)
  FGIntShiftRight(temp)
  FGIntMontgomeryModExp(Square, temp, Prime, r)
  FGIntDestroy(temp)
  FGIntModInv(Square, Prime, temp1)
  for i in countup(0, (a - 2)): 
    FGIntSquareMod(r, Prime, temp2)
    FGIntMulMod(temp1, temp2, Prime, temp)
    FGIntDestroy(temp2)
    for j in countup(1, (a - i - 2)): 
      FGIntSquareMod(temp, Prime, temp2)
      FGIntDestroy(temp)
      FGIntCopy(temp2, temp)
      FGIntDestroy(temp2)
    if FGIntCompareAbs(temp, one) != Eq: 
      FGIntMulMod(r, b, Prime, temp3)
      FGIntDestroy(r)
      FGIntCopy(temp3, r)
      FGIntDestroy(temp3)
    FGIntDestroy(temp)
    FGIntDestroy(temp2)
    if i == (a - 2): break 
    FGIntSquareMod(b, Prime, temp3)
    FGIntDestroy(b)
    FGIntCopy(temp3, b)
    FGIntDestroy(temp3)
  FGIntCopy(r, SquareRoot)
  FGIntDestroy(r)
  FGIntDestroy(s)
  FGIntDestroy(b)
  FGIntDestroy(temp1)
  FGIntDestroy(one)
  FGIntDestroy(n)
