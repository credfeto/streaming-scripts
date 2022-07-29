#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

; **********************************************************************************************************************
; * SCRIPTNAME TO SONGNAME FUNCTIONS
; **********************************************************************************************************************

GetSongName() 
{
    ; Work out what is being played from the filename of the script
    ; e.g. Comfortably Numb.Ahk
    SongNameLength := StrLen(A_ScriptName) - 4
    NewSongName := SubStr(A_ScriptName, 1, SongNameLength)

    return NewSongName
}
