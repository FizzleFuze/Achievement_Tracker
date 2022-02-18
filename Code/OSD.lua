-- See license.md for copyright info
local function Log(...)
    FFL_LogMessage(CurrentModDef.title, "OSD", ...)
end

local UpdateThread

function CreateOSD()
    local InfoBar = Dialogs.Infobar
    local InfoBarDialog = OpenDialog("Infobar")

    if InfoBar.FFAT_PrimaryAchievement then
        InfoBar.FFAT_PrimaryAchievement:Open()
        UpdateOSD()
    else
        local OSD = XWindow:new({
            Id = "FFAT_PrimaryAchievement",
            Margins = box(0, 100, 8, 0),
            Valign = "top",
            Dock = "right",
        }, InfoBarDialog)

        XText:new({
            Id = "FFAT_PrimaryAchievementText",
            RolloverTemplate = "Rollover",
            RolloverTitle = FFL_Translate("Primary Achievement"),
            RolloverText = FFL_Translate("Progress towards primary achievement"),
            TextStyle = "MessageText",
            Background = 0,
        }, OSD)

        OSD:SetParent(InfoBarDialog)
    end

    if InfoBar.FFAT_PrimaryAchievement then
        UpdateOSD()
    end
end

function UpdateOSD()

    local Text
    local OSD

    local function UpdateText()
        OSD[1]:SetText(FFL_Translate(Text))
        Sleep(1000) -- don't get too spammy
        UpdateThread = nil
    end

    local Primary = CurrentModOptions:GetProperty("ShowOnScreen")
    local Achievement

    for _, A in pairs(MainCity.labels.TrackedAchievement) do
        if A.Name == Primary then
            Achievement = A
            break
        end
    end

    if not Achievement or Achievement == "None" then
        Log("No achievement tracked")
        return
    end

    if not Dialogs.Infobar then
        return -- not done init yet :(
    end

    if not Dialogs.Infobar.FFAT_PrimaryAchievement then
        CreateOSD()
        if not Dialogs.Infobar.FFAT_PrimaryAchievement then
            Log("ERROR", "Can't update non-existing OSD!")
            return
        end
    end

    OSD = Dialogs.Infobar.FFAT_PrimaryAchievement
    Text = Achievement.Name .. "\n" .. Achievement.Description .. "\n\nCurrent Progress:\n" .. FFL_FormatNumber(Achievement.Value) .. " / " .. FFL_FormatNumber(Achievement.Target)
    if not UpdateThread then
        UpdateThread = CreateGameTimeThread(UpdateText)
    end
end

-- this causes the game to get stuck on an infinite load screen with no errors logged to file
--[[
local FF_OpenDialog = OpenDialog
function OpenDialog(DialogString, ...)
    local Dialog = FF_OpenDialog(DialogString, ...)
    if DialogString == "Infobar" then
        CreateRealTimeThread(CreateOSD)
    end
end
--]]