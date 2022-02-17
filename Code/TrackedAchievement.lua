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
    default_label = "TrackedAchievements",
    Documentation = "Achievement object for tracking.",
}

function TrackedAchievement:Init()
    if self.default_label then
        UICity:AddToLabel(self.default_label, self)
    end
end

function TrackedAchievement:Done()
    if self.default_label then
        UICity:RemoveFromLabel(self.default_label, self)
    end
end