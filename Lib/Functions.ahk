global settingsFile := "" 
global confirmClicked := false


setupFilePath() {
    global settingsFile
    
    if !DirExist(A_ScriptDir "\Settings") {
        DirCreate(A_ScriptDir "\Settings")
    }

    settingsFile := A_ScriptDir "\Settings\Configuration.txt"
    return settingsFile
}

readInSettings() {
    global enabled1, enabled2, enabled3, enabled4, enabled5, enabled6
    global placement1, placement2, placement3, placement4, placement5, placement6
    global mode

    try {
        settingsFile := setupFilePath()
        if !FileExist(settingsFile) {
            return
        }

        content := FileRead(settingsFile)
        lines := StrSplit(content, "`n")
        
        for line in lines {
            if line = "" {
                continue
            }
            
            parts := StrSplit(line, "=")
            switch parts[1] {
                case "Mode": mode := parts[2]
                case "Enabled1": enabled1.Value := parts[2]
                case "Enabled2": enabled2.Value := parts[2]
                case "Enabled3": enabled3.Value := parts[2]
                case "Enabled4": enabled4.Value := parts[2]
                case "Enabled5": enabled5.Value := parts[2]
                case "Enabled6": enabled6.Value := parts[2]
                case "Placement1": placement1.Text := parts[2]
                case "Placement2": placement2.Text := parts[2]
                case "Placement3": placement3.Text := parts[2]
                case "Placement4": placement4.Text := parts[2]
                case "Placement5": placement5.Text := parts[2]
                case "Placement6": placement6.Text := parts[2]
            }
        }
        ProcessLog("Configuration settings loaded successfully")
    }
}


SaveSettings(*) {
    global enabled1, enabled2, enabled3, enabled4, enabled5, enabled6
    global placement1, placement2, placement3, placement4, placement5, placement6
    global mode

    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.txt"
        if FileExist(settingsFile) {
            FileDelete(settingsFile)
        }

        ; Save mode and map selection
        content := "Mode=" mode "`n"
        if (mode = "Story") {
            content .= "Map=" StoryDropdown.Text
        } else if (mode = "Raid") {
            content .= "Map=" RaidDropdown.Text
        }
        
        ; Save settings for each unit
        content .= "`n`nEnabled1=" enabled1.Value
        content .= "`nEnabled2=" enabled2.Value
        content .= "`nEnabled3=" enabled3.Value
        content .= "`nEnabled4=" enabled4.Value
        content .= "`nEnabled5=" enabled5.Value
        content .= "`nEnabled6=" enabled6.Value

        content .= "`n`nPlacement1=" placement1.Text
        content .= "`nPlacement2=" placement2.Text
        content .= "`nPlacement3=" placement3.Text
        content .= "`nPlacement4=" placement4.Text
        content .= "`nPlacement5=" placement5.Text
        content .= "`nPlacement6=" placement6.Text
        
        FileAppend(content, settingsFile)
        ProcessLog("Configuration settings saved successfully")
    }
}

LoadSettings() {
    global UnitData, mode
    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.txt"
        if !FileExist(settingsFile) {
            return
        }

        content := FileRead(settingsFile)
        sections := StrSplit(content, "`n`n")
        
        for section in sections {
            if (InStr(section, "Index=")) {
                lines := StrSplit(section, "`n")
                index := ""
                
                for line in lines {
                    if line = "" {
                        continue
                    }
                    
                    parts := StrSplit(line, "=")
                    if (parts[1] = "Index") {
                        index := parts[2]
                    } else if (index && UnitData.Has(Integer(index))) {
                        switch parts[1] {
                            case "Enabled": UnitData[index].Enabled.Value := parts[2]
                            case "Placement": UnitData[index].PlacementBox.Value := parts[2]
                        }
                    }
                }
            }
        }
        ProcessLog("Auto settings loaded successfully")
    }
}

CheckBanner(unitName) {

    ; First check if Roblox window exists
    if !WinExist(rblxID) {
        ProcessLog("Roblox window not found - skipping banner check")
        return false
    }

    ; Get Roblox window position
    WinGetPos(&robloxX, &robloxY, &rblxW, &rblxH, rblxID)
    
    detectionCount := 0
    ProcessLog("Checking for: " unitName)

    ; Split unit name into individual words
    unitName := Trim(unitName)  ; Remove spaces
    unitWords := StrSplit(unitName, " ")

    Loop 5 {
        try {
            result := OCR.FromRect(robloxX + 280, robloxY + 293, 250, 55, "en",
                {   
                    grayscale: true,
                    scale: 2.0
                })
            
            ; Check if all words are found in the text
            allWordsFound := true
            for word in unitWords {
                if !InStr(result.Text, word) {
                    allWordsFound := false
                    break
                }
            }
            
            if (allWordsFound) {
                detectionCount++
                Sleep(100)
            }
        }
    }

    if (detectionCount >= 1) {
        ProcessLog("Found " unitName " in banner")
        try {
            BannerFound()
        }
        return true
    }

    ProcessLog("Did not find " unitName " in banner")
    return false
}

SaveBannerSettings(*) {
    ProcessLog("Saving Banner Unit Name")
    
    if FileExist("Settings\BannerUnit.txt")
        FileDelete("Settings\BannerUnit.txt")
    
    FileAppend(BannerUnitBox.Value, "Settings\BannerUnit.txt", "UTF-8")
}

SavePsSettings(*) {
    ProcessLog("Saving Private Server Link")
    
    if FileExist("Settings\PrivateServer.txt")
        FileDelete("Settings\PrivateServer.txt")
    
    FileAppend(PsLinkBox.Value, "Settings\PrivateServer.txt", "UTF-8")
}

SaveUINavSettings(*) {
    ProcessLog("Saving UI Navigation Key")
    
    if FileExist("Settings\UINavigation.txt")
        FileDelete("Settings\UINavigation.txt")
    
    FileAppend(UINavBox.Value, "Settings\UINavigation.txt", "UTF-8")
}

;Opens discord Link
OpenDiscordLink() {
    Run("https://discord.gg/mistdomain")
 }

 OpenFukkiReta(){
    Run("https://www.youtube.com/watch?v=TWdfNakkBFM")
 }
 
 ;Minimizes the UI
 minimizeUI(*){
    aaMainUI.Minimize()
 }
 
 Destroy(*){
    aaMainUI.Destroy()
    ExitApp
 }
 ;Login Text
 setupOutputFile() {
     content := "`n==" aaTitle "" version "==`n  Start Time: [" currentTime "]`n"
     FileAppend(content, currentOutputFile)
 }
 
 ;Gets the current time
 getCurrentTime() {
     currentHour := A_Hour
     currentMinute := A_Min
     currentSecond := A_Sec
 
     return Format("{:d}h.{:02}m.{:02}s", currentHour, currentMinute, currentSecond)
 }



 OnModeChange(*) {
    global mode
    selected := ModeDropdown.Text
    
    ; Hide all dropdowns first
    StoryDropdown.Visible := false
    StoryActDropdown.Visible := false
    LegendDropDown.Visible := false
    LegendActDropdown.Visible := false
    RaidDropdown.Visible := false
    RaidActDropdown.Visible := false
    InfinityCastleDropdown.Visible := false
    ContractDropdown.Visible := false
    MatchMaking.Visible := false
    ReturnLobbyBox.Visible := false
    
    if (selected = "Story") {
        StoryDropdown.Visible := true
        StoryActDropdown.Visible := true
        mode := "Story"
    } else if (selected = "Legend") {
        LegendDropDown.Visible := true
        LegendActDropdown.Visible := true
        mode := "Legend"
    } else if (selected = "Raid") {
        RaidDropdown.Visible := true
        RaidActDropdown.Visible := true
        mode := "Raid"
    } else if (selected = "Infinity Castle") {
        InfinityCastleDropdown.Visible := true
        mode := "Infinity Castle"
    } else if (selected = "Cursed Womb") {
        InfinityCastleDropdown.Visible := true
        mode := "Cursed Womb"
    } else if (selected = "Contracts"){
        ContractDropdown.Visible := true
        mode := "Contracts"
    }
}

OnStoryChange(*) {
    if (StoryDropdown.Text != "") {
        StoryActDropdown.Visible := true
    } else {
        StoryActDropdown.Visible := false
    }
}

OnLegendChange(*) {
    if (LegendDropDown.Text != "") {
        LegendActDropdown.Visible := true
    } else {
        LegendActDropdown.Visible := false
    }
}

OnRaidChange(*) {
    if (RaidDropdown.Text != "") {
        RaidActDropdown.Visible := true
    } else {
        RaidActDropdown.Visible := false
    }
}

OnContractChange(*) {
    if (ContractDropdown.Text != "") {
        ContractDropdown.Visible := true
    } else {
        ContractDropdown.Visible := false
    }
}

OnConfirmClick(*) {
    if (ModeDropdown.Text = "") {
        ProcessLog("Please select a gamemode before confirming")
        return
    }

    ; For Story mode, check if both Story and Act are selected
    if (ModeDropdown.Text = "Story") {
        if (StoryDropdown.Text = "" || StoryActDropdown.Text = "") {
            ProcessLog("Please select both Story and Act before confirming")
            return
        }
        ProcessLog("Selected " StoryDropdown.Text " - " StoryActDropdown.Text)
        MatchMaking.Visible := (StoryActDropdown.Text = "Infinity")
        ReturnLobbyBox.Visible := (StoryActDropdown.Text = "Infinity")
        NextLevelBox.Visible := (StoryActDropdown.Text != "Infinity")
    }
    ; For Legend mode, check if both Legend and Act are selected
    else if (ModeDropdown.Text = "Legend") {
        if (LegendDropDown.Text = "" || LegendActDropdown.Text = "") {
            ProcessLog("Please select both Legend Stage and Act before confirming")
            return
        }
        ProcessLog("Selected " LegendDropDown.Text " - " LegendActDropdown.Text)
        MatchMaking.Visible := true
        ReturnLobbyBox.Visible := true
    }
    ; For Raid mode, check if both Raid and RaidAct are selected
    else if (ModeDropdown.Text = "Raid") {
        if (RaidDropdown.Text = "" || RaidActDropdown.Text = "") {
            ProcessLog("Please select both Raid and Act before confirming")
            return
        }
        ProcessLog("Selected " RaidDropdown.Text " - " RaidActDropdown.Text)
        MatchMaking.Visible := true
        ReturnLobbyBox.Visible := true
    }
    else if (ModeDropdown.Text = "Contracts"){
        if (ContractDropdown.Text = "") {
            ProcessLog("Please select an Contract number first")
            return
        }
        ProcessLog("Selected " ContractDropdown.Text " Contract ")
        MatchMaking.Visible := true
        ReturnLobbyBox.Visible := true
    }
    else {
        ProcessLog("Selected " ModeDropdown.Text " mode")
        MatchMaking.Visible := false
        ReturnLobbyBox.Visible := false
    }

    ProcessLog("Don't forget to enable Click to Move! (I forget sometimes too!)")

    ; Hide all controls if validation passes
    ModeDropdown.Visible := false
    StoryDropdown.Visible := false
    StoryActDropdown.Visible := false
    LegendDropDown.Visible := false
    LegendActDropdown.Visible := false
    RaidDropdown.Visible := false
    RaidActDropdown.Visible := false
    InfinityCastleDropdown.Visible := false
    ContractDropdown.Visible := false
    ConfirmButton.Visible := false
    modeSelectionGroup.Visible := false
    Hotkeytext.Visible := true
    Hotkeytext2.Visible := true
    Hotkeytext3.Visible := true
    global confirmClicked := true
}


FixClick(x, y, LR := "Left") {
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep(50)
}

CaptchaDetect(x, y, w, h, inputX, inputY) {
    detectionCount := 0
    ProcessLog("Checking for numbers...")

    Loop 5 {
        try {
            result := OCR.FromRect(x, y, w, h, "en", 
                {   
                    grayscale: true,
                    scale: 2.0
                })
            
            if result {
                ; Get text before any linebreak
                number := StrSplit(result.Text, "`n")[1]
                
                ; Clean to just get numbers
                number := RegExReplace(number, "[^\d]")
                
                if (StrLen(number) >= 5 && StrLen(number) <= 7) {
                    detectionCount++
                    
                    if (detectionCount >= 1) {
                        ; Send exactly what we detected in the green text
                        FixClick(inputX, inputY)
                        Sleep(100)
                        
                        ProcessLog("Sending number: " number)
                        for digit in StrSplit(number) {
                            Send(digit)
                            Sleep(50)
                        }
                        return true
                    }
                }
            }
        }
    }

    ProcessLog("Could not detect valid captcha")
    return false
}


TogglePriorityDropdowns(*) {
    global PriorityUpgrade, priority1, priority2, priority3, priority4, priority5, priority6
    shouldShow := PriorityUpgrade.Value

    priority1.Visible := shouldShow
    priority2.Visible := shouldShow
    priority3.Visible := shouldShow
    priority4.Visible := shouldShow
    priority5.Visible := shouldShow
    priority6.Visible := shouldShow

    for unit in UnitData {
        unit.PriorityText.Visible := shouldShow
    }
}