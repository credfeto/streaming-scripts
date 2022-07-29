#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

 **********************************************************************************************************************
; * Reaper FUNCTIONS
; **********************************************************************************************************************

; note this won't do anything unless it is explicitly called in the 'SEQUENCE OF ACTIONS TO RUN' section below
StartTrackInCubase() {
    ; Activate Reaper, hit space to start playing
	Sleep 140
	WinActivate, Reaper
	Send  {Space}
	return
}