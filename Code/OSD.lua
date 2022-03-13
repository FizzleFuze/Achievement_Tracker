-- See license.md for copyright info
local function Log(...)
    FF.Funcs.LogMessage(CurrentModDef.title, "OSD", ...)
end

local AchievementOSD

--open panel for selectable achievements
--2do: add scrollbar
--[[
local function ShowSelectAchievement()
    local function OnClick(...)
        --2do: change achieve
    end

    local function OnDoubleClick(...)
        Dialogs.InGameInterface.FF_AT_SelectAchievement:Close()
    end

    if Dialogs.InGameInterface.FF_AT_SelectAchievement then
        Dialogs.InGameInterface.FF_AT_SelectAchievement:Open()
        return
    end

    local Parent = Dialogs.InGameInterface
    if not Parent then
        Log("ERROR", "No InGameInterface!")
        return
    end

    local Window = FF.X.Create("Window", "FF_AT_SelectAchievement", Parent)
    Window.VAlign = "center"
    Window.Margins = box(0, 0, 0, 0)
    Window.OnMouseButtonDoubleClick = OnDoubleClick
    Window.OnMouseButtonDown = OnClick
    Window.RolloverText = FF.Funcs.Translate("<image UI/Infopanel/left_click.tga 1400>Add/Remove<newline><image UI/Infopanel/left_click.tga 1400>*2 Close")
    Window.RolloverTitle = FF.Funcs.Translate("Select Achievement(s) to Track")

    local Frame = FF.X.Create("Frame", "FF_AT_SA_Frame", Window)
    Frame.FrameBox = box(0,20,0,0)
    Frame.Image = "UI/CommonNew/ip.dds"

    local Title = FF.X.Create("Text", "FF_AT_SA_Title", Frame, "FF_PrimaryAchievement_Title")
    Title:SetText(FF.Funcs.Translate("Track Achievements:"))

    for _, Achievement in pairs(FF.AT.Achievements) do
        local AchievementText = FF.X.Create("Text", "FF_AT_SA_Achievement_" .. Achievement.id, Frame, "FF_PrimaryAchievement_Progress")
        if Achievement.Tracked then
            AchievementText:SetText(FF.Funcs.Translate("<image UI/Infopanel/arrow_remove.dds> "..Achievement.Name))
        else
            AchievementText:SetText(FF.Funcs.Translate("<image UI/Infopanel/arrow_add.dds> "..Achievement.Name))
        end
    end
end
--]]

--make or open the OSD
function CreateOSD()
    Log("Creating OSD")

    local function OnClick(...)
        --ShowSelectAchievement()
    end

    local function OnDoubleClick(...)
        Dialogs.InGameInterface.FF_AT_AchievementOSD:Close()
    end

    if Dialogs.InGameInterface.FF_AT_AchievementOSD then
        Dialogs.InGameInterface.FF_AT_AchievementOSD:Open()
        AchievementOSD = Dialogs.InGameInterface.FF_AT_AchievementOSD
        UpdateOSD()
        return
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
    OSDWindow.ChildrenHandleMouse = false
    OSDWindow.Margins = box(0, 85, 0, 0) --below InfoBar
    OSDWindow.OnMouseButtonDoubleClick = OnDoubleClick
    OSDWindow.OnMouseButtonDown = OnClick
    OSDWindow.RolloverHint = FF.Funcs.Translate("Keep up the good work! =)")
    --OSDWindow.RolloverText = FF.Funcs.Translate("<image UI/Infopanel/left_click.tga 1400>Select<newline><image UI/Infopanel/left_click.tga 1400>*2 Close")
    OSDWindow.RolloverText = FF.Funcs.Translate("<image UI/Infopanel/left_click.tga 1400>*2 Close")
    OSDWindow.RolloverTitle = FF.Funcs.Translate("Achievement Status")
    OSDWindow.transparency = 50
    AchievementOSD = OSDWindow

    local OSDFrame = FF.X.Create("Frame", "FF_AT_PA_Frame", OSDWindow)
    OSDFrame.FrameBox = box(0,32,0,0)
    OSDFrame.Image = "UI/CommonNew/ip.dds"

    local OSDTitle = FF.X.Create("Text", "FF_PrimaryAchievement_Title", OSDFrame, "FF_PrimaryAchievement_Title")
    OSDTitle.HAlign = "center"
    OSDTitle.Margins = box(0,5,0,10)
    OSDTitle:SetText(FF.Funcs.Translate("Achievement Progress"))
end

--update the OSD
function UpdateOSD()
    Log("UpdateOSD")

    if not AchievementOSD then
        Log("WARNING", "No OSD")
        return
    end

    local OSD = AchievementOSD.FF_AT_PA_Frame
    local TrackedCount = 0
    for _, Achievement in pairs(FF.AT.Achievements) do
        if Achievement.Tracked then
            TrackedCount = TrackedCount + 1
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
        else
            if OSD["FF_AT_OSD_" .. Achievement.id] then
                OSD["FF_AT_OSD_" .. Achievement.id]:Close()
            end
        end
    end

    if TrackedCount == 0 then
        AchievementOSD:Close()
    end
end