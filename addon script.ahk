; ==============================================================================
; Script Name:    NFSMW Auto-Importer (Direct Control Folder Injector)
; Target Version: AutoHotkey v2.0+ ONLY
; Hotkeys:        Ctrl + F8 (^F8)        = Open Importer Menu
;                 Ctrl + Shift + C       = Tool to find cursor coordinates
;                 Esc                    = Stop / Kill Script
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

if !A_IsAdmin
{
    try Run('*RunAs "' . A_ScriptFullPath . '"')
    ExitApp()
}

SetKeyDelay(100, 50)

; ==============================================================================
; CONFIGURATION & STATE
; ==============================================================================

global GameDir    := "C:\Users\j435k\Desktop\nfs\NEED FOR SPEED MOST WANTED"
global VltEdPath  := "C:\Users\j435k\Desktop\nfs\NEED FOR SPEED MOST WANTED\MODS\NFS-VltEd.exe"
global BinaryPath := "C:\Users\j435k\Desktop\nfs\NEED FOR SPEED MOST WANTED\MODS\Binary_v2.8.3\Binary.exe"

global BinaryUserModeX := 200
global BinaryUserModeY := 250

global LastVltScript    := ""
global LastBinaryScript := ""

global DialogWaitSec := 45    ; Binary can take a while between dialog steps

; ==============================================================================
; MAIN HOTKEYS & GUI MENU
; ==============================================================================

^F8::ShowImporterMenu()

ShowImporterMenu()
{
    menuGui := Gui("+AlwaysOnTop", "NFSMW Mod Importer")
    menuGui.SetFont("s10", "Segoe UI")

    menuGui.Add("Text", "w320 Center", "Select Import Action:")

    btnBoth   := menuGui.Add("Button", "w320 h35", "1. Run Both (VLTEd + Binary)")
    btnVlt    := menuGui.Add("Button", "w320 h35", "2. Run VLTEd Only (.nfsms)")
    btnBinary := menuGui.Add("Button", "w320 h35", "3. Run Binary Only (.end)")
    btnCancel := menuGui.Add("Button", "w320 h30", "Cancel")

    btnBoth.OnEvent("Click", (*) => (menuGui.Destroy(), ExecutePipeline("BOTH")))
    btnVlt.OnEvent("Click", (*) => (menuGui.Destroy(), ExecutePipeline("VLT_ONLY")))
    btnBinary.OnEvent("Click", (*) => (menuGui.Destroy(), ExecutePipeline("BINARY_ONLY")))
    btnCancel.OnEvent("Click", (*) => menuGui.Destroy())

    menuGui.Show()
}

ExecutePipeline(mode)
{
    global LastVltScript, LastBinaryScript, DialogWaitSec

    vltScript := ""
    binaryScript := ""

    if (mode == "BOTH" || mode == "VLT_ONLY")
    {
        if (LastVltScript != "")
        {
            res := MsgBox("Reuse last .nfsms file?`n`n" . LastVltScript, "Cached Script Found", "YesNo Icon?")
            if (res == "Yes")
                vltScript := LastVltScript
        }

        if (vltScript == "")
        {
            vltScript := FileSelect(3, , "Select VLTEd Mod Script (.nfsms)", "VLT Script (*.nfsms)")
            if (vltScript == "")
                return
            LastVltScript := vltScript
        }
    }

    if (mode == "BOTH" || mode == "BINARY_ONLY")
    {
        if (LastBinaryScript != "")
        {
            res := MsgBox("Reuse last .end file?`n`n" . LastBinaryScript, "Cached Script Found", "YesNo Icon?")
            if (res == "Yes")
                binaryScript := LastBinaryScript
        }

        if (binaryScript == "")
        {
            binaryScript := FileSelect(3, , "Select Binary Endscript (*.end)", "Binary Endscript (*.end)")
            if (binaryScript == "")
                return
            LastBinaryScript := binaryScript
        }
    }

    ; --- STAGE 1: VLTED ---
    if (mode == "BOTH" || mode == "VLT_ONLY")
    {
        try
        {
            RunVltEdImport(vltScript)
            if (mode == "BOTH")
                TimedMsgBox("VLTEd script imported!`nProceeding to Binary in 3 seconds...", "VLTEd Status", 3)
            else
                TimedMsgBox("VLTEd script imported successfully!", "VLTEd Status", 5)
        }
        catch as err
        {
            ToolTip()
            MsgBox("VLTEd Step Failed!`n`nReason: " . err.Message, "Import Error", 16)
            return
        }
    }

    ; --- STAGE 2: BINARY ---
    if (mode == "BOTH" || mode == "BINARY_ONLY")
    {
        try
        {
            RunBinaryImport(binaryScript)
            TimedMsgBox("Binary script imported successfully!`nTask completed!", "Binary Status", 5)
        }
        catch as err
        {
            ToolTip()
            MsgBox("Binary Step Failed!`n`nReason: " . err.Message, "Import Error", 16)
            return
        }
    }

    UpdateStatus("Selection processing completed!")
    SetTimer(() => ToolTip(), -5000)
}

^+c::
{
    MouseGetPos(&mx, &my, &hwnd)
    MsgBox("Screen coordinates:`nX: " . mx . "`nY: " . my . "`n`nWindow class under cursor: " . WinGetClass(hwnd)
        . "`n`n(Binary clicks use Window-relative coords.)", "Coord Picker")
}

Esc::ExitApp()

; ==============================================================================
; CORE HELPERS
; ==============================================================================

UpdateStatus(text)
{
    ToolTip("STATUS: " . text, 20, 20)
}

TimedMsgBox(message, title, seconds)
{
    ToolTip()
    MsgBox(message, title, "64 T" . seconds)
}

; Polls until the window handle is gone. Returns true if it closed in time.
WaitDialogClosed(dlgHwnd, seconds)
{
    deadline := A_TickCount + (seconds * 1000)
    while WinExist(dlgHwnd) && A_TickCount < deadline
        Sleep(100)
    return !WinExist(dlgHwnd)
}

; ==============================================================================
; DIALOG INJECTION HELPERS
; ==============================================================================

SelectFileViaKeyboard(filePath, expected := "ahk_class #32770")
{
    global DialogWaitSec

    if !WinWait(expected, , DialogWaitSec)
        throw Error("Timed out waiting for File Selection Dialog.")

    dlgHwnd := WinExist(expected)
    WinActivate(dlgHwnd)
    WinWaitActive(dlgHwnd, , 5)
    Sleep(500)

    ; Method A: write path to the File name edit, click Open
    try
    {
        ControlSetText(filePath, "Edit1", dlgHwnd)
        Sleep(400)
        ControlClick("Button1", dlgHwnd)
        if WaitDialogClosed(dlgHwnd, 5)
            return
    }

    ; Method B: classic keyboard fallback (Alt+N focuses File name field)
    WinActivate(dlgHwnd)
    Send("!n")
    Sleep(400)
    A_Clipboard := filePath
    ClipWait(2)
    Send("^v{Enter}")

    if !WaitDialogClosed(dlgHwnd, 5)
        throw Error("File dialog did not accept the path:`n" . filePath)
}

SelectDirectoryViaControl(targetPath, expected := "ahk_class #32770")
{
    global DialogWaitSec

    if !WinWait(expected, , DialogWaitSec)
        throw Error("Timed out waiting for Directory Selection Window.")

    dlgHwnd := WinExist(expected)
    WinActivate(dlgHwnd)
    WinWaitActive(dlgHwnd, , 5)
    Sleep(600)

    ; ===== Method A: new-style picker — path edit + OK =====
    try
    {
        ControlSetText(targetPath, "Edit1", dlgHwnd)
        Sleep(400)
        ControlClick("Button1", dlgHwnd)
        if WaitDialogClosed(dlgHwnd, 4)
            return
        WinActivate(dlgHwnd)
        Send("{Enter}")
        if WaitDialogClosed(dlgHwnd, 4)
            return
    }

    ; ===== Method B: address bar (Vista+ style dialogs) =====
    WinActivate(dlgHwnd)
    Send("!d")
    Sleep(400)
    A_Clipboard := targetPath
    ClipWait(2)
    Send("^v{Enter}")
    Sleep(800)
    Send("{Enter}")
    if WaitDialogClosed(dlgHwnd, 4)
        return

    ; ===== Method C: raw keystrokes into the edit box =====
    WinActivate(dlgHwnd)
    try ControlSetText("", "Edit1", dlgHwnd)
    SendText(targetPath)
    Send("{Enter}")
    if WaitDialogClosed(dlgHwnd, 4)
        return

    ; ===== Method D: classic Browse-For-Folder tree keyboard navigation =====
    ; (Binary's dialog has no edit box — we walk the tree: This PC > C: > ...)
    try
    {
        ControlFocus("SysTreeView321", dlgHwnd)
        Sleep(400)
        Send("{Home}")
        Sleep(400)

        ; Split path into segments, skipping the drive letter (e.g. "C:")
        segs := []
        for part in StrSplit(targetPath, "\")
            if (part != "" && !InStr(part, ":"))
                segs.Push(part)

        ; Top of tree -> "This PC" -> expand -> drive letter -> expand
        SendInput("t")                                  ; jumps to "This PC"
        Sleep(500)
        Send("{Right}")                                 ; expand This PC
        Sleep(500)
        SendInput(SubStr(targetPath, 1, 1))      ; e.g. "c" -> C: drive
        Sleep(500)
        Send("{Right}")                                 ; expand the drive
        Sleep(500)

        for i, seg in segs
        {
            SendInput(SubStr(seg, 1, 4))         ; enough chars to be unique
            Sleep(600)
            if (i < segs.Length)
                Send("{Right}")                         ; expand this folder
            Sleep(400)
        }

        Send("{Enter}")                                 ; confirm selected folder
        if WaitDialogClosed(dlgHwnd, 4)
            return
        ControlClick("Button1", dlgHwnd)
        if WaitDialogClosed(dlgHwnd, 4)
            return
    }

    ; ===== Last resort: ask you to finish it manually =====
    MsgBox("Automatic folder selection failed.`n`nPlease select the game folder manually in the open dialog:`n`n" . targetPath
        . "`n`nThen click OK here.", "Manual Help Needed", "48")
    if WaitDialogClosed(dlgHwnd, 60)
        return

    throw Error("Could not set the game directory for Binary.")
}

ResolveBinaryInstallPopup(expected := "ahk_class #32770", seconds := 10)
{
    if !WinWait(expected, , seconds)
        return

    popupHwnd := WinExist(expected)
    WinActivate(popupHwnd)
    WinWaitActive(popupHwnd, , 5)
    Sleep(500)

    ; Prefer affirmative buttons, then the first button, then plain Enter
    for ctl in ["&Yes", "&OK", "Button1"]
    {
        try
        {
            ControlClick(ctl, popupHwnd)
            Sleep(600)
            if WaitDialogClosed(popupHwnd, 4)
                return
        }
    }

    Send("{Enter}")
    WaitDialogClosed(popupHwnd, 4)
}

; ==============================================================================
; AUTOMATION LOGIC
; ==============================================================================

RunVltEdImport(scriptPath)
{
    global GameDir, VltEdPath, DialogWaitSec

    if !FileExist(VltEdPath)
        throw Error("VLTEd executable not found at path:`n" . VltEdPath)

    UpdateStatus("Launching NFS-VltEd...")
    SplitPath(VltEdPath, , &vltDir)
    Run(VltEdPath, vltDir, , &vltPID)

    if !WinWait("ahk_pid " . vltPID, , 20)
        throw Error("Timed out waiting for VLTEd to launch.")

    vltHwnd := "ahk_pid " . vltPID
    WinRestore(vltHwnd)
    WinActivate(vltHwnd)
    WinWaitActive(vltHwnd, , 5)
    Sleep(1000)

    UpdateStatus("VLTEd: Selecting Directory...")
    Send("!f")
    Sleep(500)
    Send("o")

    SelectDirectoryViaControl(targetPath, expected := "ahk_class #32770")
}    
{
    global DialogWaitSec

    if !WinWait(expected, , DialogWaitSec)
        throw Error("Timed out waiting for Directory Selection Window.")

    dlgHwnd := WinExist(expected)
    WinActivate(dlgHwnd)
    WinWaitActive(dlgHwnd, , 5)
    Sleep(600)

    ; --- Inspect the dialog so we pick the RIGHT single method ---
    hasEdit := false, hasTree := false
    try
{
    ControlGetPos(,,,, "Edit1", dlgHwnd)
    hasEdit := true
}
catch
{
    ; Optional: handle error or do nothing
}

try
{
    ControlGetPos(,,,, "SysTreeView321", dlgHwnd)
    hasTree := true
}
catch
{
    ; Optional: handle error or do nothing
} 

    ; ===== Path 1: dialog has a text field (VLTEd, new-style pickers) =====
    if hasEdit
    {
        try
        {
            ControlSetText(targetPath, "Edit1", dlgHwnd)
            Sleep(400)

            ; Confirm the edit REALLY contains our path (guards against
            ; Edit1 being an inline "New Folder" rename box)
            if (ControlGetText("Edit1", dlgHwnd) == targetPath)
            {
                WinActivate(dlgHwnd)
                Send("{Enter}")          ; default button = OK. Never ControlClick Button1.
                if WaitDialogClosed(dlgHwnd, 5)
                    return
            }
        }
    }

    ; ===== Path 2: classic "Browse For Folder" tree walk (Binary) =====
    if hasTree
    {
        try
        {
            ControlFocus("SysTreeView321", dlgHwnd)
            Sleep(400)
            if (ControlGetFocus(dlgHwnd) != "SysTreeView321")
                throw Error("Could not focus tree")   ; typing won't go anywhere else

            Send("{Home}")
            Sleep(500)

            segs := []
            for part in StrSplit(targetPath, "\")
                if (part != "" && !InStr(part, ":"))
                    segs.Push(part)

            SendInput("t")                            ; jumps to "This PC"
            Sleep(700)
            Send("{Right}")
            Sleep(700)
            SendInput(SubStr(targetPath, 1, 1))       ; drive letter, e.g. "c"
            Sleep(700)
            Send("{Right}")
            Sleep(700)

            for i, seg in segs
            {
                SendInput(SubStr(seg, 1, 4))
                Sleep(800)
                if (i < segs.Length)
                    Send("{Right}")
                Sleep(500)
            }

            Send("{Enter}")
            if WaitDialogClosed(dlgHwnd, 5)
                return
        }
    }

    ; ===== Manual fallback =====
    MsgBox("Automatic folder selection failed.`n`nPlease select this folder manually in the open dialog:`n`n"
        . targetPath . "`n`nThen click OK here.", "Manual Help Needed", "48")
    if WaitDialogClosed(dlgHwnd, 90)
        return

    throw Error("Could not set the game directory.")
}
{

    UpdateStatus("Loading Database...")
    Sleep(3000)

    UpdateStatus("Opening Script -> " . scriptPath)
    WinActivate(vltHwnd)
    Send("^i")
    SelectFileViaKeyboard(scriptPath)

    UpdateStatus("Applying Script...")
    Sleep(1500)
    Send("{Enter}")
    Sleep(1500)

    UpdateStatus("Saving VLTEd Changes...")
    WinActivate(vltHwnd)
    Send("^s")
    Sleep(3000)

    UpdateStatus("Closing VLTEd...")
    WinClose(vltHwnd)
    WinWaitClose(vltHwnd, , 5)
}

RunBinaryImport(scriptPath)
{
    global GameDir, BinaryPath, BinaryUserModeX, BinaryUserModeY, DialogWaitSec

    if !FileExist(BinaryPath)
        throw Error("Binary executable not found at path:`n" . BinaryPath)

    UpdateStatus("Launching Binary as Admin...")
    SplitPath(BinaryPath, , &binDir)

    Run('*RunAs "' . BinaryPath . '"', binDir, , &binPID)

    if !WinWait("ahk_pid " . binPID, , 20)
        throw Error("Timed out waiting for Binary to launch.")

    binHwnd := "ahk_pid " . binPID
    binDlg  := "ahk_class #32770 ahk_pid " . binPID    ; only Binary's own dialogs

    ; ---- Hedge: Binary may ask for the game directory at STARTUP ----
    if WinWait(binDlg, , 8)
    {
        UpdateStatus("Binary: game directory prompt (startup)...")
        SelectDirectoryViaControl(GameDir, binDlg)
        Sleep(1000)
    }

    WinRestore(binHwnd)
    WinActivate(binHwnd)
    WinWaitActive(binHwnd, , 10)
    Sleep(1500)

    CoordMode("Mouse", "Window")

    UpdateStatus("Binary: Clicking 'User Mode'...")
    MouseMove(BinaryUserModeX, BinaryUserModeY, 10)
    Sleep(400)
    Click(BinaryUserModeX, BinaryUserModeY)
    Sleep(1500)

    UpdateStatus("Binary: Inputting .end File...")
    SelectFileViaKeyboard(scriptPath, binDlg)   ; now VERIFIES the dialog closed

    ; ---- Game directory prompt (appears after .end is parsed) ----
    UpdateStatus("Binary: checking for game directory prompt...")
    if WinWait(binDlg, , 30)
        SelectDirectoryViaControl(GameDir, binDlg)

    UpdateStatus("Binary: Resolving Install Prompt #1...")
    ResolveBinaryInstallPopup(binDlg)
    UpdateStatus("Binary: Resolving Install Prompt #2...")
    ResolveBinaryInstallPopup(binDlg)

    UpdateStatus("Binary: Finalizing installation & saving...")
    Sleep(2000)
    Send("^s")
    Sleep(2000)

    UpdateStatus("Closing Binary...")
    if !WinWaitClose(binHwnd, , 15)
        WinClose(binHwnd)
}