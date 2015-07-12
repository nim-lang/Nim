discard """
  output: '''a1 5
a2 10
a1 3
a1 1
a2 8
a2 6
a2 4
a2 2'''
  disabled: "true"
"""

import os, strutils, times, algorithm


type TaskFn = iterator (): float

type Task = object
    coro: TaskFn
    next_run: float


type Scheduler = object
    tasks: seq[Task]


proc newScheduler(): Scheduler =
    var s = Scheduler()
    s.tasks = @[]
    return s


proc start(this: var Scheduler, task: TaskFn) =
    var t = Task()
    t.coro = task
    t.next_run = 0.0
    this.tasks.add(t)


proc run(this: var Scheduler) =
    while this.tasks.len > 0:
        var dead: seq[int] = @[]
        for i in this.tasks.low..this.tasks.high:
            var task = this.tasks[i]
            if finished(task.coro):
                dead.add(i)
                continue
            if task.next_run <= epochTime():
                task.next_run = task.coro() + epochTime()
            this.tasks[i] = task
        for i in dead:
            this.tasks.delete(i)
        if this.tasks.len > 0:
            sort(this.tasks, proc (t1: Task, t2: Task): int = cmp(t1.next_run, t2.next_run))
            sleep(int((this.tasks[0].next_run - epochTime()) * 1000))


iterator a1(): float {.closure.} =
    var k = 5
    while k > 0:
        echo "a1 $1" % [$k]
        dec k, 2
        yield 0.5


iterator a2(): float {.closure.} =
    var k = 10
    while k > 0:
        echo "a2 $1" % [$k]
        dec k, 2
        yield 1.5


var sched = newScheduler()
sched.start(a1)
sched.start(a2)
sched.run()
