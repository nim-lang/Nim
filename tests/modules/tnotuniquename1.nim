discard """
  output: "ok"
"""

# module names need not be unique (but must be renamed to avoid clashes)
import mnotuniquename
import tnotuniquename/mnotuniquename as mnotuniquename1
echo "ok"
