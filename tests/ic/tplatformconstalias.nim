discard """
output: '''ok'''
"""

# The scanner cannot evaluate an imported const, so it must defer the guarded
# import to sem instead of compiling a Windows-only module on other targets.
import mplatformconstalias

when WindowsHostIsEnabled:
  import mwindowsonly
  static: doAssert windowsOnlyValue() == 1

echo "ok"
