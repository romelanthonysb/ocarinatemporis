' ocarinatemporis
' written by Romel Anthony S. Bismonte
' Dec 2011

' Ocarina control program.
' Object-oriented approach discarded in the interest of speed and
' responsiveness to controls.

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
Const PANFLUTE = 75
Const OCARINA = 79
Const SQUAREWAVE = 80
Const ORCHHIT = 55

' MIDI status definitions
' note: channel = 0; to select another channel, add channel # (1..F)
' eg. note on, channel C = NOTEON + C
Const NOTEOFF = &h80
Const NOTEON = &h90
Const PROGCHANGE = &hC0
Const CONTROLCHG = &hB0
Const PITCHWHEEL = &hE0

' MIDI Controller definitions (under control change)
Const MODWHEELC = 1
Const ALLSOUNDOFF = 120
Const ALLCTRLSOFF = 121

' joystick definitions
Const JID = 0

' Midi variables
Dim Shared As HMIDIOUT MidiDevice
Dim As Integer midiresult
Dim As MidiMessage m

' Controller input variables
Dim As Integer padresult
Dim As Integer nbtns        ' other buttons
Dim As Single jlr           ' Joystick LR: vibrato
Dim As Single jud           ' Joystick UD: pitch bend
Dim As Single cud           ' C-buttons UD
Dim As Single crl           ' C-buttons RL

' ocarina music state variables
Dim As Byte currentnote
Dim As UByte ocstate, ocstateold
Dim As UShort bendstate, bendstateold
Dim As UByte bendh, bendl           ' high and low bytes of pitch bend
Dim As UByte vibstate, vibstateold

' ocstate stands for Ocarina state, which is an 8-bit number expressing
' which note buttons are pressed at the moment:
' Bit   Button
' ---   ------
' 0     A
' 1     CD
' 2     CR
' 3     CL
' 4     CU
' 5     Z
' 6     R
' 7     unused
' The lookup table will recognize a key combination of one of the first 5 keys
' (A, CD, CR, CL, CU--the "blow" keys) plus zero or one of the other two keys
' (Z or R--the "shift" keys). All other key combinations will not be recognized.

' lookup table for associating key combinations to notes
' (TODO) Make it possible to load these values from a configuration file
Dim key2note(0 To &b01111111) As Byte

For i As Integer = 0 To &b01111111
    key2note(i) = -1
Next i

key2note(&b00000000) = -1           ' no note playing

key2note(&b00100001) = 73           ' A+Z       = c#
key2note(&b00000001) = 74           ' A         = d
key2note(&b01000001) = 75           ' A+R       = d#

key2note(&b00100010) = 76           ' CD+Z      = e
key2note(&b00000010) = 77           ' CD        = f
key2note(&b01000010) = 78           ' CD+R      = f#

key2note(&b00100100) = 80           ' CR+Z      = g#
key2note(&b00000100) = 81           ' CR        = a
key2note(&b01000100) = 82           ' CR+R      = a#

key2note(&b00101000) = 82           ' CL+Z      = a#
key2note(&b00001000) = 83           ' CL        = b
key2note(&b01001000) = 84           ' CL+R      = c

key2note(&b00110000) = 85           ' CU+Z      = c#
key2note(&b00010000) = 86           ' CU        = d
key2note(&b01010000) = 87           ' CU+R      = d#
' Note that without using pitch bend it is impossible to play the note g (79).

' initialize MIDI device
midiresult = midiOutOpen(@MidiDevice, MIDI_MAPPER, 0, 0, null)
If (midiresult <> MMSYSERR_NOERROR) Then
	Print "Error accessing MIDI device."
	Print "Press a key to quit."
	Sleep
	End
End If

' change instrument (see definitions above for alternatives)
MidiSetMessage(m,PROGCHANGE,OCARINA,0)
MidiSendMessage(m)

Cls
Print "Press [spacebar] to exit the program."

' make sure state variables start with valid values
ocstate = 0
currentnote = -1
bendstate = 8192
vibstate = 0

' main ocarina loop

Do While Inkey <> Chr(32)
    
    ' save previous ocarina state
    ocstateold = ocstate
    bendstateold = bendstate
    vibstateold = vibstate
    
    ' Get the current state of the joystick
    padresult = GetJoystick(JID, nbtns, jlr, jud, cud, crl)
    ' Interpret as a note and slider positions (pitch bend and vibrato)
    ocstate = 0
    ' Test button A, Z, R, and C-stick buttons (which are treated like axes)
    ' (TODO) Find out whether C-buttons could be treated like buttons and how
    If Bit(nbtns, 1) Then ocstate = BitSet(ocstate, 0)
    If Bit(nbtns, 8) Then ocstate = BitSet(ocstate, 5)
    If Bit(nbtns, 7) Then ocstate = BitSet(ocstate, 6)
    If cud > 0.5 Then ocstate = BitSet(ocstate, 1)
    If crl < -0.5 Then ocstate = BitSet(ocstate, 2)
    If crl > 0.5 Then ocstate = BitSet(ocstate, 3)
    If cud < -0.5 Then ocstate = BitSet(ocstate, 4)

    ' Test joystick UD and scale to 14 bit range.
    bendstate = Int((-1 * jud + 1) * 8192)

    ' (DEBUG) Print joystick state
    
    ' Test Joystick LR
    vibstate = Int(Abs(jlr) * 128)
    
    ' Use the state to issue a MIDI event using a lookup table
    If ocstate <> ocstateold Then
        ' If a note is playing, stop it first.
        If currentnote <> -1 Then
            MidiSetMessage(m,NOTEOFF,currentnote,&h7F)
            MidiSendMessage(m)
        End If
        ' Play the requested note (if it's actually a note)
        currentnote = key2note(ocstate)      
        If currentnote <> -1 Then
            MidiSetMessage(m,NOTEON,currentnote,&h7F)
            MidiSendMessage(m)
        End If
        ' (DEBUG) Print the note currently playing (result of lookup)
        Locate 2, 1
        Print Bin(ocstate, 8),
        Print Using "###"; currentnote

    End If
    
    ' Interpret Joystick UD => pitch bend and issue MIDI event if different
    If bendstate <> bendstateold Then
        ' make sure bendstate is between 0..16383
        If bendstate < 0 Then bendstate = 0
        If bendstate > 16383 Then bendstate = 16383
        ' split into two bytes, 7 bits each
        bendl = CUByte(bendstate)
        bendl = BitReset(bendl, 7)
        bendh = CUByte(bendstate Shr 7)
        bendh = BitReset(bendh, 7)
        
        ' Slide the MIDI controller
        MidiSetMessage(m,PITCHWHEEL,bendl,bendh)
        MidiSendMessage(m)
        
        ' (DEBUG) Print the two bytes side by side
        Locate 3, 1
        Print "Bend", Bin(bendstate, 16), Bin(bendh, 8), Bin(bendl, 8)
    End If
    
    ' Interpret Joystick LR => vibrato and issue MIDI event if different
    If vibstate <> vibstateold Then
        ' make sure vibstate is less than 16384
        If vibstate > 127 Then vibstate = 127
        
        ' Slide the MIDI controller
        MidiSetMessage(m,CONTROLCHG,MODWHEELC,vibstate)
        MidiSendMessage(m)
        
        ' (DEBUG) Print the two bytes side by side
        Locate 4, 1
        Print "Vibr", Bin(vibstate, 8)
    End If

Loop

' Clean up!
' Get all notes/sounds off
MidiSetMessage(m,CONTROLCHG,ALLSOUNDOFF,0)
MidiSendMessage(m)
MidiSetMessage(m,CONTROLCHG,ALLCTRLSOFF,0)
MidiSendMessage(m)

' Close MIDI device
midiresult = midiOutClose(MidiDevice)

End
