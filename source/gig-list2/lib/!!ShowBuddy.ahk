#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

; **********************************************************************************************************************
; * ShowBuddy FUNCTIONS
; **********************************************************************************************************************

; note this won't do anything unless it is explicitly called in the 'SEQUENCE OF ACTIONS TO RUN' section below
StartTrackInShowBuddy() 
{
    ; Activate ShowBuddy, hit space to start playing
    WinActivate, Show Buddy
    Send  {Space}
    return
}