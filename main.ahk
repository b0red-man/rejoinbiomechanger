; To whoever is seeing this code, I'm sorry for what I've done

; DISCLAIMER: ALMOST ALL OF THIS CODE IS COPIED DIRECTLY FROM DOLPHSOL MACRO
CoordMode, Client
#NoEnv
SendMode Input
SetWorkingDir, % A_ScriptDir "\lib"
#SingleInstance, force
#Include *i %A_ScriptDir%\lib
#Include *i Gdip_All.ahk
#Include *i Gdip_ImageSearch.ahk
#Include *i ocr.ahk

pslink = [>>>>YOUR PRIVATE SERVER LINK HERE<<<<] ; share links don't work


/*
rxl = roblox x location
ryl = roblox y location
rws = roblox width size
rhs = roblox height size
*/

global biomeData := {"Normal":{color: 0xdddddd}
,"Windy":{color: 0x9ae5ff, duration: 120, display: 0, ping: 0}
,"Rainy":{color: 0x027cbd, duration: 120, display: 0, ping: 0}
,"Snowy":{color: 0xDceff9, duration: 120, display: 0, ping: 0}
,"Hell":{color: 0xff4719, duration: 660, display: 1, ping: 0}
,"Starfall":{color: 0x011ab7, duration: 600, display: 0, ping: 0}
,"Corruption":{color: 0x6d32a8, duration: 660, display: 0, ping: 0}
,"Null":{color: 0x838383, duration: 90, display: 0, ping: 0}
,"Glitched":{color: 0xbfff00, duration: 164, display: 1, ping: 1}}

WinGetPos, rxl, ryl, rws1, rhs1, Roblox
global rws := rws1
global rhs := rhs1
webhooksend(msg) {
    url := "[>>>>YOUR WEBHOOK URL HERE!!<<<<]" ; do not remove quotes
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
global psid := SubStr(pslink, -31)
Gdip_Startup()

identifyBiome(inputStr){
    if (!inputStr)
        return 0 ; returns 0
    
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


determineBiome() {
    ; logMessage("[determineBiome] Determining biome...")
    sec = 0
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
            ; logMessage("[determineBiome] OCR result: " RegExReplace(ocrResult,"(\n|\r)+",""))
            ; logMessage("[determineBiome] Identified biome: " identifiedBiome)
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
                        webhooksend("Glitch biome detected <@&1240806151843741718>")
                        webhooksend(pslink)
                    }
                    Sleep, 180000
                    Run % "roblox://placeID=15532962292&linkCode=" psid
                    rejoin()
                    determineBiome()
                }
                Else 
                {
                    webhooksend("Biome started: " + identifiedBiome)
                    exitrblx()
                    Run % "roblox://placeID=15532962292&linkCode=" psid
                    rejoin()
                    determineBiome() 
                }
            }
        }
        Sleep, 1000
    }
}

exitrblx() {
    MouseClick, left, (rws * 0.3465499485), (rhs * 0.89708737864)
    Sleep, 600
    MouseClick, left, (rws * 0.96807415036), (rhs * -0.02038834951)
}

rejoin() {
    Sleep, 20000
    Loop, 7 {
        MouseClick, left, (rws * 0.5), (rhs * 0.7)
        Sleep, 750
    }

    Sleep, 3000
    MouseClick, left, 950, 850
    Loop, 3 {
        MouseClick, left, 950, 851
        Sleep, 750
    }
    Sleep, 2000
    MouseClick, left, (rws * 0.3465499485), (rhs * 0.89708737864)
}
secondTick() {
    Run % "roblox://placeID=15532962292&linkCode=" psid
    rejoin()
    determineBiome()
}
MsgBox, Press F1 to start, Press F2 to stop
Gui, New
Gui, Font, s1
Gui, Add, Text,, pls game give glitch biome i beg of you
Gui, Show
F1::
    secondTick()
F2::
    ExitApp