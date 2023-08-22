
# the module being the same name as the proc
# is a requirement to trigger the error
import mmodule_same_proc_client

proc bar*[T](foo: T): bool = foo.mmodule_same_proc_client()
