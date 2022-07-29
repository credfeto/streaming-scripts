#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

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

StartVideoInVlc(HostAndPort, UserName, Password, LocalVideosDirectory, RemoteVideosDirectory, SongName) 
{
    ; Define local filename for playlist
    LocalFileName := BuildPlaylistFileName(LocalVideosDirectory, SongName)
    RemoteFileName := BuildPlaylistFileName(RemoteVideosDirectory, SongName)

    ; Check to see if there is a playlist called <SongName>.m3u in the LocalDirectory
    if Not FileExist(LocalFileName) 
    {
        ; File doesn't exist
        return
    }

    ; Check to see if there is a playlist called <SongName>.m3u in the LocalDirectory
    if Not FileExist(RemoteFileName) 
    {
        ; File doesn't exist
        return
    }

    ; URI Encode the filename so that its properly parsable by the request
    FileToPlay := UriEncode(RemoteFileName)

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
