discard """
    output: '''likely occurrence
unlikely occurrence'''
"""

if likely(true):
    echo "likely occurrence"

if unlikely 4 == 34:
    echo "~~wrong branch taken~~"
else:
    echo "unlikely occurrence"
