+r::
InputBox, n, Input name dialogue, please enter your name, hide,100,100, , , locale, 7
switch ErrorLevel
{
case 0:
MsgBox, your name is %n% 
case 1: 
MsgBox, you clicked cancel 
case 2:
MsgBox, timeout! 
}
return