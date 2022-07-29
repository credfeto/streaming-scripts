#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force

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
     NowPlayingFileName := SongTrackingDirectory . "\NowPlaying.txt"
     PlayedFileName := SongTrackingDirectory . "\Played.txt"

    ; Update the last played file with the name of the song, with the latest song at the top of the file
    if FileExist(PlayedFileName)
    {
        FileRead, LastPlayedSongs, %PlayedFileName%
	
        if !IsSameAsLastSong(LastPlayedSongs, NewSongName) 
        {

            ; Append the song to the top of the file (delete the file, write the new song followed by the old one)
            FileDelete, %PlayedFileName%
            FileAppend, %NewSongName%`n, %PlayedFileName%
            FileAppend, %LastPlayedSongs%, %PlayedFileName%
	    }	
    }
    else
    {
        ; No song list, create a file with the song name in it.
        FileDelete, %PlayedFileName%
        FileAppend, %NewSongName%, %PlayedFileName%
    }

    ; Update the currently playing file with the song name
    FileDelete, %NowPlayingFileName%
    FileAppend, %NewSongName%, %NowPlayingFileName%

    return
}
