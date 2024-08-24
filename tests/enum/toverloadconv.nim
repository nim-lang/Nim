discard """
  output: '''
1.0
0.0
'''
"""

type
  Specials = enum
    explosion
    fire
    poison
  Stat = enum
    poison
    fire
    damage

const
  DEFAULT_STATS_DEFAULT: array[Stat, float32] = [
    poison: 1.0,
    fire: 0.0,
    damage: 10.0,
  ]

var
  DEFAULT_STATS = DEFAULT_STATS_DEFAULT

template RESET_DEFAULT_STATS: untyped =
  STATS = DEFAULT_STATS_DEFAULT

var
  player_stats = @DEFAULT_STATS

for s in 0..<len player_stats:
  # test type conversion here resolves ambiguity:
  if s.Stat in {poison.Stat, fire}:
    echo player_stats[s]
