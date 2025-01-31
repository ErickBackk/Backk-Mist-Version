#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\FindText.ahk
#Include %A_ScriptDir%\Lib\imageForCS.ahk

global macroStartTime := A_TickCount
global stageStartTime := A_TickCount



;HotKeys
F1:: {
    moveRobloxWindow()
}
F2:: {
    if (!ValidateMode()) {
        return
    }
    StartSelectedMode()
}
F3:: {
    Reload()
}

PlacingUnits() {
    global successfulCoordinates
    successfulCoordinates := []
    placedCounts := Map()  

    anyEnabled := false
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := "enabled" slotNum
        enabled := %enabled%
        enabled := enabled.Value
        if (enabled) {
            anyEnabled := true
            break
        }
    }

    if (!anyEnabled) {
        ProcessLog("No units enabled - skipping to monitoring")
        return MonitorStage()
    }

    placementPoints := GenerateCirclePoints()
    
    ; Go through each slot
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := "enabled" slotNum
        enabled := %enabled%
        enabled := enabled.Value
        
        ; Get number of placements wanted for this slot
        placements := "placement" slotNum
        placements := %placements%
        placements := Integer(placements.Text)
        
        ; Initialize count if not exists
        if !placedCounts.Has(slotNum)
            placedCounts[slotNum] := 0
        
        ; If enabled, place all units for this slot
        if (enabled && placements > 0) {
            ProcessLog("Placing Unit " slotNum " (0/" placements ")")
            
            ; Place all units for this slot
            while (placedCounts[slotNum] < placements) {
                for point in placementPoints {
                    if PlaceUnit(point.x, point.y, slotNum) {
                        successfulCoordinates.Push({x: point.x, y: point.y, slot: slotNum})
                        placedCounts[slotNum] += 1
                        ProcessLog("Placed Unit " slotNum " (" placedCounts[slotNum] "/" placements ")")
                        
                        CheckAbility()
                        FixClick(560, 560) ; Move Click
                        break
                    }
                    
                    if CheckForXp()
                        return MonitorStage()
                    Reconnect()
                }
                Sleep(500)
            }
        }
    }
    
    ProcessLog("All units placed to requested amounts")
    UpgradeUnits()
}


UpgradeUnits() {
    global successfulCoordinates, PriorityUpgrade, priority1, priority2, priority3, priority4, priority5, priority6

    totalUnits := Map()    
    upgradedCount := Map()  
    
    ; Initialize counters
    for coord in successfulCoordinates {
        if (!totalUnits.Has(coord.slot)) {
            totalUnits[coord.slot] := 0
            upgradedCount[coord.slot] := 0
        }
        totalUnits[coord.slot]++
    }

    ProcessLog("Initiating Unit Upgrades...")

    if (PriorityUpgrade.Value) {
        ProcessLog("Using priority upgrade system")
        
        ; Go through each priority level (1-6)
        for priorityNum in [1, 2, 3, 4, 5, 6] {
            ; Find which slot has this priority number
            for slot in [1, 2, 3, 4, 5, 6] {
                priority := "priority" slot
                priority := %priority%
                if (priority.Text = priorityNum) {
                    ; Skip if no units in this slot
                    hasUnitsInSlot := false
                    for coord in successfulCoordinates {
                        if (coord.slot = slot) {
                            hasUnitsInSlot := true
                            break
                        }
                    }
                    
                    if (!hasUnitsInSlot) {
                        continue
                    }

                    ProcessLog("Starting upgrades for priority " priorityNum " (slot " slot ")")
                    
                    ; Keep upgrading current slot until all its units are maxed
                    while true {
                        slotDone := true
                        
                        for index, coord in successfulCoordinates {
                            if (coord.slot = slot) {
                                slotDone := false
                                UpgradeUnit(coord.x, coord.y)

                                if CheckForXp() {
                                    ProcessLog("Stage ended during upgrades, proceeding to results")
                                    successfulCoordinates := []
                                    MonitorStage()
                                    return
                                }

                                if MaxUpgrade() {
                                    upgradedCount[coord.slot]++
                                    ProcessLog("Max upgrade reached for Unit " coord.slot " (" upgradedCount[coord.slot] "/" totalUnits[coord.slot] ")")
                                    successfulCoordinates.RemoveAt(index)
                                    FixClick(325, 185) ;Close upg menu
                                    break
                                }

                                Sleep(200)
                                CheckAbility()
                                FixClick(560, 560) ; Move Click
                                Reconnect()
                            }
                        }
                        
                        if (slotDone || successfulCoordinates.Length = 0) {
                            ProcessLog("Finished upgrades for priority " priorityNum)
                            break
                        }
                    }
                }
            }
        }
        
        ProcessLog("Priority upgrading completed")
        return MonitorStage()
    } else {
        ; Normal upgrade (no priority)
        while true {
            if (successfulCoordinates.Length == 0) {
                ProcessLog("All units maxed, proceeding to monitor stage")
                return MonitorStage()
            }

            for index, coord in successfulCoordinates {
                UpgradeUnit(coord.x, coord.y)

                if CheckForXp() {
                    ProcessLog("Stage ended during upgrades, proceeding to results")
                    successfulCoordinates := []
                    MonitorStage()
                    return
                }

                if MaxUpgrade() {
                    upgradedCount[coord.slot]++
                    ProcessLog("Max upgrade reached for Unit " coord.slot " (" upgradedCount[coord.slot] "/" totalUnits[coord.slot] ")")
                    successfulCoordinates.RemoveAt(index)
                    FixClick(325, 185) ;Close upg menu
                    continue
                }

                Sleep(200)
                CheckAbility()
                FixClick(560, 560) ; Move Click
                Reconnect()
            }
        }
    }
}

StoryMode() {
    global StoryDropdown, StoryActDropdown
    
    ; Get current map and act
    currentStoryMap := StoryDropdown.Text
    currentStoryAct := StoryActDropdown.Text
    
    ; Execute the movement pattern
    ProcessLog("Moving to position for " currentStoryMap)
    StoryMovement()
    
    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)){
        StoryMovement()
    }
    ProcessLog("Starting " currentStoryMap " - " currentStoryAct)
    StartStory(currentStoryMap, currentStoryAct)

    ; Handle play mode selection
    if (StoryActDropdown.Text != "Infinity") {
        PlayHere()  ; Always PlayHere for normal story acts
    } else {
        if (MatchMaking.Value) {
            FindMatch()
        } else {
            PlayHere()
        }
    }

    RestartStage()
}


LegendMode() {
    global LegendDropdown, LegendActDropdown
    
    ; Get current map and act
    currentLegendMap := LegendDropdown.Text
    currentLegendAct := LegendActDropdown.Text
    
    ; Execute the movement pattern
    ProcessLog("Moving to position for " currentLegendMap)
    StoryMovement()
    
    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        StoryMovement()
    }
    ProcessLog("Starting " currentLegendMap " - " currentLegendAct)
    StartLegend(currentLegendMap, currentLegendAct)

    ; Handle play mode selection
    if (MatchMaking.Value) {
        FindMatch()
    } else {
        PlayHere()
    }

    RestartStage()
}

RaidMode() {
    global RaidDropdown, RaidActDropdown
    
    ; Get current map and act
    currentRaidMap := RaidDropdown.Text
    currentRaidAct := RaidActDropdown.Text
    
    ; Execute the movement pattern
    ProcessLog("Moving to position for " currentRaidMap)
    RaidMovement()
    
    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        RaidMovement()
    }
    ProcessLog("Starting " currentRaidMap " - " currentRaidAct)
    StartRaid(currentRaidMap, currentRaidAct)
    ; Handle play mode selection
    if (MatchMaking.Value) {
        FindMatch()
    } else {
        PlayHere()
    }

    RestartStage()
}

InfinityCastleMode() {
    global InfinityCastleDropdown
    
    ; Get current difficulty
    currentDifficulty := InfinityCastleDropdown.Text
    
    ; Execute the movement pattern
    ProcessLog("Moving to position for Infinity Castle")
    InfCastleMovement()
    
    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        InfCastleMovement()
    }
    ProcessLog("Starting Infinity Castle - " currentDifficulty)

    ; Select difficulty with direct clicks
    if (currentDifficulty = "Normal") {
        FixClick(418, 375)  ; Click Easy Mode
    } else {
        FixClick(485, 375)  ; Click Hard Mode
    }
    
    ;Start Inf Castle
    FixClick(400, 435)
    FixClick(402, 435)
    FixClick(404, 435)

    RestartStage()
}

ChallengeMode() {    
    ProcessLog("Moving to Challenge mode")
    ChallengeMovement()
    
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        ChallengeMovement()
    }

    RestartStage()
}

CursedWombMode() {
    ProcessLog("Moving to Cursed womb")
    CursedWombMovement()

    while !(ok := FindText(&X, &Y, 445, 440, 650, 487, 0, 0, Capacity)) {
        CursedWombMovement()
    }

    FixClick(215, 285)
    sleep (500)
    FixClick(345, 370)
    sleep (500)
    
    RestartStage()
}

HolidayHuntMode() {
    ProcessLog("Moving To Holiday Event")
    HolidayMovement()


    if (MatchMaking.Value) {
        FindMatch()
    } else {
        PlayHere()
    }
    
    RestartStage()
}

global priorityOrder := ["New Path Debuff", "Range Buff", "Attack Buff", "Health Debuff", "Shield Debuff", "Regen Debuff", "Explosive Death Debuff", "Cooldown Buff", "Speed Debuff", "Yen Buff"]
UnitExistence := "|<>*91$66.btzzzzzzyDzXlzzzzzzyDzXlzzzzzzyDzXlzzzyzzyDbXlUS0UM3UC1XlUA0UE30A1XlW4EXl34AMXlX0sbXXC80XVX4MbXX6A1U3UA0bk30ARk7UC0bk3UA1sDUz8bw3kC1zzbyszzzzzzzzbw1zzzzzzzzby3zzzzzzzzzzjzzzzzzU"

cardSelector() {

    if (ModeDropdown.Text != "Holiday Hunt")
        return

    ProcessLog("Choosing Cards")
    if (ok := FindText(&X, &Y, 78, 182, 400, 451, 0, 0, UnitExistence)) {
        FixClick(329, 184) ; close upg menu
        sleep 100
    }

    FixClick(59, 572) ; Untarget Mouse
    sleep 500

    for index, priority in priorityOrder {
        if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, textCards.Get(priority))) {
            FindText().Click(cardX, cardY, 0)
            MouseMove 0, 10, 2, "R"
            Click 2
            sleep 1000
            MouseMove 0, 120, 2, "R"
            Click 2
            ProcessLog(Format("Picked Card: {}", priority))
            sleep 5000
            return
        }
    }
    ProcessLog("Failed to choose a card")
}

MonitorEndScreen() {
    global mode, StoryDropdown, StoryActDropdown, ReturnLobbyBox, MatchMaking, challengeStartTime, inChallengeMode

    Loop {
        Sleep(3000)  ; Wait 3 seconds between clicks
        
        ; Click middle of screen to claim any drops/rewards
        FixClick(320, 390)
        Loop 5 {
            Send "{WheelDown}"
            Sleep 50
        }
        FixClick(325, 185)

        if (ok := FindText(&X, &Y, 142, 129, 659, 171, 0, 0, LobbyText)) {
            ; Challenge mode logic - handle this first before other mode-specific logic
            if (!inChallengeMode && ChallengeBox.Value) {
                timeElapsed := A_TickCount - challengeStartTime
                if (timeElapsed >= 1800000) {  ; 30 minutes in milliseconds
                    ProcessLog("30 minutes passed - switching to Challenge mode")
                    inChallengeMode := true
                    challengeStartTime := A_TickCount
                    FixClick(300, 117)  ; Return to lobby
                    FixClick(302, 117)
                    FixClick(304, 117)
                    sleep (1000)
                    FixClick(400, 117) ; Return to lobby for cursed womb
                    FixClick(402, 117)
                    FixClick(404, 117)
                    return CheckLobby()
                }
            }
            
            ; If we're in challenge mode and finished, reset and return to normal mode
            if (inChallengeMode) {
                ProcessLog("Challenge completed - returning to selected mode")
                inChallengeMode := false
                challengeStartTime := A_TickCount
                FixClick(400, 117) ; Return to lobby for challenge
                FixClick(402, 117)
                FixClick(404, 117)
                return CheckLobby()
            }
        ; For Story mode with non-Infinity acts
        if (mode = "Story" && StoryActDropdown.Text != "Infinity") {
            if (ok := FindText(&X, &Y, 142, 129, 659, 171, 0, 0, LobbyText) or (ok:=FindText(&X, &Y, 142, 129, 659, 171, 0, 0, NextLevel))) {
                if (NextLevelBox.Value && lastResult = "win") {
                    ProcessLog("Level complete, continuing to next level")
                    FixClick(515, 115)  ; Click next level
                    FixClick(517, 115)
                    FixClick(519, 115)
                    return RestartStage()
                } else if (lastResult = "win") {
                    ProcessLog("Level complete, replaying level")
                    FixClick(400, 117)  ; Click replay
                    FixClick(402, 117)
                    FixClick(404, 117)
                    return RestartStage()
                } else {
                    ProcessLog("Level failed, Restarting")
                    FixClick(515, 115)  ; Click replace
                    FixClick(517, 115)
                    FixClick(519, 115)
                    return RestartStage()
                }
            }
        }
        else if (mode = "Story" && StoryActDropdown.Text = "Infinity") {
                ProcessLog("Infinity Ended, Restarting")
                FixClick(490, 117)
                FixClick(492, 117)
                FixClick(494, 117)
                return RestartStage()
        }
        else if (mode = "Infinity Castle") {
                if (lastResult = "win") { 
                    ProcessLog("Floor complete, continue to next floor")
                    FixClick(490, 117) ; Click next floor/level
                    FixClick(492, 117)
                    FixClick(494, 117)
                    return RestartStage()
                } else {
                    ProcessLog("Floor failed, Restarting")
                    FixClick(490, 117)
                    FixClick(492, 117)
                    FixClick(494, 117)
                    return RestartStage()
            }
        }
        else if (mode = "Cursed Womb") {
               if (lastResult = "win") {
                  ProcessLog("Cursed Womb completed successfully")
                  FixClick(400, 117) ; Return to lobby
                  FixClick(402, 117)
                  FixClick(404, 117)
                  return CheckLobby()
                } else {
                  ProcessLog("Cursed Womb failed")
                  FixClick(400, 117)
                  FixClick(402, 117)
                  FixClick(404, 117)
                  return CheckLobby()
                }   
            }
        else if (mode = "Holiday Hunt") {
               if (lastResult = "win") {
                  ProcessLog("Holiday Hunt completed successfully")
                  FixClick(400, 117) ; Return to lobby
                  FixClick(402, 117)
                  FixClick(404, 117)
                  return CheckLobby()
                } else {
                  ProcessLog("Holiday Hunt Failed")
                  FixClick(400, 117)
                  FixClick(402, 117)
                  FixClick(404, 117)
                  return CheckLobby()
                }   
            }
        else {
                if (ReturnLobbyBox.Value) { 
                ProcessLog("Return to lobby enabled, returning to lobby")
                FixClick(300, 117) ; Clicking Return to lobby
                FixClick(302, 117)
                FixClick(304, 117)
                return CheckLobby()
            } else {
                ProcessLog("Run complete, replaying")
                FixClick(490, 117) ; Clicking Replay
                FixClick(492, 117)
                FixClick(494, 117)
                return RestartStage()
            }
        }
    }

        Reconnect()
    }
}


MonitorStage() {
    global Wins, loss, mode, StoryActDropdown
    
    lastClickTime := A_TickCount

    Loop {
        Sleep(1000)
        
        if (mode = "Story" && StoryActDropdown.Text = "Infinity" or ModeDropdown.Text = "Holiday Hunt") {
            timeElapsed := A_TickCount - lastClickTime
            if (timeElapsed >= 300000) {  ; 5 minutes
                ProcessLog("Performing anti-AFK click")
                FixClick(560, 560)  ; Move click
                lastClickTime := A_TickCount
            }
        }

        if (ModeDropdown.Text = "Holiday Hunt" && successfulCoordinates.Length = 0) {
            cardSelector()
        }

        ; Check for XP screen
        if CheckForXp() {
            ProcessLog("Checking win/loss status")
            
            ; Calculate stage end time here, before checking win/loss
            stageEndTime := A_TickCount
            stageLength := FormatStageTime(stageEndTime - stageStartTime)
            
            ; Check for Victory or Defeat
            if (ok := FindText(&X, &Y, 175, 188, 294, 253, 0, 0, VictoryText)) {
                ProcessLog("Victory detected - Stage Length: " stageLength)
                Wins += 1
                SendWebhookWithTime(true, stageLength)
                FixClick(320, 390) ; clicks next
                FixClick(322, 390)
                FixClick(324, 390)
                return MonitorEndScreen()
            }
            else if (ok := FindText(&X, &Y, 192, 190, 323, 247, 0, 0, DefeatText)) {
                ProcessLog("Defeat detected - Stage Length: " stageLength)
                loss += 1
                SendWebhookWithTime(false, stageLength) 
                FixClick(320, 390) ; clicks next
                FixClick(322, 390)
                FixClick(324, 390)
                return MonitorEndScreen()
            }
        }
        Reconnect()
    }
}

StoryMovement() {
    FixClick(85, 295)
    sleep (1000)
    SendInput ("{w down}")
    Sleep(300)
    SendInput ("{w up}")
    Sleep(300)
    SendInput ("{d down}")
    SendInput ("{w down}")
    Sleep(4500)
    SendInput ("{d up}")
    SendInput ("{w up}")
    Sleep(500)
}

RaidMovement() {
    FixClick(765, 475) ; Click Area
    Sleep(300)
    FixClick(495, 410)
    Sleep(500)
    SendInput ("{a down}")
    Sleep(400)
    SendInput ("{a up}")
    Sleep(500)
    SendInput ("{w down}")
    Sleep(5000)
    SendInput ("{w up}")
}

InfCastleMovement() {
    FixClick(765, 475)
    Sleep (300)
    FixClick(370, 330)
    Sleep (500)
    SendInput ("{w down}")
    Sleep (500)
    SendInput ("{w up}")
    Sleep (500)
    SendInput ("{a down}")
    sleep (4000)
    SendInput ("{a up}")
    Sleep (500)
}

ChallengeMovement() {
    FixClick(765, 475)
    Sleep (500)
    FixClick(300, 415)
    SendInput ("{a down}")
    sleep (7000)
    SendInput ("{a up}")
}

CursedWombMovement() {
    FixClick(85, 295)
    Sleep (500)
    SendInput ("{a down}")
    sleep (3000)
    SendInput ("{a up}")
    sleep (1000)
    SendInput ("{s down}")
    sleep (4000)
    SendInput ("{s up}")
}

HolidayMovement() {
	FixClick(89, 302)
	Sleep (2000)
	SendInput ("{a up}")
	Sleep (100)
	SendInput ("{a down}")
	Sleep (6000)
	SendInput ("{a up}")
	Sleep (1200)
	FixClick(469, 340)
}

StartStory(map, StoryActDropdown) {
    navKeys := StrSplit(FileExist("Settings\UINavigation.txt") ? FileRead("Settings\UINavigation.txt", "UTF-8") : "\,#,}", ",")
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)

    downArrows := GetStoryDownArrows(map) ; Map selection down arrows
    Loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select storymode
    Sleep(500)

    Loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(1000)
    
    actArrows := GetStoryActDownArrows(StoryActDropdown) ; Act selection down arrows
    Loop actArrows {
        SendInput("{Down}")
        Sleep(200)
    }
    
    SendInput("{Enter}") ; Select Act
    Sleep(500)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartLegend(map, LegendActDropdown) {
    
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)
    SendInput("{Down}")
    Sleep(500)
    SendInput("{Enter}") ; Opens Legend Stage

    downArrows := GetLegendDownArrows(map) ; Map selection down arrows
    Loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }
    
    SendInput("{Enter}") ; Select LegendStage
    Sleep(500)

    Loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(1000)
    
    actArrows := GetLegendActDownArrows(LegendActDropdown) ; Act selection down arrows
    Loop actArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Act
    Sleep(500)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartRaid(map, RaidActDropdown) {
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)

    downArrows := GetRaidDownArrows(map) ; Map selection down arrows
    Loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Raid

    Loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(500)
    
    actArrows := GetRaidActDownArrows(RaidActDropdown) ; Act selection down arrows
    Loop actArrows {
        SendInput("{Down}")
        Sleep(200)
    }
    
    SendInput("{Enter}") ; Select Act
    Sleep(300)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

PlayHere() {
    FixClick(400, 435)  ; Play Here or Find Match 
    Sleep (300)
    FixClick(330, 325) ;Click Play here
    Sleep (300)
    FixClick(400, 465) ;
    Sleep (300)
}

FindMatch() {
    startTime := A_TickCount

    Loop {
        if (A_TickCount - startTime > 50000) {
            ProcessLog("Matchmaking timeout, restarting mode")
            FixClick(400, 520)
            return StartSelectedMode()
        }

        FixClick(400, 435)  ; Play Here or Find Match 
        Sleep(300)
        FixClick(460, 330)  ; Click Find Match
        Sleep(300)
        
        ; Try captcha    
        if (!CaptchaDetect(252, 292, 300, 50, 400, 335)) {
            ProcessLog("Captcha not detected, retrying...")
            FixClick(585, 190)  ; Click close
            Sleep(1000)
            continue
        }
        FixClick(300, 385)  ; Enter captcha
        return true
    }
}

GetStoryDownArrows(map) {
    switch map {
        case "Planet Greenie": return 2
        case "Walled City": return 3
        case "Snowy Town": return 4
        case "Sand Village": return 5
        case "Navy Bay": return 6
        case "Fiend City": return 7
        case "Spirit World": return 8
        case "Ant Kingdom": return 9
        case "Magic Town": return 10
        case "Haunted Academy": return 11
        case "Magic Hills": return 12
        case "Space Center": return 13
        case "Alien Spaceship": return 14
        case "Fabled Kingdom": return 15
        case "Ruined City": return 16
        case "Puppet Island": return 17
        case "Virtual Dungeon": return 18
        case "Snowy Kingdom": return 19
        case "Dungeon Throne": return 20
        case "Mountain Temple": return 21
        case "Rain Village": return 22
    }
}

GetStoryActDownArrows(StoryActDropdown) {
    switch StoryActDropdown {
        case "Infinity": return 1
        case "Act 1": return 2
        case "Act 2": return 3
        case "Act 3": return 4
        case "Act 4": return 5
        case "Act 5": return 6
        case "Act 6": return 7
    }
}


GetLegendDownArrows(map) {
    switch map {
        case "Magic Hills": return 1
        case "Space Center": return 3
        case "Fabled Kingdom": return 4
        case "Virtual Dungeon": return 6
        case "Dungeon Throne": return 7
        case "Rain Village": return 8
    }
}

GetLegendActDownArrows(LegendActDropdown) {
    switch LegendActDropdown {
        case "Act 1": return 1
        case "Act 2": return 2
        case "Act 3": return 3
    }
}

GetRaidDownArrows(map) {
    switch map {
        case "Sacred Planet": return 1
        case "Strange Town": return 2
        case "Ruined City": return 3
    }
}

GetRaidActDownArrows(RaidActDropdown) {
    switch RaidActDropdown {
        case "Act 1": return 1
        case "Act 2": return 2
        case "Act 3": return 3
        case "Act 4": return 4
        case "Act 5": return 5
    }
}

Zoom() {
    MouseMove(400, 300)
    Sleep 100

    ; Zoom in smoothly
    Loop 10 {
        Send "{WheelUp}"
        Sleep 50
    }

    ; Look down
    Click
    MouseMove(400, 400)  ; Move mouse down to angle camera down
    
    ; Zoom back out smoothly
    Loop 20 {
        Send "{WheelDown}"
        Sleep 50
    }
    
    ; Move mouse back to center
    MouseMove(400, 300)
}

TpSpawn() {
    FixClick(26, 570) ;click settings
    Sleep 300
    FixClick(400, 215)
    Sleep 300
    loop 4 {
        Sleep 150
        SendInput("{WheelDown 1}") ;scroll
    }
    Sleep 300
    FixClick(520, 270) ;Tp spawn
    Sleep 300
    FixClick(583, 147)
    Sleep 300
}

CloseChat() {
    if (ok := FindText(&X, &Y, 123, 50, 156, 79, 0, 0, OpenChat)) {
        ProcessLog "Closing Chat"
        FixClick(138, 30) ;close chat
    }
}

BasicSetup() {
    SendInput("{Tab}") ; Closes Player leaderboard
    Sleep 300
    FixClick(564, 72) ; Closes Player leaderboard
    Sleep 300
    CloseChat()
    Sleep 300
    Zoom()
    Sleep 300
    TpSpawn()
}

DetectMap() {
    ProcessLog("Determining Movement Necessity on Map...")
    startTime := A_TickCount
    
    Loop {
        ; Check if we waited more than 5 minute for votestart
        if (A_TickCount - startTime > 300000) {
            ProcessLog("Vote screen not found after 5 minute, Checking if still finding match")
            return CheckMatchmaking()
        }

        ; Check for vote screen
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            ProcessLog("No Map Found or Movement Unnecessary")
            return "no map found"
        }

        mapPatterns := Map(
            "Ant Kingdom", Ant,
            "Sand Village", Sand,
            "Magic Town", MagicTown, 
            "Magic Hill", MagicHills,
            "Navy Bay", Navy,
            "Snowy Town", SnowyTown,
            "Fiend City", Fiend,
            "Spirit World", Spirit,
            "Haunted Academy", Academy,
            "Space Center", SpaceCenter,
            "Mountain Temple", Mount,
            "Cursed Festival", Cursed,
            "Nightmare Train", Nightmare
        )

        for mapName, pattern in mapPatterns {
            if (ok := FindText(&X, &Y, 10, 90, 415, 160, 0, 0, pattern)) {
                ProcessLog("Detected map: " mapName)
                return mapName
            }
        }
        
        Sleep 1000
        Reconnect()
    }
}

HandleMapMovement(MapName) {
    ProcessLog("Executing Movement for: " MapName)
    
    switch MapName {
        case "Snowy Town":
            MoveForSnowyTown()
        case "Sand Village":
            MoveForSandVillage()
        case "Ant Kingdom":
            MoveForAntKingdom()
        case "Magic Town":
            MoveForMagicTown()
        case "Magic Hill":
            MoveForMagicHill()
        case "Navy Bay":
            MoveForNavyBay()
        case "Fiend City":
            MoveForFiendCity()
        case "Spirit World":
            MoveForSpiritWorld()
        case "Haunted Academy":
            MoveForHauntedAcademy()
        case "Space Center":
            MoveForSpaceCenter()
        case "Mountain Temple":
            MoveForMountainTemple()
        case "Cursed Festival":
            MoveForCursedFestival()
        case "Nightmare Train":
            MoveForNightmareTrain()
    }
}

MoveForSnowyTown() {
    Fixclick(700, 125, "Right")
    Sleep (6000)
    Fixclick(615, 115, "Right")
    Sleep (3000)
    Fixclick(725, 300, "Right")
    Sleep (3000)
    Fixclick(715, 395, "Right")
    Sleep (3000)
}

MoveForNavyBay() {
    SendInput ("{a down}")
    SendInput ("{w down}")
    Sleep (1700)
    SendInput ("{a up}")
    SendInput ("{w up}")
}

MoveForSandVillage() {
    Fixclick(777, 415, "Right")
    Sleep (3000)
    Fixclick(560, 555, "Right")
    Sleep (3000)
    Fixclick(125, 570, "Right")
    Sleep (3000)
    Fixclick(200, 540, "Right")
    Sleep (3000)
}

MoveForFiendCity() {
    Fixclick(185, 410, "Right")
    Sleep (3000)
    SendInput ("{a down}")
    Sleep (3000)
    SendInput ("{a up}")
    Sleep (500)
    SendInput ("{s down}")
    Sleep (2000)
    SendInput ("{s up}")
}

MoveForSpiritWorld() {
    SendInput ("{d down}")
    SendInput ("{w down}")
    Sleep(7000)
    SendInput ("{d up}")
    SendInput ("{w up}")
    sleep(500)
    Fixclick(400, 15, "Right")
    sleep(4000)
}

MoveForAntKingdom() {
    Fixclick(130, 550, "Right")
    Sleep (3000)
    Fixclick(130, 550, "Right")
    Sleep (4000)
    Fixclick(30, 450, "Right")
    Sleep (3000)
    Fixclick(120, 100, "Right")
    sleep (3000)
}

MoveForMagicTown() {
    Fixclick(700, 315, "Right")
    Sleep (2500)
    Fixclick(585, 535, "Right")
    Sleep (3000)
    SendInput ("{d down}")
    Sleep (3800)
    SendInput ("{d up}")
}

MoveForMagicHill() {
    Fixclick(45, 185, "Right")
    Sleep (3000)
    Fixclick(140, 250, "Right")
    Sleep (2500)
    Fixclick(25, 485, "Right")
    Sleep (3000)
    Fixclick(110, 455, "Right")
    Sleep (3000)
}

MoveForHauntedAcademy() {
    SendInput ("{d down}")
    sleep (3500)
    SendInput ("{d up}")
}

MoveForSpaceCenter() {
    Fixclick(160, 280, "Right")
    Sleep (7000)
}

MoveForMountainTemple() {
    Fixclick(40, 500, "Right")
    Sleep (4000)
}

MoveForCursedFestival(){
    SendInput ("{d down}")
    sleep (1800)
    SendInput ("{d up}")
}

MoveForNightmareTrain() {
    SendInput ("{a down}")
    sleep (1800)
    SendInput ("{a up}")
}

FindAndClickColor(targetColor := 0x006783, searchArea := [0, 0, A_ScreenWidth, A_ScreenHeight]) {
    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the pixel search
    if (PixelSearch(&foundX, &foundY, x1, y1, x2, y2, targetColor, 0)) {
        ; Color found, click on the detected coordinates
        Fixclick(foundX, foundY, "Right")
        ;AddToLog("Color found and clicked at: X" foundX " Y" foundY)
        return true

    } else {
    }
}

MoveForHolidayHunt() {
    loop 80 {
        Sleep 100

        if FindAndClickColor() {
            break
        }
    }
    Sleep (4000)
}


    
RestartStage() {
    currentMap := DetectMap()
    
    ; Wait for loading
    CheckLoaded()

    ; Do initial setup and map-specific movement during vote timer
    BasicSetup()
    if (currentMap != "no map found") {
        HandleMapMovement(currentMap)
    }

    ; Wait for game to actually start
    StartedGame()

    if (ModeDropdown.Text = "Holiday Hunt") {
	MoveForHolidayHunt()
    }

    ; Begin unit placement and management
    PlacingUnits()
    
    ; Monitor stage progress
    MonitorStage()
}

Reconnect() {   
    ; Check for Disconnected Screen using FindText
    if (ok := FindText(&X, &Y, 330, 218, 474, 247, 0, 0, Disconnect)) {
        ProcessLog("Lost Connection! Attempting To Reconnect To Private Server...")

        psLink := FileExist("Settings\PrivateServer.txt") ? FileRead("Settings\PrivateServer.txt", "UTF-8") : ""

        ; Reconnect to Ps
        if FileExist("Settings\PrivateServer.txt") && (psLink := FileRead("Settings\PrivateServer.txt", "UTF-8")) {
            ProcessLog("Connecting to private server...")
            Run(psLink)
        } else {
            Run("roblox://placeID=8304191830")  ; Public server if no PS file or empty
        }

        Sleep(30000)
        
        ; Restore window if it exists
        if WinExist(rblxID) {
            forceRobloxSize() 
            Sleep(1000)
        }
        
        ; Keep checking until we're back in
        loop {
            ProcessLog("Reconnecting to Roblox...")
            Sleep(5000)
            
            ; Check if we're back in lobby
            if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
                ProcessLog("Reconnected Successfully!")
                return StartSelectedMode() ; Return to raids
            }
            else {
                ; If not in lobby, try reconnecting again
                Reconnect()
            }
        }
    }
}

PlaceUnit(x, y, slot := 1) {
    SendInput(slot)
    Sleep 50
    FixClick(x, y)
    Sleep 50
    SendInput("q")
    
    if UnitPlaced() {
        Sleep 15
        return true
    }
    return false
}

MaxUpgrade() {
    Sleep 500
    ; Check for max text
    if (ok := FindText(&X, &Y, 225, 388, 278, 412 , 0, 0, MaxText) or (ok:=FindText(&X, &Y, 255, 234, 299, 250, 0, 0, MaxText2))) {
        return true
    }
    return false
}

UnitPlaced() {
    Sleep 2000
    ; Check for upgrade text
    if (ok := FindText(&X, &Y, 170, 230, 284, 252, 0, 0, UpgradeText)) {
        ProcessLog("Unit Placed Successfully")
        FixClick(325, 185) ; close upg menu
        return true
    }
    return false
}

CheckAbility() {
    global AutoAbilityBox  ; Reference your checkbox
    
    ; Only check ability if checkbox is checked
    if (AutoAbilityBox.Value) {
        if (ok := FindText(&X, &Y, 342, 253, 401, 281, 0, 0, AutoOff)) {
            FixClick(373, 237)  ; Turn ability on
            ProcessLog("Auto Ability Enabled")
        }
    }
}

CheckForXp() {
    ; Check for lobby text
    if (ok := FindText(&X, &Y, 537, 158, 759, 191, 0, 0, XpText) or (ok:=FindText(&X, &Y, 215, 351, 437, 404, 0, 0, XpText2))) {
        FixClick(325, 185)
        FixClick(560, 560)
        return true
    }
    return false
}

UpgradeUnit(x, y) {
    FixClick(x, y - 3)
    FixClick(264, 363) ; upgrade button 
    FixClick(264, 363) ; upgrade button
    FixClick(264, 363) ; upgrade button

    sleep(1000)

    if (FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, pick_card)){
        cardSelector()
        Sleep(8000)
    }
}

CheckLobby() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
            break
        }
        Reconnect()
    }
    ProcessLog("Returned to lobby, restarting selected mode")
    return StartSelectedMode()
}

CheckLoaded() {
    loop {
        Sleep(1000)
        
        ; Check for vote screen
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            ProcessLog("Successfully Loaded In")
            Sleep(1000)
            break
        }

        Reconnect()
    }
}

StartedGame() {
    loop {
        Sleep(1000)
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            FixClick(350, 103) ; click yes
            FixClick(350, 100)
            FixClick(350, 97)
            continue  ; Keep waiting if vote screen is still there
        }
        
        ; If we don't see vote screen anymore the game has started
        ProcessLog("Game started")
        global stageStartTime := A_TickCount
        break
    }
}

; circle coordinates
GenerateCirclePoints() {
    points := []
    
    ; Define each circle's radius
    radius1 := 45    ; First circle 
    radius2 := 90    ; Second circle 
    radius3 := 135   ; Third circle 
    radius4 := 180   ; Fourth circle 
    
    ; Angles for 8 evenly spaced points (in degrees)
    angles := [0, 45, 90, 135, 180, 225, 270, 315]
    
    ; First circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius1 * Cos(radians)
        y := centerY + radius1 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ; second circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius2 * Cos(radians)
        y := centerY + radius2 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ; third circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius3 * Cos(radians)
        y := centerY + radius3 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    ;  fourth circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius4 * Cos(radians)
        y := centerY + radius4 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }
    
    return points
}

StartSelectedMode() {
    global inChallengeMode, firstStartup, challengeStartTime
    FixClick(400,340)
    FixClick(400,390)

    if (ChallengeBox.Value && firstStartup) {
        ProcessLog("Auto Challenge enabled - starting with challenge")
        inChallengeMode := true
        firstStartup := false
        challengeStartTime := A_TickCount  ; Set initial challenge time
        ChallengeMode()
        return
    }
    
    ; If we're in challenge mode, do challenge
    if (inChallengeMode) {
        ProcessLog("Starting Challenge Mode")
        ChallengeMode()
        return
    }
    else if (ModeDropdown.Text = "Story") {
        StoryMode()
    }
    else if (ModeDropdown.Text = "Legend") {
        LegendMode()
    }
    else if (ModeDropdown.Text = "Raid") {
        RaidMode()
    }
    else if (ModeDropdown.Text = "Infinity Castle") {
        InfinityCastleMode()
    }
    else if (ModeDropdown.Text = "Cursed Womb") {
        CursedWombMode()
    }
    else if (ModeDropdown.Text = "Holiday Hunt") {
        HolidayHuntMode()
    }
}

FormatStageTime(ms) {
    seconds := Floor(ms / 1000)
    minutes := Floor(seconds / 60)
    hours := Floor(minutes / 60)
    
    minutes := Mod(minutes, 60)
    seconds := Mod(seconds, 60)
    
    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
}


ValidateMode() {
    if (ModeDropdown.Text = "") {
        ProcessLog("Please select a gamemode before starting the macro!")
        return false
    }
    if (!confirmClicked) {
        ProcessLog("Please click the confirm button before starting the macro!")
        return false
    }
    return true
}

CheckMatchmaking() {
    if (ok := FindText(&X, &Y, 556, 113, 598, 153, 0, 0, FindingMatch)) {
        ProcessLog("Still searching for match, returning to detect map")
        RestartStage()
        return
    }
    else {
        Reconnect()
        StartSelectedMode()
    }
 }

 GetNavKeys() {
    return StrSplit(FileExist("Settings\UINavigation.txt") ? FileRead("Settings\UINavigation.txt", "UTF-8") : "\,#,}", ",")
}