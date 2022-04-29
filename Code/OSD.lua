-- See license.md for copyright info
local function Log(...)
    FF.Funcs.LogMessage(CurrentModDef.title, "OSD", ...)
end

local AchievementOSD

--make or open the OSD
function CreateOSD()
    Log("Creating OSD")
    Log("Naptime!")
    Sleep(500)
    Log("WAKEUP! PUT ON A LITTLE MAKEUP!")

    local function OnDoubleClick(...)
        Dialogs.InGameInterface.FF_AT_AchievementOSD:Close()
    end

    if Dialogs then
        if Dialogs.InGameInterface then
            if Dialogs.InGameInterface.FF_AT_AchievementOSD then
                Dialogs.InGameInterface.FF_AT_AchievementOSD:Open()
                AchievementOSD = Dialogs.InGameInterface.FF_AT_AchievementOSD
                UpdateOSD()
                return
            end
        end
    end

    local Parent = Dialogs.InGameInterface
    if not Parent then
        Log("ERROR", "No InGameInterface!")
        return
    end

    local DisplayMode = CurrentModOptions:GetProperty("DisplayMode")
    if DisplayMode ~= "OSD" and DisplayMode ~= "Both" then
        return
    end

    --Achievement Tracker OSD
    local OSDWindow = FF.X.Create("Window", "FF_AT_AchievementOSD", Parent)
    OSDWindow.Margins = box(0, 85, 0, 0) --below InfoBar
    OSDWindow.OnMouseButtonDoubleClick = OnDoubleClick
    OSDWindow.RolloverHint = FF.Funcs.Translate("Keep up the good work! =)")
    OSDWindow.RolloverText = FF.Funcs.Translate("<image UI/Infopanel/left_click.tga 1400>*2 Close")
    OSDWindow.RolloverTitle = FF.Funcs.Translate("Achievement Status")
    OSDWindow.transparency = 50
    AchievementOSD = OSDWindow

    local OSDMover = XMoveControl:new({
        Dock = 'top',
        HAlign = "stretch",
        HandleKeyboard = 'false',
        HandleMouse = 'true',
        Id = "FF_AT_OSDMover",
        IdNode = true,
        MinHeight = 35,
        Padding = box(2,2,2,2),
        Transparency = 50,
        VAlign = "stretch",
        ZOrder = 2,
        OnMouseButtonDoubleClick = OnDoubleClick
    }, OSDWindow)

    local OSDFrame = FF.X.Create("Frame", "FF_AT_PA_Frame", AchievementOSD)
    OSDFrame.FrameBox = box(0,32,0,0)
    OSDFrame.Image = "UI/CommonNew/ip.dds"

    local OSDTitle = FF.X.Create("Text", "FF_PrimaryAchievement_Title", OSDFrame, "FF_PrimaryAchievement_Title")
    OSDTitle.HAlign = "center"
    OSDTitle.Margins = box(0,5,0,10)
    OSDTitle:SetText(FF.Funcs.Translate("Achievement Progress"))

    UpdateOSD()
end

--update the OSD
function UpdateOSD()
    Log("UpdateOSD")

    if not AchievementOSD then
        local DisplayMode = CurrentModOptions:GetProperty("DisplayMode")
        if (DisplayMode == "OSD" or DisplayMode == "Both") then
            CreateRealTimeThread(CreateOSD)
            return
        end
    end

    if not UIColony.OSDList then
        Log("WARNING", "No tracked achievements to display!")
        return
    end

    if #UIColony.OSDList == 0 then
        AchievementOSD:Close()
        return
    end

    local OSD = AchievementOSD.FF_AT_PA_Frame


    --hide untracked achievements
    for _, Achievement in pairs(FF.AT.Achievements) do
        local Found = false
        for _, TrackedAchievement in pairs(UIColony.OSDList) do
            if TrackedAchievement == Achievement.Name then
                Found = true
            end
        end

        if not Found and OSD["FF_AT_OSD_" .. Achievement.id] then
            OSD["FF_AT_OSD_" .. Achievement.id]:Close()
        end
    end

    --show tracked achievements
    for _, Achievement in pairs(FF.AT.Achievements) do
        for _, TrackedAchievement in pairs(UIColony.OSDList) do
            if TrackedAchievement == Achievement.Name then
                local Progress
                local Text

                if GetAchievementFlags(Achievement.id) then
                    Progress = "COMPLETE"
                else
                    Progress = FF.Funcs.FormatNumber(Achievement.Value) .. " / " .. FF.Funcs.FormatNumber(Achievement.Target)
                end

                if OSD["FF_AT_OSD_" .. Achievement.id] then
                    Text = OSD["FF_AT_OSD_" .. Achievement.id]
                    Text:Open()
                else
                    Text = FF.X.Create("Text", "FF_AT_OSD_" .. Achievement.id, OSD, "FF_PrimaryAchievement_Progress")
                end
                Text:SetText(FF.Funcs.Translate(Achievement.Name .. ": ") .. Progress)
            end
        end
    end
end