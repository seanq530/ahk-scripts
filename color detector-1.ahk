CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"
loop {
    MouseGetPos &x, &y
    ToolTip PixelGetColor(x,y), x + 10,y + 1

    sleep 5
}
+c::{
    MouseGetPos &x, &y
    rcolor := PixelGetColor(x, y)
    ccolor := SubStr(rcolor, 3)
    A_Clipboard := ccolor
    ToolTip "copied: " ccolor, x + 10,y + 3
    Sleep 1000
}
