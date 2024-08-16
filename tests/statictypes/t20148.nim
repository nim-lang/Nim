type Percent = range[0.0 .. 1.0]
# type Percent = float # using unlimited `float` works fine

proc initColor*(alpha: Percent): bool =
  echo alpha

const moduleInstanceStyle = initColor(1)
# let moduleInstanceStyle = initColor(1) # using runtime conversion works fine
