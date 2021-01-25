## Cryptographically secure pseudorandom number generator.
## 
## | Targets    | Implementation|
## | :---         | ----:       |
## | Windows| `BCryptGenRandom`_ |
## | Linux| `getrandom`_ system call when available, otherwise `/dev/urandom`_ will be used|
## | MacOSX| `getentropy`_ system call when available, otherwise `/dev/urandom`_ will be used|
## | IOS  | `SecRandomCopyBytes`_|
## | OpenBSD| `getentropy openbsd`_ system call when available, otherwise `/dev/urandom`_ will be used|
## | FreeBSD| `getrandom freebsd`_ system call when available, otherwise `/dev/urandom`_ will be used|
## | JS(Web Browser)| `getRandomValues`_|
## | Other platforms| `/dev/urandom`_|
##
## .. _BCryptGenRandom: https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptgenrandom
## .. _getrandom: https://man7.org/linux/man-pages/man2/getrandom.2.html
## .. _/dev/urandom: https://en.wikipedia.org/wiki//dev/random
## .. _getentropy: https://www.unix.com/man-page/mojave/2/getentropy
## .. _SecRandomCopyBytes: https://developer.apple.com/documentation/security/1399291-secrandomcopybytes?language=objc
## .. _getentropy openbsd: https://man.openbsd.org/getentropy.2
## .. _getrandom freebsd: https://www.freebsd.org/cgi/man.cgi?query=getrandom&manpath=FreeBSD+12.0-stable
## .. _getRandomValues: https://www.w3.org/TR/WebCryptoAPI/#Crypto-method-getRandomValues
## 

import std/os

runnableExamples:
  doAssert urandom(0).len == 0
  doAssert urandom(113).len == 113
  doAssert urandom(1234) != urandom(1234) # unlikely to fail in practice



when defined(posix):
  import std/posix

  const batchSize = 256

  template processReadBytes(readBytes: int, p: pointer, res: var int) =
    if readBytes == 0:
      break
    elif readBytes > 0:
      inc(res, readBytes)
      cast[ptr pointer](p)[] = cast[pointer](cast[ByteAddress](p) + readBytes)
    else:
      if osLastError().int in {EINTR, EAGAIN}:
        discard
      else:
        res = -1
        break

  proc getDevUrandom(p: var openArray[byte], size: Natural): int =
    let size = p.len
    if size == 0:
      return

    let fd = posix.open("/dev/urandom", O_RDONLY)

    if fd > 0:
      var stat: Stat
      if fstat(fd, stat) != -1 and S_ISCHR(stat.st_mode):
        let
          chunks = (size - 1) div batchSize
          left = size - chunks * batchSize

        var base = 0
        for i in 0 ..< chunks:
          let readBytes = posix.read(fd, addr p[base], batchSize)
          if readBytes < 0:
            return readBytes
          inc(base, batchSize)

        result = posix.read(fd, addr p[base], left)
      discard posix.close(fd)

when defined(js):
  import std/private/jsutils

  proc getRandomValues(arr: Uint8Array) {.importjs: "window.crypto.getRandomValues(#)".}

  const
    maxBrowserCryptoBufferSize = 256

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      let chunks = (size - 1) div maxBrowserCryptoBufferSize
      var base = 0
      for i in 0 ..< chunks:
        for j in 0 ..< maxBrowserCryptoBufferSize:
          var src = newUint8Array(maxBrowserCryptoBufferSize)
          getRandomValues(src)
          p[base + j] = src[j]

        inc(base, maxBrowserCryptoBufferSize)

      let left = size - chunks * maxBrowserCryptoBufferSize
      var src = newUint8Array(left)
      getRandomValues(src)
      for i in 0 ..< left:
        p[base + i] = src[i]

elif defined(windows):
  type
    PVOID = pointer
    BCRYPT_ALG_HANDLE = PVOID
    PUCHAR = ptr cuchar
    NTSTATUS = clong
    ULONG = culong

  const
    STATUS_SUCCESS = 0x00000000
    BCRYPT_USE_SYSTEM_PREFERRED_RNG = 0x00000002

  proc bCryptGenRandom(
    hAlgorithm: BCRYPT_ALG_HANDLE,
    pbBuffer: PUCHAR,
    cbBuffer: ULONG,
    dwFlags: ULONG
  ): NTSTATUS {.stdcall, importc: "BCryptGenRandom", dynlib: "Bcrypt.dll".}


  proc randomBytes(pbBuffer: pointer, cbBuffer: Natural): int =
    bCryptGenRandom(nil, cast[PUCHAR](pbBuffer), ULONG(cbBuffer),
                            BCRYPT_USE_SYSTEM_PREFERRED_RNG)

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      result = randomBytes(addr p[0], size)

elif defined(linux):
  let SYS_getrandom {.importc: "SYS_getrandom", header: "<sys/syscall.h>".}: clong

  proc syscall(n: clong, buf: pointer, bufLen: cint, flags: cuint): int {.importc: "syscall", header: "<sys/syscall.h>".}

  proc randomBytes(p: pointer, size: Natural): int =
    while result < size:
      let readBytes = syscall(SYS_getrandom, p, cint(size - result), 0)
      processReadBytes(readBytes, p, result)

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      result = randomBytes(addr p[0], size)

elif defined(openbsd):
  proc getentropy(p: pointer, size: cint): cint {.importc: "getentropy", header: "<unistd.h>".}

  proc randomBytes(p: pointer, size: Natural): int =
    while result < size:
      let readBytes = getentropy(p, cint(size - result))
      processReadBytes(readBytes, p, result)

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      result = randomBytes(addr p[0], size)

elif defined(freebsd):
  type ssize_t = int
  proc getrandom(p: pointer, size: csize_t, flags: cuint): ssize_t {.importc: "getrandom", header: "<sys/random.h>".}

  proc randomBytes(p: pointer, size: int): int =
    while result < size:
      let readBytes = getrandom(p, csize_t(size - result), 0)
      processReadBytes(readBytes, p, result)

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      result = randomBytes(addr p[0], size)

elif defined(ios):
  {.passL: "-framework Security".}

  const errSecSuccess = 0
  type
    SecRandom {.importc: "struct __SecRandom".} = object

    SecRandomRef = ptr SecRandom
      ## An abstract Core Foundation-type object containing information about a random number generator.

  proc secRandomCopyBytes(
    rnd: SecRandomRef, count: csize_t, bytes: pointer
    ): cint {.importc: "SecRandomCopyBytes", header: "<Security/SecRandom.h>".}

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      # `kSecRandomDefault` is a synonym for NULL.
      result = secRandomCopyBytes(nil, csize_t(size), addr p[0])

elif defined(macosx):
  proc getentropy(p: pointer, size: csize_t): cint {.importc: "getentropy", header: "<sys/random.h>".}

  proc randomBytes(p: pointer, size: Natural): int =
    while result < size:
      let readBytes = getentropy(p, csize_t(size - result))
      processReadBytes(readBytes, p, result)

  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      result = randomBytes(addr p[0], size)
else:
  proc urandom*(p: var openArray[byte]): int =
    let size = p.len
    if size > 0:
      result = getDevUrandom(p, size)

proc urandom*(size: Natural): seq[byte] =
  result = newSeq[byte](size)
  let ret = urandom(result)
  when defined(js): discard ret
  elif defined(windows):
    if ret != STATUS_SUCCESS:
      raiseOsError(osLastError())
  else:
    if ret < 0:
      raiseOsError(osLastError())
