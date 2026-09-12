discard """
  targets: "c cpp js"
  matrix: "; --legacy:importcNoSideEffect -d:testLegacyImportc"
"""

block: # `.noSideEffect`
  func foo(bar: proc(): int): int {.effectsOf: bar.} = bar()
  var count = 0
  proc fn1(): int = 1
  proc fn2(): int = (count.inc; count)

  template accept(body) =
    doAssert compiles(block:
      body)

  template reject(body) =
    doAssert not compiles(block:
      body)

  accept:
    func fun1() = discard foo(fn1)
  reject:
    func fun1() = discard foo(fn2)

  var foo2: type(foo) = foo
  accept:
    func main() = discard foo(fn1)
  reject:
    func main() = discard foo2(fn1)

block: # issue #26193
  proc imported() {.importc.}
  proc impureImported() {.importc, sideEffect.}
  proc pureImported() {.importc, noSideEffect.}
  func importedFunc() {.importc.}
  proc wrapper() = imported()

  const legacyImportc = defined(testLegacyImportc)
  doAssert compiles(block:
    func direct() = imported()) == legacyImportc
  doAssert compiles(block:
    proc direct() {.noSideEffect.} = imported()) == legacyImportc
  doAssert compiles(block:
    func indirect() = wrapper()) == legacyImportc
  doAssert not compiles(block:
    func explicitImpurity() = impureImported())
  doAssert not compiles(block:
    let callback: proc() {.noSideEffect.} = imported)
  doAssert compiles(block:
    let callback: proc() {.noSideEffect.} = pureImported)
  doAssert compiles(block:
    func explicitPurity() =
      pureImported()
      importedFunc())
  doAssert compiles(block:
    proc gcSafeImport() {.gcsafe, raises: [].} = imported())
