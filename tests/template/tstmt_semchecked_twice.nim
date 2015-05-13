
# bug #2585

type
    RenderPass = object
       state: ref int

    RenderData* = object
        fb: int
        walls: seq[RenderPass]

    Mat2 = int
    Vector2[T] = T
    Pixels=int

template use*(fb: int, st: stmt) : stmt =
    echo "a ", $fb
    st
    echo "a ", $fb

proc render(rdat: var RenderData; passes: var openarray[RenderPass]; proj: Mat2;
            indexType = 1) =
    for i in 0 .. <len(passes):
        echo "blah ", repr(passes[i])



proc render2*(rdat: var RenderData; screenSz: Vector2[Pixels]; proj: Mat2) =
    use rdat.fb:
        render(rdat, rdat.walls, proj, 1)
