discard """
output: '''
Nim: nan
Nim: nan (float)
Nim: nan (double)
'''
"""

let f = NaN
echo "Nim: ", f

let f32: float32 = NaN
echo "Nim: ", f32, " (float)"

let f64: float64 = NaN
echo "Nim: ", f64, " (double)"
