
import mmodule_same_proc

# importing baz causes the error not to trigger
#import baz

# bug #11188

discard "foo".bar()
