type ReplyQueue*[T] = object
  marker: T
  replies*: seq[string]
  batches*: seq[seq[string]]

proc enqueue*[T](queue: var ReplyQueue[T], reply: sink string) =
  queue.replies.add reply

proc enqueueAndReturn*[T](queue: var ReplyQueue[T], reply: sink string): string =
  queue.replies.add reply
  reply

proc enqueueBatch*[T](queue: var ReplyQueue[T], replies: sink seq[string]) =
  queue.batches.add replies
