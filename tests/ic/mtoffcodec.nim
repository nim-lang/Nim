# Helper for ttypeoffer.nim: the extra overload that flips `compiles(toSszType(Gwei))`.
import mtoffgwei
template toSszType*(v: Gwei): uint64 = uint64(v)
