-- See license.md for copyright info

--wrapper logging function for this file
local function Log(...)
    FFL_LogMessage(CurrentModDef.title, "TrackedAchievement", ...)
end

DefineClass.TrackedAchievement = {
    __parents = { "Object", },
    properties = {
        { id = "id", default = "Uninitialized"},
        { id = "Name", help = "Achievement Name", editor = "text", default = "Uninitialized"},
        { id = "Description", help = "Achievement Description", editor = "text", default = "Uninitialized"},
        { id = "ParameterName", help = "Names of parameters which must be met.", editor = "text", default = "Uninitialized"},
        { id = "ParameterTarget", help = "Values of parameters which much be met.", editor = "text", default = "Uninitialized"},
    },
    ParameterValue = 0,
    Image = nil,
    default_label = "TrackedAchievement",
    Documentation = "Achievement object for tracking.",
    MessageThread = nil,
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
function TrackedAchievement:ShowAchievementProgress()

    if GetAchievementFlags(self.id) then
        return -- don't show ones which are already complete
    end

    if not self.MessageThread then
       self.MessageThread = CreateGameTimeThread( function()
            Sleep(CurrentModOptions:GetProperty("SolDelay") * const.DayDuration)
            Sleep(CurrentModOptions:GetProperty("HourDelay") * const.HourDuration)

           local Notification = {
               id = self.id,
               Title = self.Name .. " Progress",
               Message = InfobarObj.FmtRes(nil, self.ParameterValue) .. " / " .. InfobarObj.FmtRes(nil, self.ParameterTarget),
               Icon = "UI/Achievements/" .. self.Image .. ".dds",
               Callback = nil,
               Options = {
                   expiration = 45000,
                   game_time = true
               },
               Map = MainCity.map_id
           }
           AddCustomOnScreenNotification(Notification.id, Notification.Title, Notification.Message, Notification.Icon, nil, Notification.Options, Notification.Map)

           self.MessageThread = nil
        end )
    end
end

function TrackedAchievement:UpdateValue(NewValue)
    self.ParameterValue = NewValue
    self:ShowAchievementProgress()
end