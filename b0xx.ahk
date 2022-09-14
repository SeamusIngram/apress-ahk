#SingleInstance force
#NoEnv
#include <CvJoyInterface>
SetBatchLines, -1

hotkeys := [ "Analog Up"             ; 1
           , "Analog Down"           ; 2
           , "Analog Left"           ; 3
           , "Analog Right"          ; 4
           , "Notch"                 ; 5
           , "Slow"                  ; 6
           , "A"                     ; 7
           , "B"                     ; 8
           , "L"                     ; 9
           , "R"                     ; 10
           , "X"                     ; 11
           , "Y"                     ; 12
           , "Z"                     ; 13
           , "C-stick Up"            ; 14
           , "C-stick Down"          ; 15
           , "C-stick Left"          ; 16
           , "C-stick Right"         ; 17
           , "Light Shield"          ; 18
           , "Hold"                  ; 19
           , "Start"                 ; 20
           , "D-pad Up"              ; 21
           , "D-pad Down"            ; 22
           , "D-pad Left"            ; 23
           , "D-pad Right"           ; 24
           , "Debug"]                ; 25

states := {  "Analog Up":0             ; 1
           , "Analog Down":0           ; 2
           , "Analog Left":0           ; 3
           , "Analog Right":0          ; 4
           , "Notch":0                 ; 5
           , "Slow":0                  ; 6
           , "A":0                     ; 7
           , "B":0                     ; 8
           , "L":0                     ; 9
           , "R":0                     ; 10
           , "X":0                     ; 11
           , "Y":0                     ; 12
           , "Z":0                     ; 13
           , "C-stick Up":0            ; 14
           , "C-stick Down":0          ; 15
           , "C-stick Left":0          ; 16
           , "C-stick Right":0         ; 17
           , "Light Shield":0          ; 18
           , "Hold":0                  ; 19
           , "Start":0                 ; 20
           , "D-pad Up":0              ; 21
           , "D-pad Down":0            ; 22
           , "D-pad Left":0            ; 23
           , "D-pad Right":0           ; 24
           , "Debug":0}                ; 25

; vJoy buttons to send, from the configuration file
digital_buttons := { "A":5                     
                   , "B":4                     
                   , "L":1                     
                   , "R":3                     
                   , "X":6                     
                   , "Y":2                     
                   , "Z":7                                    
                   , "Start":8                 
                   , "D-pad Up":9              
                   , "D-pad Down":11            
                   , "D-pad Left":10          
                   , "D-pad Right":12}           

; SOCD 
leftPressed := false
rightPressed := false
upPressed := false
downPressed := false
forbidLeft := false
forbidRight := false
forbidUp := false
forbidDown := false
; Stick Speeds
V_FAST := 5
V_SLOW := 0.5
V_RETURN := 3
V_ROLL := 3 
; Analog Press parameters
resetHold := true
dxAccum = 0
dyAccum = 0
xy := [0, 0]
; target coordinate constants
PI := 4 * ATan(1)
coordsShieldDrop := [56, 55]
coordsNotchHorizontal := [73, 31]
coordsNotchVertical := [31, 73]

Menu, Tray, Click, 1
Menu, Tray, Add, Edit Controls, ShowGui
Menu, Tray, Default, Edit Controls

for index, element in hotkeys{
 Gui, Add, Text, xm vLB%index%, %element% Hotkey:
 IniRead, savedHK%index%, hotkeys.ini, Hotkeys, %index%, %A_Space%
 If savedHK%index%                                       ;Check for saved hotkeys in INI file.
  ; Hotkey,% savedHK%index%, Label%index%                 ;Activate saved hotkeys if found.
  ; Hotkey,% savedHK%index% . " UP", Label%index%_UP                 ;Activate saved hotkeys if found.
  ;TrayTip, B0XX, Label%index%_UP, 3, 0
  ;TrayTip, B0XX, % savedHK%A_Index%, 3, 0
  ;TrayTip, B0XX, % savedHK%index% . " UP", 3, 0
 checked := false
 if(!InStr(savedHK%index%, "~", false)){
  checked := true
 }
 StringReplace, noMods, savedHK%index%, ~                  ;Remove tilde (~) and Win (#) modifiers...
 StringReplace, noMods, noMods, #,,UseErrorLevel              ;They are incompatible with hotkey controls (cannot be shown).
 Gui, Add, Hotkey, x+5 w50 vHK%index% gGuiLabel, %noMods%        ;Add hotkey controls and show saved hotkeys.
 if(!checked)
  Gui, Add, CheckBox, x+5 vCB%index% gGuiLabel, Prevent Default Behavior  ;Add checkboxes to allow the Windows key (#) as a modifier..
 else
  Gui, Add, CheckBox, x+5 vCB%index% Checked gGuiLabel, Prevent Default Behavior  ;Add checkboxes to allow the Windows key (#) as a modifier..
}
; Create an object from vJoy Interface Class.
vJoyInterface := new CvJoyInterface()

; Was vJoy installed and the DLL Loaded?
if (!vJoyInterface.vJoyEnabled()) {
  ; Show log of what happened
  Msgbox % vJoyInterface.LoadLibraryLog
  ExitApp
}

myStick := vJoyInterface.Devices[1]
TrayTip, B0XX, Script Started, 3, 0

; Performance counter frequency, for timings
DllCall("QueryPerformanceFrequency", "Int64*", freq)
DllCall("QueryPerformanceCounter", "Int64*", t)

while(true){
  for index, element in hotkeys{
    StringReplace, noMods, savedHK%index%, ~ ;Remove tilde (~) and Win (#) modifiers...
    StringReplace, noMods, noMods, #
    states[element] := GetKeyState(noMods)
  }
  SOCD()
  updateButtons()
  updateAnalogStick()
  updateCStick()
  updateLS()
  ;Sleep 1
}

SOCD(){
  global
  if (leftPressed and left() and right() and not rightPressed)
     forbidLeft := true
  if (rightPressed and left() and right() and not leftPressed)
     forbidRight := true
  if (upPressed and up() and down() and not downPressed)
     forbidUp := true
  if (downPressed and up() and down() and not upPressed){
    forbidDown := true
  }

  if not left()
     forbidLeft := false
  if not right()
      forbidRight := false
  if not up()
     forbidUp := false
  if not down()
     forbidDown := false

  leftPressed := left()
  rightPressed := right()
  upPressed := up()
  downPressed := down()

  if forbidLeft
     states["Analog Left"] := 0
  if forbidRight
     states["Analog Right"] := 0
  if forbidUp
     states["Analog Up"] := 0
  if forbidDown
    states["Analog Down"] := 0

}

updateButtons(){
  global
  for k, v in digital_buttons{
      myStick.SetBtn(states[k],v)
  }
}

updateAnalogStick(){
  setAnalogStick(getAnalogCoords())
}

updateCStick(){
  setCStick(getCStickCoords())
}

updateLS(){
  global
  if states["Light Shield"]
    setAnalogR(49)
  else
    setAnalogR(0)
}

setAnalogStick(coords) {
  global
  convertedCoords := convertCoords(coords)
  myStick.SetAxisByIndex(convertedCoords[1], 1)
  myStick.SetAxisByIndex(convertedCoords[2], 2)
}

getAnalogCoords() {
  global
  DllCall("QueryPerformanceCounter", "Int64*", tNew)
  dt := (tNew - t)* 1000 / freq 
  targetPoint := target()
  currentRegion := getRegion(xy)
  targetRegion := getRegion(targetPoint)
  adjacentRegion := Abs(targetRegion-currentRegion) <= 1 or targetRegion+currentRegion == 9
  rolling := adjacentRegion and xy[1]*xy[1]+xy[2]*xy[2] >= 5625
  
  if not states["hold"]
    resetHold := true
  if (noPressed())
    v := V_RETURN
  else if (states["slow"])
    v := V_SLOW
  else if rolling
    v := V_ROLL
  else
    v:= V_FAST
  d := dt*v
  if states["hold"] 
    xy := getAnalogCoordsHolding()
  else if rolling
    xy := getAnalogCoordsRolling()
  else
    xy := getAnalogCoordsDefault()
  DllCall("QueryPerformanceCounter", "Int64*", t)
  return scaleCoords(xy)
}

target(){
  if neither(anyVert(), anyHoriz()) 
    coords := [0, 0]
  else if (anyVert() and anyHoriz())
    coords := [56,56]
  else if (anyVert())
      coords := [0, 80]
  else
      coords := [80, 0]
  return reflectCoords(coords)
}

getRegion(coords){
  x := coords[1]
  y := coords[2]
  if (x >= 23) {
    if (y >= 23)
      region := 2
    else if (y >= -22)
      region := 1
    else
      region :=8
  }
  else if (x >= -22){
    if (y >= 23)
      region := 3
    else if (y >= -22)
      region := -1
    else
      region := 7
  }
  else{
    if (y >= 23)
      region := 4
    else if (y >= -22)
      region := 5
    else
      region := 6
  }
  return region
}

directionOfChange(coords,targetCoords,region) {
  if (region == 1 or region == 2 or region == 8)
    ccw := coords[2] < targetCoords[2]
  else if (region >= 4 and region <= 6)
    ccw := coords[2] > targetCoords[2]
  else if(region == 3)
    ccw := coords[1] > targetCoords[1]
  else    
    ccw := coords[1] < targetCoords[1]
  return ccw
}

angleToTarget(coords,targetCoords){
  x := coords[1]
  y := coords[2]
  tx := targetCoords[1]
  ty := targetCoords[2]
  if ((x == 0 and tx = 0) or (y == 0 and ty == 0))
    theta = 0
  else  
    theta := ACos((12800-((x-tx)*(x-tx)+(y-ty)*(y-ty)))/12800)
  return theta
}

rollToPoint(coords,theta,currentTheta){
  global
  local dx,dy,p
  dx := 80*(Cos(theta)-Cos(currentTheta))
  dy := 80*(Sin(theta)-Sin(currentTheta))
  targetPoint :=[coords[1]+sign(dx)*Abs(Floor(dx)),coords[2]+sign(dy)*Abs(Floor(dy))]
  ;MsgBox % counterClockwise "`n new angle " theta "`n starting angle" currentTheta "`n coords" xy[1]","xy[2] "`n dx "dx "`n dy "dy "`n target" targetPoint[1]","targetPoint[2]
  p := quantize(dx,dy)
  return p
}

getAnalogCoordsHolding(){
  global
  local coords
  
  if not noPressed() and resetHold
    coords := [xy[1],xy[2]]
  else{
    resetHold := false
    targetPoint := [0,0]
    d := V_RETURN*dt
    theta := atan2(targetPoint[2]-xy[2],targetPoint[1]-xy[1])
    dx := (Floor(targetPoint[1]) == Floor(xy[1])) ? 0 : d*Cos(theta)
    dy := d*Sin(theta)
    coords := quantize(dx,dy)
  }
  return coords
}

getAnalogCoordsRolling(){
  global
  local theta,currentTheta,coords
  ;MsgBox Rolling
  theta := d/80
  currentTheta := atan2(xy[2],xy[1])
  counterClockwise := directionOfChange(xy,targetPoint,currentRegion)
  newTheta := counterClockwise ? currentTheta + theta : currentTheta - theta
  if (newTheta > PI)
    newTheta -= 2*PI
  else if (newTheta < -1*PI)4
    newTheta += 2*PI
  if (states["notch"] and Mod(currentRegion, 2) == 0 and Mod(targetRegion, 2) == 1){
    if (((currentRegion == 2 or currentRegion == 4) and targetRegion ==3) or ((currentRegion == 6 or currentRegion == 8) and targetRegion == 7))
      targetPoint := reflectByRegion([31,73],currentRegion)
    else  
      targetPoint := reflectByRegion([73,31],currentRegion)
    thetaMax := angleToTarget(xy,targetPoint)
    if (theta >= Abs(thetaMax)) or (xy[1] == targetPoint[1]) or (xy[2] == targetPoint[2])
      coords := [targetPoint[1],targetPoint[2]]
    else  
      coords := rollToPoint(xy,newTheta,currentTheta)
  }
  else if ((states["L"] or states["R"] or states["Light Shield"]) and Mod(targetRegion, 2) == 0 and xy[2]<targetPoint[2]) {
    targetPoint := reflectByRegion([56,55],currentRegion)
    thetaMax := angleToTarget(xy,targetPoint)
    if (theta >= Abs(thetaMax)) or (xy[1] == targetPoint[1]) or (xy[2] == targetPoint[2])
      coords := [targetPoint[1],targetPoint[2]]
    else  
      coords := rollToPoint(xy,newTheta,currentTheta)
  }
  else {
    thetaMax := angleToTarget(xy,targetPoint)
    ;MsgBox % theta "`n" thetaMax
    if (theta >= Abs(thetaMax)) or (xy[1] == targetPoint[1]) or (xy[2] == targetPoint[2])
      coords := [targetPoint[1],targetPoint[2]]
    else  
      coords := rollToPoint(xy,newTheta,currentTheta)
  }
  return coords
}

getAnalogCoordsDefault(){
  global
  local theta,dx,dy,coords
  theta := atan2(targetPoint[2]-xy[2],targetPoint[1]-xy[1])
  dx := (Floor(targetPoint[1]) == Floor(xy[1])) ? 0 : d*Cos(theta)
  dy := d*Sin(theta)
  coords := quantize(dx,dy)
  if (coords[1]*coords[1] + coords[2]*coords[2] > 6400){
    coords := [targetPoint[1]targetPoint[2]]
  }
  return coords
}

scaleCoords(coords) {
  x := coords[1]
  y := coords[2]
  return [x/80, y/80]
}

quantize(dx,dy){
  global
  local x,y,theta,adjustX,adjustY,adjusted = false
  if Abs(dx) < 1
    dxAccum += dx
  if Abs(dy) < 1
    dyAccum += dy
  if Abs(dxAccum) > 1{
    x := xy[1] + sign(dxAccum)*Floor(Abs(dxAccum))
    dxAccum -= sign(dxAccum)*Floor(Abs(dxAccum))
    adjusted := true
  }
  else{
    adjustX := Abs(dx) > Abs(targetPoint[1]-xy[1]) ?  targetPoint[1]-xy[1] : dx
    x := xy[1] + sign(adjustX)*Floor(Abs(adjustX))
    if Floor(Abs(adjustX)) > 0
      adjusted = true
  }
  if Abs(dyAccum) > 1{
    y := xy[2] + sign(dyAccum)*Floor(Abs(dyAccum))
    dyAccum -= sign(dyAccum)*Floor(Abs(dyAccum))
    adjusted := true
  }
  else{
    adjustY := Abs(dy) > Abs(targetPoint[2]-xy[2]) ?  targetPoint[2]-xy[2] : dy
    y := xy[2] + sign(adjustY)*Floor(Abs(adjustY))
    if Floor(Abs(adjustY)) > 0
      adjusted = true
  }
  if adjusted and x*x+y*y >6400{
    theta := atan2(y,x)
    if Abs(theta) > PI/4 and Abs(theta) < 3*PI/4
      y -= sign(y)
    else
      x -= sign(x)
  }
  return [x,y]
}

setCStick(coords) {
  global
  convertedCoords := convertCoords(coords)
  myStick.SetAxisByIndex(convertedCoords[1], 4)
  myStick.SetAxisByIndex(convertedCoords[2], 5)
}

getCStickCoords() {
  global
  if (neither(anyVertC(), anyHorizC()) or bothMods()) {
    coords := [0, 0]
  } else if (anyVertC() and anyHorizC()) {
    coords := [0.525, 0.85]
  } else if (anyVertC()) {
      coords := [0, 1]
  } else {
    if (states["Notch"] and up()) {
      coords := [0.9, 0.5]
    } else if (states["Notch"] and down()) {
      coords := [0.9, -0.5]
    } else {
      coords := [1, 0]
    }
  }
  return reflectCStickCoords(coords)
}

reflectCoords(coords) {
  x := coords[1]
  y := coords[2]
  if (down()) {
    y := -y
  }
  if (left()) {
    x := -x
  }
  return [x, y]
}

reflectCStickCoords(coords) {
  cx := coords[1]
  cy := coords[2]
  if (cDown()) {
    cy := -cy
  }
  if (cLeft()) {
    cx := -cx
  }
  return [cx, cy]
}

reflectByRegion(coords,region){
  x := coords[1]
  y := coords[2]
  if (region == 4 or region == 6)
    x:= -x 
  if (region >= 6)
    y := -y
  return [x,y]
}

; Converts coordinates from melee values (-1 to 1) to vJoy values (0 to 32767).
convertCoords(coords) {
  mx = 10271 ; Why this number? idk, I would have thought it should be 16384 * (80 / 128) = 10240, but this works
  my = -10271
  bx = 16448 ; 16384 + 64
  by = 16320 ; 16384 - 64
  return [ mx * coords[1] + bx
         , my * coords[2] + by ]
}

setAnalogR(value) {
  global
  ; vJoy/Dolphin does something strange with rounding analog shoulder presses. In general,
  ; it seems to want to round to odd values, so
  ;   16384 => 0.00000 (0)   <-- actual value used for 0
  ;   19532 => 0.35000 (49)  <-- actual value used for 49
  ;   22424 => 0.67875 (95)  <-- actual value used for 94
  ;   22384 => 0.67875 (95)
  ;   22383 => 0.66429 (93)
  ; But, *extremely* inconsistently, I have seen the following:
  ;   22464 => 0.67143 (94)
  ; Which no sense and I can't reproduce. 
  convertedValue := 16384 * (1 + (value  / 255))
  myStick.SetAxisByIndex(convertedValue, 3)
}

up() {
  global
  return states["Analog Up"]
}

down() {
  global
  return states["Analog Down"]
}

left() {
  global
  return states["Analog Left"]
}

right() {
  global
  return states["Analog Right"]
}

anyHoriz() {
  global
  return left() or right()
}

anyVert() {
  global
  return up() or down()
}

cLeft() {
  global
  return states["C-Stick Left"]
}

cRight() {
  global
  return states["C-Stick Right"]
}

cUp() {
  global
  return states["C-Stick Up"]
}

cDown() {
  global
  return states["C-Stick Down"]
}

anyHorizC() {
  global
  return cLeft() or cRight()
}

anyVertC() {
  global
  return cUp() or cDown()
}

bothMods(){
  global
  return states["Notch"] and states["Slow"]
}

noPressed(){
  global
  return not up() and not down() and not left() and not right()
}

neither(a, b) {
  return (not a) and (not b)
}

atan2(y, x) {
   return dllcall("msvcrt\atan2", "Double", y, "Double", x, "CDECL Double")
}

sign(nr) {
	return (nr>0)-(nr<0)
}
validateHK(GuiControl) {
 global lastHK
 Gui, Submit, NoHide
 lastHK := %GuiControl%                     ;Backup the hotkey, in case it needs to be reshown.
 num := SubStr(GuiControl,3)                ;Get the index number of the hotkey control.
 If (HK%num% != "") {                       ;If the hotkey is not blank...
  StringReplace, HK%num%, HK%num%, SC15D, AppsKey      ;Use friendlier names,
  StringReplace, HK%num%, HK%num%, SC154, PrintScreen  ;  instead of these scan codes.
  ;If CB%num%                                ;  If the 'Win' box is checked, then add its modifier (#).
   ;HK%num% := "#" HK%num%
  If (!CB%num% && !RegExMatch(HK%num%,"[#!\^\+]"))       ;  If the new hotkey has no modifiers, add the (~) modifier.
   HK%num% := "~" HK%num%                   ;    This prevents any key from being blocked.
  checkDuplicateHK(num)
 }
 If (savedHK%num% || HK%num%)               ;Unless both are empty,
  setHK(num, savedHK%num%, HK%num%)         ;  update INI/GUI
}

checkDuplicateHK(num) {
 global
 Loop,% hotkeys.Length()
  If (HK%num% = savedHK%A_Index%) {
   dup := A_Index
   TrayTip, B0XX, Hotkey Already Taken, 3, 0
   Loop,6 {
    GuiControl,% "Disable" b:=!b, HK%dup%   ;Flash the original hotkey to alert the user.
    Sleep,200
   }
   GuiControl,,HK%num%,% HK%num% :=""       ;Delete the hotkey and clear the control.
   break
  }
}

setHK(num,INI,GUI) {
 If INI{                          ;If previous hotkey exists,
  ; Hotkey, %INI%, Label%num%, Off  ;  disable it.
  ; Hotkey, %INI% UP, Label%num%_UP, Off  ;  disable it.
}
 If GUI{                           ;If new hotkey exists,
  ; Hotkey, %GUI%, Label%num%, On   ;  enable it.
  ; Hotkey, %GUI% UP, Label%num%_UP, On   ;  enable it.
}
 IniWrite,% GUI ? GUI:null, hotkeys.ini, Hotkeys, %num%
 savedHK%num%  := HK%num%
 ;TrayTip, Label%num%,% !INI ? GUI " ON":!GUI ? INI " OFF":GUI " ON`n" INI " OFF"
}

#MenuMaskKey vk07                 ;Requires AHK_L 38+
#If ctrl := HotkeyCtrlHasFocus()
 *AppsKey::                       ;Add support for these special keys,
 *BackSpace::                     ;  which the hotkey control does not normally allow.
 *Delete::
 *Enter::
 *Escape::
 *Pause::
 *PrintScreen::
 *Space::
 *Tab::
  modifier := ""
  If GetKeyState("Shift","P")
   modifier .= "+"
  If GetKeyState("Ctrl","P")
   modifier .= "^"
  If GetKeyState("Alt","P")
   modifier .= "!"
  Gui, Submit, NoHide             ;If BackSpace is the first key press, Gui has never been submitted.
  If (A_ThisHotkey == "*BackSpace" && %ctrl% && !modifier)   ;If the control has text but no modifiers held,
   GuiControl,,%ctrl%                                       ;  allow BackSpace to clear that text.
  Else                                                     ;Otherwise,
   GuiControl,,%ctrl%, % modifier SubStr(A_ThisHotkey,2)  ;  show the hotkey.
  validateHK(ctrl)
 return
#If

HotkeyCtrlHasFocus() {
 GuiControlGet, ctrl, Focus       ;ClassNN
 If InStr(ctrl,"hotkey") {
  GuiControlGet, ctrl, FocusV     ;Associated variable
  Return, ctrl
 }
}
;Show GUI from tray Icon
ShowGui:
    Gui, show,, Dynamic Hotkeys
    GuiControl, Focus, LB1 ; this puts the windows "focus" on the checkbox, that way it isn't immediately waiting for input on the 1st input box
return                                                               ;Check the box if Win modifier is used.

GuiLabel:
 If %A_GuiControl% in +,^,!,+^,+!,^!,+^!    ;If the hotkey contains only modifiers, return to wait for a key.
  return
 If InStr(%A_GuiControl%,"vk07")            ;vk07 = MenuMaskKey (see below)
  GuiControl,,%A_GuiControl%, % lastHK      ;Reshow the hotkey, because MenuMaskKey clears it.
 Else
  validateHK(A_GuiControl)
return