# Running `tests/ic`

    ./bin/testament --nim:<your compiler> cat ic

## The metamorphic tests are expensive, and look hung when they are not

16 of the tests carry `#? metamorphic`. Each has 3–4 `#!STEP` directives, and
every step compiles the program **twice** — once under `nim ic`, once with
`nim c` as the reference oracle. That is 100+ full compilations for the
category. Under `--ic:on` each compilation additionally fans out one backend
process per module per stage, and each of those is a compiler holding its own
module graph (~800MB peak).

**A `nim ic` parent sitting at 0% CPU is normal.** It is waiting on its
children. It is not a deadlock, and neither is a metamorphic test that occupies
the runner for many minutes. Before concluding anything is stuck, check that the
test NAME changes over a few minutes — that is the difference between slow and
hung, and it is easy to get wrong.

On a memory-constrained machine the fan-out will swap. The symptoms are exactly
the ones that read as a deadlock: several processes at 0% CPU, no output, a
different test "stuck" on every run, and the same compilation finishing in
seconds when run on its own. Check `vm_stat` (page-ins per second) and
`sysctl vm.swapusage` before looking for a bug. This was diagnosed as a
testament/`nim ic` interaction more than once before anyone measured.

Cap the fan-out to fit the machine — precedence documented at `deps.nim`'s
`let parallel`:

    --parallelBuild:N     # standard flag, given meaning under IC
    -d:icJobs:N           # same cap, legacy define
    -d:icNoParallel       # serial, and non-interleaved child output

Serial output matters for a second reason: the parallel backend processes share
one stderr, so any per-process diagnostic printing (`NIM_IC_BNODE_GRIND`,
`-d:icCanRaiseLog`) interleaves and produces torn lines. Either use
`-d:icNoParallel` or parse defensively and count what you dropped.

## Running a single test

`testament r tests/ic/<file>.nim` works for the ordinary tests. It does NOT work
for the metamorphic ones — the multi-step files carry several `discard """`
spec blocks and the single-test path rejects them with "duplicate `specStart`".
Those only run through `cat ic`.

Files matching `tests/ic/*_temp.nim` are ignored by git (see `.gitignore`) and
are scratch, not tests: several import helper modules that do not exist and fail
for that reason alone.
