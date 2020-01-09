const stderrName* = when defined(osx): "__stderrp" else: "stderr"
const stdoutName* = when defined(osx): "__stdoutp" else: "stdout"
const stdinName* = when defined(osx): "__stdinp" else: "stdin"
