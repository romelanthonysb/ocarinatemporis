#include "fbgfx.bi"
Using FB

Screen 12

Dim As Integer buttons			' button state
Dim As Single x1, x2, x3, x4	' state of axes
Dim As Integer r				' result of checking joystick
Dim As Integer i				' counter
Dim As Integer k				' keyboard input

Const joystickid = 0

If GetJoystick(joystickid, buttons) = 1 Then
	Print "Joystick error; press a key to exit."
	Sleep
	End
End If

Do
	r = GetJoystick(joystickid, buttons, x1, x2, x3, x4)
	Locate 1, 1
	Print "Buttons: "; Bin(buttons, 16)
	Print Using "Axis 1 +#.######"; x1
	Print Using "Axis 2 +#.######"; x2
	Print Using "Axis 3 +#.######"; x3
	Print Using "Axis 4 +#.######"; x4
	
Loop Until Multikey(SC_ESCAPE)
