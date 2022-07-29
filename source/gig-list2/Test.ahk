#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; **********************************************************************************************************************
; * INCLUDE Scripts from the library
; **********************************************************************************************************************

#Include lib\!!SongName.ahk
#Include lib\!!RecentlyPlayed.ahk
#Include lib\!!VLC.ahk
#Include lib\!!Reaper.ahk

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
; * SEQUENCE OF ACTIONS TO RUN
; **********************************************************************************************************************


StopVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword)
ClearPlaylistInVlc(VlcHostAndPort, VlcUsername, VlcPassword)
SongName := GetSongName()
UpdateNowPlaying(PlaylistDirectory, SongName)
StartVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword, VideosDirectoryName, VideosDirectoryName, SongName)

StartTrackInReaper()


return