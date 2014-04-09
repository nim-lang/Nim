proc QuickSort(list: seq[int]): seq[int] =
    if len(list) == 0:
        return @[]
    var pivot = list[0]
    var left: seq[int] = @[]
    var right: seq[int] = @[]
    for i in low(list)..high(list):
        if list[i] < pivot:
            left.add(list[i])
        elif list[i] > pivot:
            right.add(list[i])
    result = QuickSort(left) & 
      pivot & 
      QuickSort(right)
    
proc echoSeq(a: seq[int]) =
    for i in low(a)..high(a):
        echo(a[i])

var
    list: seq[int]
        
list = QuickSort(@[89,23,15,23,56,123,356,12,7,1,6,2,9,4,3])
echoSeq(list)


