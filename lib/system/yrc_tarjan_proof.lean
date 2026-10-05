/-
  Tarjan-based deadness computation — correctness proof
  =====================================================
  Self-contained, no Mathlib. Checked with Lean 4 (v4.32.0).

  Companion to yrc_proof.lean; models the NOVEL part of yrc.nim's
  collector: cycle detection via a single Tarjan SCC traversal plus one
  linear reverse scan over the condensation, replacing Bacon-style trial
  deletion (three traversals: markGray / scan / collectWhite).

  ## The algorithm (capture / computeDeadness in yrc.nim)

  `capture` runs an iterative Tarjan DFS from the candidate roots. Each
  visited cell is claimed (dense index in the header), its rc word is
  snapshotted, and every traversed slot contributes one edge record.
  SCCs are numbered 0, 1, 2, … in POP (completion) order. Tarjan's
  invariant: when an SCC is completed, every SCC it points to was
  completed earlier — so every condensation cross edge goes from a
  HIGHER SCC id to a LOWER one ("sinks first").

  `computeDeadness` then makes ONE pass s = nScc−1 … 0 (sources before
  sinks, since in-edges come from higher ids):

      ext(s) = sumRefs(s) − internal(s) − deadIn(s)
      if not forcedLive(s) and ext(s) == 0:
        s is DEAD;  for each cross edge s → t: deadIn(t) += 1
      else:
        s is LIVE;  for each cross edge s → t: forcedLive(t) := true

  where sumRefs(s) = Σ rc over members, internal(s) = # captured edges
  within s, and forcedLive is seeded from cells still registered in the
  roots buffer (inRootsFlag).

  ## What we prove

  Fix the SPEC of liveness on the condensation: an SCC is live iff it
  has an external reference, a roots-buffer seed, or a captured cross
  edge from a live SCC (`LiveScc`, an inductive definition).

  1. `scan_dead_iff_not_live` — any deadness assignment satisfying the
     scan's per-SCC equation (well-defined thanks to the sinks-first
     edge order) marks an SCC dead IFF it is not live. Soundness AND
     completeness in one theorem: the single reverse scan computes the
     garbage set EXACTLY on the captured snapshot.
  2. `impl_fixpoint_is_spec` — the implementation's ARITHMETIC form
     (ext = sumRefs − internal − deadIn with forcedLive propagation) is
     the same equation, given rc-exactness (sumRefs = external +
     internal + cross-in; established by merge + commit validation, see
     yrc_proof.lean §4).
  3. Cell-level bridge: `tarjan_sound` — cells of dead SCCs are
     unreachable in the snapshot; `tarjan_complete` — every captured
     garbage cell IS marked dead (this needs strong connectivity of the
     SCCs and exactness of the external counts; Bacon needs his second
     and third traversals for the same guarantee).
  4. `demotion_closure_sound` — validate-time demotion (an SCC dropped
     from the dead set because a mutator dirtied it) must PROPAGATE
     along captured cross edges: the freed set stays closed only if the
     demoted set is successor-closed within the dead set. A demoted SCC
     survives with its out-edges intact, so any still-dead target would
     be freed while a surviving cell points at it.

  ## What is assumed (and where it is discharged)

  • The sinks-first edge order (`horder`) — Tarjan's classical
    invariant; the DFS itself is not modeled.
  • rc-exactness (`hcount`) — discharged operationally by yrc_proof §4
    (merge + dirty check + rc-word recheck).
  • That `capture` records exactly the heap edges among captured cells
    and that SCC members are mutually reachable (`h_edge_resp`,
    `h_conn`, `h_cross_real`) — properties of the traversal + Tarjan.
-/

abbrev Obj := Nat

/-! ## §1 Descending induction

  The scan processes higher SCC ids first; every recursive dependency
  of `dead s` is on some `u > s`. This induction principle is the
  well-definedness of the whole scheme. -/

theorem descending_induction {n : Nat} (P : Fin n → Prop)
    (step : ∀ s : Fin n, (∀ u : Fin n, s < u → P u) → P s) :
    ∀ s, P s := by
  have key : ∀ k, ∀ s : Fin n, n - s.val ≤ k → P s := by
    intro k
    induction k with
    | zero =>
      intro s hs
      have := s.isLt
      omega
    | succ k ih =>
      intro s _
      apply step
      intro u hu
      apply ih
      have h1 := u.isLt
      have h2 : s.val < u.val := hu
      omega
  intro s
  exact key n s (by omega)

/-! ## §2 The condensation and the liveness spec

  `edges` are the captured condensation cross edges (with multiplicity:
  one entry per traversed slot, exactly like cap.edges bucketed into
  crossTgt). `extRefs s` counts references into SCC `s` from OUTSIDE
  the capture: stack refs, uncaptured heap cells, other collections'
  partitions — everything in Σrc not explained by captured edges.
  `seed s` is the inRootsFlag forcedLive seeding. -/

section Condensation

variable {n : Nat}
variable (edges : List (Fin n × Fin n))
variable (extRefs : Fin n → Nat)
variable (seed : Fin n → Bool)

/-- The SPEC: an SCC is live iff something external anchors it —
    directly or through a chain of captured cross edges. -/
inductive LiveScc : Fin n → Prop where
  | ext (s : Fin n) : 0 < extRefs s → LiveScc s
  | root (s : Fin n) : seed s = true → LiveScc s
  | pred (u s : Fin n) : (u, s) ∈ edges → LiveScc u → LiveScc s

/-- The per-SCC equation the reverse scan establishes: dead iff no
    external refs, no seed, and ALL cross predecessors dead. (The
    sinks-first order makes this a valid definition: every predecessor
    has a higher id and is decided first — see `descending_induction`;
    without that order the "definition" would be circular.) -/
def ScanEq (dead : Fin n → Bool) : Prop :=
  ∀ s, dead s = true ↔
    (extRefs s = 0 ∧ seed s = false ∧
     ∀ e ∈ edges, e.2 = s → dead e.1 = true)

/-- Live SCCs are never marked dead (soundness direction). -/
theorem live_not_dead (dead : Fin n → Bool)
    (hfix : ScanEq edges extRefs seed dead) :
    ∀ s, LiveScc edges extRefs seed s → dead s ≠ true := by
  intro s hl
  induction hl with
  | ext s h =>
    intro hd
    have := ((hfix s).mp hd).1
    omega
  | root s h =>
    intro hd
    have := ((hfix s).mp hd).2.1
    rw [h] at this
    cases this
  | pred u s hmem _ ih =>
    intro hd
    exact ih (((hfix s).mp hd).2.2 (u, s) hmem rfl)

/-- Non-live SCCs are always marked dead (completeness direction) —
    by descending induction along the scan order. -/
theorem not_live_dead
    (horder : ∀ e ∈ edges, e.2 < e.1)
    (dead : Fin n → Bool)
    (hfix : ScanEq edges extRefs seed dead) :
    ∀ s, ¬ LiveScc edges extRefs seed s → dead s = true := by
  refine descending_induction
    (fun s => ¬ LiveScc edges extRefs seed s → dead s = true) ?_
  intro s ihs hnl
  rw [hfix]
  refine ⟨?_, ?_, ?_⟩
  · cases Nat.eq_zero_or_pos (extRefs s) with
    | inl h => exact h
    | inr h => exact absurd (LiveScc.ext s h) hnl
  · cases hsd : seed s with
    | false => rfl
    | true => exact absurd (LiveScc.root s hsd) hnl
  · intro e he hes
    have hlt : s < e.1 := by
      have := horder e he
      rw [hes] at this
      exact this
    apply ihs e.1 hlt
    intro hlu
    have hmem : (e.1, s) ∈ edges := by
      rw [← hes]
      simpa using he
    exact hnl (LiveScc.pred e.1 s hmem hlu)

/-- **Main condensation theorem**: the single reverse scan computes
    EXACTLY the non-live SCCs. One Tarjan DFS + one linear scan replace
    Bacon's three graph traversals, with no loss of precision on the
    snapshot. -/
theorem scan_dead_iff_not_live
    (horder : ∀ e ∈ edges, e.2 < e.1)
    (dead : Fin n → Bool)
    (hfix : ScanEq edges extRefs seed dead) :
    ∀ s, dead s = true ↔ ¬ LiveScc edges extRefs seed s := by
  intro s
  constructor
  · intro hd hl
    exact live_not_dead edges extRefs seed dead hfix s hl hd
  · exact not_live_dead edges extRefs seed horder dead hfix s

/-! ## §3 The implementation's arithmetic form

  computeDeadness does not test "all predecessors dead" directly; it
  maintains ext(s) = sumRefs(s) − internal(s) − deadIn(s) and a
  forcedLive flag pushed along cross edges of live SCCs. We show this
  is the same equation, given rc-exactness:

      sumRefs s = extRefs s + internal s + (# cross edges into s).

  ext(s) = 0 then says extRefs s = 0 AND every cross in-edge came from
  a dead predecessor; ¬forcedLive says no seed and no LIVE predecessor
  pushed the flag — together exactly `ScanEq`. -/

def inCount (s : Fin n) : Nat :=
  edges.countP (fun e => e.2 == s)

def deadInCount (dead : Fin n → Bool) (s : Fin n) : Nat :=
  edges.countP (fun e => e.2 == s && dead e.1)

/-- countP is monotone under pointwise implication. -/
theorem countP_le_of_imp {α : Type} (l : List α) (p q : α → Bool)
    (himp : ∀ x ∈ l, p x = true → q x = true) :
    l.countP p ≤ l.countP q := by
  induction l with
  | nil => simp
  | cons a l ih =>
    have iht := ih (fun x hx => himp x (List.mem_cons_of_mem a hx))
    by_cases hpa : p a = true
    · have hqa := himp a (by simp) hpa
      simp [hpa, hqa]
      omega
    · simp only [List.countP_cons]
      have : p a = false := by
        cases h : p a
        · rfl
        · exact absurd h hpa
      simp [this]
      omega

/-- If a stronger predicate matches as often as a weaker one, they
    agree on every element. -/
theorem countP_eq_forces_all {α : Type} (l : List α) (p q : α → Bool)
    (himp : ∀ x ∈ l, q x = true → p x = true)
    (heq : l.countP p = l.countP q) :
    ∀ x ∈ l, p x = true → q x = true := by
  induction l with
  | nil => intro x hx; cases hx
  | cons a l ih =>
    have himpt : ∀ x ∈ l, q x = true → p x = true :=
      fun x hx => himp x (List.mem_cons_of_mem a hx)
    have hmono := countP_le_of_imp l q p himpt
    intro x hx hpx
    simp only [List.countP_cons] at heq
    cases List.mem_cons.mp hx with
    | inl hxa =>
      subst hxa
      cases hqx : q x with
      | true => rfl
      | false =>
        exfalso
        simp [hpx, hqx] at heq
        omega
    | inr hxl =>
      have hqa_pa : (if q a = true then 1 else 0) ≤ (if p a = true then 1 else 0) := by
        by_cases hq : q a = true
        · simp [hq, himp a (by simp) hq]
        · simp [hq]
      have heqt : l.countP p = l.countP q := by
        by_cases hq : q a = true
        · simp [hq, himp a (by simp) hq] at heq
          omega
        · have hqf : q a = false := by
            cases h : q a
            · rfl
            · exact absurd h hq
          by_cases hp : p a = true
          · simp [hp, hqf] at heq
            omega
          · have hpf : p a = false := by
              cases h : p a
              · rfl
              · exact absurd h hp
            simp [hpf, hqf] at heq
            omega
      exact ih himpt heqt x hxl hpx

/-- If all cross predecessors of `s` are dead, deadIn equals the full
    in-count (and vice versa). -/
theorem deadIn_eq_inCount_iff (dead : Fin n → Bool) (s : Fin n) :
    deadInCount edges dead s = inCount edges s ↔
    (∀ e ∈ edges, e.2 = s → dead e.1 = true) := by
  constructor
  · intro heq e he hes
    have himp : ∀ x ∈ edges, (fun e => e.2 == s && dead e.1) x = true →
        (fun e => e.2 == s) x = true := by
      intro x _ hx
      simp only [Bool.and_eq_true] at hx
      exact hx.1
    have := countP_eq_forces_all edges
      (fun e => e.2 == s) (fun e => e.2 == s && dead e.1)
      himp heq.symm e he
    have hbeq : (e.2 == s) = true := by
      simp [hes]
    have := this hbeq
    simp only [Bool.and_eq_true] at this
    exact this.2
  · intro hall
    unfold deadInCount inCount
    apply List.countP_congr
    intro e he
    by_cases hes : e.2 = s
    · simp [hes, hall e he hes]
    · have : (e.2 == s) = false := by
        simp [hes]
      simp [this]

/-- The implementation's per-SCC decision, verbatim from
    computeDeadness: NOT forced (no seed, no live predecessor pushed
    the flag) and ext = sumRefs − internal − deadIn = 0 (stated
    subtraction-free). -/
def ImplEq (sumRefs internal : Fin n → Nat) (dead : Fin n → Bool) : Prop :=
  ∀ s, dead s = true ↔
    (¬ (seed s = true ∨ ∃ e ∈ edges, e.2 = s ∧ dead e.1 = false) ∧
     sumRefs s = internal s + deadInCount edges dead s)

/-- **The arithmetic is the spec**: under rc-exactness, the
    implementation's equation is `ScanEq`, so `scan_dead_iff_not_live`
    applies to computeDeadness as written. -/
theorem impl_fixpoint_is_spec
    (sumRefs internal : Fin n → Nat) (dead : Fin n → Bool)
    (hcount : ∀ s, sumRefs s = extRefs s + internal s + inCount edges s)
    (himpl : ImplEq edges seed sumRefs internal dead) :
    ScanEq edges extRefs seed dead := by
  intro s
  rw [himpl s]
  constructor
  · rintro ⟨hnf, harith⟩
    have hor := hnf
    rw [not_or] at hor
    obtain ⟨hseed, hnopred⟩ := hor
    have hseedf : seed s = false := by
      cases h : seed s
      · rfl
      · exact absurd h hseed
    have hall : ∀ e ∈ edges, e.2 = s → dead e.1 = true := by
      intro e he hes
      cases h : dead e.1 with
      | true => rfl
      | false => exact absurd ⟨e, he, hes, h⟩ hnopred
    have hdc := (deadIn_eq_inCount_iff edges dead s).mpr hall
    have hc := hcount s
    refine ⟨by omega, hseedf, hall⟩
  · rintro ⟨hext, hseedf, hall⟩
    have hdc := (deadIn_eq_inCount_iff edges dead s).mpr hall
    refine ⟨?_, ?_⟩
    · rw [not_or]
      refine ⟨by simp [hseedf], ?_⟩
      rintro ⟨e, he, hes, hdf⟩
      rw [hall e he hes] at hdf
      cases hdf
    · have hc := hcount s
      omega

end Condensation

/-! ## §4 Cell-level correctness

  Bridge from the condensation to the actual heap snapshot. `extRef`
  covers every reference source outside the capture: mutator stacks,
  the roots buffer, uncaptured heap cells' slots that the arithmetic
  cannot explain, and other collections' partitions (cross-collection
  edges — this is the SCC-side view of `cross_target_live` in
  yrc_proof.lean §5). -/

structure CellGraph where
  edge : Obj → Obj → Prop
  extRef : Obj → Prop

/-- A cell is live iff an external reference anchors it through heap
    edges (the cell-level ground truth; `anchored` of yrc_proof.lean). -/
inductive CellLive (g : CellGraph) : Obj → Prop where
  | ext (x : Obj) : g.extRef x → CellLive g x
  | step (x y : Obj) : CellLive g x → g.edge x y → CellLive g y

/-- Paths through heap edges, used to move liveness around inside an
    SCC (Tarjan guarantees SCC members are mutually reachable). -/
inductive EdgePath (g : CellGraph) : Obj → Obj → Prop where
  | refl (x : Obj) : EdgePath g x x
  | step (x y z : Obj) : EdgePath g x y → g.edge y z → EdgePath g x z

theorem cellLive_along_path (g : CellGraph) (u v : Obj)
    (hl : CellLive g u) (hp : EdgePath g u v) : CellLive g v := by
  induction hp with
  | refl => exact hl
  | step _ _ _ hedge ih => exact CellLive.step _ _ ih hedge

section CellBridge

variable {n : Nat}
variable (g : CellGraph)
variable (edges : List (Fin n × Fin n))
variable (extRefs : Fin n → Nat)
variable (seed : Fin n → Bool)
variable (captured : Obj → Prop)
variable (scc : Obj → Fin n)

/-- Any live captured cell sits in a live SCC.
    Premises are properties of `capture`:
    * `h_edge_resp` — every heap edge between captured cells was
      recorded (same SCC → internal; different → cross edge);
    * `h_closed` — an edge from an UNCAPTURED cell is unexplained by
      the captured arithmetic, so it lands in extRefs;
    * `h_ext` — direct external refs (stacks, roots buffer, foreign
      partitions) are counted in extRefs. -/
theorem captured_live_scc
    (h_edge_resp : ∀ u v, captured u → captured v → g.edge u v →
        scc u = scc v ∨ (scc u, scc v) ∈ edges)
    (h_closed : ∀ u v, captured v → g.edge u v → ¬ captured u →
        0 < extRefs (scc v))
    (h_ext : ∀ v, captured v → g.extRef v → 0 < extRefs (scc v)) :
    ∀ x, CellLive g x → captured x →
      LiveScc edges extRefs seed (scc x) := by
  intro x hl
  induction hl with
  | ext x h =>
    intro hc
    exact LiveScc.ext _ (h_ext x hc h)
  | step u v hu hedge ih =>
    intro hcv
    by_cases hcu : captured u
    · cases h_edge_resp u v hcu hcv hedge with
      | inl heq => rw [← heq]; exact ih hcu
      | inr hmem => exact LiveScc.pred _ _ hmem (ih hcu)
    · exact LiveScc.ext _ (h_closed u v hcv hedge hcu)

/-- **Soundness**: every cell of a dead SCC is unanchored in the
    snapshot — freeing it is justified by yrc_proof.lean §1
    (`yrc_safety`) + §3 (stability through the commit window). -/
theorem tarjan_sound
    (dead : Fin n → Bool)
    (hfix : ScanEq edges extRefs seed dead)
    (h_edge_resp : ∀ u v, captured u → captured v → g.edge u v →
        scc u = scc v ∨ (scc u, scc v) ∈ edges)
    (h_closed : ∀ u v, captured v → g.edge u v → ¬ captured u →
        0 < extRefs (scc v))
    (h_ext : ∀ v, captured v → g.extRef v → 0 < extRefs (scc v)) :
    ∀ x, captured x → dead (scc x) = true → ¬ CellLive g x := by
  intro x hc hd hl
  exact live_not_dead edges extRefs seed dead hfix (scc x)
    (captured_live_scc g edges extRefs seed captured scc
      h_edge_resp h_closed h_ext x hl hc) hd

/-- Every cell of a live SCC is genuinely live. Needs the converse
    premises: external counts are EXACT (no phantom refs — deferred
    decs inflate rc, so in the running system this holds only after
    the merge; overcounts delay collection by a round, they never
    cause a wrong free), cross edges are real edges, and SCC members
    are mutually reachable (Tarjan). -/
theorem live_scc_cells_live
    (h_ext_exact : ∀ s : Fin n, 0 < extRefs s →
        ∃ v, captured v ∧ scc v = s ∧ g.extRef v)
    (h_seed_exact : ∀ s : Fin n, seed s = true →
        ∃ v, captured v ∧ scc v = s ∧ g.extRef v)
    (h_cross_real : ∀ (u s : Fin n), (u, s) ∈ edges →
        ∃ cu cv, captured cu ∧ captured cv ∧ scc cu = u ∧ scc cv = s ∧
          g.edge cu cv)
    (h_conn : ∀ u v, captured u → captured v → scc u = scc v →
        EdgePath g u v) :
    ∀ s, LiveScc edges extRefs seed s →
      ∀ x, captured x → scc x = s → CellLive g x := by
  intro s hl
  induction hl with
  | ext s h =>
    intro x hc hs
    obtain ⟨v, hcv, hsv, hev⟩ := h_ext_exact s h
    exact cellLive_along_path g v x (CellLive.ext v hev)
      (h_conn v x hcv hc (by rw [hsv, hs]))
  | root s h =>
    intro x hc hs
    obtain ⟨v, hcv, hsv, hev⟩ := h_seed_exact s h
    exact cellLive_along_path g v x (CellLive.ext v hev)
      (h_conn v x hcv hc (by rw [hsv, hs]))
  | pred u s hmem _ ih =>
    intro x hc hs
    obtain ⟨cu, cv, hccu, hccv, hscu, hscv, he⟩ := h_cross_real u s hmem
    have hculive : CellLive g cu := ih cu hccu hscu
    exact cellLive_along_path g cv x (CellLive.step cu cv hculive he)
      (h_conn cv x hccv hc (by rw [hscv, hs]))

/-- **Completeness**: every captured garbage cell is marked dead — the
    scan collects ALL cycles reachable from the candidate set in one
    round (on the snapshot; concurrent inflation only defers). -/
theorem tarjan_complete
    (horder : ∀ e ∈ edges, e.2 < e.1)
    (dead : Fin n → Bool)
    (hfix : ScanEq edges extRefs seed dead)
    (h_ext_exact : ∀ s : Fin n, 0 < extRefs s →
        ∃ v, captured v ∧ scc v = s ∧ g.extRef v)
    (h_seed_exact : ∀ s : Fin n, seed s = true →
        ∃ v, captured v ∧ scc v = s ∧ g.extRef v)
    (h_cross_real : ∀ (u s : Fin n), (u, s) ∈ edges →
        ∃ cu cv, captured cu ∧ captured cv ∧ scc cu = u ∧ scc cv = s ∧
          g.edge cu cv)
    (h_conn : ∀ u v, captured u → captured v → scc u = scc v →
        EdgePath g u v) :
    ∀ x, captured x → ¬ CellLive g x → dead (scc x) = true := by
  intro x hc hnl
  apply not_live_dead edges extRefs seed horder dead hfix
  intro hl
  exact hnl (live_scc_cells_live g edges extRefs seed captured scc
    h_ext_exact h_seed_exact h_cross_real h_conn (scc x) hl x hc rfl)

end CellBridge

/-! ## §5 Validate-time demotion must propagate

  validateDead demotes a dead SCC when a mutator dirtied it (queue
  entry or changed rc word). A demoted SCC becomes a survivor: its
  slots are NOT nil'd at commit, so its captured out-edges remain in
  the heap. If a cross target of a demoted SCC stayed in the dead set,
  the commit would free a cell that a surviving cell still points to —
  deadIn had explained that edge away under the assumption that the
  predecessor dies too.

  Minimal instance of the hazard: two SCCs, one edge 1 → 0, both
  computed dead (ext = 0 for both; SCC 0's only reference comes from
  SCC 1, subtracted as deadIn). Demote SCC 1 alone, and the freed set
  {0} has a live in-edge from the surviving SCC 1.

  The theorem below states the repair: if the demoted set `K` is
  successor-closed within the dead set (demoting s also demotes every
  dead t with a captured edge s → t, transitively — one countdown pass
  suffices because edges go from higher to lower ids), then the freed
  set F = dead ∖ K is predecessor-closed: every captured edge into F
  comes from F. Combined with extRefs = 0 and no seed (ScanEq) this
  makes F closed in the sense of yrc_proof.lean §3, so freeing F is
  covered by `commit_free_safe` there. -/

theorem demotion_closure_sound {n : Nat}
    (edges : List (Fin n × Fin n))
    (extRefs : Fin n → Nat) (seed : Fin n → Bool)
    (dead : Fin n → Bool)
    (hfix : ScanEq edges extRefs seed dead)
    (K : Fin n → Prop)                       -- the demoted SCCs
    (hK_closed : ∀ e ∈ edges, K e.1 → dead e.2 = true → K e.2) :
    -- every captured edge into the freed set comes from the freed set
    ∀ e ∈ edges, (dead e.2 = true ∧ ¬ K e.2) →
      (dead e.1 = true ∧ ¬ K e.1) := by
  intro e he ⟨hd2, hk2⟩
  have hd1 : dead e.1 = true :=
    ((hfix e.2).mp hd2).2.2 e he rfl
  refine ⟨hd1, ?_⟩
  intro hk1
  exact hk2 (hK_closed e he hk1 hd2)

/-- Without successor-closure the guarantee genuinely fails: in the
    two-SCC instance above, demoting only SCC 1 leaves the freed set
    {0} with an in-edge from a survivor. (Concrete witness, checked by
    `decide`-style evaluation.) -/
example :
    let edges : List (Fin 2 × Fin 2) := [(1, 0)]
    let dead : Fin 2 → Bool := fun _ => true
    let K : Fin 2 → Prop := fun s => s = 1     -- demote only SCC 1
    -- ScanEq holds for `dead` (both SCCs legitimately computed dead) …
    ScanEq edges (fun _ => 0) (fun _ => false) dead ∧
    -- … yet the freed set {0} has an in-edge from surviving SCC 1:
    ((1, 0) ∈ edges ∧ dead 0 = true ∧ ¬ K 0 ∧ K 1) := by
  refine ⟨?_, ?_⟩
  · intro s
    simp
  · refine ⟨by simp, rfl, by simp, rfl⟩

/-! ## Summary (all QED, no sorry)

  * `descending_induction` — the sinks-first SCC numbering makes the
    reverse scan a well-founded definition.
  * `scan_dead_iff_not_live` — the scan marks an SCC dead iff it is
    not externally anchored: exact garbage identification in ONE
    linear pass over the condensation.
  * `impl_fixpoint_is_spec` — the implementation's arithmetic
    (ext = sumRefs − internal − deadIn, forcedLive propagation) is
    that same equation under rc-exactness.
  * `tarjan_sound` / `tarjan_complete` — at the cell level: dead cells
    are unanchored (frees are safe) and unanchored captured cells are
    freed (nothing is missed on the snapshot).
  * `demotion_closure_sound` + counterexample — demotion is sound iff
    it propagates along captured cross edges to still-dead targets;
    a lone demotion can leave the freed set with a surviving
    predecessor.

  Not modeled: the Tarjan DFS itself (its two classical invariants —
  SCC partition and sinks-first emission — enter as premises), the
  iterative traceStack encoding, crossPend (cross-collection edges are
  folded into `extRefs`, justified by yrc_proof.lean §5), and the
  temporal validity of rc-exactness (yrc_proof.lean §4).
-/
