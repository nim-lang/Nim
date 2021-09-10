block: # Replicates #18728
  type
    FlipFlop[A, B] = ref object
      next: FlipFlop[B, A]
  
    Trinary[A, B, C] = ref object
      next: Trinary[B, C, A]
  
  assert typeof(FlipFlop[int, string]().next) is FlipFlop[string, int]
  assert typeof(FlipFlop[string, int]().next) is FlipFlop[int, string]
  assert typeof(Trinary[int, float, string]().next) is Trinary[float, string, int]
  assert typeof(Trinary[int, float, string]().next.next) is Trinary[string, int, float]