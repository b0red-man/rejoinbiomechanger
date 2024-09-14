; To whoever is seeing this code, I'm sorry for what I've done


; DISCLAIMER: ALMOST ALL OF THIS CODE IS COPIED DIRECTLY FROM DOLPHSOL MACRO
CoordMode, Mouse, Client
CoordMode, Pixel, Client
#NoEnv
SendMode Input
SetWorkingDir, % A_ScriptDir "\lib"
#Requires AutoHotkey v1.1+ 64-bit
#SingleInstance, force
#Include *i %A_ScriptDir%\lib
#Include *i Gdip_All.ahk
#Include *i Gdip_ImageSearch.ahk
#Include *i ocr.ahk

global nping = False ; null ping
global sfping = False ; starfall ping
global hping = False ; hell ping
global crping = False ; corruption ping

global pslink = "<<<PS LINK HERE>>>" ; share links don't work, don't remove quotes
global url = "<<<DISCORD WEBHOOK LINK HERE>>>" ; yes webhook url very cool :yipee:

global userid = "" ; optional, only used for biome pings

global biomeData := {"Normal":{color: 0xdddddd}
,"Windy":{color: 0x9ae5ff, duration: 120, display: 0, ping: 0}
,"Rainy":{color: 0x027cbd, duration: 120, display: 0, ping: 0}
,"Snowy":{color: 0xDceff9, duration: 120, display: 0, ping: 0}
,"Hell":{color: 0xff4719, duration: 660, display: 1, ping: 0}
,"Starfall":{color: 0x011ab7, duration: 600, display: 0, ping: 0}
,"Corruption":{color: 0x6d32a8, duration: 660, display: 0, ping: 0}
,"Null":{color: 0x838383, duration: 90, display: 0, ping: 0}
,"Glitched":{color: 0xbfff00, duration: 164, display: 1, ping: 1}}

getPlayButtonColorRatio() {
    getRobloxPos(pX,pY,width,height)

    ; Play Button Text
    targetW := height * 0.15
    startX := width * 0.5 - targetW * 0.55
    x := pX + startX
    y := pY + height * 0.8
    w := targetW * 1.1
    h := height * 0.1
    ; OutputDebug, % x ", " y ", " w ", " h
    ; Highlight(x, y, w, h, 5000)

    retrievedMap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
    ; Gdip_SaveBitmapToFile(retrievedMap, "retrievedMap.png")
    effect := Gdip_CreateEffect(5,-60,80)
    Gdip_BitmapApplyEffect(retrievedMap,effect)
    ; Gdip_SaveBitmapToFile(retrievedMap, "retrievedMap_effect.png")
    playMap := Gdip_ResizeBitmap(retrievedMap,32,32,0)
    ; Gdip_SaveBitmapToFile(playMap, "playMap.png")
    Gdip_GetImageDimensions(playMap, Width, Height)
    ; OutputDebug, % "playMap dimensions: " Width "w x " Height "h"

    blackPixels := 0
    whitePixels := 0

    Loop, %Width% {
        tX := A_Index-1
        Loop, %Height% {
            tY := A_Index-1
            pixelColor := Gdip_GetPixel(playMap, tX, tY)
            blackPixels += compareColors(pixelColor,0x000000) < 32
            whitePixels += compareColors(pixelColor,0xffffff) < 32
        }
    }
    ; OutputDebug, % "Black Pixels: " blackPixels
    ; OutputDebug, % "White Pixels: " whitePixels

    Gdip_DisposeEffect(effect)
    Gdip_DisposeBitmap(playMap)
    Gdip_DisposeBitmap(retrievedMap)
    
    if (whitePixels > 30 && blackPixels > 30){
        ratio := whitePixels/blackPixels
        OutputDebug, % "ratio: " ratio "`n"

        ; return (ratio > 0.35) && (ratio < 0.65)
        return ratio
    }
    return 0
}

macrorunning = False

getColorComponents(color){
    return [color & 255, (color >> 8) & 255, (color >> 16) & 255]
}

compareColors(color1, color2) ; determines how far apart 2 colors are
{
    color1V := getColorComponents(color1)
    color2V := getColorComponents(color2)

    cV := [color1V[1] - color2V[1], color1V[2] - color2V[2], color1V[3] - color2V[3]]
    dist := Abs(cV[1]) + Abs(cV[2]) + Abs(cV[3])
    return dist
}

containsText(x, y, width, height, text) {
    ; Potential improvement by ignoring non-alphanumeric characters

    ; Highlight(x-10, y-10, width+20, height+20, 2000)
    
    try {
        pbm := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)
        pbm := Gdip_ResizeBitmap(pbm,500,500,true)
        ocrText := ocrFromBitmap(pbm)
        Gdip_DisposeBitmap(pbm)

        if (!ocrText) {
            return false
        }
        ocrText := RegExReplace(ocrText,"(\n|\r)+"," ")
        StringLower, ocrText, ocrText
        StringLower, text, text
        textFound := InStr(ocrText, text)
        if (!textFound) { ; Reduce logging by only saving when not found
        }

        return textFound > 0
    } catch e {
        return -1
    }
}

msgsend(msg) {
    postdata=
    (
    {
        "content": "%msg%"
    }
    )
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, false)
    WebRequest.SetRequestHeader("Content-Type", "application/json")
    WebRequest.Send(postdata)
}

embedsend(desc, clr) {
    postdata=
    (
    {
        "embeds": [
            {
                "description": "%desc%",
                "color": "%clr%"
            }
        ]
    }
    )
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, false)
    WebRequest.SetRequestHeader("Content-Type", "application/json")
    WebRequest.Send(postdata)
} 
closeRoblox() {
    GetRobloxPos(x, y, width, height)
    ClickMouse(x + (width*0.97916666666), y + (height*-0.02258726899))
}
global similarCharacters := {"1":"l"
    ,"n":"m"
    ,"m":"n"
    ,"t":"f"
    ,"f":"t"
    ,"s":"S"
    ,"S":"s"
    ,"w":"W"
    ,"W":"w"}

if (pslength > 100) {
    MsgBox, share links dont work stupid
    ExitApp
}

getRobloxPos(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "", hwnd := ""){
    if !hwnd
        hwnd := GetRobloxHWND()
    VarSetCapacity( buf, 16, 0 )
    DllCall( "GetClientRect" , "UPtr", hwnd, "ptr", &buf)
    DllCall( "ClientToScreen" , "UPtr", hwnd, "ptr", &buf)

    x := NumGet(&buf,0,"Int")
    y := NumGet(&buf,4,"Int")
    width := NumGet(&buf,8,"Int")
    height := NumGet(&buf,12,"Int")
}

isPlayButtonVisible(){ ; Era 8 Play button: 750,860,420,110 (covers movement area)
    getRobloxPos(pX,pY,width,height)

    ; Play Button Area
    targetW := height * 0.3833
    startX := width * 0.5 - targetW * 0.55
    x := pX + startX
    y := pY + height * 0.8
    w := targetW * 1.1
    h := height * 0.1

    if (containsText(x, y, w, h, "Play") || containsText(x, y, w, h, "Ploy")) { ; Add commonly detected misspelling
        return true
    }

    ; Check again after delay to avoid false positives
    ; if (isGameNameVisible()) {
    ;     Sleep, 5000
    ;     return isGameNameVisible()
    ; }

    ; Compare after 5 checks to rule out false positives
    ratioSum := 0
    Loop, 5 {
        ratioSum += getPlayButtonColorRatio()
    }
    ratioAvg := ratioSum / 5
    if (ratioAvg >= 0.09 && ratioAvg <= 0.13) {
        return true
    }
    return false
}

ClickPlay() {
    getRobloxPos(pX,pY,width,height)
    actionfinish = false

    rHwnd := GetRobloxHWND()
    if (rHwnd) {
        WinActivate, ahk_id %rHwnd%
    }
    
    ; Click Play
    ClickMouse(pX + (width*0.5), pY + (height*0.82))
    ClickMouse(pX + (width*0.51), pY + (height*0.82))
    Sleep, 2500

    ; Enable Auto Roll - Completely removed from Initialize() to avoid toggling when macro is restarted, but game is not
    MouseMove, % pX + (width * 0.3505), % pY + (height * 0.91)
    ClickMouse(pX + (width * 0.3505), pY + (height * 0.911))
    Sleep, 4000

    ; Skip existing aura prompt
    MouseMove, % pX + (width*0.6), % pY + (height*0.84)
    ClickMouse(pX + (width*0.6), pY + (height*0.841))
    Sleep, 2000
    	
    MouseMove, % pX + (width*0.5), % pY + (height* 0.5)
    Sleep, 1000
    
    ; Press the Escape key
    Send, {Escape}
    Sleep, 500 ; Small delay to ensure the Escape action is registered

    ; Press the R key
    Send, r
    Sleep, 500 ; Small delay to ensure the R key action is registered

    ; Press the Enter key
    Send, {Enter}
    Sleep, 3000 ; Small delay to ensure the Enter key action is registered
    
    Send, {d down} ; Hold down the "D" key
    Sleep, 550 ; Keep it held down for 1 seconds 1 milliseconds
    Send, {d up}   ; Release the "D" key

    
}









global psid := SubStr(pslink, -31)
Gdip_Startup()

; variables for statistics
global snowcount = 0
global raincount = 0
global windcount = 0
global hellcount = 0
global starcount = 0
global corrupcount = 0
global nullcount = 0
global glitchcount = 0

identifyBiome(inputStr){
    if (!inputStr)
        return 0
    
    internalStr := RegExReplace(inputStr,"\s")
    internalStr := RegExReplace(internalStr,"^([\[\(\{\|IJ]+)")
    internalStr := RegExReplace(internalStr,"([\]\)\}\|IJ]+)$")

    highestRatio := 0
    matchingBiome := ""

    for v,_ in biomeData {
        if (v = "Glitched"){
            continue
        }
        scanIndex := 1
        accuracy := 0
        Loop % StrLen(v) {
            checkingChar := SubStr(v,A_Index,1)
            Loop % StrLen(internalStr) - scanIndex + 1 {
                index := scanIndex + A_Index - 1
                targetChar := SubStr(internalStr, index, 1)
                if (targetChar = checkingChar){
                    accuracy += 3 - A_Index
                    scanIndex := index+1
                    break
                } else if (similarCharacters[targetChar] = checkingChar){
                    accuracy += 2.5 - A_Index
                    scanIndex := index+1
                    break
                }
            }
        }
        ratio := accuracy/(StrLen(v)*2)
        if (ratio > highestRatio){
            matchingBiome := v
            highestRatio := ratio
        }
    }

    if (highestRatio < 0.70){
        matchingBiome := 0
        glitchedCheck := StrLen(internalStr)-StrLen(RegExReplace(internalStr,"\d")) + (RegExMatch(internalStr,"\.") ? 4 : 0)
        if (glitchedCheck >= 20){
            OutputDebug, % "glitched biome pro!"
            matchingBiome := "Glitched"
        }
    }


    return matchingBiome ; always returns 0
}

GetRobloxHWND(){
	if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe")) {
		return hwnd
	} else if (WinExist("Roblox ahk_exe ApplicationFrameHost.exe")) {
		ControlGet, hwnd, Hwnd, , ApplicationFrameInputSinkWindow1
		return hwnd
	} else {
        Sleep, 5000
		return 0 
    }
}

ClickMouse(posX, posY) {
    MouseMove, % posX, % posY
    Sleep, 175
    MouseClick
    Sleep, 200

    ; Highlight(posX-5, posY-5, 10, 10, 5000) ; Highlight for 5 seconds
}

determineBiome() {
    Loop {
        if (!WinActive("ahk_id " GetRobloxHWND()) && !WinActive("Roblox")){
            Sleep, 5000
            return
        }
        getRobloxPos(rX,rY,width,height)
        x := rX
        y := rY + height - height*0.135 + ((height/600) - 1)*10 ; Original: rY + height - height*0.102 + ((height/600) - 1)*10
        w := width*0.15
        h := height*0.03
        pBM := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)

        effect := Gdip_CreateEffect(3,"2|0|0|0|0" . "|" . "0|1.5|0|0|0" . "|" . "0|0|1|0|0" . "|" . "0|0|0|1|0" . "|" . "0|0|0.2|0|1",0)
        effect2 := Gdip_CreateEffect(5,-100,250)
        effect3 := Gdip_CreateEffect(2,10,50)
        Gdip_BitmapApplyEffect(pBM,effect)
        Gdip_BitmapApplyEffect(pBM,effect2)
        Gdip_BitmapApplyEffect(pBM,effect3)

        identifiedBiome := 0
        Loop 10 {
            st := A_TickCount
            newSizedPBM := Gdip_ResizeBitmap(pBM,300+(A_Index*38),70+(A_Index*7.5),1,2)

            ocrResult := ocrFromBitmap(newSizedPBM)
            identifiedBiome := identifyBiome(ocrResult)

            Gdip_DisposeBitmap(newSizedPBM)

            if (identifiedBiome){
                break
            }
        }
        if (identifiedBiome && identifiedBiome != "Normal") {
            Gdip_SaveBitmapToFile(pBM,ssPath)
        }
        Gdip_DisposeEffect(effect)
        Gdip_DisposeEffect(effect2)
        Gdip_DisposeEffect(effect3)
        Gdip_DisposeBitmap(retrievedMap)
        Gdip_DisposeBitmap(pBM)

        DllCall("psapi.dll\EmptyWorkingSet", "ptr", -1)
        if (identifiedBiome != "Normal") {
            if (identifiedBiome != "0") {
                if (identifiedBiome == "Glitched") {
                    Loop, 30 {
                        msgsend("Glitch biome detected @everyone")
                        msgsend(pslink)
                    }
                    Sleep, 180000
                    rejoin()
                }
                if (identifiedBiome == "Null") {
                    if (nping == True) {
                        msgsend("Null Biome found! <@" userid ">")
                    }
                    nullcount += 1
                }
                if (identifiedBiome == "Starfall") {
                    if (sfping == True) {
                        msgsend("Starfall Biome found! <@" userid ">")
                    }
					starcount += 1
                }
                if (identifiedBiome == "Hell") {
                    if (hping == True) {
                        msgsend("Hell Biome found! <@" userid ">")
                    }
					hellcount += 1
                }
                if (identifiedBiome == "Corruption") {
                    if (crping == True) {
                        msgsend("Corruption Biome found! <@" userid ">")
                    }
                    corrupcount += 1
                }
				if (identifiedBiome == "Snowy") {
					snowcount += 1
				}
				if (identifiedBiome == "Rainy") {
					raincount += 1
				}
				if (identifiedBiome == "Windy") {
					windcount += 1
				}
				totalcount := raincount + snowcount + corrupcount + hellcount + starcount + nullcount
                embedsend("Biome started: " + identifiedBiome, "151515")
                rejoin()
                determineBiome() 
            }
        }
        OutputDebug, % "Current Biome: " identifiedBiome
        Sleep, 750
    }
}
getRobloxPos(x, y, width, height)
MsgBox % width " " height
rejoin() {
    getRobloxPos(x, y, width, height)
    Run % "roblox://placeID=15532962292&linkCode=" psid
    ; Sleep, 5000
    ; closeRoblox()
    Loop {
        ClickMouse(x + (width*0.5), y + (height*0.75))
        if(isPlayButtonVisible()) {
            ClickPlay()
            break
        }
        Sleep, 300
    }
}
/*
zoomOut() {
    Loop, 50 {
        Send, {WheelDown}
    }
    Sleep, 500
    getRobloxPos(pX,pY,width,height)
    MouseClickDrag, right, (pX + width*0.5), (pY + height*0.8), (pX + width*0.5), (pY + height*0.2)
}
*/

secondTick() {
    rejoin()
    determineBiome()
}
MsgBox, Press F1 to start, Press F2 to stop
Gui, New
Gui, Font, s1
Gui, Add, Text,, pls game give glitch biome i beg of you
Gui, Show
F1::
    embedsend("Macro started", "300000")
    macrorunning == True
    secondTick()
F2::
    if (macrorunning == True) {
        embedsend("Macro stopped", "300000")
    }
    ExitApp