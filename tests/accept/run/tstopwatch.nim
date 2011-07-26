discard """
file: "tstopwatch.nim"
output: '''Elapsed time: 3 seconds'''
"""

import stopwatch

var sw = initStopwatch()

sw.start()
os.sleep(3000)
sw.stop()
write(stdout, "Elapsed time: " & $(sw.ElapsedTime) & " seconds")