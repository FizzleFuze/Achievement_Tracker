-- See license.md for copyright info
--FF.Lib.Debug = true

local function Log(...)
    FF.Funcs.LogMessage(CurrentModDef.title, "AchievementTracker", ...)
end

-- mod options
local function ModOptions()
    Log("HERRRO PREASE!")
    local DisplayMode = CurrentModOptions:GetProperty("DisplayMode")
    if (DisplayMode == "OSD" or DisplayMode == "Both") then
        local ToggleTrackedAchievement = CurrentModOptions:GetProperty("TrackedAchievement")

        for _, Achievement in pairs(FF.AT.Achievements) do
            Log("Toggled: ", ToggleTrackedAchievement)
            if Achievement.Name == ToggleTrackedAchievement then
                Achievement.Tracked = not Achievement.Tracked

                if Achievement.Tracked then
                    Log("Adding tracked achievement: ")
                    Log(Achievement.Name)
                    UIColony.OSDList = UIColony.OSDList or {}
                    table.insert_unique(UIColony.OSDList, Achievement.Name)
                else
                    Log("Removing tracked achievement: ")
                    Log(Achievement.Name)
                    for k,v in pairs(UIColony.OSDList) do
                        if v == Achievement.Name then
                            table.remove(UIColony.OSDList, k)
                            return
                        end
                    end
                end
            end
        end

        CreateRealTimeThread(CreateOSD)
        UpdateOSD()
        Mods.FIZZLE3.options.TrackedAchievement = "None" -- so that re-applying mod options doesn't toggle the last achievement automagically
    end
end

--initialize achievement objects
local function Init()
    Log("Init AT")

    if not MainCity then
        Log("ERROR", "No city!")
        return
    end

    if not Presets.Achievement then
        Log("ERROR", "No Achievements!")
        return
    end

    local function InitAchievements(Achievements)
        Log("BEGIN InitAchievements")
        for _,Achievement in pairs(Achievements) do
            local AchievementObj = TrackedAchievement:Init(_InternalTranslate(Achievement.id))
            AchievementObj.Name = _InternalTranslate(Achievement.display_name)
            AchievementObj.Description = _InternalTranslate(Achievement.how_to)
            AchievementObj.Image = Achievement.image
            AchievementObj.Target = Achievement.target
            AchievementObj.Value = 0
        end
    end

    InitAchievements(Presets.Achievement['Default'])
    if g_AvailableDlc.picard then
        InitAchievements(Presets.Achievement['Below and Beyond'])
    end
    if g_AvailableDlc.armstrong then
        InitAchievements(Presets.Achievement['Green Planet'])
    end
    if g_AvailableDlc.gagarin then
        InitAchievements(Presets.Achievement['Space Race'])
    end

    --boo for hardcoding
    if FF.AT.Achievements.AsteroidHopping then
        FF.AT.Achievements.AsteroidHopping.Target = 10
    end
    if FF.AT.Achievements.USAResearchedEngineering then
        FF.AT.Achievements.USAResearchedEngineering.Target = #Presets.TechPreset.Engineering
    end
    if FF.AT.Achievements.Multitasking then
        FF.AT.Achievements.Multitasking.Target = 3
    end
    if FF.AT.Achievements.SpaceDwarves then
        FF.AT.Achievements.SpaceDwarves.Target = 200
    end
    if FF.AT.Achievements.Willtheyhold then
        FF.AT.Achievements.Willtheyhold.Target = 100
    end
    if FF.AT.Achievements.ScannedAllSectors then
        FF.AT.Achievements.ScannedAllSectors.Target = 100
    end
    if FF.AT.Achievements.DeepScannedAllSectors then
        FF.AT.Achievements.DeepScannedAllSectors.Target = 100
    end
    if FF.AT.Achievements.MaxedAllTPs then
        FF.AT.Achievements.MaxedAllTPs.Target = 400
    end
    if FF.AT.Achievements.SpaceExplorer then
        FF.AT.Achievements.SpaceExplorer.Target = #Presets.TechPreset.ReconAndExpansion -- = 0... data must not be initialized yet, updated later
    end

    --boo for using the wrong scale
    if FF.AT.Achievements.IndiaConvertedWasteRock then
        FF.AT.Achievements.IndiaConvertedWasteRock.Type = "Resource"
    end
    if FF.AT.Achievements.BrazilConvertedWasteRock then
        FF.AT.Achievements.BrazilConvertedWasteRock.Type = "Resource"
    end
    if FF.AT.Achievements.RussiaExtractedAlot then
        FF.AT.Achievements.RussiaExtractedAlot.Type = "Resource"
    end
    if FF.AT.Achievements.BlueSunProducedFunding then
        FF.AT.Achievements.BlueSunProducedFunding.Type = "Resource"
    end
    if FF.AT.Achievements.BlueSunExportedAlot then
        FF.AT.Achievements.BlueSunExportedAlot.Type = "Resource"
    end

    local DisplayMode = CurrentModOptions:GetProperty("DisplayMode")
    Log("DisplayMode = ", DisplayMode)
    if (DisplayMode == "OSD" or DisplayMode == "Both") then
        CreateRealTimeThread(CreateOSD)
    end
end

--achievement triggers below
function OnMsg.MarkPreciousMetalsExport(city, _)

    --BlueSunExportedAlot
    if GetMissionSponsor().id == "BlueSun" and UIColony.day < 100 then
        FF.AT.Achievements.BlueSunExportedAlot:UpdateValue(city.total_export)
    end
end

function OnMsg.RocketLanded(rocket)

    --AsteroidHopping
    if rocket:IsKindOf("LanderRocketBase") then
        local has_landed_on_asteroid = ObjectIsInEnvironment(rocket, "Asteroid")
        if has_landed_on_asteroid and rocket.asteroids_visited_this_trip <= 10 then
            FF.AT.Achievements.AsteroidHopping:UpdateValue(#rocket.asteroids_visited_this_trip)
        end
    end
    --Landed50Rockets
    if g_RocketsLandedCount <= AchievementPresets.Landed50Rockets.target then
        FF.AT.Achievements.Landed50Rockets:UpdateValue(g_RocketsLandedCount)
    end
end

function OnMsg.TechResearched(_, research, first_time)
    if not first_time then
        return
    end
    --SpaceExplorer
    if FF.AT.Achievements.SpaceExplorer.Target == 0 then
        FF.AT.Achievements.SpaceExplorer.Target = #Presets.TechPreset.ReconAndExpansion
    end
    for field_id, field in pairs(TechFields) do
        if field:HasMember("save_in") and field.save_in == "picard" then
            local researched, total = research:TechCount(field_id, "researched")
            if researched < total then
                if FF.AT.Achievements.SpaceExplorer.Target > 0 then
                    FF.AT.Achievements.SpaceExplorer:UpdateValue(researched)
                    return
                end
            end
        end
    end
    --USAResearchedEngineering
    if sponsor.id == "NASA" and UIColony.day < 100 and research:TechCount("Engineering", "researched") <= #research.tech_field.Engineering then
        FF.AT.Achievements.USAResearchedEngineering:UpdateValue(#research.tech_field.Engineering)
        --EuropeResearchedBreakthroughs
    elseif sponsor.id == "ESA" and UIColony.day < 100 and research:TechCount("Breakthroughs", "researched") <= AchievementPresets.EuropeResearchedBreakthroughs.target then
        FF.AT.Achievements.EuropeResearchedBreakthroughs:UpdateValue(research:TechCount("Breakthroughs", "researched"))
    end
end

function OnMsg.AsteroidRocketLanded(rocket)


    --Multitasking
    if not rocket:IsKindOf("LanderRocketBase") then
        return
    end
    local num_astroids_visiting = 0
    local loaded_maps = GetLoadedMaps()
    for _, map_id in pairs(loaded_maps) do
        local map_data = ActiveMaps[map_id]
        if map_data.Environment == "Asteroid" then
            local city = Cities[map_id]
            local rockets = city.labels.AllRockets or empty_table
            local vehicles = city.labels.Rover or empty_table
            local buildings = city.labels.Building or empty_table
            if 0 < #vehicles or 0 < #rockets or 0 < #buildings then
                num_astroids_visiting = num_astroids_visiting + 1
            end
        end
    end
    if num_astroids_visiting <= 3 then
        FF.AT.Achievements.Multitasking:UpdateValue(num_astroids_visiting)
    end
end

function OnMsg.NewDay(Day)


    if Day == 100 then
        if GetMissionSponsor().id == "BlueSun" then
            FF.AT.Achievements.BlueSunExportedAlot:SetFailed()
            FF.AT.Achievements.BlueSunProducedFunding:SetFailed()
        elseif GetMissionSponsor().id == "CNSA" then
            FF.AT.Achievements.ChinaTaiChiGardens:SetFailed()
            FF.AT.Achievements.ChinaReachedHighPopulation:SetFailed()
        elseif GetMissionSponsor().id == "Japan" then
            FF.AT.Achievements.JapanTrainedSpecialists:SetFailed()
        elseif GetMissionSponsor().id == "ESA" then
            FF.AT.Achievements.EuropeResearchedBreakthroughs:SetFailed()
            FF.AT.Achievements.EuropeResearchedAlot:SetFailed()
        elseif GetMissionSponsor().id == "ISRO" then
            FF.AT.Achievements.IndiaConvertedWasteRock:SetFailed()
            FF.AT.Achievements.IndiaBuiltDomes:SetFailed()
        elseif GetMissionSponsor().id == "Roscosmos" then
            FF.AT.Achievements.RussiaExtractedAlot:SetFailed()
        elseif GetMissionSponsor().id == "NewArk" then
            FF.AT.Achievements.NewArkChurchHappyColonists:SetFailed()
            FF.AT.Achievements.NewArcChurchMartianborns:SetFailed()
        elseif GetMissionSponsor().id == "NASA" then
            FF.AT.Achievements.USAResearchedEngineering:SetFailed()
        elseif GetMissionSponsor().id == "Brazil" then
            FF.AT.Achievements.BrazilConvertedWasteRock:SetFailed()
        end
    end

    --SpaceDwarves
    local underground_city = Cities[UIColony.underground_map_id]
    if not underground_city then
        return
    end
    local number_underground_colonists = #(underground_city.labels.Colonist or "")
    local total_colonists = #(UIColony.city_labels.labels.Colonist or "")
    if number_underground_colonists == total_colonists and 200 > number_underground_colonists then
        FF.AT.Achievements.SpaceDwarves:UpdateValue(number_underground_colonists)
    end
end

function OnMsg.PreventedCaveIn(_)

    --Willtheyhold
    if PreventedCaveIns < 100 then
        FF.AT.Achievements.Willtheyhold:UpdateValue(PreventedCaveIns)
    end
end

function OnMsg.BuildingInit(bld)

    --ChinaTaiChiGardens
    if UIColony.day <= 100 then
        local sponsor_id = GetMissionSponsor().id
        if sponsor_id == "CNSA" and IsKindOf(bld, "TaiChiGarden") then
            local domes_with_garden = {}
            local label = MainCity.labels.TaiChiGarden or empty_table
            for i = 1, #label do
                domes_with_garden[label[i].parent_dome] = true
            end
            if table.count(domes_with_garden) <= AchievementPresets.ChinaTaiChiGardens.target then
                FF.AT.Achievements.ChinaTaiChiGardens:UpdateValue(table.count(domes_with_garden))
            end
        end
    end
end

function OnMsg.TrainingComplete(building, _)

    --JapanTrainedSpecialists
    if UIColony.day <= 100 and building.training_type == "specialization" and GetMissionSponsor().id == "Japan" then
        if TotalTrainedSpecialists <= AchievementPresets.JapanTrainedSpecialists.target then
            FF.AT.Achievements.JapanTrainedSpecialists:UpdateValue(TotalTrainedSpecialists)
        end
    end
end

function OnMsg.FundingChanged(colony, amount)

    --BlueSunProducedFunding
    if GameTime() > 1 and GetMissionSponsor().id == "BlueSun" and UIColony.day <= 100 and 0 < amount then
        if FundingGenerated <= AchievementPresets.BlueSunProducedFunding.target * 1000000 then
            FF.AT.Achievements.BlueSunProducedFunding:UpdateValue(FundingGenerated)
        end
    end
    --GatheredFunding
    if colony.funding <= AchievementPresets.GatheredFunding.target then
        FF.AT.Achievements.GatheredFunding:UpdateValue(colony.funding)
    end
end

function OnMsg.NewHour(_)

    --EuropeResearchedAlot
    local sponsor = GetMissionSponsor().id
    if sponsor == "ESA" and UIColony.day <= 100 and UIColony:GetEstimatedRP() <= AchievementPresets.EuropeResearchedAlot.target then
        FF.AT.Achievements.EuropeResearchedAlot:UpdateValue(UIColony:GetEstimatedRP())
    end
    --NewArkChurchHappyColonists
    if sponsor == "NewArk" and UIColony.day <= 100 then
        local colonists = UIColony:GetCityLabels("Colonist") or empty_table
        local count = 0
        for _, colonist in ipairs(colonists) do
            if colonist.stat_comfort >= 70 * const.Scale.Stat then
                count = count + 1
                if count <= AchievementPresets.NewArkChurchHappyColonists.target then
                    FF.AT.Achievements.NewArkChurchHappyColonists:UpdateValue(count)
                end
            end
        end
    end
    --RussiaHadManyColonists
    if sponsor == "Roscosmos" and CalcChallengeRating() + 100 >= 500 and #(UIColony:GetCityLabels("Colonist") or empty_table) <= AchievementPresets.RussiaHadManyColonists.target then
        FF.AT.Achievements.RussiaHadManyColonists:UpdateValue(#(UIColony:GetCityLabels("Colonist") or empty_table))
    end
    --SpaceYBuiltDrones (this is hardcoded in to Drone.lua and hasn't been updated for B&B)
    if MainCity.labels.Drone then
        if GetMissionSponsor().id == "SpaceY" and UIColony.day < 100 and #MainCity.labels.Drone <= AchievementPresets.SpaceYBuiltDrones.target then
            FF.AT.Achievements.SpaceYBuiltDrones:UpdateValue(#MainCity.labels.Drone or empty_table)
        end
    end
end

function OnMsg.WasteRockConversion(amount, producers)

    local sponsor = GetMissionSponsor().id
    WasteRockConverted = WasteRockConverted + amount
    if producers.PreciousMetals then
        WasteRockConvertedToRareMetals = WasteRockConvertedToRareMetals + amount
    end
    --IndiaConvertedWasteRock
    if sponsor == "ISRO" and UIColony.day <= 100 and WasteRockConverted / const.ResourceScale <= AchievementPresets.IndiaConvertedWasteRock.target then
        FF.AT.Achievements.IndiaConvertedWasteRock:UpdateValue(WasteRockConverted / const.ResourceScale)
        --BrazilConvertedWasteRock
    elseif sponsor == "Brazil" and UIColony.day <= 100 and WasteRockConvertedToRareMetals / const.ResourceScale <= AchievementPresets.BrazilConvertedWasteRock.target then
        FF.AT.Achievements.BrazilConvertedWasteRock:UpdateValue(WasteRockConverted / const.ResourceScale)
    end
end

function OnMsg.TerraformParamChanged()

    local TerraformTotal = 0
    local TerraformingParameters = {
        "Atmosphere",
        "Temperature",
        "Water",
        "Vegetation"
    }

    for _, TerraformingParameter in ipairs(TerraformingParameters) do
        TerraformTotal = TerraformTotal + GetTerraformParamPct(TerraformingParameter)
    end

    FF.AT.Achievements.MaxedAllTPs:UpdateValue(TerraformTotal)
end

local CheckTraitsAchievements = function()

    if GetAchievementFlags("ColonistWithRareTraits") and GetAchievementFlags("HadColonistWith5Perks") and GetAchievementFlags("HadVegans") then
        return
    end
    local vegans_count = 0
    local colonists = UIColony:GetCityLabels("Colonist") or empty_table
    for i = 1, #colonists do
        local c = colonists[i]
        if not GetAchievementFlags("ColonistWithRareTraits") or not GetAchievementFlags("HadColonistWith5Perks") then
            local perks_count = 0
            local rare_traits_count = 0
            for trait_id, _ in pairs(c.traits) do
                if g_RareTraits[trait_id] then
                    rare_traits_count = rare_traits_count + 1
                end
                local trait_data = TraitPresets[trait_id]
                if trait_data and trait_data.group == "Positive" then
                    perks_count = perks_count + 1
                end
            end
            --ColonistWithRareTraits
            if rare_traits_count <= ColonistWithRareTraits_target then
                FF.AT.Achievements.ColonistWithRareTraits:UpdateValue(rare_traits_count)
            end
            --HadColonistWith5Perks
            if perks_count <= HadColonistWith5Perks_target then
                FF.AT.Achievements.HadColonistWith5Perks:UpdateValue(perks_count)
            end
        end
        if c.traits.Vegan then
            vegans_count = vegans_count + 1
        end
    end
    --HadVegans
    if vegans_count <= HadVegans_target then
        FF.AT.Achievements.HadVegans:UpdateValue(vegans_count)
    end
end
function OnMsg.ColonistAddTrait()
    DelayedCall(30000, CheckTraitsAchievements)
end

function OnMsg.SectorScanned()

    if GetAchievementFlags("ScannedAllSectors") and GetAchievementFlags("DeepScannedAllSectors") then
        return
    end
    local sector_status_to_number = {
        unexplored = 0,
        scanned = 1,
        ["deep scanned"] = 2
    }

    local SectorsScanned = 0
    local SectorsDeepScanned = 0
    for x = 1, const.SectorCount do
        for y = 1, const.SectorCount do
            if sector_status_to_number[MainCity.MapSectors[x][y].status] == 1 then
                SectorsScanned = SectorsScanned + 1
            elseif sector_status_to_number[MainCity.MapSectors[x][y].status] == 2 then
                SectorsDeepScanned = SectorsDeepScanned + 1
            end
        end
    end

    local SectorCount = 100
    --ScannedAllSectors
    if SectorsScanned <= SectorCount then
        FF.AT.Achievements.ScannedAllSectors:UpdateValue(SectorsScanned)
    end
    --DeepScannedAllSectors
    if SectorsDeepScanned <= SectorCount then
        FF.AT.Achievements.DeepScannedAllSectors:UpdateValue(SectorsDeepScanned)
    end
end

local CountNonConstructionSitesInLabel = function(city, label)
    local container = (city or UICity).labels[label] or empty_table
    local count = 0
    for i = 1, #container do
        if not IsKindOf(container[i], "ConstructionSite") then
            count = count + 1
        end
    end
    return count
end
function OnMsg.ConstructionComplete(bld)

    if IsKindOf(bld, "RocketLandingSite") then
        return
    end
    local city = bld.city
    --Built1000Buildings
    if g_BuildingsBuilt <= AchievementPresets.Built1000Buildings.target then
        FF.AT.Achievements.Built1000Buildings:UpdateValue(g_BuildingsBuilt)
    end
    --IndiaBuiltDomes
    if IsKindOf(bld, "Dome") and GetMissionSponsor().id == "ISRO" and UIColony.day < 100 and not GetAchievementFlags("IndiaBuiltDomes") and
            CountNonConstructionSitesInLabel(city, "Dome") <= AchievementPresets.IndiaBuiltDomes.target - 1 then
        FF.AT.Achievements.IndiaBuiltDomes:UpdateValue(CountNonConstructionSitesInLabel(city, "Dome"))
    end
    --BuiltSeveralWonders
    if bld.build_category == "Wonders" and not GetAchievementFlags("BuiltSeveralWonders") and
            CountNonConstructionSitesInLabel(city, "Wonders") <= AchievementPresets.BuiltSeveralWonders.target - 1
    then
        FF.AT.Achievements.BuiltSeveralWonders:UpdateValue(CountNonConstructionSitesInLabel(city, "Wonders"))
    end
end

function OnMsg.ResourceExtracted()

    --RussiaExtractedAl1ot
    if GetMissionSponsor().id == "Roscosmos" and UIColony.day < 100 and g_TotalExtractedResources <= RussiaExtractedAlot_target then
        FF.AT.Achievements.RussiaExtractedAlot:UpdateValue(g_TotalExtractedResources)
    end
end

local CheckColonistCountAchievements = function()
    local total_colonists = #(UIColony:GetCityLabels("Colonist") or empty_table)
    --ChinaReachedHighPopulation
    if GetMissionSponsor().id == "CNSA" and UIColony.day < 100 and total_colonists <= ChinaReachedHighPopulation_target then
        FF.AT.Achievements.ChinaReachedHighPopulation:UpdateValue(total_colonists)
    end
    --Reached1000Colonists
    if total_colonists <= Reached1000Colonists_target then
        FF.AT.Achievements.Reached1000Colonists:UpdateValue(total_colonists)
    end
    --Reached250Colonists
    if total_colonists <= Reached250Colonists_target then
        FF.AT.Achievements.Reached250Colonists:UpdateValue(total_colonists)
    end
end
function OnMsg.ColonistBorn(colonist)

    --NewArcChurchMartianborns
    if colonist.traits.Child and colonist.age == 0 then
        if GetMissionSponsor().id == "NewArk" and UIColony.day < 100 and g_TotalChildrenBornWithMating <= AchievementPresets.NewArcChurchMartianborns.target then
            FF.AT.Achievements.NewArcChurchMartianborns:UpdateValue(g_TotalChildrenBornWithMating)
        end
    end
    DelayedCall(1000, CheckColonistCountAchievements)
end
function OnMsg.ColonistArrived()
    DelayedCall(1000, CheckColonistCountAchievements)
end

function OnMsg.ColonistCured(_, bld)

    --CuredColonists
    if bld.total_cured <= AchievementPresets.CuredColonists.target then
        FF.AT.Achievements.CuredColonists:UpdateValue(bld.total_cured)
    end
end

function OnMsg.ColonistJoinsDome(_, dome)

    --Had100ColonistsInDome
    if #(dome.labels.Colonist or empty_table) <= AchievementPresets.Had100ColonistsInDome.target then
        FF.AT.Achievements.Had100ColonistsInDome:UpdateValue(#(dome.labels.Colonist or empty_table))
    end
    --Had50AndroidsInDome
    if #(dome.labels.Android or empty_table) >= AchievementPresets.Had50AndroidsInDome.target then
        FF.AT.Achievements.Had50AndroidsInDome:UpdateValue(#(dome.labels.Android or empty_table))
    end
end

--event handling
OnMsg.ApplyModOptions = ModOptions
OnMsg.CityStart = Init
OnMsg.LoadGame = Init