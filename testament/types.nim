import specs, tables

type
  Category* = distinct string

  Generator* = proc(): seq[Bundle] ## \
  ## Generators look for tests to run
  ## TODO: this could be an iterator, but compiler is too buggy at the time of
  ##       writing

  RunFilter* = proc(r: Instance): bool

  TestAction* = enum
    actionCompile = "compile"
    actionRun = "run"
    actionRunC = "runc"
    actionReject = "reject"
    actionRunNoSpec = "runNoSpec"
    actionExec = "exec"

  ResultEnum* = enum
    reNimcCrash,     # nim compiler seems to have crashed
    reMsgsDiffer,       # error messages differ
    reFilesDiffer,      # expected and given filenames differ
    reLinesDiffer,      # expected and given line numbers differ
    reOutputsDiffer,
    reExitcodesDiffer,
    reInvalidPeg,
    reCodegenFailure,
    reCodeNotFound,
    reExeNotFound,
    reInstallFailed     # package installation failed
    reBuildFailed       # package building failed
    reIgnored,          # test is ignored
    reSuccess           # test was successful

  Target* = enum
    targetC = "C"
    targetCpp = "C++"
    targetObjC = "ObjC"
    targetJS = "JS"

  Spec* = object ## Template from which test instances can be generated
    action*: TestAction
    file*, cmd*: string
    outp*: string
    line*, column*: int
    tfile*: string
    tline*, tcolumn*: int
    exitCode*: int
    msg*: string
    ccodeCheck*: string
    maxCodeSize*: int
    res*: ResultEnum
    substr*, sortoutput*: bool
    targets*: set[Target] ## Each target will generate a separate instance
    nimout*: string

  Instance* = object # A single instance of a test, after expanding test matrix
    id*: string
    cat*: Category
    filename*: string
    action*: TestAction
    target*: Target
    options*: string
    expected*: TestData
    cmd*: string
    sortoutput*: bool

  Bundle* = seq[Instance] ## Instances within a bundle are run serially, even \
                          ## parallel running is enabled

  TestData* = object ## Expected or actual test data
    options*: string
    file*: string
    outp*: string
    line*, column*: int
    tfile*: string
    tline*, tcolumn*: int
    exitCode*: int
    msg*: string
    ccodeCheck*: string
    maxCodeSize*: int
    res*: ResultEnum
    substr*: bool
    nimout*: string

  Result* = object
    inst*: Instance
    given*: TestData

    expectedMsg*, givenMsg*: string

    startTime*: float
    endTime*: float
