#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; **********************************************************************************************************************
; * INCLUDE Scripts from the library
; **********************************************************************************************************************
; Adds functions to help with the settings
#Include lib\!!String.ahk
; Adds functions to get the song name from the running script name
#Include lib\!!SongName.ahk
; Adds functions to update the Currently playing/Last Played files
#Include lib\!!RecentlyPlayed.ahk
; Adds functions for controlling VLC
#Include lib\!!VLC.ahk
; Adds Functions for controlling Cubase
#Include lib\!!Cubase.ahk
; Adds functions for controlling OBS
#Include lib\!!OBS.ahk
; Adds functions for controlling Reaper
#Include lib\!!Reaper.ahk
; Adds functions for controlling ShowBuddy
#Include lib\!!Reaper.ahk

; **********************************************************************************************************************
; * CONFIGURATION
; **********************************************************************************************************************
; Configuration ini read from settings.ini - see settings.ini for documentation
IniRead, PlayListEnabled, settings.ini, Playlist, Enabled, "True"
IniRead, PlaylistDirectory, settings.ini, Playlist, PlaylistDirectory, "C:\Currently Playing"
IniRead, LocalVideosDirectoryName, settings.ini, Video, LocalVideosDirectory, "C:\Currently Playing\Videos"
IniRead, RemoteVideosDirectoryName, settings.ini, Video, RemoteVideosDirectory, "C:\Currently Playing\Videos"
IniRead, VideoEnabled, settings.ini, Video, Enabled, "True"
IniRead, VlcHostAndPort, settings.ini, Video, VlcHostAndPort, "127.0.0.1:8080"
IniRead, VlcUsername, settings.ini, Video, VlcUsername, ""
IniRead, VlcPassword, settings.ini, Video, VlcPassword, "vlcremote"
IniRead, CubaseEnabled, settings.ini, Cubase, Enabled, "False"
IniRead, ReaperEnabled, settings.ini, Reaper, Enabled, "False"
IniRead, ShowBuddyEnabled, settings.ini, ShowBuddy, Enabled, "False"
IniRead, ObsEnabled, settings.ini, Obs, Enabled, "False"

; **********************************************************************************************************************
; * SEQUENCE OF ACTIONS TO RUN
; **********************************************************************************************************************

SongName := GetSongName()
if IsEnabled(VideoEnabled) {
    StopVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword)
    ClearPlaylistInVlc(VlcHostAndPort, VlcUsername, VlcPassword)
}
if IsEnabled(PlayListEnabled) UpdateNowPlaying(PlaylistDirectory, SongName)
if IsEnabled(VideoEnabled) StartVideoInVlc(VlcHostAndPort, VlcUsername, VlcPassword, LocalVideosDirectoryName, RemoteVideosDirectoryName, SongName)
if IsEnabled(CubaseEnabled) StartTrackInCubase()
if IsEnabled(ReaperEnabled) StartTrackInReaper()
if IsEnabled(ShowBuddyEnabled) StartTrackInShowBuddy()
if IsEnabled(ObsEnabled) PutOBSonTop()


return