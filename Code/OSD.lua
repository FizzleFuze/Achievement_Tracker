-- See license.md for copyright info
local function Log(...)
    FF.Funcs.LogMessage(CurrentModDef.title, "OSD", ...)
end

--locals
local UpdateThread

function CreateOSD()
    local ShowMAWindow = SharedModEnv["FF_AT_ShowMainAchievementWindow"]

    local function OnClick(...)
        --2do: change achieve
    end

    local function OnDoubleClick(...)
        ShowMAWindow = false
        Dialogs.InGameInterface.FF_AT_PrimaryAchievement:Close()
    end

    local Parent = Dialogs.InGameInterface
    if not Parent then
        Log("ERROR", "No InGameInterface!")
        return
    end

    if Parent.FFAT_PrimaryAchievement then --backwards compatibility
        Parent.FFAT_PrimaryAchievement:DeleteChildren()
        Parent.FFAT_PrimaryAchievement:delete()
    end

    if Parent.FF_AT_PrimaryAchievement then
        Parent.FF_AT_PrimaryAchievement:DeleteChildren()
        Parent.FF_AT_PrimaryAchievement:delete()
    end

    if not ShowMAWindow then
        return
    end

    local OSD = XWindow:new({
        ChildrenHandleMouse = false,
        Dock = "box",
        FoldWhenHidden = true, --how to hide?
        HAlign = "center",
        HandleKeyboard = false,
        HandleMouse = true,
        Id = "FF_AT_PrimaryAchievement",
        IdNode = true,
        Margins = box(0, 85, 0, 0), --below InfoBar
        OnMouseButtonDoubleClick = OnDoubleClick,
        OnMouseButtonDown = OnClick,
        Padding = box(2,2,2,2),
        RolloverHint = FF.Funcs.Translate("Keep up the good work! =)"),
        RolloverTemplate = "Rollover",
        RolloverText = FF.Funcs.Translate("<image UI/Infopanel/left_click.tga 1400>*2 Close"),
        RolloverTitle = FF.Funcs.Translate("Primary Achievement"),
        transparency = 50,
        VAlign = "top",
    }, Parent)

    local Frame = XFrame:new({
        Dock = "box",
        FrameBox = box(0,20,0,0),
        HAlign = "stretch",
        HandleKeyboard = false,
        Id = "FF_AT_PA_Frame",
        Image = "UI/CommonNew/ip.dds",
        Padding = box(5,0,5,5),
        VAlign = "stretch",
    }, OSD)

    XText:new({
        Dock = "top",
        HandleKeyboard = false,
        Id = "FF_AT_PA_Title",
        TextStyle = "FF_PrimaryAchievement_Title",
        TextHAlign = "center",
    }, Frame)

    XText:new({
        Dock = "top",
        HandleKeyboard = "false",
        Id = "FF_AT_PA_Description",
        Margins = box(5,10,5,0),
        TextStyle = "FF_PrimaryAchievement_Text",
    }, Frame)

    XText:new({
        Dock = "top",
        HandleKeyboard = "false",
        Id = "FF_AT_PA_Progress",
        TextStyle = "FF_PrimaryAchievement_Progress",
        TextHAlign = "center",
        VAlign = "stretch",
    }, Frame)

    OSD:SetParent(Parent) --2do: test if this is necessary
    UpdateOSD()
end

function UpdateOSD()

    local function UpdateText()
        local Title, Description, Progress

        for _, A in pairs(MainCity.labels.TrackedAchievement) do
            if A.Name == CurrentModOptions:GetProperty("ShowOnScreen") then

                local OSD = Dialogs.InGameInterface.FF_AT_PrimaryAchievement.FF_AT_PA_Frame
                if not OSD then
                    Log("No OSD")
                    return
                end

                Title = A.Name
                Description = A.Description
                Progress = "Current Progress: " .. FF.Funcs.FormatNumber(A.Value) .. " / " .. FF.Funcs.FormatNumber(A.Target)

                if not OSD.FF_AT_PA_Title or not OSD.FF_AT_PA_Description or not OSD.FF_AT_PA_Progress then
                    Log("ERROR", "Primary Achievement children don't exist!")
                    return
                end
                OSD.FF_AT_PA_Title:SetText(FF.Funcs.Translate(Title))
                OSD.FF_AT_PA_Description:SetText(FF.Funcs.Translate(Description))
                OSD.FF_AT_PA_Progress:SetText(FF.Funcs.Translate(Progress))
                UpdateThread = nil
            end
        end
    end

    if not UpdateThread then
            UpdateThread = CreateGameTimeThread(UpdateText)
    end
end