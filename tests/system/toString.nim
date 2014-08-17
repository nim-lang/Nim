discard """
  output:'''@[23, 45]
@[, foo, bar]'''
"""

echo($(@[23, 45]))
echo($(@["", "foo", "bar"]))
#echo($(["", "foo", "bar"]))
#echo($([23, 45]))
