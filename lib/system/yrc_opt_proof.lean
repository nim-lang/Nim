/-
  YRC Optimization Proofs — SCC-uniform ages, demand-grown slots, deferred
  reclamation
  =======================================================================
  Self-contained, no Mathlib. Checked with Lean 4 (v4.32.0).

  Companion to yrc_proof.lean (core safety: garbage stability, validation
  soundness, partitions, grace, fence, deadlock freedom) and to
  yrc_tarjan_proof.lean (soundness AND completeness of the SCC deadness
  scan). This file models the three changes of the "YRC: optimizations"
  round, each of which touches an invariant the other two files rely on:

  §A  SCC-UNIFORM EPOCH AGES (commitDead's re-stamp loop).
      Before: every proven-live cell was stamped with its OWN survival
      age + 1. One member of an SCC could then reach `YrcPromoteAge`
      ahead of its SCC-mates; the next capture pruned that INTERNAL edge,
      tainting the SCC `flagPruned`, which stops it from ever being
      re-stamped — freezing every member's age and re-tracing the whole
      structure on every collection from then on. Members age at
      different rates whenever a structure is built incrementally, so
      this was the common case.
      After: the whole SCC is stamped with the age of its YOUNGEST
      member + 1, so promotion is all-or-nothing.

  §B  DEMAND-GROWN COLLECTOR SLOTS (`gParSlots`, startCollection).
      Before: `MaxPar` was a fixed 8 and the 9th collecting thread PARKED
      in `parkUntil(anySlotFree())` instead of collecting. After:
      `gParSlots` counts the slots in play, starts at 1, and is raised
      under gMergeLock exactly when a thread wants to collect and every
      slot in play is busy; `MaxPar` (256) is only the table capacity.
      Every scan (`isActiveTag`, `anySlotFree`, `buildPendingWatch`) now
      runs over a prefix that GROWS under the reader, which is sound only
      because of the ordering rule at `slotsInPlay`.

  §C  DEFERRED RECLAMATION (`gPendingCells` / `releasePending`).
      Before: commitDead BLOCKED until every concurrent capture ended
      (the grace period), inside the GC fence — stalling both the
      committing collector and every mutator doing a seq operation.
      After: the dead batch is parked together with a watch list of the
      captures it must outlive, and released at the start of this
      thread's next collection. The parked collection's TAG STAYS in
      `gActiveTags` (only the phase is cleared): that is what stops a
      foreign capture from claiming — and then freeing — a parked cell.

  Nothing here weakens yrc_proof.lean: §A only changes which cells a
  capture skips (pruning shrinks the captured set, the conservative
  direction), §B only changes how many slots a scan covers, and §C only
  moves the free of an already-validated, already-closed dead set later
  in time, where garbage stability (yrc_proof.lean §3) keeps it dead.
-/

abbrev Obj := Nat
abbrev Tag := Nat
-- Slot indices and times are plain `Nat`: `omega` ignores atoms whose type
-- is an abbreviation, and both appear in arithmetic below.

/-! ## §A SCC-uniform epoch ages

  The spare header word (`rootIdx`) is a three-way namespace: 0 for a
  cell no collection ever touched, a claim tag while a collection owns
  the cell, or an epoch stamp (`epochBase | epoch` in the high word, the
  survival age in the low word). Tags are allocated strictly below
  `epochBase`, so a stamp is never mistaken for a tag — modelled here by
  keeping the three cases as separate constructors. -/

inductive Word where
  | fresh                        -- 0: never claimed, never stamped
  | tag (t : Tag)                -- a collection's claim word
  | stamp (e : Nat) (age : Nat)  -- an epoch stamp written by commitDead

/-- The age a capture reads out of a claim word (`cap.ages`): a stamp
    contributes its recorded age, anything else contributes 0. -/
def ageOf : Word → Nat
  | .stamp _ a => a
  | _ => 0

def capturedAge (w : Obj → Word) (x : Obj) : Nat := ageOf (w x)

/-- `claimCell(pruneLive = true)` prunes at a target whose stamp is of the
    CURRENT epoch and whose age reached `YrcPromoteAge`: the target is
    treated as an opaque live external and is not descended into. Roots
    are always claimed with `pruneLive = false`, so this never applies to
    them. -/
def prunable (curEpoch promoteAge : Nat) : Word → Prop
  | .stamp e a => e = curEpoch ∧ promoteAge ≤ a
  | _ => False

/-- `high(int32)`, the seed of commitDead's per-SCC minimum. -/
def bigAge : Nat := 2147483647

/-- Minimum of a list with a default (the `var age = high(int32)` fold). -/
def listMin : List Nat → Nat → Nat
  | [], d => d
  | a :: l, d => Nat.min a (listMin l d)

theorem listMin_le : ∀ (l : List Nat) (d a : Nat), a ∈ l → listMin l d ≤ a := by
  intro l
  induction l with
  | nil => intro d a ha; cases ha
  | cons b t ih =>
    intro d a ha
    cases List.mem_cons.mp ha with
    | inl h =>
      simp only [listMin, Nat.min_def]
      split <;> omega
    | inr h =>
      have := ih d a h
      simp only [listMin, Nat.min_def]
      split <;> omega

theorem listMin_ge : ∀ (l : List Nat) (d b : Nat), b ≤ d →
    (∀ x, x ∈ l → b ≤ x) → b ≤ listMin l d := by
  intro l
  induction l with
  | nil => intro d b hd _; simpa [listMin] using hd
  | cons a t ih =>
    intro d b hd hall
    have h1 : b ≤ a := hall a (by simp)
    have h2 := ih d b hd (fun x hx => hall x (List.mem_cons_of_mem a hx))
    simp only [listMin, Nat.min_def]
    split <;> omega

theorem listMin_const (l : List Nat) (d a : Nat) (hne : l ≠ [])
    (hall : ∀ x, x ∈ l → x = a) (had : a ≤ d) : listMin l d = a := by
  have hlo : a ≤ listMin l d :=
    listMin_ge l d a had (fun x hx => by have := hall x hx; omega)
  cases l with
  | nil => exact absurd rfl hne
  | cons b t =>
    have hb : b ∈ b :: t := by simp
    have hhi := listMin_le (b :: t) d b hb
    have := hall b hb
    omega

/-- **The change.** commitDead stamps a proven-live SCC with ONE word: the
    current epoch and 1 + the age of its YOUNGEST member. -/
def sccAge (w : Obj → Word) (ms : List Obj) : Nat :=
  listMin (ms.map (fun m => capturedAge w m)) bigAge + 1

/-- The post-state of commitDead's re-stamp loop, as committed: every
    member of the SCC gets the same word, nothing else is touched. -/
structure StampedUniform (w w' : Obj → Word) (e : Nat) (ms : List Obj) : Prop where
  members : ∀ m, m ∈ ms → w' m = .stamp e (sccAge w ms)
  others : ∀ x, x ∉ ms → w' x = w x

/-- The previous, per-cell scheme, for contrast. -/
structure StampedPerCell (w w' : Obj → Word) (e : Nat) (ms : List Obj) : Prop where
  members : ∀ m, m ∈ ms → w' m = .stamp e (capturedAge w m + 1)
  others : ∀ x, x ∉ ms → w' x = w x

/-- **A1 Uniformity**: after commit, all members of a stamped SCC carry
    the identical claim word — same epoch AND same age. -/
theorem stamped_uniform (w w' : Obj → Word) (e : Nat) (ms : List Obj)
    (h : StampedUniform w w' e ms) :
    ∀ x y, x ∈ ms → y ∈ ms → w' x = w' y := by
  intro x y hx hy
  rw [h.members x hx, h.members y hy]

/-- **A2 No internal prune**: a capture descends into a member `u` of an
    SCC only through an edge that was NOT pruned (or because `u` is a
    root, which bypasses stamps entirely). With uniform words, every
    other member `v` is then unprunable too — so no INTERNAL edge of the
    SCC can be pruned, and the SCC is never tainted `flagPruned` by its
    own topology. This is precisely the failure the per-cell age caused. -/
theorem uniform_no_internal_prune
    (w : Obj → Word) (curEpoch promoteAge : Nat) (ms : List Obj)
    (huni : ∀ x y, x ∈ ms → y ∈ ms → w x = w y)
    (u v : Obj) (hu : u ∈ ms) (hv : v ∈ ms)
    (hdescended : ¬ prunable curEpoch promoteAge (w u)) :
    ¬ prunable curEpoch promoteAge (w v) := by
  rw [← huni u v hu hv]
  exact hdescended

/-- A2 applied to the state commitDead actually leaves behind. -/
theorem committed_scc_no_internal_prune
    (w w' : Obj → Word) (e curEpoch promoteAge : Nat) (ms : List Obj)
    (hst : StampedUniform w w' e ms)
    (u v : Obj) (hu : u ∈ ms) (hv : v ∈ ms)
    (hdescended : ¬ prunable curEpoch promoteAge (w' u)) :
    ¬ prunable curEpoch promoteAge (w' v) :=
  uniform_no_internal_prune w' curEpoch promoteAge ms
    (stamped_uniform w w' e ms hst) u v hu hv hdescended

/-- **A3 The per-cell scheme diverges**: two members of ONE SCC whose
    captured ages differ (the normal case for a structure built
    incrementally across collections) end up with different ages. -/
theorem perCell_ages_diverge (w w'' : Obj → Word) (e : Nat) (ms : List Obj)
    (hp : StampedPerCell w w'' e ms) (u v : Obj) (hu : u ∈ ms) (hv : v ∈ ms)
    (hdiff : capturedAge w u ≠ capturedAge w v) :
    ageOf (w'' u) ≠ ageOf (w'' v) := by
  rw [hp.members u hu, hp.members v hv]
  simp only [ageOf]
  omega

/-- ...and diverged ages inside one SCC mean exactly one prunable end of
    an internal edge: the promoted member is pruned while its unpromoted
    SCC-mate is still being traced. -/
theorem diverged_ages_prune_internally (curEpoch promoteAge au av : Nat)
    (hu : au < promoteAge) (hv : promoteAge ≤ av) :
    ¬ prunable curEpoch promoteAge (.stamp curEpoch au) ∧
      prunable curEpoch promoteAge (.stamp curEpoch av) := by
  constructor
  · intro h
    obtain ⟨-, h2⟩ := h
    omega
  · exact ⟨rfl, hv⟩

/-- **A4 The minimum can only delay a promotion, never hasten one**, so
    taking it cannot widen the floating-garbage bound (~2 epochs). -/
theorem uniform_age_le_perCell (w w' w'' : Obj → Word) (e : Nat) (ms : List Obj)
    (hu : StampedUniform w w' e ms) (hp : StampedPerCell w w'' e ms)
    (m : Obj) (hm : m ∈ ms) :
    ageOf (w' m) ≤ ageOf (w'' m) := by
  have hmem : capturedAge w m ∈ ms.map (fun x => capturedAge w x) :=
    List.mem_map_of_mem hm
  have hle := listMin_le (ms.map (fun x => capturedAge w x)) bigAge
                (capturedAge w m) hmem
  rw [hu.members m hm, hp.members m hm]
  simp only [ageOf, sccAge]
  omega

/-- Corollary: wherever the SCC-uniform stamp prunes, the per-cell stamp
    would have pruned too. Pruning is the only thing a stamp does, so the
    change cannot make any capture skip MORE than before. -/
theorem uniform_never_hastens_promotion (w w' w'' : Obj → Word) (e : Nat)
    (ms : List Obj) (promoteAge : Nat)
    (hu : StampedUniform w w' e ms) (hp : StampedPerCell w w'' e ms)
    (m : Obj) (hm : m ∈ ms) (h : promoteAge ≤ ageOf (w' m)) :
    promoteAge ≤ ageOf (w'' m) := by
  have := uniform_age_le_perCell w w' w'' e ms hu hp m hm
  omega

/-- **A5 The uniform age is exactly the common age + 1**, so a surviving
    SCC's age advances by one per collection and stays uniform: the
    invariant of A1/A2 is inductive. -/
theorem uniform_age_succ (w w' : Obj → Word) (e a : Nat) (ms : List Obj)
    (hne : ms ≠ []) (hcap : a ≤ bigAge)
    (hall : ∀ m, m ∈ ms → capturedAge w m = a)
    (h : StampedUniform w w' e ms) :
    ∀ m, m ∈ ms → ageOf (w' m) = a + 1 := by
  intro m hm
  have hmin : listMin (ms.map (fun x => capturedAge w x)) bigAge = a := by
    apply listMin_const
    · cases ms with
      | nil => exact absurd rfl hne
      | cons b t => simp
    · intro x hx
      obtain ⟨y, hy, rfl⟩ := List.mem_map.mp hx
      exact hall y hy
    · exact hcap
  rw [h.members m hm]
  simp only [ageOf, sccAge, hmin]

/-- **A6 The freeze**: an SCC that is never re-stamped (the `flagPruned`
    taint excludes it from commitDead's stamp loop) keeps its age
    forever. Below `YrcPromoteAge` that means it is fully re-traced by
    every collection until the epoch turns — the regression A2 removes. -/
theorem age_frozen_if_never_restamped (age : Nat → Nat) (a : Nat)
    (h0 : age 0 = a) (hfreeze : ∀ n, age (n + 1) = age n) :
    ∀ n, age n = a := by
  intro n
  induction n with
  | zero => exact h0
  | succ n ih => rw [hfreeze n, ih]

/-- **A7 Progress**: an SCC that IS re-stamped every round promotes after
    `YrcPromoteAge` collections, and by A2 stays promoted uniformly — so
    a long-lived structure is traced once per epoch, not once per
    collection. -/
theorem age_promotes_if_restamped (age : Nat → Nat) (a promoteAge : Nat)
    (h0 : age 0 = a) (hstep : ∀ n, age (n + 1) = age n + 1) :
    promoteAge ≤ age promoteAge := by
  have h : ∀ n, age n = a + n := by
    intro n
    induction n with
    | zero => simpa using h0
    | succ n ih => rw [hstep n, ih]; omega
  rw [h promoteAge]
  omega

/-! ## §B Demand-grown collector slots

  `gParSlots` counts the slots IN PLAY. It starts at 1, is raised under
  gMergeLock when a thread wants to collect and every slot in play is
  busy, and is NEVER lowered. Two things must hold:

  (i) a scan over the prefix `0 ..< slotsInPlay()` must never MISS an
      active tag — a missed tag would let a second collection claim a
      cell another collection already owns, breaking partition
      disjointness (yrc_proof.lean §5) and admitting a double free;
  (ii) a thread must not park while the table still has room — that was
      the throttle the fixed `MaxPar = 8` imposed.

  (i) rests on the publication order in startCollection: the wider bound
  is stored BEFORE the tag lands in the new slot, and `gParSlots` only
  grows. So a load of `slotsInPlay()` ordered AFTER the read of a tagged
  claim word is guaranteed to cover the slot that wrote that tag. -/

/-- `gParSlots` never shrinks, so a prefix scan cannot shrink under a
    reader either. -/
theorem in_play_persists (parSlots : Nat → Nat)
    (hmono : ∀ i j, i ≤ j → parSlots i ≤ parSlots j)
    (k : Nat) (t t' : Nat) (h : t ≤ t') (hk : k < parSlots t) :
    k < parSlots t' := by
  have := hmono t t' h
  omega

/-- **B1 The scan covers the slot that wrote the tag.** `tGrow` is when
    the slot was put in play (under gMergeLock), `tTag` the tag store,
    `tRead` the reader's load of the claim word, `tScan` its subsequent
    load of `slotsInPlay()`. -/
theorem scan_covers_tagged_slot (parSlots : Nat → Nat)
    (hmono : ∀ i j, i ≤ j → parSlots i ≤ parSlots j)
    (k : Nat) (tGrow tTag tRead tScan : Nat)
    (hgrow : k < parSlots tGrow)
    (hpub : tGrow ≤ tTag)     -- wider bound published before the tag store
    (hread : tTag ≤ tRead)    -- the reader observed the tag
    (hafter : tRead ≤ tScan) :-- slotsInPlay() loaded AFTER the claim word
    k < parSlots tScan := by
  have := hmono tGrow tScan (by omega)
  omega

/-- **B2 `isActiveTag` is complete**: an active tag is always found by the
    prefix scan, so `claimCell` never claims a cell another collection
    owns. -/
theorem active_tag_never_missed (parSlots : Nat → Nat)
    (tagAt : Nat → Nat → Tag)
    (hmono : ∀ i j, i ≤ j → parSlots i ≤ parSlots j)
    (k : Nat) (t : Tag) (tGrow tTag tRead tScan : Nat)
    (hgrow : k < parSlots tGrow) (hpub : tGrow ≤ tTag)
    (hread : tTag ≤ tRead) (hafter : tRead ≤ tScan)
    (hheld : tagAt k tScan = t) :
    ∃ j, j < parSlots tScan ∧ tagAt j tScan = t :=
  ⟨k, scan_covers_tagged_slot parSlots hmono k tGrow tTag tRead tScan
        hgrow hpub hread hafter, hheld⟩

/-- **B3 The ordering rule is load-bearing**: a `slotsInPlay()` load
    ordered BEFORE the read of the claim word can legitimately miss the
    slot, because the pool may widen in between. -/
theorem scan_before_read_may_miss :
    ∃ (parSlots : Nat → Nat) (k : Nat) (tScan tGrow : Nat),
      (∀ i j, i ≤ j → parSlots i ≤ parSlots j) ∧ tScan < tGrow ∧
        k < parSlots tGrow ∧ ¬ (k < parSlots tScan) := by
  refine ⟨fun t => t + 1, 1, 0, 1, ?_, ?_, ?_, ?_⟩
  · intro i j h
    show i + 1 ≤ j + 1
    omega
  · decide
  · decide
  · decide

/-- startCollection's slot decision. -/
inductive SlotOutcome where
  | reuse (k : Nat)   -- a slot already in play was free
  | grow (k : Nat)    -- pool widened; the new slot is `k = inPlay`
  | park               -- table full: MaxPar collections already running

inductive SlotClaim (busy : Nat → Prop) (inPlay maxPar : Nat) : SlotOutcome → Prop where
  | reuse (k : Nat) (hk : k < inPlay) (hfree : ¬ busy k) :
      SlotClaim busy inPlay maxPar (.reuse k)
  | grow (hfull : ∀ k, k < inPlay → busy k) (hroom : inPlay < maxPar) :
      SlotClaim busy inPlay maxPar (.grow inPlay)
  | park (hfull : ∀ k, k < inPlay → busy k) (hno : maxPar ≤ inPlay) :
      SlotClaim busy inPlay maxPar .park

/-- **B4 Parking means saturation**, not throttling: a thread blocks in
    `parkUntil(anySlotFree())` only when `MaxPar` collections are running
    concurrently. Under the old fixed bound this triggered at the 9th
    collecting thread (32 threads vs 8 slots: 6.3s against 2.6s). -/
theorem park_only_when_saturated (busy : Nat → Prop) (inPlay maxPar : Nat)
    (h : SlotClaim busy inPlay maxPar .park) :
    maxPar ≤ inPlay ∧ ∀ k, k < inPlay → busy k := by
  cases h with
  | park hfull hno => exact ⟨hno, hfull⟩

/-- **B5 No parking below capacity.** -/
theorem no_park_below_capacity (busy : Nat → Prop) (inPlay maxPar : Nat)
    (hroom : inPlay < maxPar) : ¬ SlotClaim busy inPlay maxPar .park := by
  intro h
  cases h with
  | park hfull hno => omega

/-- **B6 A grown slot is fresh**: `k = inPlay` is distinct from every slot
    already in play, so the widening thread cannot collide with a
    collection that is already running. -/
theorem grown_slot_not_in_play (inPlay k : Nat) (hk : k < inPlay) :
    inPlay ≠ k := by omega

/-! ## §C Deferred reclamation

  commitDead used to spin until every concurrent capture had ended before
  freeing, INSIDE the GC fence. Now the batch is parked in
  `gPendingCells` with a watch list `gPendingWatch` of the (slot, tag)
  pairs that were in capture phase at commit time, and `releasePending`
  — the FIRST thing startCollection does, outside the fence and holding
  no lock — waits out that list and then frees.

  Three obligations:
  (C1) the watch list is COMPLETE: every capture that could hold a stale
       `(slot, value)` snapshot of the batch is on it;
  (C2) the grace check is SOUND: `graceSatisfied` reports "finished" only
       when the watched capture really has finished;
  (C3) the batch is PROTECTED while parked: no foreign capture may claim
       (and hence free) one of its cells. This is why finishCollection
       clears only `gSlotPhase` and leaves the tag in `gActiveTags`. -/

/-- One slot's published state. -/
structure SlotState where
  tag : Tag
  phase : Nat   -- 0 idle, 1 capturing, 2 committing

/-- finishCollection with a batch parked: phase → 0, tag RETAINED. -/
def finishParked (st : SlotState) : SlotState := { st with phase := 0 }

/-- releasePending, after the grace wait: the tag is given up first, then
    the destructors and `nimRawDispose` run. -/
def releaseSlot (st : SlotState) : SlotState := { st with tag := 0 }

theorem finishParked_keeps_tag (st : SlotState) :
    (finishParked st).tag = st.tag := rfl

/-- A parked slot blocks nobody's grace period: its phase is 0, so every
    other collector's `graceSatisfied` passes over it. -/
theorem parked_slot_blocks_nobody (st : SlotState) (tg : Tag) :
    ¬ ((finishParked st).tag = tg ∧ (finishParked st).phase = 1) := by
  intro h
  simp [finishParked] at h

/-- ...yet the tag survives, which is what protects the parked cells. -/
theorem parked_slot_still_tagged (st : SlotState) (t : Tag) (h : st.tag = t) :
    (finishParked st).tag = t := h

/-- `gPendingWatch`, as `(slot shl 32) or tag` pairs. -/
abbrev WatchList := List (Nat × Tag)

/-- `graceSatisfied()` evaluated at time `t`. -/
def graceSatisfied (tagAt : Nat → Nat → Tag) (phaseAt : Nat → Nat → Nat)
    (W : WatchList) (t : Nat) : Prop :=
  ∀ p, p ∈ W → ¬ (tagAt p.1 t = p.2 ∧ phaseAt p.1 t = 1)

/-- **C1 The watch list is complete.** A capture that was in flight at
    commit time is running on a slot that was in play when its tag was
    stored; by B1 the `buildPendingWatch` scan — which loads
    `slotsInPlay()` after reading the claim state — covers that slot, and
    the capture's phase is 1, so it is recorded. -/
theorem watch_covers_inflight_capture (parSlots : Nat → Nat)
    (tagAt : Nat → Nat → Tag) (phaseAt : Nat → Nat → Nat)
    (hmono : ∀ i j, i ≤ j → parSlots i ≤ parSlots j)
    (s : Nat) (tg : Tag) (tGrow tTag commitT : Nat)
    (hgrow : s < parSlots tGrow) (hpub : tGrow ≤ tTag) (hread : tTag ≤ commitT)
    (hcapturing : tagAt s commitT = tg ∧ phaseAt s commitT = 1) :
    s < parSlots commitT ∧ tagAt s commitT = tg ∧ phaseAt s commitT = 1 :=
  ⟨scan_covers_tagged_slot parSlots hmono s tGrow tTag commitT commitT
     hgrow hpub hread (Nat.le_refl commitT), hcapturing.1, hcapturing.2⟩

/-- **C2 The grace check is sound**: if `graceSatisfied` holds at `t` and
    a watched capture was still running at `t`, we have a contradiction —
    so every watched capture finished strictly before `t`. There is no
    ABA on the (slot, tag) pair: tags come from a monotonic counter
    (yrc_proof.lean §5 `tags_distinct`), so a later collection on the
    same slot carries a different tag. -/
theorem grace_check_sound (tagAt : Nat → Nat → Tag) (phaseAt : Nat → Nat → Nat)
    (W : WatchList) (s : Nat) (tg : Tag) (start finish t : Nat)
    (hw : (s, tg) ∈ W)
    (hcap : ∀ u, start ≤ u → u ≤ finish → tagAt s u = tg ∧ phaseAt s u = 1)
    (hstart : start ≤ t)
    (hsat : graceSatisfied tagAt phaseAt W t) :
    finish < t := by
  cases Nat.lt_or_ge finish t with
  | inl h => exact h
  | inr h => exact absurd (hcap t hstart h) (hsat (s, tg) hw)

/-- A capture's window and the values it ever snapshots (TraceEntry), as
    in yrc_proof.lean §6. -/
structure CaptureWindow where
  start : Nat
  finish : Nat
  snap : Obj → Prop
  derefs : Obj → Nat → Prop

/-- **C3 Grace safety survives the deferral.** `commitT` is when the dead
    set validated, `releaseT` when releasePending's wait succeeded (C2),
    `freeT` when the batch is actually disposed. The only change from
    yrc_proof.lean's `grace_no_use_after_free` is that `freeT` moved
    LATER — the wait is unchanged in strength, it just happens off the
    commit path. -/
theorem deferred_grace_no_use_after_free
    (C : CaptureWindow) (D : Obj → Prop) (commitT releaseT freeT : Nat)
    (h_deref : ∀ x t, C.derefs x t → C.start ≤ t ∧ t ≤ C.finish ∧ C.snap x)
    (h_watched : C.start < commitT → C.finish < releaseT)
    (h_release : releaseT ≤ freeT)
    (h_miss : commitT ≤ C.start → ∀ x, D x → ¬ C.snap x) :
    ∀ x t, D x → C.derefs x t → t < freeT := by
  intro x t hD hd
  obtain ⟨h1, h2, h3⟩ := h_deref x t hd
  cases Nat.lt_or_ge C.start commitT with
  | inl h => have := h_watched h; omega
  | inr h => exact absurd h3 (h_miss h x hD)

/-- claimCell's decision on a cell, as a relation over its claim word. -/
inductive ClaimResult where
  | mine     -- our own tag: already captured this round
  | refuse   -- owned by another ACTIVE collection (-1, crossPend)
  | prune    -- proven live this epoch (-2, opaque live external)
  | claim    -- CAS it into our partition

inductive ClaimDecision (myTag curEpoch promoteAge : Nat) (active : Tag → Prop) :
    Word → ClaimResult → Prop where
  | mine (t : Tag) (h : t = myTag) :
      ClaimDecision myTag curEpoch promoteAge active (.tag t) .mine
  | refuse (t : Tag) (hne : t ≠ myTag) (ha : active t) :
      ClaimDecision myTag curEpoch promoteAge active (.tag t) .refuse
  | claimTag (t : Tag) (hne : t ≠ myTag) (ha : ¬ active t) :
      ClaimDecision myTag curEpoch promoteAge active (.tag t) .claim
  | prune (e a : Nat) (hp : prunable curEpoch promoteAge (.stamp e a)) :
      ClaimDecision myTag curEpoch promoteAge active (.stamp e a) .prune
  | claimStamp (e a : Nat) (hp : ¬ prunable curEpoch promoteAge (.stamp e a)) :
      ClaimDecision myTag curEpoch promoteAge active (.stamp e a) .claim
  | claimFresh :
      ClaimDecision myTag curEpoch promoteAge active .fresh .claim

/-- **C4 A cell carrying an active foreign tag is always refused.** -/
theorem tagged_cell_refused (myTag curEpoch promoteAge : Nat) (active : Tag → Prop)
    (ownerTag : Tag) (hne : ownerTag ≠ myTag) (ha : active ownerTag)
    (r : ClaimResult)
    (h : ClaimDecision myTag curEpoch promoteAge active (.tag ownerTag) r) :
    r = .refuse := by
  cases h with
  | mine t ht => exact absurd ht hne
  | refuse t hne' ha' => rfl
  | claimTag t hne' ha' => exact absurd ha ha'

/-- **C5 No double free while parked.** The parked cells still carry the
    parking collection's tag, and finishCollection left that tag in
    `gActiveTags` (only the phase was cleared, C-`finishParked`). So a
    foreign capture that reaches a parked cell through a stale snapshot
    refuses it: it can neither traverse it nor claim it, hence never
    classifies it dead and never frees it. Without the tag retention this
    is exactly a double free — the batch's owner will free it too. -/
theorem no_foreign_claim_while_parked
    (activeAt : Nat → Tag → Prop) (ownerTag myTag : Tag)
    (curEpoch promoteAge : Nat) (commitT releaseT u : Nat)
    (hretain : ∀ v, commitT ≤ v → v ≤ releaseT → activeAt v ownerTag)
    (hne : ownerTag ≠ myTag) (h1 : commitT ≤ u) (h2 : u ≤ releaseT)
    (r : ClaimResult)
    (h : ClaimDecision myTag curEpoch promoteAge (activeAt u) (.tag ownerTag) r) :
    r = .refuse :=
  tagged_cell_refused myTag curEpoch promoteAge (activeAt u) ownerTag hne
    (hretain u h1 h2) r h

/-- **C6 Deferring the free is safe.** The batch was closed (unreachable)
    at commit time — that is what validation established (yrc_proof.lean
    §4 `validated_closed`) — and `hstable` is exactly
    yrc_proof.lean §3 `garbage_stability`: a closed set stays closed
    under every mutator step, allocation and foreign free. Freeing one
    collection later therefore satisfies the same §1 free condition as
    freeing immediately. -/
theorem deferred_free_safe (unreachable : Nat → Obj → Prop) (D : Obj → Prop)
    (commitT freeT : Nat)
    (hcommit : ∀ x, D x → unreachable commitT x)
    (hstable : ∀ x t t', D x → t ≤ t' → unreachable t x → unreachable t' x)
    (hlater : commitT ≤ freeT) :
    ∀ x, D x → unreachable freeT x :=
  fun x hx => hstable x commitT freeT hx hlater (hcommit x hx)

/-- **C7 The grace wait left the GC fence.** It now runs at the start of
    startCollection, before `yrcGcFenceEnter`, so no mutator seq
    operation can be stalled by it — the property the deferral was made
    for. -/
theorem grace_wait_outside_fence (waitStart waitEnd fenceEnter fenceExit t : Nat)
    (horder : waitEnd < fenceEnter) (hw : waitStart ≤ t ∧ t ≤ waitEnd) :
    ¬ (fenceEnter ≤ t ∧ t ≤ fenceExit) := by
  intro hf
  omega

/-- `waits a b`: thread `a` is blocked in releasePending on thread `b`'s
    capture. -/
def waits (capturing releasing : Nat → Prop) (a b : Nat) : Prop :=
  releasing a ∧ capturing b

/-- **C8 The new wait cannot deadlock.** releasePending runs BEFORE this
    thread claims a slot, so a releasing thread is never itself
    capturing; the wait-for graph therefore has depth one and cannot
    contain a cycle of any length. (Captures never wait on anything:
    claimCell returns -1 immediately on contention.) -/
theorem release_wait_depth_one (capturing releasing : Nat → Prop)
    (hexcl : ∀ t, releasing t → ¬ capturing t)
    (a b c : Nat) (h1 : waits capturing releasing a b) :
    ¬ waits capturing releasing b c := by
  intro h2
  exact hexcl b h2.1 h1.2

/-- Corollary: no 2-cycle, hence no mutual wait between two parked
    collectors. -/
theorem release_wait_acyclic (capturing releasing : Nat → Prop)
    (hexcl : ∀ t, releasing t → ¬ capturing t) (a b : Nat)
    (h1 : waits capturing releasing a b) :
    ¬ waits capturing releasing b a :=
  release_wait_depth_one capturing releasing hexcl a b a h1

/-! ## Summary of verified properties (all QED, no sorry)

  §A  `stamped_uniform` — a committed SCC's members carry one identical
      claim word.
      `uniform_no_internal_prune`, `committed_scc_no_internal_prune` — a
      capture that descends into a member cannot prune an internal edge,
      so an SCC is never tainted `flagPruned` by its own topology.
      `perCell_ages_diverge` + `diverged_ages_prune_internally` — the
      pre-fix scheme admits exactly that taint.
      `uniform_age_le_perCell`, `uniform_never_hastens_promotion` — the
      minimum only delays promotions, so the float bound is unchanged.
      `uniform_age_succ` — uniformity is inductive: age advances by one
      and stays uniform.
      `age_frozen_if_never_restamped` / `age_promotes_if_restamped` — the
      frozen-age regression versus the intended once-per-epoch trace.

  §B  `in_play_persists`, `scan_covers_tagged_slot`,
      `active_tag_never_missed` — a growing `gParSlots` prefix scan never
      misses an active tag, PROVIDED `slotsInPlay()` is loaded after the
      claim word; `scan_before_read_may_miss` shows the order is
      load-bearing.
      `park_only_when_saturated`, `no_park_below_capacity`,
      `grown_slot_not_in_play` — a collector parks only when `MaxPar`
      collections run at once, and a widened slot collides with nobody.

  §C  `watch_covers_inflight_capture` — the watch list records every
      capture that could hold a stale snapshot of the batch (via §B).
      `grace_check_sound` — `graceSatisfied` reports "finished" only when
      the watched capture has finished.
      `deferred_grace_no_use_after_free` — no capture dereferences a
      parked cell at or after its free time.
      `tagged_cell_refused`, `no_foreign_claim_while_parked` — retaining
      the tag (finishCollection clears only the phase) is what prevents a
      foreign collection from claiming and freeing a parked cell.
      `parked_slot_blocks_nobody`, `parked_slot_still_tagged` — the two
      halves of that split: protection without blocking.
      `deferred_free_safe` — deferring the free preserves the §1 free
      condition, by garbage stability.
      `grace_wait_outside_fence` — the wait no longer overlaps the GC
      fence, so it cannot stall a mutator's seq operation.
      `release_wait_depth_one`, `release_wait_acyclic` — the new wait
      adds no cycle to the wait-for structure of yrc_proof.lean §8.

  ## What is NOT proved

  • Slot-retention liveness. A parked batch holds its tag slot until the
    owning thread's NEXT collection (or GC_runOrc / nimYrcThreadTeardown,
    both of which call releasePending). A thread that parks a batch and
    then never collects again keeps a slot occupied; with enough such
    threads the table could saturate and other collectors would park
    (§B4). Bounded in practice by `MaxPar = 256` and by teardown, not
    formalized.
  • That `buildPendingWatch` returning false (nothing capturing) really
    is the common case — a performance claim, measured, not proved.
  • Destructor timing. Deferral runs a dead batch's destructors one
    collection later. Safety is C6; the observable-behaviour claim
    ("nothing else observes the delay, the cells are unreachable and
    their references already dropped") is an argument about the Nim
    language semantics, not modelled here.
  • Conservatism of tag retention. While a batch is parked, the tag also
    protects SURVIVORS that kept a stale tag (dirty and pruned SCCs are
    deliberately not re-stamped), so a foreign capture refuses them for
    one extra collection. That delays their re-examination; it cannot
    lose them, because §A's E1–E4 hooks keep a dec-witness registered.
  • Everything already listed as unproved in yrc_proof.lean (rc-exactness
    mechanics, the C11 memory model, liveness/completeness of the retry
    loop, tag wrap-around).
-/
