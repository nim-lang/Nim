discard """
output: '''42'''
"""

# Regression test: a `{.base.}` method whose body holds a closure iterator with a
# nested capturing closure must not crash the IC backend. The method's dispatcher
# (a `copySym` clone sharing the iterator) must NOT be lambda-lifted per module;
# otherwise the shared iterator's `up` field is baked twice under divergent owner
# identities -> "up references do not agree" / "could not determine closure type"
# (the real-world symptom: ~all libp2p async `{.base.}` methods failed under
# `nim ic`). Fixed by excluding `sfDispatcher` from nifbackend.ownsRuntimeRoutine.

import mmethupref
let b = Base(val: 40)
echo b.compute()
