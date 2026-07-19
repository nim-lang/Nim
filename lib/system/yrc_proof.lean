/-
  YRC Safety Proof — lock-free SATB collector with parallel collections
  =====================================================================
  Self-contained, no Mathlib. Checked with Lean 4 (v4.32.0).

  Formal model of the safety arguments behind lib/system/yrc.nim in its
  current form: lock-free write barrier, optimistic capture / validate /
  commit, and up to `MaxPar` concurrent collections over disjoint
  CAS-claimed partitions.

  ## What the implementation does (the things we model)

  Write barrier `nimAsgnYrc(dest, src)`:
    1. direct ATOMIC incRef of src        (rc word mutation, visible to all)
    2. atomicExchange dest ← src          (graph is immediately current;
                                           old value read atomically)
    3. buffer dec(old) in a striped queue (deferred — this queue IS the
                                           snapshot-at-the-beginning log)

  A collection (any mutator thread can become a collector):
    1. merge queues into rc words, steal candidate roots  (under gMergeLock)
    2. CAPTURE: Tarjan SCC traversal; each visited cell is claimed by
       CAS-ing a collection tag into its spare header word (claimCell);
       cells claimed by another ACTIVE collection are not traversed
       (claimCell → -1, deferred via crossPend)
    3. compute deadness per SCC: ext(S) = sumRefs − internal − deadIn
    4. VALIDATE at commit: an SCC is freed only if no queue entry mentions
       a member (dirty check) and every member's rc word is unchanged
       since capture (recheck) — validateDead
    5. COMMIT: nil all slots of dead cells, trialDec edges to survivors,
       wait out concurrent captures (grace period), then free — commitDead

  ## Proof structure

  §1  Heap model, reachability, the core safety theorem.
  §2  Write barrier: no lost objects.
  §3  Mutator operational semantics and GARBAGE STABILITY: a closed
      (externally unreferenced) set stays closed under every mutator step,
      allocation, and foreign frees. This is why optimistic
      capture/validate/commit is sound and why aborts cost nothing.
  §4  Commit validation arithmetic: validated ext(D) = 0 implies D is
      closed; corollary CROSS-TARGET LIVENESS — a cell referenced from
      outside a collection's partition is never freed by that collection.
  §5  Tag uniqueness and partition disjointness for parallel collections.
  §6  Grace period: no capture ever dereferences a freed cell.
  §7  The asymmetric seq/GC fence (seqs_v2.nim): Dekker-style mutual
      exclusion between seq structure mutations and collections.
  §8  Deadlock freedom for the remaining locks (gMergeLock + stripes) and
      the spin-wait ordering argument.
-/

-- Objects and threads are just natural numbers for simplicity.
abbrev Obj := Nat
abbrev Thread := Nat

/-! ## §1 Heap model and reachability -/

/-- The state of the heap at a point in time. -/
structure State where
  /-- Physical heap edges: `edges x y` means object `x` has a ref field
      pointing to `y`. Always up-to-date (atomic stores/exchanges). -/
  edges : Obj → Obj → Prop
  /-- Stack roots per thread: local variables and the shared candidate
      roots buffer (both are "external" to any captured subgraph). -/
  roots : Thread → Obj → Prop
  /-- Live allocations. The allocator hands out only unallocated objects;
      captured cells stay allocated until their collection frees them. -/
  allocated : Obj → Prop

/-- An object is *reachable* if some thread can reach it via stack roots
    plus heap edges. -/
inductive Reachable (s : State) : Obj → Prop where
  | root (t : Thread) (x : Obj) : s.roots t x → Reachable s x
  | step (x y : Obj) : Reachable s x → s.edges x y → Reachable s y

/-- Directed reachability following physical heap edges only. -/
inductive HeapReachable (s : State) : Obj → Obj → Prop where
  | refl (x : Obj) : HeapReachable s x x
  | step (x y z : Obj) : HeapReachable s x y → s.edges y z → HeapReachable s x z

theorem heapReachable_of_reachable (s : State) (r x : Obj)
    (hr : Reachable s r) (hp : HeapReachable s r x) :
    Reachable s x := by
  induction hp with
  | refl => exact hr
  | step _ _ _ hedge ih => exact Reachable.step _ _ ih hedge

/-- An object has an *external reference* if some thread points to it. -/
def hasExternalRef (s : State) (x : Obj) : Prop :=
  ∃ t, s.roots t x

/-- Externally anchored: heap-reachable from an externally referenced
    object. This is what deadness computation + survivor rescue computes. -/
def anchored (s : State) (x : Obj) : Prop :=
  ∃ r, hasExternalRef s r ∧ HeapReachable s r x

/-- The collector frees `x` only if `x` is not anchored. -/
def collectorFrees (s : State) (x : Obj) : Prop :=
  ¬ anchored s x

/-- Every reachable object is anchored. -/
theorem reachable_is_anchored (s : State) (x : Obj)
    (h : Reachable s x) : anchored s x := by
  induction h with
  | root t x hroot =>
    exact ⟨x, ⟨t, hroot⟩, HeapReachable.refl x⟩
  | step a b _ h_edge ih =>
    obtain ⟨r, h_ext_r, h_path_r_a⟩ := ih
    exact ⟨r, h_ext_r, HeapReachable.step r a b h_path_r_a h_edge⟩

/-- **Core Safety Theorem**: freed objects are unreachable. -/
theorem yrc_safety (s : State) (x : Obj)
    (h_freed : collectorFrees s x) : ¬ Reachable s x := by
  intro h_reach
  exact h_freed (reachable_is_anchored s x h_reach)

/-! ## §2 The write barrier

  `nimAsgnYrc` performs the atomic inc of `src` BEFORE the exchange, so
  there is no instant at which the edge `a → src` exists without src's rc
  accounting for it; and the exchange reads `old` atomically, so two
  racing barriers on the same slot can never both dec the same old value.
  The dec of `old` is deferred: until the next merge, old's rc is merely
  inflated — always conservative. -/

/-- Model of `nimAsgnYrc(field a, src)`: `a`'s field pointed to `old`,
    now points to `src`. The graph update is immediate (atomicExchange). -/
def writeBarrier (s : State) (a old src : Obj) : State :=
  { s with
    edges := fun x y =>
      if x = a ∧ y = src then True
      else if x = a ∧ y = old then False
      else s.edges x y }

/-- Overwriting a slot with nil: only removes an edge. -/
def storeNil (s : State) (a old : Obj) : State :=
  { s with
    edges := fun x y =>
      if x = a ∧ y = old then False else s.edges x y }

/-- **No Lost Object**: if thread `t` holds `a` and stores `a.f = b`,
    then `b` is reachable afterwards — the exchange publishes the edge
    atomically, so a concurrent collection's survivor rescue traces it. -/
theorem no_lost_object (s : State) (t : Thread) (a old b : Obj)
    (h_root_a : s.roots t a) :
    Reachable (writeBarrier s a old b) b := by
  apply Reachable.step a b
  · exact Reachable.root t a h_root_a
  · simp [writeBarrier]

/-! ## §3 Mutator semantics and garbage stability

  The heart of optimistic capture/validate/commit is the *garbage
  stability theorem*: a set with no external references cannot acquire
  one later, because mutators can only copy references they can reach.
  Hence a dead set that VALIDATES at commit time stays dead through the
  grace window and until the actual `free` calls — no re-validation is
  needed, and an aborted (dirty) capture merely wasted its own work.

  Every constructor's precondition encodes the fundamental capability
  restriction: to use a reference you must hold it. `P` is the set of
  cells protected from foreign frees (in yrc: cells stamped with an
  active tag are never freed by another collection — §5). -/

def addRoot (s : State) (t : Thread) (x : Obj) : State :=
  { s with roots := fun t' y => (t' = t ∧ y = x) ∨ s.roots t' y }

def delRoot (s : State) (t : Thread) (x : Obj) : State :=
  { s with roots := fun t' y => if t' = t ∧ y = x then False else s.roots t' y }

def allocObj (s : State) (t : Thread) (x : Obj) : State :=
  { s with
    roots := fun t' y => (t' = t ∧ y = x) ∨ s.roots t' y
    allocated := fun y => y = x ∨ s.allocated y }

def freeObj (s : State) (x : Obj) : State :=
  { s with
    edges := fun u v => if u = x ∨ v = x then False else s.edges u v
    allocated := fun y => if y = x then False else s.allocated y }

/-- One step of the concurrent system, as seen by a fixed observer
    protecting the cell set `P`. -/
inductive MutStep (P : Obj → Prop) (s : State) : State → Prop where
  /-- `a.f = src`: the mutator must hold refs to `a` and `src`. -/
  | write (a old src : Obj)
      (ha : Reachable s a) (hsrc : Reachable s src) :
      MutStep P s (writeBarrier s a old src)
  /-- `a.f = nil`. -/
  | writeNil (a old : Obj) (ha : Reachable s a) :
      MutStep P s (storeNil s a old)
  /-- Copy a reachable ref into a local / the roots buffer. -/
  | rootCopy (t : Thread) (x : Obj) (hx : Reachable s x) :
      MutStep P s (addRoot s t x)
  /-- Drop a local ref (scope exit, roots-buffer unregistration). -/
  | rootDrop (t : Thread) (x : Obj) :
      MutStep P s (delRoot s t x)
  /-- Allocate: the allocator returns only unallocated addresses. -/
  | alloc (t : Thread) (x : Obj) (hfresh : ¬ s.allocated x) :
      MutStep P s (allocObj s t x)
  /-- A DIFFERENT collection frees one of its own dead cells: it is
      unreachable (its own §1 safety) and not protected (§5 partition
      disjointness: it carries the other collection's tag, not ours). -/
  | foreignFree (x : Obj) (hunreach : ¬ Reachable s x) (hprot : ¬ P x) :
      MutStep P s (freeObj s x)

/-- Reflexive-transitive closure: an arbitrary interleaving of steps by
    all mutators and all other collections. -/
inductive MutSteps (P : Obj → Prop) (s : State) : State → Prop where
  | refl : MutSteps P s s
  | tail {s' s'' : State} :
      MutSteps P s s' → MutStep P s' s'' → MutSteps P s s''

/-- `S` is *closed*: no thread points into it and no heap edge enters it
    from outside. This is exactly "validated dead set" (§4). -/
def closed (s : State) (S : Obj → Prop) : Prop :=
  (∀ t x, S x → ¬ s.roots t x) ∧
  (∀ u v, S v → s.edges u v → S u)

/-- Members of a closed set are unreachable. -/
theorem closed_unreachable (s : State) (S : Obj → Prop)
    (h : closed s S) : ∀ x, Reachable s x → ¬ S x := by
  intro x hr
  induction hr with
  | root t x hroot => exact fun hS => h.1 t x hS hroot
  | step a b _ hedge ih => exact fun hS => ih (h.2 a b hS hedge)

/-- The invariant carried through the grace window: `S` closed and all
    members still allocated (their memory has not been reused). -/
def DeadInv (s : State) (S : Obj → Prop) : Prop :=
  closed s S ∧ ∀ x, S x → s.allocated x

/-- **One-step stability**: no single action of any mutator, allocator or
    other collection can break the invariant of a closed set. -/
theorem step_preserves_deadInv (s s' : State) (S : Obj → Prop)
    (hinv : DeadInv s S) (hstep : MutStep S s s') : DeadInv s' S := by
  obtain ⟨hcl, halloc⟩ := hinv
  cases hstep with
  | write a old src ha hsrc =>
    refine ⟨⟨fun t x hS hroot => hcl.1 t x hS hroot, ?_⟩, fun x hS => halloc x hS⟩
    intro u v hSv hedge
    simp only [writeBarrier] at hedge
    by_cases h1 : u = a ∧ v = src
    · exact absurd (h1.2 ▸ hSv) (closed_unreachable s S hcl src hsrc)
    · by_cases h2 : u = a ∧ v = old
      · -- corner case old = src: the "remove old" branch is overridden
        -- by the "add src" branch, so the edge survives — but then
        -- v = old = src is reachable, hence not in S
        simp [h2] at hedge
        have hSsrc : S src := by rw [← hedge, ← h2.2]; exact hSv
        exact absurd hSsrc (closed_unreachable s S hcl src hsrc)
      · simp [h1, h2] at hedge
        exact hcl.2 u v hSv hedge
  | writeNil a old ha =>
    refine ⟨⟨fun t x hS hroot => hcl.1 t x hS hroot, ?_⟩, fun x hS => halloc x hS⟩
    intro u v hSv hedge
    simp only [storeNil] at hedge
    by_cases h2 : u = a ∧ v = old
    · simp [h2] at hedge
    · simp [h2] at hedge
      exact hcl.2 u v hSv hedge
  | rootCopy t x hx =>
    refine ⟨⟨?_, fun u v hSv hedge => hcl.2 u v hSv hedge⟩, fun y hS => halloc y hS⟩
    intro t' y hSy hroot
    simp only [addRoot] at hroot
    cases hroot with
    | inl h => exact absurd (h.2 ▸ hSy) (closed_unreachable s S hcl x hx)
    | inr h => exact hcl.1 t' y hSy h
  | rootDrop t x =>
    refine ⟨⟨?_, fun u v hSv hedge => hcl.2 u v hSv hedge⟩, fun y hS => halloc y hS⟩
    intro t' y hSy hroot
    simp only [delRoot] at hroot
    by_cases h : t' = t ∧ y = x
    · simp [h] at hroot
    · simp [h] at hroot
      exact hcl.1 t' y hSy hroot
  | alloc t x hfresh =>
    refine ⟨⟨?_, fun u v hSv hedge => hcl.2 u v hSv hedge⟩, ?_⟩
    · intro t' y hSy hroot
      simp only [allocObj] at hroot
      cases hroot with
      | inl h => exact hfresh (h.2 ▸ halloc y hSy)
      | inr h => exact hcl.1 t' y hSy h
    · intro y hS
      simp only [allocObj]
      exact Or.inr (halloc y hS)
  | foreignFree x hunreach hprot =>
    refine ⟨⟨fun t y hSy hroot => hcl.1 t y hSy hroot, ?_⟩, ?_⟩
    · intro u v hSv hedge
      simp only [freeObj] at hedge
      by_cases h : u = x ∨ v = x
      · simp [h] at hedge
      · simp [h] at hedge
        exact hcl.2 u v hSv hedge
    · intro y hSy
      simp only [freeObj]
      have hyx : ¬ y = x := fun he => hprot (he ▸ hSy)
      simp [hyx]
      exact halloc y hSy

/-- **Garbage Stability Theorem**: once a set is closed, it stays closed
    (and unreusable) under any interleaving of concurrent activity. -/
theorem deadInv_stable (s s' : State) (S : Obj → Prop)
    (hinv : DeadInv s S) (hsteps : MutSteps S s s') : DeadInv s' S := by
  induction hsteps with
  | refl => exact hinv
  | tail _ hstep ih => exact step_preserves_deadInv _ _ S ih hstep

/-- Snapshot garbage cannot be resurrected: members of a set that was
    closed at commit time are unreachable at every later point. -/
theorem garbage_stability (s s' : State) (S : Obj → Prop)
    (hinv : DeadInv s S) (hsteps : MutSteps S s s') :
    ∀ x, S x → ¬ Reachable s' x := by
  intro x hS hr
  exact closed_unreachable s' S (deadInv_stable s s' S hinv hsteps).1 x hr hS

/-- **Commit-then-free safety**: if the dead set validated (was closed)
    at commit time, then freeing its members after ANY amount of further
    concurrent activity (the grace window, other collections' frees,
    destructor-driven mutations) satisfies the §1 free condition. -/
theorem commit_free_safe (s s' : State) (S : Obj → Prop)
    (hinv : DeadInv s S) (hsteps : MutSteps S s s') :
    ∀ x, S x → collectorFrees s' x := by
  intro x hS hanch
  obtain ⟨r, ⟨t, hroot⟩, hpath⟩ := hanch
  have hr : Reachable s' x :=
    heapReachable_of_reachable s' r x (Reachable.root t r hroot) hpath
  exact closed_unreachable s' S (deadInv_stable s s' S hinv hsteps).1 x hr hS

/-! ## §4 Commit validation arithmetic

  `computeDeadness` marks an SCC dead when
      ext(S) = sumRefs(S) − internal(S) − deadIn(S) = 0,
  i.e. summed over the whole dead set D (union of dead SCCs):
      Σ_{c∈D} rc(c) = #(edges within D).
  `validateDead` then establishes that the captured rc words are the
  COMMIT-TIME rc values (rc recheck) and that no unmerged queue entry
  mentions a member (dirty check via markDirtyFromQueues — the deferred
  dec queues double as the SATB log; direct incs are atomic rc mutations
  caught by the recheck). Under yrc's invariant "rc counts every
  reference: heap slots, stack refs, and the roots-buffer flag" (the
  roots-buffer refs are excluded by clearing inRootsFlag on the slice
  BEFORE computeDeadness — collectCyclesImpl), we get: every member's rc
  splits into internal references (from D) and external ones, and the
  totals matching forces every external count to zero. -/

theorem sum_map_split (l : List Obj) (f g h : Obj → Nat)
    (hp : ∀ c, c ∈ l → f c = g c + h c) :
    (l.map f).sum = (l.map g).sum + (l.map h).sum := by
  induction l with
  | nil => simp
  | cons a l ih =>
    have ha : f a = g a + h a := hp a (by simp)
    have ih' := ih (fun c hc => hp c (List.mem_cons_of_mem a hc))
    simp only [List.map_cons, List.sum_cons]
    omega

theorem sum_zero_all (l : List Nat) (h : l.sum = 0) :
    ∀ x, x ∈ l → x = 0 := by
  induction l with
  | nil => intro x hx; cases hx
  | cons a l ih =>
    simp only [List.sum_cons] at h
    intro x hx
    cases List.mem_cons.mp hx with
    | inl he => subst he; omega
    | inr hm => exact ih (by omega) x hm

/-- **Validation soundness (arithmetic)**: if every member's commit-time
    rc splits as internal + external, and the collector's check
    Σ rc = Σ internal passed, then no member has any external ref. -/
theorem validated_no_external
    (members : List Obj) (rc inD extIn : Obj → Nat)
    (h_exact : ∀ c, c ∈ members → rc c = inD c + extIn c)
    (h_check : (members.map rc).sum = (members.map inD).sum) :
    ∀ c, c ∈ members → extIn c = 0 := by
  have hsplit := sum_map_split members rc inD extIn h_exact
  have hzero : (members.map extIn).sum = 0 := by omega
  intro c hc
  exact sum_zero_all _ hzero (extIn c) (List.mem_map_of_mem hc)

/-- **Validated implies closed**: bridging the counts to the graph. The
    two counting premises say what `extIn` MEANS: any stack/root ref and
    any heap edge from a non-member contributes at least one external
    count (this is the rc-exactness established by merge + validate). -/
theorem validated_closed (s : State) (D : Obj → Prop)
    (members : List Obj) (extIn : Obj → Nat)
    (hmem : ∀ x, D x → x ∈ members)
    (h_roots_counted : ∀ t c, D c → s.roots t c → 1 ≤ extIn c)
    (h_edges_counted : ∀ u c, D c → ¬ D u → s.edges u c → 1 ≤ extIn c)
    (h_zero : ∀ c, c ∈ members → extIn c = 0) :
    closed s D := by
  constructor
  · intro t x hD hroot
    have h1 := h_roots_counted t x hD hroot
    have h2 := h_zero x (hmem x hD)
    omega
  · intro u v hD hedge
    by_cases hu : D u
    · exact hu
    · have h1 := h_edges_counted u v hD hu hedge
      have h2 := h_zero v (hmem v hD)
      omega

/-! ## §5 Parallel collections: tags, partitions, cross-target liveness -/

/-- Tags are issued from a monotonic counter under gMergeLock
    (startCollection). Distinct issue times give distinct tags, so a
    stale stamp from a finished collection can never be mistaken for a
    different active collection's tag. (The implementation wraps the
    counter at 2³¹; the model assumes no wrap-around while a tag is
    active — an ABA that would need 2³¹ collections to complete during
    one collection's lifetime.) -/
theorem tags_distinct (issue : Nat → Nat)
    (hmono : ∀ i j, i < j → issue i < issue j) :
    ∀ i j, issue i = issue j → i = j := by
  intro i j heq
  cases Nat.lt_trichotomy i j with
  | inl h => have := hmono i j h; omega
  | inr h =>
    cases h with
    | inl h => exact h
    | inr h => have := hmono j i h; omega

/-- Each cell's header stores ONE stamp (claimCell CASes the whole
    word), so two active collections with distinct tags claim disjoint
    partitions. -/
theorem partitions_disjoint (stamp : Obj → Nat) (tagA tagB : Nat)
    (hne : tagA ≠ tagB) :
    ∀ x, stamp x = tagA → stamp x = tagB → False := by
  intro x hA hB
  exact hne (hA ▸ hB)

/-- **Cross-target liveness**: a cell claimed by collection B but
    referenced from OUTSIDE B's partition is never in B's dead set.
    B's internal count for the cell only includes edges from B's dead
    members; the foreign edge contributes an external count, and
    validation forces external counts to zero — so the cell's SCC fails
    the deadness check (equivalently: it is demoted). This is why
    claimCell may simply refuse foreign-claimed cells (return -1) and
    crossPend defer them: their owner provably keeps them alive this
    round, and re-registration makes them candidates for the next. -/
theorem cross_target_live (D : Obj → Prop) (claimedB : Obj → Prop)
    (members : List Obj) (extIn : Obj → Nat)
    (s : State)
    (hDsub : ∀ x, D x → claimedB x)
    (hmem : ∀ x, D x → x ∈ members)
    (h_edges_counted : ∀ u c, D c → ¬ D u → s.edges u c → 1 ≤ extIn c)
    (h_zero : ∀ c, c ∈ members → extIn c = 0)
    (u c : Obj) (hedge : s.edges u c) (hu : ¬ claimedB u) :
    ¬ D c := by
  intro hDc
  have hDu : ¬ D u := fun h => hu (hDsub u h)
  have h1 := h_edges_counted u c hDc hDu hedge
  have h2 := h_zero c (hmem c hDc)
  omega

/-! ## §6 The grace period

  A concurrent capture holds raw `(slot, value)` snapshots (TraceEntry);
  the value pointer is dereferenced later (header read in claimCell). A
  capture that overlapped our validation may have snapshotted a slot
  that USED to point into our dead set. commitDead therefore waits, for
  every other slot that is in capture phase (gSlotPhase == 1), until
  that capture ends — captures never wait on anyone, so this is bounded.

  Two obligations:
  (a) captures that started BEFORE our commit are waited out — temporal
      argument below (`grace_no_use_after_free`);
  (b) captures that start AT/AFTER our commit never snapshot a dead
      cell in the first place (`post_commit_snap_misses_dead`): they
      only read slots of cells they claim; our dead cells carry our
      still-active tag, so claimCell refuses them (never traversed),
      and no slot OUTSIDE the dead set points into it (closedness, held
      through the window by §3 stability). -/

/-- Any snapshot value read by a post-commit capture comes from a slot
    of a cell that capture claimed; claimed cells are never dead cells
    of another active collection (§5), and the dead set is closed. -/
theorem post_commit_snap_misses_dead (s : State)
    (D claimedC snap : Obj → Prop)
    (hdisj : ∀ x, claimedC x → ¬ D x)
    (hclosed : closed s D)
    (hsnap : ∀ v, snap v → ∃ u, claimedC u ∧ s.edges u v) :
    ∀ v, D v → ¬ snap v := by
  intro v hD hs
  obtain ⟨u, hu, he⟩ := hsnap v hs
  exact hdisj u hu (hclosed.2 u v hD he)

/-- One concurrent capture, with its interval in a global time order and
    the set of values it ever snapshots. `derefs x t` = the capture
    reads x's header at time t (always within its interval, always on a
    snapshotted value). -/
structure CaptureWindow where
  start : Nat
  finish : Nat
  snap : Obj → Prop
  derefs : Obj → Nat → Prop

/-- **Grace safety**: no capture dereferences a dead cell at or after
    its free time. `commitT` is when the dead set validated; `freeT` is
    when commitDead's free loop runs. The premises are exactly the
    protocol: (grace) commitDead's spin means any capture that started
    before commit has finished before we free; (miss) §6(b) above. -/
theorem grace_no_use_after_free
    (C : CaptureWindow) (D : Obj → Prop) (commitT freeT : Nat)
    (h_deref : ∀ x t, C.derefs x t → C.start ≤ t ∧ t ≤ C.finish ∧ C.snap x)
    (h_grace : C.start < commitT → C.finish < freeT)
    (h_miss : commitT ≤ C.start → ∀ x, D x → ¬ C.snap x) :
    ∀ x t, D x → C.derefs x t → t < freeT := by
  intro x t hD hd
  obtain ⟨h1, h2, h3⟩ := h_deref x t hd
  cases Nat.lt_or_ge C.start commitT with
  | inl h => have := h_grace h; omega
  | inr h => exact absurd h3 (h_miss h x hD)

/-! ## §7 The asymmetric seq/GC fence (seqs_v2.nim)

  Seq structure mutations (which may FREE the old buffer on realloc)
  must not overlap a collection, but seq-vs-seq and collection-vs-
  collection may run concurrently. The committed fence:

    mutator (acquireMutatorLock):    collector (yrcGcFenceEnter):
      1. FetchAdd gSeqActive[s] SC     1. FetchAdd gGcActive  SC
      2. Load gGcActive        SC      2. Load gSeqActive[s]  SC (each s)
      proceed iff it read 0            proceed when all read 0
      (else back off: FetchSub, spin, retry)

  Under sequential consistency all four operations occupy positions in
  one total order. Suppose both sides are in their critical sections
  simultaneously (neither has executed its matching FetchSub). The
  mutator read gGcActive = 0 AFTER its own inc: since the collector's
  inc precedes its critical section and no dec intervened, the
  collector's inc must be ordered after the mutator's read — and
  symmetrically for the collector's read. That yields a cycle in the
  total order: -/

theorem fence_mutual_exclusion
    (mutInc mutChk gcInc gcChk : Nat)  -- positions in the SC total order
    (h_mut_po : mutInc < mutChk)       -- program order, mutator
    (h_gc_po : gcInc < gcChk)          -- program order, collector
    (h_mut_read0 : mutChk < gcInc)     -- mutator read gGcActive = 0
    (h_gc_read0 : gcChk < mutInc) :    -- collector read counter = 0
    False := by omega

/-! ## §8 Deadlock freedom

  ### Locks

  The global collector lock is gone. What remains:
    • gMergeLock                (level 0)
    • stripes[i].lockInc        (level 2*i + 1,  i in 0..N-1)
    • stripes[i].lockDec        (level 2*i + 2,  i in 0..N-1)
    • gWaitLock                 (leaf: pairs gWaitCond's wait/broadcast;
                                 only ever held around a predicate check,
                                 a wait(), or a broadcast() — never while
                                 acquiring any other lock, and no other
                                 lock is held when it is taken)

  Total order:  gMergeLock < lockInc[0] < lockDec[0] < lockInc[1] < ...

  Every code path acquires in strictly ascending level order:

  **nimIncRefCyclic** fast path: lockInc[myStripe] alone. Overflow path:
    lockInc[i] for i = 0..N-1, one at a time, no gMergeLock. ✓
  **nimDecRefIsLastCyclic*** fast path: lockDec[myStripe] alone; the
    overflow calls collectCycles AFTER releasing it (overflow-flag
    pattern). ✓
  **startCollection**: gMergeLock, then mergePendingRoots takes
    lockInc[i], lockDec[i] ascending, releasing each. ✓
  **markDirtyFromQueues**: stripe locks only, ascending, and gMergeLock
    is NOT held (commitDead's gMergeLock sections are disjoint from it).
  **validateDead / commitDead / GC_prepareOrc root registration**:
    gMergeLock alone, no stripe lock held or taken inside. ✓
  **nimAsgnYrc / nimSinkYrc**: lock-free (atomic inc + exchange); only
    the deferred dec takes lockDec[myStripe] on its own. ✓

  ### Blocking waits (parked on gWaitCond after a bounded spin)

    W1 backpressure (startCollection): waits for a free tag slot —
       gMergeLock is RELEASED first; slots free when collections finish
       (finishCollection broadcasts).
    W2 solo gate (runCollection): a non-solo collection waits for
       gSoloCapture = 0 — cleared when the solo collection's CAPTURE
       ends (collectCyclesImpl broadcasts), before its commit.
    W3 grace (commitDead): waits for other slots to leave capture phase
       (broadcast at the phase 1→2 transition and at finish).
    W4 fence (yrcGcFenceEnter): spins for in-flight seq ops — each is a
       short critical section that never blocks (releaseMutatorLock is
       a plain FetchSub).

  W1–W3 park on gWaitCond: the waiter re-checks its predicate under
  gWaitLock before sleeping, and every state transition that can make a
  predicate true (capture-end, collection-finish) broadcasts under the
  same lock — so a transition either happens before the re-check (the
  waiter never sleeps) or after it (the waiter is inside wait() and is
  woken). No missed wakeups, and the wait-for structure is unchanged.

  No wait cycle exists: order the blocking conditions by what they wait
  FOR. A capture phase terminates unconditionally (finite traversal, no
  waits inside — claimCell returns -1 immediately on contention). W2
  waits only on a capture; W3 waits only on captures; a collection
  executes W2 BEFORE its own capture and W3 AFTER it, so "X waits (W2)
  on S's capture" and "S waits (W3) on X's capture" cannot hold
  simultaneously: S clears gSoloCapture before entering commit, so by
  the time S is in W3, X has passed W2. W1 waits on full collections,
  which terminate because W2/W3/W4 do. Formally, the lock part is the
  same ascending-order argument as before: -/

/-- Lock levels in YRC. -/
inductive LockId (n : Nat) where
  | mergeLock : LockId n
  | lockInc (i : Nat) (h : i < n) : LockId n
  | lockDec (i : Nat) (h : i < n) : LockId n

def lockLevel {n : Nat} : LockId n → Nat
  | .mergeLock => 0
  | .lockInc i _ => 2 * i + 1
  | .lockDec i _ => 2 * i + 2

/-- All lock levels are distinct (the order is total and well-defined). -/
theorem lockLevel_injective {n : Nat} (a b : LockId n)
    (h : lockLevel a = lockLevel b) : a = b := by
  cases a with
  | mergeLock =>
    cases b with
    | mergeLock => rfl
    | lockInc j hj => simp [lockLevel] at h
    | lockDec j hj => simp [lockLevel] at h
  | lockInc i hi =>
    cases b with
    | mergeLock => simp [lockLevel] at h
    | lockInc j hj =>
      have : i = j := by simp [lockLevel] at h; omega
      subst this; rfl
    | lockDec j hj => simp [lockLevel] at h; omega
  | lockDec i hi =>
    cases b with
    | mergeLock => simp [lockLevel] at h
    | lockInc j hj => simp [lockLevel] at h; omega
    | lockDec j hj =>
      have : i = j := by simp [lockLevel] at h; omega
      subst this; rfl

/-- gMergeLock has the lowest level. -/
theorem mergeLock_level_min {n : Nat} (l : LockId n) (h : l ≠ .mergeLock) :
    lockLevel (.mergeLock : LockId n) < lockLevel l := by
  cases l with
  | mergeLock => exact absurd rfl h
  | lockInc i hi => simp [lockLevel]
  | lockDec i hi => simp [lockLevel]

/-- **Deadlock Freedom** (2-thread wait cycle; N-thread follows by the
    same transitivity on the wait-for chain): impossible when every
    thread acquires locks in strictly ascending level order. -/
theorem no_deadlock_from_total_order {n : Nat}
    (held₁ waited₁ held₂ waited₂ : LockId n)
    (h1 : lockLevel held₁ < lockLevel waited₁)
    (h2 : lockLevel held₂ < lockLevel waited₂)
    (h_wait1 : waited₁ = held₂)
    (h_wait2 : waited₂ = held₁) :
    False := by
  subst h_wait1; subst h_wait2
  omega

/-! ## Summary of verified properties (all QED, no sorry)

  §1  `yrc_safety` — the collector frees only unanchored objects, which
      no thread can reach. No use-after-free at the graph level.
  §2  `no_lost_object` — the atomically published edge is traced.
  §3  `step_preserves_deadInv`, `deadInv_stable`, `garbage_stability` —
      a closed set stays closed under every mutator write, root
      copy/drop, allocation, and foreign free: snapshot garbage cannot
      be resurrected. `commit_free_safe` — freeing a commit-validated
      dead set after ANY further concurrent activity is safe.
  §4  `validated_no_external`, `validated_closed` — the Σrc = Σinternal
      check plus rc-exactness forces zero external references, i.e. the
      dead set is closed at commit time (feeding §3).
  §5  `tags_distinct`, `partitions_disjoint`, `cross_target_live` —
      concurrent collections own disjoint partitions, and a cell
      referenced across a partition boundary is never freed by its
      owner this round (soundness of claimCell's -1 + crossPend).
  §6  `post_commit_snap_misses_dead`, `grace_no_use_after_free` — with
      commitDead's grace spin, no capture ever dereferences freed
      memory.
  §7  `fence_mutual_exclusion` — the SEQ_CST Dekker pairing in
      seqs_v2.nim excludes seq structure mutation during collection.
  §8  `lockLevel_injective`, `mergeLock_level_min`,
      `no_deadlock_from_total_order` — the remaining locks form a total
      order acquired ascending; spin-waits form an acyclic wait-for
      structure (prose above).

  ## What is NOT proved

  • Tarjan/SCC implementation correctness: that `capture` computes the
    actual SCCs and that computeDeadness's per-SCC sums equal the model's
    Σrc/Σinternal for the emitted dead set (condensation, sinks-first
    order, deadIn accounting). §4 takes the counts as given.
  • rc-exactness mechanics: that merge + the dirty check + the rc-word
    recheck really imply "commit-time rc = internal + external" (§4's
    h_exact). The argument: rc is only mutated by atomic direct incs
    (caught by the recheck), merged queue entries (queues drained at
    merge; later entries caught by the dirty peek), and the collector's
    own inRootsFlag toggles (excluded from the compared word — see the
    comment above claimCell).
  • The C11 memory model: §7 assumes sequential consistency for the
    SEQ_CST operations (sound: SEQ_CST ops do form a total order) and
    the acquire/release reasoning elsewhere is informal.
  • Liveness/completeness: every dead cycle is EVENTUALLY freed.
    Aborted (dirty) SCCs and crossPend targets are re-registered as
    candidates, so they are re-examined; termination of that loop under
    adversarial mutators is not formalized. Also unproved: termination
    bounds for the four spin-waits (prose in §8).
  • Tag wrap-around: 2³¹ collections completing during one collection's
    lifetime could forge a stale stamp (noted at `tags_distinct`).

  ## Epoch stamps (generational pruning)

  Commit re-stamps proven-live cells with (epochBase|epoch, survivalAge)
  in the claim word; a capture treats a current-epoch stamp of age ≥
  YrcPromoteAge on a DESCENDANT as an opaque live external and does not
  descend. Soundness needs no new lemmas: a pruned cell is simply an
  uncaptured cell, so the captured set shrinks and every §3–§6 statement
  quantifies over a smaller S. Pruning can only ADD unexplained external
  refs to captured SCCs (a pruned predecessor's refs are never explained
  by internal/deadIn), so it can force a false "live", never a false
  "dead" — the conservative direction. Completeness (bounded float,
  ≤ ~2 epochs) rests on four hooks, each keeping a dec-witness
  registered:
    E1  roots never prune: a registered candidate is always fully
        root-scanned, stamps notwithstanding;
    E2  an SCC that pruned an out-edge and survives keeps one member
        registered (flagPruned) — its "live" verdict may lean on a stamp
        that went stale within the epoch;
    E3  a commit-time dec into a stamped cell re-registers the target —
        the dec may be the death blow to a cell no collection analyzed;
    E4  explicit full collects advance the epoch first, so all stamps
        are stale and nothing is pruned.
  Not formalized. Also noted: the epoch clock counts collections, and
  short epochs (≲ 4) resonate with the adaptive threshold — pruned
  collections are cheap, so collections and hence epoch turns speed up,
  re-tracing MORE than with no stamps; a work-based clock would fix it.

  Reference: D.F. Bacon and V.T. Rajan, "Concurrent Cycle Collection in
  Reference Counted Systems", ECOOP 2001 — the deadness arithmetic is
  the condensation form of their trial deletion; the capture/validate/
  commit structure and the SATB use of the deferred-dec queues are
  yrc-specific.
-/
