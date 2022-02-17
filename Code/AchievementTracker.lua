-- See license.md for copyright info
--FFL_Debugging = true

--wrapper logging function for this file
local function Log(...)
    FFL_LogMessage(CurrentModDef.title, "AchievementTracker", ...)
end

--locals
local AchievementObjects = {}

--initialize achievement objects
local function Init()
    if not MainCity then
        Log("No city!")
        return
    end

    if not DataInstances.Achievement then
        Log("ERROR", "No Achievements!")
        return
    end

    if FFL_Debugging then
        if MainCity.labels.TrackedAchievements then
            MainCity.labels.TrackedAchievements = nil
        end
    end

    if not MainCity.labels.TrackedAchievements then
        for _,Achievement in pairs(DataInstances.Achievement) do
            --[[
            local AchievementObj = PlaceObjIn("TrackedAchievement", MainCity.map_id, {
                id = Achievement.id,
                Name = Achievement.display_name,
                Description = Achievement.description,
                Image = Achievement.image,
                ParameterName = Achievement.how_to,
                ParameterTarget = Achievement.target,
            })
            --]]

            local AchievementObj = PlaceObj("TrackedAchievement")
            AchievementObj.id = Achievement.id
            AchievementObj.Name = Achievement.display_name
            AchievementObj.Description = Achievement.description
            AchievementObj.Image = Achievement.image
            AchievementObj.ParameterName = Achievement.how_to
            AchievementObj.ParameterTarget = Achievement.target

            AchievementObjects[AchievementObj.id] = AchievementObj
        end
    end
end

--show message about progress for achievement
local function ShowAchievementProgress(Achievement)

    if GetAchievementFlags(Achievement.id) then
        return -- don't show ones which are already complete
    end

    local Notification = {
        id = Achievement.id,
        Title = Achievement.Name .. " Progress",
        Message = Achievement.ParameterName .. ": " .. Achievement.ParameterValue .. "/" .. Achievement.ParameterTarget,
        Icon = "UI/Achievements/" .. Achievement.Image .. ".dds",
        Callback = nil,
        Options = {
            expiration = 45000,
            game_time = true
        },
        Map = MainCity.map_id
    }
    AddCustomOnScreenNotification(Notification.id, Notification.Title, Notification.Message, Notification.Icon, nil, Notification.Options, Notification.Map)
end

--achievement triggers below
function OnMsg.MarkPreciousMetalsExport(city, _)
    --BlueSunExportedAlot
    if GetMissionSponsor().id == "BlueSun" and UIColony.day < 100 then
        AchievementObjects.BlueSunExportedAlot.ParameterValue = city.total_export
        ShowAchievementProgress(AchievementObjects.BlueSunExportedAlot)
    end
end

function OnMsg.RocketLanded(rocket)
    --AsteroidHopping
    if rocket:IsKindOf("LanderRocketBase") then
        local has_landed_on_asteroid = ObjectIsInEnvironment(rocket, "Asteroid")
        if has_landed_on_asteroid and rocket.asteroids_visited_this_trip <= 10 then
            AchievementObjects.AsteroidHopping.ParameterValue = #rocket.asteroids_visited_this_trip
            ShowAchievementProgress(AchievementObjects.AsteroidHopping)
        end
    end
    --Landed50Rockets
    if g_RocketsLandedCount <= AchievementPresets.Landed50Rockets.target then
        AchievementObjects.Landed50Rockets.ParameterValue = g_RocketsLandedCount
        ShowAchievementProgress(AchievementObjects.Landed50Rockets)
    end
end

function OnMsg.TechResearched(_, research, first_time)
    if not first_time then
        return
    end
    --SpaceExplorer
    for field_id, field in pairs(TechFields) do
        if field:HasMember("save_in") and field.save_in == "picard" then
            local researched, total = research:TechCount(field_id, "researched")
            if researched < total then
                AchievementObjects.SpaceExplorer.ParameterValue = researched
                ShowAchievementProgress(AchievementObjects.SpaceExplorer)
                return
            end
        end
    end
    --USAResearchedEngineering
    if sponsor.id == "NASA" and UIColony.day < 100 and research:TechCount("Engineering", "researched") <= #research.tech_field.Engineering then
        AchievementObjects.USAResearchedEngineering.ParameterValue = #research.tech_field.Engineering
        ShowAchievementProgress(AchievementObjects.USAResearchedEngineering)
    --EuropeResearchedBreakthroughs
    elseif sponsor.id == "ESA" and UIColony.day < 100 and research:TechCount("Breakthroughs", "researched") <= AchievementPresets.EuropeResearchedBreakthroughs.target then
        AchievementObjects.EuropeResearchedBreakthroughs.ParameterValue = research:TechCount("Breakthroughs", "researched")
        ShowAchievementProgress(AchievementObjects.EuropeResearchedBreakthroughs)
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
        AchievementObjects.Multitasking.ParameterValue = num_astroids_visiting
        ShowAchievementProgress(AchievementObjects.Multitasking)
    end
end

function OnMsg.NewDay(_)
    --SpaceDwarves
    local underground_city = Cities[UIColony.underground_map_id]
    if not underground_city then
        return
    end
    local number_underground_colonists = #(underground_city.labels.Colonist or "")
    local total_colonists = #(UIColony.city_labels.labels.Colonist or "")
    if number_underground_colonists == total_colonists and 200 > number_underground_colonists then
        AchievementObjects.SpaceDwarves.ParameterValue = number_underground_colonists
        ShowAchievementProgress(AchievementObjects.SpaceDwarves)
    end
end

function OnMsg.PreventedCaveIn(_)
    --Willtheyhold
    if PreventedCaveIns < 100 then
        AchievementObjects.Willtheyhold.ParameterValue = PreventedCaveIns
        ShowAchievementProgress(AchievementObjects.Willtheyhold)
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
                AchievementObjects.ChinaTaiChiGardens.ParameterValue = table.count(domes_with_garden)
                ShowAchievementProgress(AchievementObjects.ChinaTaiChiGardens)
            end
        end
    end
end

function OnMsg.TrainingComplete(building, _)
    --JapanTrainedSpecialists
    if UIColony.day <= 100 and building.training_type == "specialization" and GetMissionSponsor().id == "Japan" then
        if TotalTrainedSpecialists <= AchievementPresets.JapanTrainedSpecialists.target then
            AchievementObjects.JapanTrainedSpecialists.ParameterValue = TotalTrainedSpecialists
            ShowAchievementProgress(AchievementObjects.JapanTrainedSpecialists)
        end
    end
end

function OnMsg.FundingChanged(colony, amount)
    --BlueSunProducedFunding
    if GameTime() > 1 and GetMissionSponsor().id == "BlueSun" and UIColony.day <= 100 and 0 < amount then
        if FundingGenerated <= AchievementPresets.BlueSunProducedFunding.target * 1000000 then
            AchievementObjects.BlueSunProducedFunding.ParameterValue = FundingGenerated
            ShowAchievementProgress(AchievementObjects.BlueSunProducedFunding)
        end
    end
    --GatheredFunding
    if colony.funding <= AchievementPresets.GatheredFunding.target then
        AchievementObjects.GatheredFunding.ParameterValue = colony.funding
        ShowAchievementProgress(AchievementObjects.GatheredFunding)
    end
end

function OnMsg.NewHour(_)
    --EuropeResearchedAlot
    local sponsor = GetMissionSponsor().id
    if sponsor == "ESA" and UIColony.day <= 100 and UIColony:GetEstimatedRP() <= AchievementPresets.EuropeResearchedAlot.target then
        AchievementObjects.EuropeResearchedAlot.ParameterValue = UIColony:GetEstimatedRP()
        ShowAchievementProgress(AchievementObjects.EuropeResearchedAlot)
    end
    --NewArkChurchHappyColonists
    if sponsor == "NewArk" and UIColony.day <= 100 then
        local colonists = UIColony:GetCityLabels("Colonist") or empty_table
        local count = 0
        for _, colonist in ipairs(colonists) do
            if colonist.stat_comfort >= 70 * const.Scale.Stat then
                count = count + 1
                if count <= AchievementPresets.NewArkChurchHappyColonists.target then
                    AchievementObjects.NewArkChurchHappyColonists.ParameterValue = count
                    ShowAchievementProgress(AchievementObjects.NewArkChurchHappyColonists)
                end
            end
        end
    end
    --RussiaHadManyColonists
    if sponsor == "Roscosmos" and CalcChallengeRating() + 100 >= 500 and #(UIColony:GetCityLabels("Colonist") or empty_table) <= AchievementPresets.RussiaHadManyColonists.target then
        AchievementObjects.RussiaHadManyColonists.ParameterValue = #(UIColony:GetCityLabels("Colonist") or empty_table)
        ShowAchievementProgress(AchievementObjects.RussiaHadManyColonists)
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
        AchievementObjects.IndiaConvertedWasteRock.ParameterValue = WasteRockConverted / const.ResourceScale
        ShowAchievementProgress(AchievementObjects.IndiaConvertedWasteRock)
    --BrazilConvertedWasteRock
    elseif sponsor == "Brazil" and UIColony.day <= 100 and WasteRockConvertedToRareMetals / const.ResourceScale <= AchievementPresets.BrazilConvertedWasteRock.target then
        AchievementObjects.BrazilConvertedWasteRock.ParameterValue = WasteRockConverted / const.ResourceScale
        ShowAchievementProgress(AchievementObjects.BrazilConvertedWasteRock)
    end
end

local AllTerraformParamsMaxed = function()
    local params = {
        "Atmosphere",
        "Temperature",
        "Water",
        "Vegetation"
    }
    for _, param in ipairs(params) do
        if GetTerraformParamPct(param) < 100 then
            return false
        end
    end
    return true
end
function OnMsg.TerraformParamChanged()

    if not AllTerraformParamsMaxed() then
        local Notification = {
            id = "MaxedAllTPs",
            Title = "Creator of Worlds Progress",
            Message = "Atmosphere: " .. GetTerraformParamPct("Atmosphere") .. " / 100 " .. "Temperature: " .. GetTerraformParamPct("Temperature") .. " / 100 " .. "Water: " ..
                    GetTerraformParamPct("Water") .. " / 100 " .."Vegetation: " .. GetTerraformParamPct("Vegetation") .. " / 100 ",
            Icon = "UI/Achievements/" .. Achievement.Image .. ".dds", --2do: update
            Callback = nil,
            Options = {
                expiration = 10000,
                game_time = true
            },
            Map = MainCity.map_id
        }
        AddCustomOnScreenNotification(Notification.id, Notification.Title, Notification.Message, Notification.Icon, nil, Notification.Options, Notification.Map)
    end
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
                AchievementObjects.ColonistWithRareTraits.ParameterValue = rare_traits_count
                ShowAchievementProgress(AchievementObjects.ColonistWithRareTraits)
            end
            --HadColonistWith5Perks
            if perks_count <= HadColonistWith5Perks_target then
                AchievementObjects.HadColonistWith5Perks.ParameterValue = perks_count
                ShowAchievementProgress(AchievementObjects.HadColonistWith5Perks)
            end
        end
        if c.traits.Vegan then
            vegans_count = vegans_count + 1
        end
    end
    --HadVegans
    if vegans_count <= HadVegans_target then
        AchievementObjects.HadVegans.ParameterValue = vegans_count
        ShowAchievementProgress(AchievementObjects.HadVegans)
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

    local SectorCount = 50 --2do: how many sectors on a map?
    --ScannedAllSectors
    if SectorsScanned <= SectorCount then
        AchievementObjects.ScannedAllSectors.ParameterValue = SectorsScanned
        ShowAchievementProgress(AchievementObjects.ScannedAllSectors)
    end
    --DeepScannedAllSectors
    if SectorsDeepScanned <= SectorCount then
        AchievementObjects.DeepScannedAllSectors.ParameterValue = SectorsDeepScanned
        ShowAchievementProgress(AchievementObjects.DeepScannedAllSectors)
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
        AchievementObjects.Built1000Buildings.ParameterValue = g_BuildingsBuilt
        ShowAchievementProgress(AchievementObjects.Built1000Buildings)
    end
    --IndiaBuiltDomes
    if IsKindOf(bld, "Dome") and GetMissionSponsor().id == "ISRO" and UIColony.day < 100 and not GetAchievementFlags("IndiaBuiltDomes") and CountNonConstructionSitesInLabel(city, "Dome") <= AchievementPresets.IndiaBuiltDomes.target - 1 then
        AchievementObjects.IndiaBuiltDomes.ParameterValue = CountNonConstructionSitesInLabel(city, "Dome")
        ShowAchievementProgress(AchievementObjects.IndiaBuiltDomes)
    end
    --BuiltSeveralWonders
    if bld.build_category == "Wonders" and not GetAchievementFlags("BuiltSeveralWonders") and CountNonConstructionSitesInLabel(city, "Wonders") <= AchievementPresets.BuiltSeveralWonders.target - 1
    then
        AchievementObjects.BuiltSeveralWonders.ParameterValue = CountNonConstructionSitesInLabel(city, "Wonders")
        ShowAchievementProgress(AchievementObjects.BuiltSeveralWonders)
    end
end

function OnMsg.ResourceExtracted(_, amount)
    --RussiaExtractedAlot
    if GetMissionSponsor().id == "Roscosmos" and UIColony.day < 100 and g_TotalExtractedResources <= RussiaExtractedAlot_target then
        AchievementObjects.RussiaExtractedAlot.ParameterValue = g_TotalExtractedResources
        ShowAchievementProgress(AchievementObjects.RussiaExtractedAlot)
    end
end

local CheckColonistCountAchievements = function()
    local total_colonists = #(UIColony:GetCityLabels("Colonist") or empty_table)
    --ChinaReachedHighPopulation
    if GetMissionSponsor().id == "CNSA" and UIColony.day < 100 and total_colonists <= ChinaReachedHighPopulation_target then
        AchievementObjects.ChinaReachedHighPopulation.ParameterValue = total_colonists
        ShowAchievementProgress(AchievementObjects.ChinaReachedHighPopulation)
    end
    --Reached1000Colonists
    if total_colonists <= Reached1000Colonists_target then
        AchievementObjects.Reached1000Colonists.ParameterValue = total_colonists
        ShowAchievementProgress(AchievementObjects.Reached1000Colonists)
    end
    --Reached250Colonists
    if total_colonists <= Reached250Colonists_target then
        AchievementObjects.Reached250Colonists.ParameterValue = total_colonists
        ShowAchievementProgress(AchievementObjects.Reached250Colonists)
    end
end
function OnMsg.ColonistBorn(colonist)
    --NewArcChurchMartianborns
    if colonist.traits.Child and colonist.age == 0 then
        if GetMissionSponsor().id == "NewArk" and UIColony.day < 100 and g_TotalChildrenBornWithMating <= AchievementPresets.NewArcChurchMartianborns.target then
            AchievementObjects.NewArcChurchMartianborns.ParameterValue = g_TotalChildrenBornWithMating
            ShowAchievementProgress(AchievementObjects.NewArcChurchMartianborns)
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
        AchievementObjects.CuredColonists.ParameterValue = bld.total_cured
        ShowAchievementProgress(AchievementObjects.CuredColonists)
    end
end

function OnMsg.ColonistJoinsDome(_, dome)
    --Had100ColonistsInDome
    if #(dome.labels.Colonist or empty_table) <= AchievementPresets.Had100ColonistsInDome.target then
        AchievementObjects.Had100ColonistsInDome.ParameterValue = #(dome.labels.Colonist or empty_table)
        ShowAchievementProgress(AchievementObjects.Had100ColonistsInDome)
    end
    --Had50AndroidsInDome
    if #(dome.labels.Android or empty_table) >= AchievementPresets.Had50AndroidsInDome.target then
        AchievementObjects.Had50AndroidsInDome.ParameterValue = #(dome.labels.Android or empty_table)
        ShowAchievementProgress(AchievementObjects.Had50AndroidsInDome)
    end
end

--event handling
OnMsg.ModsReloaded = Init
OnMsg.CityStart = Init
OnMsg.LoadGame = Init