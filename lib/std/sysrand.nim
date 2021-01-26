#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Cryptographically secure pseudorandom number generator.
## 
## | Targets    | Implementation|
## | :---         | ----:       |
## | Windows | `BCryptGenRandom`_ |
## | Linux | `getrandom`_ |
## | MacOSX | `getentropy`_ |
## | IOS | `SecRandomCopyBytes`_ |
## | OpenBSD | `getentropy openbsd`_ |
## | FreeBSD | `getrandom freebsd`_ |
## | JS(Web Browser) | `getRandomValues`_ |
## | Nodejs | `randomFillSync`_ |
## | Other Unix platforms | `/dev/urandom`_ |
##
## .. _BCryptGenRandom: https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptgenrandom
## .. _getrandom: https://man7.org/linux/man-pages/man2/getrandom.2.html
## .. _getentropy: https://www.unix.com/man-page/mojave/2/getentropy
## .. _SecRandomCopyBytes: https://developer.apple.com/documentation/security/1399291-secrandomcopybytes?language=objc
## .. _getentropy openbsd: https://man.openbsd.org/getentropy.2
## .. _getrandom freebsd: https://www.freebsd.org/cgi/man.cgi?query=getrandom&manpath=FreeBSD+12.0-stable
## .. _getRandomValues: https://www.w3.org/TR/WebCryptoAPI/#Crypto-method-getRandomValues
## .. _randomFillSync: https://nodejs.org/api/crypto.html#crypto_crypto_randomfillsync_buffer_offset_size
## .. _/dev/urandom: https://en.wikipedia.org/wiki//dev/random
##

runnableExamples:
  doAssert urandom(0).len == 0
  doAssert urandom(113).len == 113
  doAssert urandom(1234) != urandom(1234) # unlikely to fail in practice

##
## See also
## ========
## * `random module <random.html>`_
##

import std/os


when defined(posix):
  import std/posix

  when not defined(linux):
    const batchSize = 256

    template batchImpl(result: var int, dest: var openArray[byte], getRandomImpl) =
      let size = dest.len
      if size == 0:
        return

      let
        chunks = (size - 1) div batchSize
        left = size - chunks * batchSize
      var base = 0
      for i in 0 ..< chunks:
        let readBytes = getRandomImpl(addr dest[base], batchSize)
        if readBytes < 0:
          return readBytes
        inc(base, batchSize)

      result = getRandomImpl(addr dest[base], left)

when defined(js):
  import std/private/jsutils

  when defined(nodejs):
    {.emit: "const _nim_nodejs_crypto = require('crypto');".}

    proc randomFillSync(p: Uint8Array) {.importjs: "_nim_nodejs_crypto.randomFillSync(#)".}

    template urandomImpl(dest: var openArray[byte]) =
      let size = dest.len
      if size == 0:
        return

      var src = newUint8Array(size)
      randomFillSync(src)
      for i in 0 ..< size:
        dest[i] = src[i]

  else:
    const batchSize = 256

    proc getRandomValues(p: Uint8Array) {.importjs: "window.crypto.getRandomValues(#)".}

    template urandomImpl(dest: var openArray[byte]) =
      let size = dest.len
      if size == 0:
        return

      let chunks = (size - 1) div batchSize
      for i in 0 ..< chunks:
        for j in 0 ..< batchSize:
          var src = newUint8Array(batchSize)
          getRandomValues(src)
          dest[result + j] = src[j]

        inc(result, batchSize)

      let left = size - chunks * batchSize
      var src = newUint8Array(left)
      getRandomValues(src)
      for i in 0 ..< left:
        dest[result + i] = src[i]

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

  template urandomImpl(dest: var openArray[byte]) =
    let size = dest.len
    if size == 0:
      return

    result = randomBytes(addr dest[0], size)

elif defined(linux):
  let SYS_getrandom {.importc: "SYS_getrandom", header: "<sys/syscall.h>".}: clong
  const syscallHeader = """#include <unistd.h>
#include <sys/syscall.h>"""

  proc syscall(
    n: clong, buf: pointer, bufLen: cint, flags: cuint
  ): int {.importc: "syscall", header: syscallHeader.}
    #  When reading from the urandom source (GRND_RANDOM is not set),
    #  getrandom() will block until the entropy pool has been
    #  initialized (unless the GRND_NONBLOCK flag was specified).  If a
    #  request is made to read a large number of bytes (more than 256),
    #  getrandom() will block until those bytes have been generated and
    #  transferred from kernel memory to buf.

  template urandomImpl(dest: var openArray[byte]) =
    let size = dests.len
    if size == 0:
      return

    while result < size:
      let readBytes = syscall(SYS_getrandom, addr dest[result], cint(size - result), 0)
      if readBytes == 0:
        break
      elif readBytes > 0:
        inc(result, readBytes)
      else:
        if osLastError().int in {EINTR, EAGAIN}:
          discard
        else:
          result = -1
          break

elif defined(openbsd):
  proc getentropy(p: pointer, size: cint): cint {.importc: "getentropy", header: "<unistd.h>".}
    # fills a buffer with high-quality entropy,
    # which can be used as input for process-context pseudorandom generators like `arc4random`.
    # The maximum buffer size permitted is 256 bytes.

  proc getRandomImpl(p: pointer, size: int): int {.inline.} =
    result = getentropy(p, cint(size)).int

  template urandomImpl(dest: var openArray[byte]) =
    batchImpl(result, dest, getRandomImpl)

elif defined(freebsd):
  type cssize_t {.importc: "ssize_t", header: "<sys/types.h>".} = int

  proc getrandom(p: pointer, size: csize_t, flags: cuint): cssize_t {.importc: "getrandom", header: "<sys/random.h>".}
    # Upon successful completion, the number of bytes which were	actually read
    # is returned. For requests larger than 256	bytes, this can	be fewer bytes
    # than were requested. Otherwise, -1 is returned and the global variable
    # errno is set to indicate the error.

  proc getRandomImpl(p: pointer, size: int): int {.inline.} =
    result = getrandom(p, csize_t(batchSize), 0)

  template urandomImpl(dest: var openArray[byte]) =
    batchImpl(result, dest, getRandomImpl)

elif defined(ios):
  {.passL: "-framework Security".}

  const errSecSuccess = 0 ## No error.

  type
    SecRandom {.importc: "struct __SecRandom".} = object

    SecRandomRef = ptr SecRandom
      ## An abstract Core Foundation-type object containing information about a random number generator.

  proc secRandomCopyBytes(
    rnd: SecRandomRef, count: csize_t, bytes: pointer
    ): cint {.importc: "SecRandomCopyBytes", header: "<Security/SecRandom.h>".}
    ## Generates an array of cryptographically secure random bytes.

  template urandomImpl(dest: var openArray[byte]) =
    let size = dest.len
    if size == 0:
      return

    # `kSecRandomDefault` is a synonym for NULL.
    result = secRandomCopyBytes(nil, csize_t(size), addr dest[0])

elif defined(macosx):
  const sysrandomHeader = """#include <Availability.h>
#include <sys/random.h>
"""

  proc getentropy(p: pointer, size: csize_t): cint {.importc: "getentropy", header: sysrandomHeader.}
    # getentropy() fills a buffer with random data, which can be used as input 
    # for process-context pseudorandom generators like arc4random(3).
    # The maximum buffer size permitted is 256 bytes.

  proc getRandomImpl(p: pointer, size: int): int {.inline.} =
    result = getentropy(p, csize_t(size)).int

  template urandomImpl(dest: var openArray[byte]) =
    batchImpl(result, dest, getRandomImpl)
else:
  template urandomImpl(dest: var openArray[byte]) =
    let size = dest.len
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
          let readBytes = posix.read(fd, addr dest[base], batchSize)
          if readBytes < 0:
            return readBytes
          inc(base, batchSize)

        result = posix.read(fd, addr dest[base], left)
      discard posix.close(fd)

proc urandom*(dest: var openArray[byte]): int =
  ## Fills `dest` with random bytes suitable for cryptographic use.
  ## 
  ## If `dest` is empty, `urandom` immediately returns success,
  ## without calling underlying operating system api.
  urandomImpl(dest)

proc urandom*(size: Natural): seq[byte] {.inline.} =
  ## Returns random bytes suitable for cryptographic use.
  result = newSeq[byte](size)
  let ret = urandom(result)
  when defined(js): discard ret
  elif defined(windows):
    if ret != STATUS_SUCCESS:
      raiseOsError(osLastError())
  else:
    if ret < 0:
      raiseOsError(osLastError())
