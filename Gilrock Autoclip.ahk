#NoEnv
#SingleInstance Force
SetBatchLines, -1

; Global variables
global ColorList := []
global RarityList := []
global ClipKey1 := ""
global ClipKey2 := ""
global ClipKey3 := ""
global IsMonitoring := false
global CaptureDelay := 15000
global DiscordWebhook := ""
global DiscordUserID := ""
global EnableWebhook := false
global DetectionX := 0
global DetectionY := 0
global ScreenWidth := 0
global ScreenHeight := 0
global SettingsFile := "Settings.ini"

; Load settings on startup
LoadSettings()

; ========================================
; CUTSCENE COLORS - Edit these directly!
; ========================================
; Add default colors if none exist
colorCount := ColorList.MaxIndex()
if (!colorCount) {
    ; Format: Add color and rarity at same index
    ColorList.Push("0xFEFFC5")
    RarityList.Push("Divine (50M+)")
    
    ColorList.Push("0xFFB280")
    RarityList.Push("Immortal (250M+)")
    
    ColorList.Push("0xD480FE")
    RarityList.Push("Eternal (1B+)")
    
    ; To add more colors:
    ; ColorList.Push("0xYOURCOLOR")
    ; RarityList.Push("Your Rarity")
    
    SaveSettings()
}
; ========================================

; Create GUI
Gui, Font, s10
Gui, Add, Text, x10 y10 w400, Created by Deakidoo

; Get screen resolution and set detection point to center
SysGet, ScreenWidth, 78
SysGet, ScreenHeight, 79
DetectionX := ScreenWidth // 2
DetectionY := ScreenHeight // 2

; Clip keybinds section
Gui, Add, GroupBox, x10 y35 w400 h110, Clip/Record Keybinds
Gui, Add, Text, x20 y60, Key 1:
Gui, Add, Edit, x80 y57 w100 h25 vKey1Display ReadOnly, %ClipKey1%
Gui, Add, Button, x190 y57 w80 h25 gSetClipKey1, Set Key
Gui, Add, Button, x280 y57 w60 h25 gClearKey1, Clear

Gui, Add, Text, x20 y90, Key 2:
Gui, Add, Edit, x80 y87 w100 h25 vKey2Display ReadOnly, %ClipKey2%
Gui, Add, Button, x190 y87 w80 h25 gSetClipKey2, Set Key
Gui, Add, Button, x280 y87 w60 h25 gClearKey2, Clear

Gui, Add, Text, x20 y120, Key 3:
Gui, Add, Edit, x80 y117 w100 h25 vKey3Display ReadOnly, %ClipKey3%
Gui, Add, Button, x190 y117 w80 h25 gSetClipKey3, Set Key
Gui, Add, Button, x280 y117 w60 h25 gClearKey3, Clear

; Discord webhook section
Gui, Add, GroupBox, x10 y155 w400 h110, Discord Webhook (Optional)
Gui, Add, CheckBox, x20 y175 w250 h25 vEnableWebhookCheck gToggleWebhook Checked%EnableWebhook%, Enable Discord Notifications
Gui, Add, Text, x20 y200, Webhook URL:
Gui, Add, Edit, x110 y197 w210 h25 vWebhookInput, %DiscordWebhook%
Gui, Add, Button, x330 y197 w70 h25 gSaveWebhook vSaveWebhookBtn, Save
Gui, Add, Text, x20 y230, User ID (ping):
Gui, Add, Edit, x110 y227 w210 h25 vUserIDInput, %DiscordUserID%
Gui, Add, Button, x330 y227 w70 h25 gSaveUserID vSaveUserIDBtn, Save

; Set initial state of webhook controls
if (EnableWebhook) {
    GuiControl, Enable, WebhookInput
    GuiControl, Enable, SaveWebhookBtn
    GuiControl, Enable, UserIDInput
    GuiControl, Enable, SaveUserIDBtn
} else {
    GuiControl, Disable, WebhookInput
    GuiControl, Disable, SaveWebhookBtn
    GuiControl, Disable, UserIDInput
    GuiControl, Disable, SaveUserIDBtn
}

; Control section
Gui, Add, GroupBox, x10 y275 w400 h80, Capture Settings
Gui, Add, Text, x20 y300, Delay before clip:
delaySeconds := CaptureDelay // 1000
Gui, Add, Edit, x127 y297 w35 h25 vDelayInput Number, %delaySeconds%
Gui, Add, Button, x175 y297 w100 h25 gUpdateDelay, Update

Gui, Add, Button, x20 y325 w180 h25 gStartMonitoring vStartBtn, Start Monitoring
Gui, Add, Button, x210 y325 w180 h25 gStopMonitoring vStopBtn Disabled, Stop Monitoring

Gui, Add, Text, x10 y360 w400 h25 vStatusText Center, Status: Ready

Gui, Show, w420 h395, Gilrock Autoclip
return

; Toggle webhook input field
ToggleWebhook:
    Gui, Submit, NoHide
    if (EnableWebhookCheck) {
        GuiControl, Enable, WebhookInput
        GuiControl, Enable, SaveWebhookBtn
        GuiControl, Enable, UserIDInput
        GuiControl, Enable, SaveUserIDBtn
        EnableWebhook := true
    } else {
        GuiControl, Disable, WebhookInput
        GuiControl, Disable, SaveWebhookBtn
        GuiControl, Disable, UserIDInput
        GuiControl, Disable, SaveUserIDBtn
        EnableWebhook := false
    }
    SaveSettings()
    return

; Save Discord webhook URL
SaveWebhook:
    Gui, Submit, NoHide
    DiscordWebhook := WebhookInput
    
    if (DiscordWebhook = "") {
        MsgBox, 48, Invalid Webhook, Please enter a valid Discord webhook URL
        return
    }
    
    ; Test webhook
    if (TestDiscordWebhook()) {
        GuiControl,, StatusText, Status: Discord webhook added!
        SaveSettings()
    } else {
        MsgBox, 48, Connection Failed, Failed to connect to Discord webhook. Please check the URL.
        GuiControl,, StatusText, Status: Discord webhook failed.
    }
    return

; Save Discord User ID for pings
SaveUserID:
    Gui, Submit, NoHide
    DiscordUserID := UserIDInput
    
    if (DiscordUserID != "") {
        GuiControl,, StatusText, Status: Discord User ID saved
    } else {
        GuiControl,, StatusText, Status: Discord User ID cleared
    }
    
    SaveSettings()
    return

; Clip key capture functions
SetClipKey1:
    ClipKey1 := CaptureKeyPress()
    GuiControl,, Key1Display, %ClipKey1%
    SaveSettings()
    return

SetClipKey2:
    ClipKey2 := CaptureKeyPress()
    GuiControl,, Key2Display, %ClipKey2%
    SaveSettings()
    return

SetClipKey3:
    ClipKey3 := CaptureKeyPress()
    GuiControl,, Key3Display, %ClipKey3%
    SaveSettings()
    return

ClearKey1:
    ClipKey1 := ""
    GuiControl,, Key1Display,
    SaveSettings()
    return

ClearKey2:
    ClipKey2 := ""
    GuiControl,, Key2Display,
    SaveSettings()
    return

ClearKey3:
    ClipKey3 := ""
    GuiControl,, Key3Display,
    SaveSettings()
    return

; Capture single key press
CaptureKeyPress() {
    GuiControl,, StatusText, Press any key or modifier (Ctrl/Alt/Shift/Win/F1-F12)...
    
    ; Use Input with specific options to capture all keys
    Input, key, L1 T10 M, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Space}{Enter}{Escape}{Tab}{Backspace}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{Up}{Down}{Left}{Right}
    
    ; Check what was pressed
    if (ErrorLevel = "EndKey:LControl" || ErrorLevel = "EndKey:RControl") {
        GuiControl,, StatusText, Status: Key captured!
        return "Control"
    }
    if (ErrorLevel = "EndKey:LAlt" || ErrorLevel = "EndKey:RAlt") {
        GuiControl,, StatusText, Status: Key captured!
        return "Alt"
    }
    if (ErrorLevel = "EndKey:LShift" || ErrorLevel = "EndKey:RShift") {
        GuiControl,, StatusText, Status: Key captured!
        return "Shift"
    }
    if (ErrorLevel = "EndKey:LWin" || ErrorLevel = "EndKey:RWin") {
        GuiControl,, StatusText, Status: Key captured!
        return "LWin"
    }
    
    ; Check for function keys F1-F12
    Loop, 12
    {
        fKey := "F" . A_Index
        if (ErrorLevel = "EndKey:" . fKey) {
            GuiControl,, StatusText, Status: Key captured!
            return fKey
        }
    }
    
    ; Check for other special keys
    if (ErrorLevel = "EndKey:Space") {
        GuiControl,, StatusText, Status: Key captured!
        return "Space"
    }
    if (ErrorLevel = "EndKey:Enter") {
        GuiControl,, StatusText, Status: Key captured!
        return "Enter"
    }
    if (ErrorLevel = "EndKey:Escape") {
        GuiControl,, StatusText, Status: Key captured!
        return "Escape"
    }
    if (ErrorLevel = "EndKey:Tab") {
        GuiControl,, StatusText, Status: Key captured!
        return "Tab"
    }
    if (ErrorLevel = "EndKey:Backspace") {
        GuiControl,, StatusText, Status: Key captured!
        return "Backspace"
    }
    if (ErrorLevel = "EndKey:Delete") {
        GuiControl,, StatusText, Status: Key captured!
        return "Delete"
    }
    if (ErrorLevel = "EndKey:Insert") {
        GuiControl,, StatusText, Status: Key captured!
        return "Insert"
    }
    if (ErrorLevel = "EndKey:Home") {
        GuiControl,, StatusText, Status: Key captured!
        return "Home"
    }
    if (ErrorLevel = "EndKey:End") {
        GuiControl,, StatusText, Status: Key captured!
        return "End"
    }
    if (ErrorLevel = "EndKey:PgUp") {
        GuiControl,, StatusText, Status: Key captured!
        return "PgUp"
    }
    if (ErrorLevel = "EndKey:PgDn") {
        GuiControl,, StatusText, Status: Key captured!
        return "PgDn"
    }
    if (ErrorLevel = "EndKey:Up") {
        GuiControl,, StatusText, Status: Key captured!
        return "Up"
    }
    if (ErrorLevel = "EndKey:Down") {
        GuiControl,, StatusText, Status: Key captured!
        return "Down"
    }
    if (ErrorLevel = "EndKey:Left") {
        GuiControl,, StatusText, Status: Key captured!
        return "Left"
    }
    if (ErrorLevel = "EndKey:Right") {
        GuiControl,, StatusText, Status: Key captured!
        return "Right"
    }
    
    ; Handle timeout
    if (ErrorLevel = "Timeout") {
        GuiControl,, StatusText, Status: Key capture cancelled
        return ""
    }
    
    ; Return the captured alphanumeric key
    if (key != "") {
        GuiControl,, StatusText, Status: Key captured!
        return key
    }
    
    GuiControl,, StatusText, Status: Key capture cancelled
    return ""
}

; Update capture delay
UpdateDelay:
    Gui, Submit, NoHide
    if (DelayInput < 1) {
        MsgBox, 48, Invalid Delay, Delay must be at least 1 second!
        return
    }
    CaptureDelay := DelayInput * 1000
    GuiControl,, StatusText, Status: Delay set to %DelayInput% seconds
    SaveSettings()
    return

; Start color monitoring
StartMonitoring:
    totalColors := ColorList.MaxIndex()
    if (!totalColors) {
        MsgBox, 48, Setup Required, Please add at least one cutscene color to detect!
        return
    }
    
    if (ClipKey1 = "" && ClipKey2 = "" && ClipKey3 = "") {
        MsgBox, 48, Setup Required, Please set at least one clip keybind!
        return
    }
    
    IsMonitoring := true
    GuiControl, Disable, StartBtn
    GuiControl, Enable, StopBtn
    GuiControl,, StatusText, Status: Monitoring...
    
    SetTimer, MonitorCursor, 100
    return

; Stop monitoring
StopMonitoring:
    IsMonitoring := false
    SetTimer, MonitorCursor, Off
    GuiControl, Enable, StartBtn
    GuiControl, Disable, StopBtn
    GuiControl,, StatusText, Status: Monitoring stopped
    return

; Main detection loop
MonitorCursor:
    if (!IsMonitoring)
        return
    
    ; Get color at center of screen (fixed detection point)
    PixelGetColor, detectedColor, %DetectionX%, %DetectionY%, RGB
    
    ; Check if detected color matches any in our list
    maxIdx := ColorList.MaxIndex()
    if (maxIdx) {
        Loop, %maxIdx%
        {
            targetColor := ColorList[A_Index]
            if (detectedColor = targetColor) {
                ; Cutscene color detected!
                cleanColor := StrReplace(targetColor, "0x", "")
                rarity := RarityList[A_Index]
                delaySeconds := CaptureDelay // 1000
                
                GuiControl,, StatusText, Status: %rarity% cutscene detected! - Waiting %delaySeconds%s...
                SetTimer, MonitorCursor, Off
                
                ; Send Discord notification if enabled
                if (EnableWebhook && DiscordWebhook != "") {
                    SendDiscordNotification(rarity, targetColor)
                }
                
                ; Wait for cutscene to play
                Sleep, %CaptureDelay%
                
                ; Execute clip keybinds simultaneously
                ExecuteClipKeybind()
                
                GuiControl,, StatusText, Status: Clip triggered! Resuming monitoring...
                SetTimer, MonitorCursor, 100
                return
            }
        }
    }
    return

; Execute the configured clip keybinds
ExecuteClipKeybind() {
    keysDown := ""
    keysUp := ""
    
    if (ClipKey1 != "") {
        keysDown .= "{" . ClipKey1 . " down}"
        keysUp .= "{" . ClipKey1 . " up}"
    }
    if (ClipKey2 != "") {
        keysDown .= "{" . ClipKey2 . " down}"
        keysUp .= "{" . ClipKey2 . " up}"
    }
    if (ClipKey3 != "") {
        keysDown .= "{" . ClipKey3 . " down}"
        keysUp .= "{" . ClipKey3 . " up}"
    }
    
    ; Press all keys simultaneously
    Send, %keysDown%
    Sleep, 50
    Send, %keysUp%
    return
}

; Test Discord webhook connection
TestDiscordWebhook() {
    global DiscordWebhook
    try {
        jsonPayload := "{ ""content"": ""✅ Cutscene Clip Detector connected successfully!"" }"
        
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", DiscordWebhook, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(jsonPayload)
        whr.WaitForResponse()
        
        return (whr.Status = 200 || whr.Status = 204)
    } catch {
        return false
    }
}

; Send notification to Discord
SendDiscordNotification(rarity, detectedColorHex) {
    global DiscordWebhook, DiscordUserID
    try {
        ; Get current system time in 12-hour format with AM/PM
        FormatTime, currentTime, , h:mm:ss tt
        
        ; Convert hex color to decimal for Discord embed color
        cleanHex := StrReplace(detectedColorHex, "0x", "")
        embedColor := "0x" . cleanHex
        embedColor += 0 ; Convert to decimal
        
        ; Escape any quotes in rarity string
        rarity := StrReplace(rarity, """", "\""")
        
        ; Build JSON payload
        jsonPayload := "{"
        
        ; Add user ping OUTSIDE the embed if User ID is set
        if (DiscordUserID != "") {
            jsonPayload .= """content"": ""<@" . DiscordUserID . ">""," 
        }
        
        ; Build the embed
        jsonPayload .= """embeds"": [{"
        jsonPayload .= """title"": """ . rarity . " Detected!"","
        jsonPayload .= """description"": ""Time: " . currentTime . ""","
        jsonPayload .= """color"": " . embedColor
        jsonPayload .= "}]"
        jsonPayload .= "}"
        
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", DiscordWebhook, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(jsonPayload)
        whr.WaitForResponse()
        
        return true
    } catch {
        return false
    }
}

; Load settings from INI file
LoadSettings() {
    global SettingsFile, ColorList, RarityList, ClipKey1, ClipKey2, ClipKey3
    global CaptureDelay, DiscordWebhook, DiscordUserID, EnableWebhook
    
    ; Load keybinds
    IniRead, ClipKey1, %SettingsFile%, Keybinds, Key1, %A_Space%
    IniRead, ClipKey2, %SettingsFile%, Keybinds, Key2, %A_Space%
    IniRead, ClipKey3, %SettingsFile%, Keybinds, Key3, %A_Space%
    
    ; Clean up ERROR values
    if (ClipKey1 = "ERROR")
        ClipKey1 := ""
    if (ClipKey2 = "ERROR")
        ClipKey2 := ""
    if (ClipKey3 = "ERROR")
        ClipKey3 := ""
    
    ; Load capture delay
    IniRead, delaySeconds, %SettingsFile%, Settings, CaptureDelay, 15
    if (delaySeconds < 1)
        delaySeconds := 15
    CaptureDelay := delaySeconds * 1000
    
    ; Load Discord settings
    IniRead, DiscordWebhook, %SettingsFile%, Discord, WebhookURL, %A_Space%
    IniRead, DiscordUserID, %SettingsFile%, Discord, UserID, %A_Space%
    IniRead, webhookEnabledStr, %SettingsFile%, Discord, Enabled, 0
    
    ; Clean up ERROR values
    if (DiscordWebhook = "ERROR")
        DiscordWebhook := ""
    if (DiscordUserID = "ERROR")
        DiscordUserID := ""
    
    EnableWebhook := (webhookEnabledStr = "1") ? true : false
    
    ; Load colors and rarities
    IniRead, colorCount, %SettingsFile%, Colors, Count, 0
    if (colorCount > 0) {
        Loop, %colorCount%
        {
            IniRead, colorHex, %SettingsFile%, Colors, Color%A_Index%, %A_Space%
            IniRead, rarity, %SettingsFile%, Colors, Rarity%A_Index%, %A_Space%
            
            if (colorHex != "" && rarity != "" && colorHex != "ERROR" && rarity != "ERROR") {
                ColorList.Push(colorHex)
                RarityList.Push(rarity)
            }
        }
    }
}

; Save settings to INI file
SaveSettings() {
    global SettingsFile, ColorList, RarityList, ClipKey1, ClipKey2, ClipKey3
    global CaptureDelay, DiscordWebhook, DiscordUserID, EnableWebhook
    
    ; Save keybinds
    IniWrite, %ClipKey1%, %SettingsFile%, Keybinds, Key1
    IniWrite, %ClipKey2%, %SettingsFile%, Keybinds, Key2
    IniWrite, %ClipKey3%, %SettingsFile%, Keybinds, Key3
    
    ; Save capture delay
    delaySeconds := CaptureDelay // 1000
    IniWrite, %delaySeconds%, %SettingsFile%, Settings, CaptureDelay
    
    ; Save Discord settings
    IniWrite, %DiscordWebhook%, %SettingsFile%, Discord, WebhookURL
    IniWrite, %DiscordUserID%, %SettingsFile%, Discord, UserID
    webhookEnabled := EnableWebhook ? "1" : "0"
    IniWrite, %webhookEnabled%, %SettingsFile%, Discord, Enabled
    
    ; Clear old color entries
    IniDelete, %SettingsFile%, Colors
    
    ; Save colors and rarities
    maxIdx := ColorList.MaxIndex()
    colorCount := maxIdx ? maxIdx : 0
    IniWrite, %colorCount%, %SettingsFile%, Colors, Count
    
    if (maxIdx) {
        Loop, %maxIdx%
        {
            colorHex := ColorList[A_Index]
            rarity := RarityList[A_Index]
            
            ; Make sure we have both values before saving
            if (colorHex != "" && rarity != "") {
                IniWrite, %colorHex%, %SettingsFile%, Colors, Color%A_Index%
                IniWrite, %rarity%, %SettingsFile%, Colors, Rarity%A_Index%
            }
        }
    }
}

GuiClose:
    SaveSettings()
    ExitApp
