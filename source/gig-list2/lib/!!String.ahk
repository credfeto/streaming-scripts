#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

 **********************************************************************************************************************
; * String FUNCTIONS
; **********************************************************************************************************************

ToLower(text) {
    
	StringLower, lowerCase, text
	return lowerCase
}

IsEnabled(option) {

	if(ToLower(option) == "true") {
		return 1
	}

	return 0
}