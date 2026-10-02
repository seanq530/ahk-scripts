+d:: 
arr := ["alpah","beta","charlie"]
arr.Push("delta")
loop, read, C:\Users\j435k\Desktop\data.txt
    arr.Push(A_LoopReadLine)
for index, element in arr 
MsgBox % element . " is number " . index

return 