-- See license.md for copyright info

local function Log(...)
    FF.Funcs.LogMessage(CurrentModDef.title, "TrackedAchievement", ...)
end

TrackedAchievement = {
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
    Tracked = false
}

function TrackedAchievement:Init(id)
    if not id then
        Log("ERROR", "Cannot track achievement without id")
        return
    end

    local NewTrackedAchievement = {}
    setmetatable(NewTrackedAchievement, self)
    self.__index = self

    NewTrackedAchievement.id = id
    FF.AT.Achievements[id] = NewTrackedAchievement
    return NewTrackedAchievement
end

function TrackedAchievement:Done()
    local index = table.find(FF.AT.Achievements, 'id', self.id)
    table.remove(FF.AT.Achievements, index)
end

--delayed show message
function TrackedAchievement:ShowMessage()

    local Speed = 1
    local SleepTime = { Sols = 0, Hours = 0 }

    if GetEstimatedGameSpeedState() == "medium" then
        Speed = 3
    elseif GetEstimatedGameSpeedState() == "fast" then
        Speed = 5
    end

    local Notification = {
        id = self.id,
        Title = self.Name,
        Message = "", -- set after sleep to be up to date
        Icon = "UI/Achievements/" .. self.Image .. ".dds",
        Callback = nil,
        Options = {
            expiration = CurrentModOptions:GetProperty("MessageLength") * 1000 * Speed, -- real time changes with game speed >.>
            game_time = false,
            rollover_text = FF.Funcs.Translate(self.description),
        },
        -- Map = MainCity.map_id  _G['ActiveMapID']
    }

    local function ShowPopup()
        local Popup = {
            Title = FF.Funcs.Translate(self.Name),
            Text = self.Description .. "\n\nCurrent Progress: " .. FF.Funcs.FormatNumber(self.Value) .. " / " .. FF.Funcs.FormatNumber(self.Target),
            Choices = { "OK" }
        }
        Popup.Text = FF.Funcs.Translate(Popup.Text)
        WaitCustomPopupNotification(Popup.Title, Popup.Text, Popup.Choices)
    end

    local function ShowMsg()
        if self.Value >= self.Target then  --complete
            Notification.Title = Notification.Title .. " Completed!"
            Notification.Message = FF.Funcs.FormatNumber(self.Value) .. " / " .. FF.Funcs.FormatNumber(self.Target).. "\nCongratulations on your achievement! :)"
        elseif self.Failed then --fail
            Notification.Title = Notification.Title .. " Failed!"
            Notification.Message = FF.Funcs.FormatNumber(self.Value) .. " / " .. FF.Funcs.FormatNumber(self.Target).. "\nBetter luck next time :)"
        elseif self.Value < self.Target then --progress
            SleepTime.Sols = CurrentModOptions:GetProperty("SolDelay")
            SleepTime.Hours = CurrentModOptions:GetProperty("HourDelay")
            Notification.Title = Notification.Title .. " Progress"
            Notification.Message = FF.Funcs.FormatNumber(self.Value) .. " / " .. FF.Funcs.FormatNumber(self.Target)
        end

        AddCustomOnScreenNotification(Notification.id, Notification.Title, Notification.Message, Notification.Icon, ShowPopup, Notification.Options, ActiveMapID)
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
        NewValue = NewValue / 1000
    end

    if NewValue ~= self.Value then
        self.Value = NewValue
        self:ShowMessage()
    end

    local DisplayMode = CurrentModOptions:GetProperty("DisplayMode")
    if DisplayMode == "OSD" or DisplayMode == "Both" then
        UpdateOSD()
    end

end

function TrackedAchievement:SetFailed()
    self.Failed = true
    self:ShowMessage()
end