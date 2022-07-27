#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; **********************************************************************************************************************
; * CONFIGURATION
; **********************************************************************************************************************

; Where is the folder that contain the files for now playing and played (Accessing ObsDirectoryStudio on the OBS Machine)
; if the same machine they should be the same

ObsDirectory := "C:\Currently Playing"

; Where is the folder that contains files for now playing and played on the studio machine (or video laptop)
; if remote should use the drive letter mapping e.g. O:\Currently Playing OR a network path to the share \\STUDIO-PC\C\Currently Playing

ObsDirectoryStudio := "C:\Currently Playing"

; Where the videos file exists under BOTH ObsDirectory and ObsDirectoryStudio
; e.g. if ObsDirectory is C:\Playing and ObsDirectoryStudio is N:\Playing the Videos folder should be pointing to the
;    same folder C:\Playing\Videos and N:\Playing\Videos
; This folder should contain a m3u file for any track that has video 
; e.g. "Comfortably Numb.ahk" should have "Comfortably Numb.m3u" in the folder

VideosDirectoryName := "Videos"

; VLC Setup
; Open Preferences: Tools -> Preferences
; Switch Show settings at bottom left to "All"
; Find "Main Interfaces" in tree,  Select "Web"
; Under "Main Interfaces" in tree go to "Lua" and in the the 'Lua HTTP' section set a password e.g. vlcremote

; Where is the VLC instance located on the network:
; if to the same machine use localhost to different machine, use name or (for speed IP Address):

VlcHostAndPort := "localhost:8080"

; VLC Username: Normally blank

VlcUsername := ""

; VLC Password - should be the same as what is set in 'Lua HTTP' Password

VlcPassword := "vlcremote"

; Whether to start playlist using local exe - this disables stopping VLC and clearing any existing playlist when set to true

VlcLocal := false

; VLC Executable to run when VlcLocal is set to true

VlcLocalExe := "C:\Program Files\VideoLAN\VLC\vlc.exe"


; **********************************************************************************************************************
; * SCRIPTNAME TO SONGNAME FUNCTIONS
; **********************************************************************************************************************

GetSongName() {
    ; Work out what is being played from the filename of the script
    ; e.g. Comfortably Numb.Ahk
    SongNameLength := StrLen(A_ScriptName) - 4
    NewSongName := SubStr(A_ScriptName, 1, SongNameLength)

    return NewSongName
}

; **********************************************************************************************************************
; * SONG LIST UPDATE FUNCTIONS
; **********************************************************************************************************************
IsSameAsLastSong(LastSong, NewSong) {
    ; Split the file into an array of lines we go through
    lastSongsList := StrSplit(LastSong, "`n")

    ; Find the first non-blank entry in the list and check its name against the new song name
    Match := false
    For index, entry in lastSongsList {
        EntrySongName := Trim(entry, "`r")
        if(StrLen(EntrySongName) != 0) {
            if (EntrySongName == NewSong) {
                ; Last song was the same as the new song - don't do any more
                Match := true
	        }

	        break
        }
    }

    return %Match%
}

UpdateNowPlaying(SongTrackingDirectory, NewSongName) {
    NowPlaying := SongTrackingDirectory . "\NowPlaying.txt"
    Played := SongTrackingDirectory . "\Played.txt"

    ; Update the last played file with the name of the song, with the latest song at the top of the file
    if FileExist(Played)
    {
        FileRead, LastPlayedSongs, %Played%
	
        if !IsSameAsLastSong(LastPlayedSongs, NewSongName) {

            ; Append the song to the top of the file (delete the file, write the new song followed by the old one)
            FileDelete, %Played%
            FileAppend, %NewSongName%`n, %Played%
            FileAppend, %LastPlayedSongs%, %Played%
	    }	
    }
    else
    {
        ; No song list, create a file with the song name in it.
        FileDelete, %Played%
        FileAppend, %NewSongName%, %Played%
    }

    ; Update the currently playing file with the song name
    FileDelete, %NowPlaying%
    FileAppend, %NewSongName%, %NowPlaying%

    return
}

; **********************************************************************************************************************
; * VLC FUNCTIONS BEGIN
; **********************************************************************************************************************

b64Encode(string) {
    ; BASIC Authentication requires BASE 64 encoding
    VarSetCapacity(bin, StrPut(string, "UTF-8")) && len := StrPut(string, &bin, "UTF-8") - 1
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", 0, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    VarSetCapacity(buf, size << 1, 0)
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", &buf, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    return StrGet(&buf)
}

LC_UriEncode(Uri, RE="[0-9A-Za-z]") {
    ; Make sure parameters are encoded
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	While Code := NumGet(Var, A_Index - 1, "UChar")
		Res .= (Chr:=Chr(Code)) ~= RE ? Chr : Format("%{:02X}", Code)
	Return, Res
}

StartVideoInVlcLocal(LocalDirectory, CommonVideosDirectory, SongName) {
   LocalFileName := LocalDirectory . "\" . CommonVideosDirectory . "\" . SongName . ".m3u"

    ; Check to see if there is a playlist called <SongName>.m3u in the LocalDirectory
    if Not FileExist(LocalFileName) {
        ; File doesn't exist
        return
    }

    Run, VlcLocalExe, LocalFileName
}
   
StartVideoInVlcRemote(HostAndPort, UserName, Password, RemoteDirectory, LocalDirectory, CommonVideosDirectory, SongName) {
    
    ; Define local and remote filenames - they should both resolve to the same file
    RemoteFileName := RemoteDirectory . "\" . CommonVideosDirectory . "\" . SongName . ".m3u"
    LocalFileName := LocalDirectory . "\" . CommonVideosDirectory . "\" . SongName . ".m3u"

    ; Check to see if there is a playlist called <SongName>.m3u in the RemoteDirectory
    if Not FileExist(RemoteFileName) {
        ; File doesn't exist
        return
    }

    ; Check to see if there is a playlist called <SongName>.m3u in the LocalDirectory
    if Not FileExist(LocalFileName) {
        ; File doesn't exist
        return
    }

    ; Generate BASIC AUth token
    auth := b64Encode(UserName . ":" . Password)

    ; URI Encode the filename so that its properly parsable by the http request
    FileToPlay := LC_UriEncode(LocalFileName)

    ; Build the play playlist command
    command := "http://" . HostAndPort . "/requests/status.xml?command=in_play&input=" . FileToPlay

    ; Send the request to VLC's web server
    oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open("GET", command, false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    oWhr.SetRequestHeader("Authorization", "Basic " . auth)
    oWhr.Send()
}

StartVideoInVlc(HostAndPort, UserName, Password, RemoteDirectory, LocalDirectory, CommonVideosDirectory, SongName) {
    global VlcLocal
    if VlcLocal {
    	StartVideoInVlcLocal(LocalDirectory, CommonVideosDirectory, SongName)
    } else {
        StartVideoInVlcRemote(HostAndPort, UserName, Password, RemoteDirectory, LocalDirectory, CommonVideosDirectory, SongName) 
    }
}

StopVideoInVlc(HostAndPort, UserName, Password) {
    global VlcLocal
    if VlcLocal {
    
    }
    
    ; Stop playing whatever may be playing

   ; Generate BASIC AUth token
    auth := b64Encode(UserName . ":" . Password)

    ; Build the stop play playlist command
    command := "http://" . HostAndPort . "/requests/status.xml?command=pl_stop"

    ; Send the request to VLC's web server
    oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open("GET", command, false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    oWhr.SetRequestHeader("Authorization", "Basic " . auth)
    oWhr.Send()
}

ClearPlaylistInVlc(HostAndPort, UserName, Password) {
    global VlcLocal
    if VlcLocal {
    	return
    }
    
    ; Clear the playlist

   ; Generate BASIC AUth token
    auth := b64Encode(UserName . ":" . Password)

    ; Build the clear playlist command
    playPLaylistCommand := "http://" . HostAndPort . "/requests/status.xml?command=pl_empty"

    ; Send the request to VLC's web server
    oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open("GET", playPLaylistCommand, false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    oWhr.SetRequestHeader("Authorization", "Basic " . auth)
    oWhr.Send()
}

; **********************************************************************************************************************
; * VLC FUNCTIONS END
; **********************************************************************************************************************


; **********************************************************************************************************************
; * ShowBuddy FUNCTIONS
; **********************************************************************************************************************

StartTrackInShowBuddy() {
	; Activate ShowBuddy, hit space to start playing
    WinActivate, Show Buddy
	Send  {Space}
	return
}

; **********************************************************************************************************************
; * Cubase FUNCTIONS
; **********************************************************************************************************************

StartTrackInCubase() {
    ; Activate Cubase, hit space to start playing
	Sleep 140
	WinActivate, Cubase
	Send  {Space}
	return
}


; **********************************************************************************************************************
; **********************************************************************************************************************
; **********************************************************************************************************************
; *                                                       END OF FUNCTIONS                                             *
; **********************************************************************************************************************
; **********************************************************************************************************************
; **********************************************************************************************************************


; **********************************************************************************************************************
; * SEQUENCE OF ACTIONS TO RUN
; **********************************************************************************************************************

StopVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword)
ClearPlaylistInVlc(VlcHostAndPort, VlcUsername, VlcPassword)
SongName := GetSongName()
UpdateNowPlaying(ObsDirectory, SongName)
StartVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword, ObsDirectory, ObsDirectoryStudio, VideosDirectoryName, SongName)

; StartTrackInCubase()
; StartTrackInShowBuddy()


return
