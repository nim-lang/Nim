# Helper: instantiates fromRaw[int] in a CLEAN scope (no mtscopeb) -> the
# correct instance that the consumer must reuse.
import mtscopegen
proc warm*(): string = fromRaw(5)
