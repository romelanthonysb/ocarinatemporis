' ocarinatemporis
' written by Romel Anthony S. Bismonte
' December 2011

' ocarina.bas - definition of the Ocarina object,
' its properties and commands.

#include "midimesg.bas"

' Ocarina type definition
Type Ocarina
    As Integer      blowkey     ' the ocarina key currently sounding
    As Integer      note        ' the note currently being played
    As Integer      zrbend      ' -1/0/+1 semitone bend (using Z or R)
    As Single       joybend     ' pitch bend using the joystick
End Type

Dim As Ocarina oc
Dim As Integer nbtns            ' state of the buttons
Dim As Integer j                ' result of calling GetJoystick
Dim As Integer playA
Dim As Integer playAOld
Dim As MidiMessage m

' Change instrument to "panflute"
MidiSetMessage(m,PROGCHANGE,PANFLUTE,0)
MidiSendMessage(m)

playA = 0
playAOld = 0

' this code does not use the Ocarina type above yet.
Do
    playAOld = playA
    j = GetJoystick(0, nbtns)
    If j = 0 Then
        If (nbtns And 2) Then
            playA = 1
        Else
            playA = 0
        End If
    End If
    
    If (playA = 1) AndAlso (playAOld = 0) Then
        MidiSetMessage(m,NOTEON,&h3E,&h7F)
        MidiSendMessage(m)
    End If
    If (playA = 0) AndAlso (playAOld = 1) Then
        MidiSetMessage(m,NOTEOFF,&h3E,&h80)
        MidiSendMessage(m)
    End If       
Loop While Inkey <> Chr(32)
