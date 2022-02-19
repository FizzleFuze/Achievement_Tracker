-- See license.md for copyright info
SharedModEnv["FFL_Debug"] = true
local function Log(...)
    FFL_LogMessage(CurrentModDef.title, "TrackedAchievement", ...)
end

DefineClass.TrackedAchievement = {
    __parents = { "Object", },
    id = "Uninitialized",
    Name = "Uninitialized",
    Description = "Uninitialized",
    Image = nil,
    default_label = "TrackedAchievement",
    MessageThread = nil,
    Failed = false,
    Target = 0,
    Value = 0,
    Type = "default",
}

function TrackedAchievement:Init()
    if self.default_label then
        MainCity:AddToLabel(self.default_label, self)
    end
end

function TrackedAchievement:Done()
    if self.default_label then
        MainCity:RemoveFromLabel(self.default_label, self)
    end
end

--delayed show message
function TrackedAchievement:ShowMessage()

    local SleepTime = { Sols = 0, Hours = 0 }
    local Notification = {
        id = self.id,
        Title = self.Name,
        Message = "", -- set after sleep to be up to date
        Icon = "UI/Achievements/" .. self.Image .. ".dds",
        Callback = nil,
        Options = {
            expiration = 45000,
            game_time = true,
            rollover_text = FFL_Translate(self.description),
        },
        Map = MainCity.map_id
    }

    local function ShowPopup()
        local Popup = {
            Title = FFL_Translate(self.Name),
            Text = self.Description .. "\n\nCurrent Progress: " .. FFL_FormatNumber(self.Value) .. " / " .. FFL_FormatNumber(self.Target),
            Choices = { "OK" }
        }
        Popup.Text = FFL_Translate(Popup.Text)

        WaitCustomPopupNotification(Popup.Title, Popup.Text, Popup.Choices)
    end

    local function ShowMsg()
        if self.Value >= self.Target then  --complete
            Notification.Title = Notification.Title .. " Completed!"
            Notification.Message = FFL_FormatNumber(self.Value) .. " / " .. FFL_FormatNumber(self.Target).. "\nCongratulations on your achievement! :)"
        elseif self.Failed then --fail
            Notification.Title = Notification.Title .. " Failed!"
            Notification.Message = FFL_FormatNumber(self.Value) .. " / " .. FFL_FormatNumber(self.Target).. "\nBetter luck next time :)"
        elseif self.Value < self.Target then --progress
            SleepTime.Sols = CurrentModOptions:GetProperty("SolDelay")
            SleepTime.Hours = CurrentModOptions:GetProperty("HourDelay")
            Notification.Title = Notification.Title .. " Progress"
            Notification.Message = FFL_FormatNumber(self.Value) .. " / " .. FFL_FormatNumber(self.Target)
        end

        AddCustomOnScreenNotification(Notification.id, Notification.Title, Notification.Message, Notification.Icon, ShowPopup, Notification.Options, Notification.Map)
        Sleep(SleepTime.Sols * const.Scale.sols)
        Sleep(SleepTime.Hours * const.Scale.hours)
        self.MessageThread = nil
    end

    if GetAchievementFlags(self.id) then
        return -- don't show ones which are already complete
    end

    if not self.MessageThread then
        self.MessageThread = CreateGameTimeThread(ShowMsg)
    end
end

function TrackedAchievement:UpdateValue(NewValue)
    if self.Type == "Resource" then
        NewValue = NewValue / 100
    end

    if CurrentModOptions:GetProperty("ShowOnScreen") == self.Name then
        UpdateOSD()
    end

    if NewValue ~= self.Value then
        self.Value = NewValue
        self:ShowMessage()
    end
end

function TrackedAchievement:SetFailed()
    self.Failed = true
    self:ShowMessage()
end