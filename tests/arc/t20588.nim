discard """
  action: reject
  nimout: '''
t20588.nim(21, 37) Error: invalid call 'auto'
'''
"""













func hakunaMatata[N, D](n: N, d: D): auto =
    if d.float > 0: (n/d) else: 0.0.auto

discard hakunaMatata(42.0, 0.42)
