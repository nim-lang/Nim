# Cycle Collector Overhead Analysis

## Known Parameters from Benchmarks

From `yrc_realistic_benchmark.nim`:
- **RC operations**: ~0.04% of total runtime in realistic programs
- **Atomic RC slowdown**: ~1.36x vs non-atomic (0.009s vs 0.007s for 1M ops)
- **Total overhead**: Negligible (< 0.1%) due to RC ops being tiny fraction

From `yrc_benchmark.nim`:
- **Single-threaded**: Buffered RC is ~2.6x slower than atomic RC
- **Multi-threaded (8 threads)**: Buffered RC is ~1.46x slower than atomic RC
- **Contention benefit**: Buffering improves by ~3.27x under contention

## Mathematical Model

### 1. Per-Operation Overhead

**Immediate Atomic RC** (acyclic case):
```
T_atomic = T_nonatomic × 1.36
```

**Buffered RC** (cyclic case):
```
T_buffered = T_atomic × f_buffering

where:
  f_buffering = 2.6 (single-threaded)
  f_buffering = 1.46 (multi-threaded, 8 threads)
```

### 2. Collection Overhead

Collection runs when `roots.len >= RootsThreshold` (default: 10).

**Collection frequency**:
```
F_collection = N_decRefs / RootsThreshold

where:
  N_decRefs = number of decRef operations that create roots
```

**Per-collection cost**:
```
C_collection = C_merge + C_bacon

where:
  C_merge = cost to drain all stripe queues (O(N_stripes × QueueSize))
  C_bacon = cost of Bacon's algorithm (markGray + scan + collectColor)
```

**Amortized collection overhead per RC operation**:
```
O_collection = C_collection / RootsThreshold
```

### 3. Total Overhead Formula

**For acyclic objects** (immediate atomic RC):
```
Overhead_acyclic = (T_atomic - T_nonatomic) × P_rc
                 = T_nonatomic × 0.36 × P_rc

where:
  P_rc = percentage of time spent on RC operations (~0.04%)
```

**For cyclic objects** (buffered RC + cycle collection):
```
Overhead_cyclic = (T_buffered - T_atomic) × P_rc + O_collection × F_collection
                 = T_atomic × (f_buffering - 1) × P_rc + C_collection × (N_decRefs / RootsThreshold)

where:
  f_buffering = 2.6 (single) or 1.46 (multi-threaded)
  P_rc = percentage of time spent on RC operations (~0.04%)
```

### 4. Realistic Program Estimate

Given:
- RC operations: 0.04% of total runtime
- Atomic RC: 1.36x slower than non-atomic
- Buffered RC: 2.6x slower than atomic (single-threaded)
- Collection threshold: 10 roots
- Assume: 1 collection per 10 decRefs that create roots

**Acyclic overhead**:
```
Overhead_acyclic = 0.36 × 0.04% = 0.0144% ≈ 0.01%
```

**Cyclic overhead** (single-threaded):
```
Overhead_buffering = (2.6 - 1) × 0.04% = 0.064% ≈ 0.06%

Collection overhead calculated below...
```

### 5. Collection Overhead Model

**Collection frequency**:
```
Collections = N_root_decRefs / RootsThreshold

where:
  N_root_decRefs = number of decRefs that create roots (add to roots array)
  RootsThreshold = 10 (default)
```

**Per-collection cost**:
```
C_collection = C_merge + C_bacon

where:
  C_merge = cost to drain stripe queues (O(N_stripes × QueueSize))
  C_bacon = cost of Bacon's algorithm (O(roots.len × avg_edges))
```

**Amortized collection overhead**:
```
O_collection = (Collections × C_collection) / TotalTime
             = (N_root_decRefs / RootsThreshold × C_collection) / TotalTime
```

### 6. Realistic Collection Cost Estimate

From YRC implementation analysis:
- `mergePendingRoots`: Processes up to `NumStripes × QueueSize` buffered ops
- `collectCyclesBacon`: Traces graph starting from `roots.len` roots

**Simplified cost model**:
```
C_merge ≈ NumStripes × (avg_queue_fill / QueueSize) × T_atomic_op × QueueSize
        ≈ 64 × 0.5 × 7ns × 128 ≈ 29μs  (assuming 50% queue fill)

C_bacon ≈ roots.len × avg_edges_per_root × T_trace_op
        ≈ 10 × 3 × 20ns ≈ 0.6μs  (assuming small cycles, 3 edges avg)

C_collection ≈ 30μs per collection
```

**Realistic scenario** (from benchmark: 20s runtime, 1M RC ops):
```
Assume:
  - 10% of decRefs create roots: N_root_decRefs = 100,000
  - Collections = 100,000 / 10 = 10,000
  - C_collection = 30μs

Total collection time = 10,000 × 30μs = 300ms
Collection overhead = 300ms / 20s = 1.5%
```

**More conservative estimate** (larger cycles, more work):
```
C_collection ≈ 100μs per collection (larger cycles, more edges)
Total collection time = 10,000 × 100μs = 1s
Collection overhead = 1s / 20s = 5%
```

### 7. Final Estimate

**For realistic program** (20s runtime, 1M RC ops, 0.04% RC time):

**Acyclic objects** (immediate atomic):
```
Overhead = 0.36 × 0.04% = 0.014% ≈ 0.01%
```

**Cyclic objects** (buffered + collection):
```
Buffering overhead = (2.6 - 1) × 0.04% = 0.064% ≈ 0.06%

Collection overhead = 1.5% - 5% (depending on cycle complexity)

Total cyclic overhead ≈ 1.56% - 5.06%
```

**Key insight**:
- The buffering overhead is negligible (~0.06%)
- The collection overhead dominates (~3%)
- But collection only happens for cyclic data structures
- For acyclic data (most common case), overhead is ~0.01%

### 8. Multi-Threaded Impact

Under contention (8 threads):
- Buffering overhead drops from 0.064% to ~0.03% (f_buffering = 1.46)
- Collection overhead remains similar (global lock serializes it)
- **Total cyclic overhead ≈ 3.03%** (slightly better)

### 9. Summary Formula

```
Total_Overhead = Overhead_acyclic × P_acyclic + Overhead_cyclic × P_cyclic

where:
  Overhead_acyclic = 0.01% (atomic RC overhead)
  Overhead_cyclic = 1.56% - 5.06% (buffering + collection)
  P_acyclic = percentage of acyclic objects (typically 90-95%)
  P_cyclic = percentage of cyclic objects (typically 5-10%)
```

**For typical program** (95% acyclic, 5% cyclic):
```
Total_Overhead_min = 0.01% × 0.95 + 1.56% × 0.05
                   = 0.0095% + 0.078%
                   ≈ 0.09%

Total_Overhead_max = 0.01% × 0.95 + 5.06% × 0.05
                   = 0.0095% + 0.253%
                   ≈ 0.26%
```

**For program with more cycles** (90% acyclic, 10% cyclic):
```
Total_Overhead_min = 0.01% × 0.90 + 1.56% × 0.10
                   = 0.009% + 0.156%
                   ≈ 0.17%

Total_Overhead_max = 0.01% × 0.90 + 5.06% × 0.10
                   = 0.009% + 0.506%
                   ≈ 0.52%
```

### 10. Key Insights

1. **Acyclic overhead is negligible**: ~0.01% even with atomic operations
2. **Buffering overhead is small**: ~0.06% of total runtime
3. **Collection overhead dominates**: 1.5% - 5% depending on cycle complexity
4. **Overall impact is small**: 0.1% - 0.5% for typical programs
5. **Multi-threading helps**: Buffering overhead drops under contention

**Conclusion**:
- For **acyclic data** (most common): overhead ≈ **0.01%**
- For **cyclic data**: overhead ≈ **1.5% - 5%** (mostly from collection)
- For **typical programs** (95% acyclic): total overhead ≈ **0.1% - 0.3%**

The cycle collector overhead is **small but measurable** (1-5% for cyclic data), while the atomic RC overhead for acyclic data is **negligible** (< 0.1%).

### 11. Multi-Threading Trade-Off Analysis

**Key Insight**: Even if cycle collector overhead is high (e.g., 50% in worst-case scenarios), it's still a **net win** because it enables multi-threading.

**Trade-off formula**:
```
Net_Speedup = (1 + Thread_Speedup) / (1 + Overhead) - 1

where:
  Thread_Speedup = performance gain from parallelization (e.g., 4x with 8 threads)
  Overhead = cycle collector overhead (e.g., 0.5 = 50%)
```

**Example scenarios**:

**Scenario 1: Typical overhead (0.3%)**
```
Net_Speedup = (1 + 4.0) / (1 + 0.003) - 1
            = 5.0 / 1.003 - 1
            = 4.985 - 1
            = 3.985x ≈ 4x speedup
```

**Scenario 2: High overhead (5%)**
```
Net_Speedup = (1 + 4.0) / (1 + 0.05) - 1
            = 5.0 / 1.05 - 1
            = 4.76 - 1
            = 3.76x speedup
```

**Scenario 3: Very high overhead (50%)**
```
Net_Speedup = (1 + 4.0) / (1 + 0.5) - 1
            = 5.0 / 1.5 - 1
            = 3.33 - 1
            = 2.33x speedup
```

**Break-even analysis**:
```
For overhead = 50%:
  Break-even when: (1 + Thread_Speedup) / 1.5 >= 1
  Thread_Speedup >= 0.5 (i.e., 1.5x speedup from threading)

For overhead = 5%:
  Break-even when: (1 + Thread_Speedup) / 1.05 >= 1
  Thread_Speedup >= 0.05 (i.e., 1.05x speedup from threading)
```

**Conclusion**:
- Even with **50% overhead**, you still get **2.3x net speedup** with 4x threading
- The overhead is a **one-time cost** paid upfront
- Multi-threading provides **multiplicative gains** that easily compensate
- The overhead is a **key enabler** - without thread-safe RC, multi-threading is impossible for `ref` types
- In practice, overhead is typically **0.1% - 5%**, making the trade-off even more favorable

**Real-world perspective**:
- **Without thread-safety**: Single-threaded only → 1x performance
- **With thread-safety + 50% overhead**: Multi-threaded → 2.3x - 4x performance
- **Net benefit**: 2.3x - 4x improvement, even in worst-case overhead scenario

The cycle collector overhead is not just acceptable—it's **essential infrastructure** that unlocks parallel performance.
