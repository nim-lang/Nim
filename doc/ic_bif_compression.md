# Experimental IC BIF compression

Build the compiler with `-d:icCompressBif` to try Zstandard level 1 compression
of `.s.bif` and `.t.bif` module artifacts. The Zstandard library must be
available to the linker. The normal compiler is unchanged. The experiment uses
a distinct IC cache version; use separate nimcache directories for comparisons.

Compressed files have a private wrapper and are expanded before the existing
lazy BIF loader reads them. Expansion allocates a private copy in each compiler
process for its lifetime; uncompressed BIFs instead share file-backed pages.
The existing standalone BIF tools do not understand the wrapper. IDE symbol
queries also lose the cheap on-disk membership probe in this experiment.
These are important limitations when interpreting the timing and memory results.

## FigDraw sample

On an Apple M3 Pro, using release-built compilers and FigDraw's
`tests/ttransfer.nim`, with `--parallelBuild:4` and separate empty caches:

| Measurement | Uncompressed | zlib 1 | LZ4 default | Zstandard 1 |
| --- | ---: | ---: | ---: | ---: |
| Cold build, wall time (2 runs) | 40.06–40.33 s | 46.71–52.11 s | 47.58–53.67 s | 49.87–60.10 s |
| Module BIF bytes (476 files) | 115,951,298 | 27,027,791 | 36,880,157 | 22,080,850 |
| No-op rebuild (3 runs) | 0.19–0.21 s | 0.20 s | 0.22–0.30 s | 0.22–0.31 s |
| Rebuild after removing main `.t.bif` | 2.47 s | 2.41 s | 2.11 s | 2.27 s |

The cold numbers are two observations each, and forced rebuild numbers are
single observations, not a statistical benchmark. Cold builds ran sequentially
with fresh caches in the order uncompressed, zlib, LZ4, Zstandard, uncompressed,
zlib, Zstandard, LZ4. Their spread is too large to establish a speed ranking
among the codecs. The resulting test executables passed and produced identical
output. Peak aggregate worker memory was not measured. A no-op rebuild does not
exercise BIF decompression. The local libraries were LZ4 1.10.0 and Zstandard
1.5.7.

Example commands, from the Nim checkout and then the FigDraw checkout:

```sh
bin/nim c -d:release -o:bin/nim-ic-baseline compiler/nim.nim
bin/nim c -d:release -d:icCompressBif --passL:"$(pkg-config --libs libzstd)" -o:bin/nim-ic-zstd compiler/nim.nim
cd ../figdraw
/path/to/Nim/bin/nim-ic-baseline ic --parallelBuild:4 --nimcache:/tmp/ic-baseline --out:/tmp/figdraw-baseline tests/ttransfer.nim
/path/to/Nim/bin/nim-ic-zstd ic --parallelBuild:4 --nimcache:/tmp/ic-zstd --out:/tmp/figdraw-zstd tests/ttransfer.nim
```
