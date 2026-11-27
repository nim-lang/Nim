discard """
  output: '''
5
5
'''
"""

# bug #14414
block:
  proc gendef[N = 2](): array[N, float] =
    echo N
    echo len(result)
  discard gendef[5]()
