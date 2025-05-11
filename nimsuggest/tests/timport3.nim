import fixtu#[!]# #Suggest folders
import nimpre#[!]# #Can suggest from search path (see cmd arg below)
discard """
$nimsuggest --tester --v4 --maxresults:1 --path:nimpretty $file
>sug $1
sug;;skModule;;fixtures;;;;fixtures;;1;;0;;"";;100;;None
>sug $2
sug;;skModule;;nimpretty;;;;nimpretty;;2;;0;;"";;100;;None
"""