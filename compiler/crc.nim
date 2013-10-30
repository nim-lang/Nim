#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  strutils

type
  TCrc32* = int32

const
  InitCrc32* = TCrc32(- 1)
  InitAdler32* = int32(1)

proc updateCrc32*(val: int8, crc: TCrc32): TCrc32 {.inline.}
proc updateCrc32*(val: Char, crc: TCrc32): TCrc32 {.inline.}
proc crcFromBuf*(buf: Pointer, length: int): TCrc32
proc strCrc32*(s: string): TCrc32
proc crcFromFile*(filename: string): TCrc32
proc updateAdler32*(adler: int32, buf: pointer, length: int): int32
# implementation

type
  TCRC_TabEntry = int

const
  crc32table: array[0..255, TCRC_TabEntry] = [0, 1996959894, - 301047508,
    - 1727442502, 124634137, 1886057615, - 379345611, - 1637575261, 249268274,
    2044508324, - 522852066, - 1747789432, 162941995, 2125561021, - 407360249,
    - 1866523247, 498536548, 1789927666, - 205950648, - 2067906082, 450548861,
    1843258603, - 187386543, - 2083289657, 325883990, 1684777152, - 43845254,
    - 1973040660, 335633487, 1661365465, - 99664541, - 1928851979, 997073096,
    1281953886, - 715111964, - 1570279054, 1006888145, 1258607687, - 770865667,
    - 1526024853, 901097722, 1119000684, - 608450090, - 1396901568, 853044451,
    1172266101, - 589951537, - 1412350631, 651767980, 1373503546, - 925412992,
    - 1076862698, 565507253, 1454621731, - 809855591, - 1195530993, 671266974,
    1594198024, - 972236366, - 1324619484, 795835527, 1483230225, - 1050600021,
    - 1234817731, 1994146192, 31158534, - 1731059524, - 271249366, 1907459465,
    112637215, - 1614814043, - 390540237, 2013776290, 251722036, - 1777751922,
    - 519137256, 2137656763, 141376813, - 1855689577, - 429695999, 1802195444,
    476864866, - 2056965928, - 228458418, 1812370925, 453092731, - 2113342271,
    - 183516073, 1706088902, 314042704, - 1950435094, - 54949764, 1658658271,
    366619977, - 1932296973, - 69972891, 1303535960, 984961486, - 1547960204,
    - 725929758, 1256170817, 1037604311, - 1529756563, - 740887301, 1131014506,
    879679996, - 1385723834, - 631195440, 1141124467, 855842277, - 1442165665,
    - 586318647, 1342533948, 654459306, - 1106571248, - 921952122, 1466479909,
    544179635, - 1184443383, - 832445281, 1591671054, 702138776, - 1328506846,
    - 942167884, 1504918807, 783551873, - 1212326853, - 1061524307, - 306674912,
    - 1698712650, 62317068, 1957810842, - 355121351, - 1647151185, 81470997,
    1943803523, - 480048366, - 1805370492, 225274430, 2053790376, - 468791541,
    - 1828061283, 167816743, 2097651377, - 267414716, - 2029476910, 503444072,
    1762050814, - 144550051, - 2140837941, 426522225, 1852507879, - 19653770,
    - 1982649376, 282753626, 1742555852, - 105259153, - 1900089351, 397917763,
    1622183637, - 690576408, - 1580100738, 953729732, 1340076626, - 776247311,
    - 1497606297, 1068828381, 1219638859, - 670225446, - 1358292148, 906185462,
    1090812512, - 547295293, - 1469587627, 829329135, 1181335161, - 882789492,
    - 1134132454, 628085408, 1382605366, - 871598187, - 1156888829, 570562233,
    1426400815, - 977650754, - 1296233688, 733239954, 1555261956, - 1026031705,
    - 1244606671, 752459403, 1541320221, - 1687895376, - 328994266, 1969922972,
    40735498, - 1677130071, - 351390145, 1913087877, 83908371, - 1782625662,
    - 491226604, 2075208622, 213261112, - 1831694693, - 438977011, 2094854071,
    198958881, - 2032938284, - 237706686, 1759359992, 534414190, - 2118248755,
    - 155638181, 1873836001, 414664567, - 2012718362, - 15766928, 1711684554,
    285281116, - 1889165569, - 127750551, 1634467795, 376229701, - 1609899400,
    - 686959890, 1308918612, 956543938, - 1486412191, - 799009033, 1231636301,
    1047427035, - 1362007478, - 640263460, 1088359270, 936918000, - 1447252397,
    - 558129467, 1202900863, 817233897, - 1111625188, - 893730166, 1404277552,
    615818150, - 1160759803, - 841546093, 1423857449, 601450431, - 1285129682,
    - 1000256840, 1567103746, 711928724, - 1274298825, - 1022587231, 1510334235,
    755167117]

proc updateCrc32(val: int8, crc: TCrc32): TCrc32 =
  result = TCrc32(crc32Table[(int(crc) xor (int(val) and 0x000000FF)) and
      0x000000FF]) xor (crc shr TCrc32(8))

proc updateCrc32(val: Char, crc: TCrc32): TCrc32 =
  result = updateCrc32(toU8(ord(val)), crc)

proc strCrc32(s: string): TCrc32 =
  result = InitCrc32
  for i in countup(0, len(s) - 1): result = updateCrc32(s[i], result)

proc `><`*(c: TCrc32, s: string): TCrc32 =
  result = c
  for i in 0..len(s)-1: result = updateCrc32(s[i], result)

type
  TByteArray = array[0..10000000, int8]
  PByteArray = ref TByteArray

proc crcFromBuf(buf: Pointer, length: int): TCrc32 =
  var p = cast[PByteArray](buf)
  result = InitCrc32
  for i in countup(0, length - 1): result = updateCrc32(p[i], result)

proc crcFromFile(filename: string): TCrc32 =
  const
    bufSize = 8000 # don't use 8K for the memory allocator!
  var
    bin: tfile
  result = InitCrc32
  if not open(bin, filename):
    return                    # not equal if file does not exist
  var buf = alloc(BufSize)
  var p = cast[PByteArray](buf)
  while true:
    var readBytes = readBuffer(bin, buf, bufSize)
    for i in countup(0, readBytes - 1): result = updateCrc32(p[i], result)
    if readBytes != bufSize: break
  dealloc(buf)
  close(bin)

const
  base = int32(65521) # largest prime smaller than 65536
                      # NMAX = 5552; original code with unsigned 32 bit integer
                      # NMAX is the largest n
                      # such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1
  nmax = 3854 # code with signed 32 bit integer
              # NMAX is the largest n such that
              # 255n(n+1)/2 + (n+1)(BASE-1) <= 2^31-1
              # The penalty is the time loss in the extra MOD-calls.

proc updateAdler32(adler: int32, buf: pointer, length: int): int32 =
  var
    s1, s2: int32
    L, k, b: int
  s1 = adler and int32(0x0000FFFF)
  s2 = (adler shr int32(16)) and int32(0x0000FFFF)
  L = length
  b = 0
  while (L > 0):
    if L < nmax: k = L
    else: k = nmax
    dec(L, k)
    while (k > 0):
      s1 = s1 +% int32((cast[cstring](buf))[b])
      s2 = s2 +% s1
      inc(b)
      dec(k)
    s1 = `%%`(s1, base)
    s2 = `%%`(s2, base)
  result = (s2 shl int32(16)) or s1
