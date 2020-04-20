---
name: Bug report
about: Have you found an unexpected behavior? Use this template.
title: Think about the title, twice
labels: ''
assignees: ''

---

Function `echo` outputs the wrong string.

### Example
```nim
echo "Hello World!"
```

### Current Output
```
Hola mundo!
```

### Expected Output
```
Hello World!
```

### Possible Solution

* In file xyz there is a call that might be the cause of it.

### Additional Information

* It was working in version a.b.c
* Issue #abc is related, but different because of ...
* This issue is blocking my project xyz

```
$ nim -v
Nim Compiler Version 0.1.2
```
