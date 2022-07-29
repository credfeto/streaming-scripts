#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

; **********************************************************************************************************************
; * OBS FUNCTIONS
; **********************************************************************************************************************

; note this won't do anything unless it is explicitly called in the 'SEQUENCE OF ACTIONS TO RUN' section below
PutOBSonTop() {
    ; Put OBS on top for BOMEs Scene Changes
    SetTitleMatchMode, 2
    WinActivate, OBS
}