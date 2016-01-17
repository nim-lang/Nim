import future, sequtils

proc any[T](list: varargs[T], pred: (T) -> bool): bool =
    for item in list:
        if pred(item):
            result = true
            break

proc contains(s: string, words: varargs[string]): bool =
  any(words, (word) => s.contains(word))