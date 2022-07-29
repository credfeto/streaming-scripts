#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; **********************************************************************************************************************
; * CONFIGURATION
; **********************************************************************************************************************

; Where is the folder that contain the files for now playing and played
; if the same machine they should be the same

PlaylistDirectory := "C:\Currently Playing"

; Where the videos files exists
; This folder should contain a m3u file for any track that has video 
; e.g. "Comfortably Numb.ahk" should have "Comfortably Numb.m3u" in the folder

VideosDirectoryName := "C:\Currently Playing\Videos"

; VLC Setup
; Open Preferences: Tools -> Preferences
; Switch Show settings at bottom left to "All"
; Find "Main Interfaces" in tree,  Select "Web"
; Under "Main Interfaces" in tree go to "Lua" and in the the 'Lua HTTP' section set a password e.g. vlcremote

; Notes:
; * VLC should be running before this script is executed
;
; * This script will not work, if it cannot talk to VLC.  To test this out on the machine that VLC is running on go to:
;
;             http://127.0.0.1:8080
;
;       You should be prompted for a username and password, leave the username password and set the password to what is set in VLC and
;       it will show a 'mobile interface'
; 
;       If VLC is on another machine then you need additionally from where this script is running go to:
;
;             http://RemoteMachineNameOrIp:8080
;
;       e.g: http://studio-pc:8080



; Where is the VLC instance located on the network:
; note that the port by default is 8080

VlcHostAndPort := "127.0.0.1:8080"

; VLC Username: Normally blank

VlcUsername := ""

; VLC Password - should be the same as what is set in 'Lua HTTP' Password

VlcPassword := "vlcremote"


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

; **********************************************************************************************************************
; * SONG LIST UPDATE FUNCTIONS
; **********************************************************************************************************************

IsSameAsLastSong(LastSong, NewSong) 
{
    ; Split the file into an array of lines we go through
    lastSongsList := StrSplit(LastSong, "`n")

    ; Find the first non-blank entry in the list and check its name against the new song name
    Match := false
    For index, entry in lastSongsList {
        EntrySongName := Trim(entry, "`r")
        if(StrLen(EntrySongName) != 0) {
            if (EntrySongName == NewSong) 
            {
                ; Last song was the same as the new song - don't do any more
                Match := true
	        }

	        break
        }
    }

    return %Match%
}

UpdateNowPlaying(SongTrackingDirectory, NewSongName) 
{
    NowPlaying := SongTrackingDirectory . "\NowPlaying.txt"
    Played := SongTrackingDirectory . "\Played.txt"

    ; Update the last played file with the name of the song, with the latest song at the top of the file
    if FileExist(Played)
    {
        FileRead, LastPlayedSongs, %Played%
	
        if !IsSameAsLastSong(LastPlayedSongs, NewSongName) 
        {

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

Base64Encode(string) 
{
    size := 0

    ; BASIC Authentication requires BASE 64 encoding
    VarSetCapacity(bin, StrPut(string, "UTF-8")) && len := StrPut(string, &bin, "UTF-8") - 1
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", 0, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    VarSetCapacity(buf, size << 1, 0)
    if !(DllCall("crypt32\CryptBinaryToString", "ptr", &bin, "uint", len, "uint", 0x1, "ptr", &buf, "uint*", size))
        throw Exception("CryptBinaryToString failed", -1)
    return StrGet(&buf)
}

UriEncode(Uri, RE="[0-9A-Za-z]") 
{ 
    Res := ""
    
    ; Make sure parameters are encoded
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	While Code := NumGet(Var, A_Index - 1, "UChar")
		Res .= (Chr:=Chr(Code)) ~= RE ? Chr : Format("%{:02X}", Code)
	Return, Res
}

SendCommandToVlc(command, UserName, Password) 
{
    ; Generate BASIC AUth token
    auth := Base64Encode(UserName . ":" . Password)

    ; Send the request to VLC's control server
    try
    {
        oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        oWhr.Open("GET", command, false)
        oWhr.SetRequestHeader("Content-Type", "application/json")
        oWhr.SetRequestHeader("Authorization", "Basic " . auth)
        oWhr.Send()
    }
    catch e
    {
        MsgBox, % "Could not connect to VLC: " . command
        ExitApp, -1
    }
}

BuildPlaylistFileName(VideosDirectory, SongName) 
{
   FileName := VideosDirectory . "\" . SongName . ".m3u"

   return %FileName%
}

StartVideoInVlc(HostAndPort, UserName, Password, VideosDirectory, SongName) 
{
    ; Define local filename for playlist
    LocalFileName := BuildPlaylistFileName(VideosDirectory, SongName)

    ; Check to see if there is a playlist called <SongName>.m3u in the LocalDirectory
    if Not FileExist(LocalFileName) 
    {
        ; File doesn't exist
        return
    }

    ; URI Encode the filename so that its properly parsable by the request
    FileToPlay := UriEncode(LocalFileName)

    ; Build the play playlist command
    command := "http://" . HostAndPort . "/requests/status.xml?command=in_play&input=" . FileToPlay

    SendCommandToVlc(command, UserName, Password)
} 

StopVideoInVlc(HostAndPort, UserName, Password) 
{
    ; Build the stop play playlist command
    command := "http://" . HostAndPort . "/requests/status.xml?command=pl_stop"

    SendCommandToVlc(command, UserName, Password)
}

ClearPlaylistInVlc(HostAndPort, UserName, Password) 
{

    ; Build the clear playlist command
    command := "http://" . HostAndPort . "/requests/status.xml?command=pl_empty"

    SendCommandToVlc(command, UserName, Password)
}

; **********************************************************************************************************************
; * VLC FUNCTIONS END
; **********************************************************************************************************************



; **********************************************************************************************************************
; * Reaper FUNCTIONS
; **********************************************************************************************************************

; note this won't do anything unless it is explicitly called in the 'SEQUENCE OF ACTIONS TO RUN' section below
StartTrackInReaper() {
    ; Activate Reaper, hit space to start playing
	Sleep 140
    SetTitleMatchMode, 2
	WinActivate, Reaper
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
UpdateNowPlaying(PlaylistDirectory, SongName)
StartVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword, VideosDirectoryName, SongName)

StartTrackInReaper()


return