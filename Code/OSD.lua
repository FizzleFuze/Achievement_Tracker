-- See license.md for copyright info
local function Log(...)
    FFL_LogMessage(CurrentModDef.title, "OSD", ...)
end

local UpdateThread

function CreateOSD()
    local Parent = Dialogs.InGameInterface
    local ParentDialog = OpenDialog("InGameInterface")

    if Parent.FFAT_PA_Title then
        Parent.FFAT_PrimaryAchievement:Open()
        UpdateOSD()
    else
        local OSD = XWindow:new({
            Id = "FFAT_PrimaryAchievement",
            Margins = box(0, 100, 0, 0), --below InfoBar
            HAlign = "center",
        }, ParentDialog)

        XText:new({
            Id = "FFAT_PA_Title",
            TextStyle = "AchievementTitle",
            Dock = "top",
        }, OSD)
        XText:new({
            Id = "FFAT_PA_Text",
            Margins = box(0, OSD[1].measure_height, 0, 0), --below title
            RolloverTemplate = "Rollover",
            RolloverTitle = FFL_Translate("Primary Achievement"),
            RolloverText = FFL_Translate("Progress towards primary achievement"),
            TextStyle = "AchievementDescr",
            Background = 0,
            Dock = "top",
        }, OSD)

        OSD:SetParent(ParentDialog)
    end

    if Parent.FFAT_PrimaryAchievement then
        UpdateOSD()
    end
end

function UpdateOSD()
    local Title, Text, OSD
    local Parent = Dialogs.InGameInterface

    local function UpdateText()
        for _, A in pairs(MainCity.labels.TrackedAchievement) do
            if A.Name == CurrentModOptions:GetProperty("ShowOnScreen") then
                Title = A.Name
                Text = A.Description .. "\nCurrent Progress: " .. FFL_FormatNumber(A.Value) .. " / " .. FFL_FormatNumber(A.Target)
                OSD[1]:SetText(FFL_Translate(Title))
                OSD[2]:SetText(FFL_Translate(Text))
                UpdateThread = nil
                return
            end
        end
    end

    if not Parent then
        return -- not done init yet :(
    end

    if not Parent.FFAT_PrimaryAchievement then
        CreateOSD()
        if not Parent.FFAT_PrimaryAchievement then
            Log("ERROR", "Can't update non-existing OSD!")
            return
        end
    end

    OSD = Parent.FFAT_PrimaryAchievement
    if not UpdateThread then
        UpdateThread = CreateGameTimeThread(UpdateText)
    end
end

-- this causes the game to get stuck on an infinite load screen with no errors logged to file
--[[
local FF_OpenDialog = OpenDialog
function OpenDialog(ID, ...)
    local Dialog = FF_OpenDialog(ID, ...)
    if ID == "InGameInterface" then
        CreateRealTimeThread(CreateOSD)
    end
    return Dialog
end
--]]