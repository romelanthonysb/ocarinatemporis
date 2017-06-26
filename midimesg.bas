#include once "windows.bi"
#include once "win\mmsystem.bi"

Type MidiMessage Field = 1  
	status As Ubyte
	param1 As Ubyte
	param2 As Ubyte
	reserved As Ubyte
end type     

#define MidiSendMessage(MSGVAR) midiOutShortMsg(MidiDevice, *CPtr(Integer Ptr,@MSGVAR))
#define MidiSetMessage(MSGVAR,STAT,P1,P2) MSGVAR.status=STAT:MSGVAR.param1=P1:MSGVAR.param2=P2

' Instrument types
Const PANFLUTE = &h4B

' MIDI status definitions
' note: channel = 0; to select another channel, add channel # (1..F)
' eg. note on, channel C = NOTEON + C
Const NOTEOFF = &h80
Const NOTEON = &h90
Const PROGCHANGE = &hC0

Dim Shared As HMIDIOUT MidiDevice
Dim As Integer midiresult

' initialize device
midiresult = midiOutOpen(@MidiDevice, MIDI_MAPPER, 0, 0, null)
If (midiresult <> MMSYSERR_NOERROR) Then
	Print "Error accessing MIDI device."
	Print "Press a key to quit."
	Sleep
	End
End If
