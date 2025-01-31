#include ImagePut.ahk
#singleinstance force

; This script runs on both AutoHotkey v1 and v2.
hwnd := ImagePutWindow("https://picsum.photos/500", "Thank you for trying ImagePut ♥")

; Copy to the clipboard.
clip := ImagePutClipboard("https://picsum.photos/500")

; Save images.
file1 := ImagePutFile(hwnd)
file2 := ImagePutFile(clip)