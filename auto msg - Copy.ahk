#Requires AutoHotkey v2.0

+l:: {
    fp := FileSelect("D", , "Select Folder with Files to Send")
    if (fp = "") {
        MsgBox("No folder selected.")
        return
    }

    if WinExist("Discord") {
        WinActivate("Discord")
        WinWaitActive("Discord",, 2)
    } else {
        MsgBox("Discord Web tab was not found!")
        return
    }

    Loop Files, fp "\*.*" {
        filePath := A_LoopFilePath

        Send("{Tab}")
        Sleep(100)

        SplitPath(filePath, &fname, &fdir)

        shell := ComObject("Shell.Application")
        folder := shell.NameSpace(fdir)
        item := folder.ParseName(fname)
        shell.NameSpace(0).CopyHere(item)
        Sleep(200)

        Send("^v")
        Sleep(500)
        Send("{Enter}")
        Sleep(1000) 
    }
}