-- See license.md for copyright info
SharedModEnv["FFL_Debug"] = true

local function Log(...)
    FFL_LogMessage(CurrentModDef.title, "AchievementTracker", ...)
end

--locals
local AchievementObjects = {}
local InitDone = false

--initialize achievement objects
local function Init()
    InitDone = false
    if not MainCity then
        Log("No city!")
        return
    end

    if not AchievementPresets then
        Log("ERROR", "No Achievements!")
        return
    end

    if SharedModEnv["FFL_Debug"] then
        if MainCity.labels.TrackedAchievements then
            MainCity.labels.TrackedAchievements = nil
        end
    end

    if not MainCity.labels.TrackedAchievements then
        for _,Achievement in pairs(AchievementPresets) do

            if Achievement.save_in then
                if (Achievement.save_in == "picard" and g_AvailableDlc.picard) or
                        (Achievement.save_in == "armstrong" and g_AvailableDlc.armstrong) or
                        (Achievement.save_in == "gagarin" and g_AvailableDlc.gagarin) then
                end
            end

            local AchievementObj = PlaceObj("TrackedAchievement")
            AchievementObj.id = _InternalTranslate(Achievement.id)
            AchievementObj.Name = _InternalTranslate(Achievement.display_name)
            AchievementObj.Description = _InternalTranslate(Achievement.how_to)
            AchievementObj.Image = Achievement.image
            AchievementObj.Target = Achievement.target

            AchievementObjects[AchievementObj.id] = AchievementObj

            CreateGameTimeThread(function()
                Sleep(1000) -- wait for PlaceObj to finish
                --boo for hardcoding
                AchievementObjects.AsteroidHopping.Target = 10
                AchievementObjects.USAResearchedEngineering.Target = #Presets.TechPreset.Engineering
                AchievementObjects.Multitasking.Target = 3
                AchievementObjects.SpaceDwarves.Target = 200
                AchievementObjects.Willtheyhold.Target = 100
                AchievementObjects.ScannedAllSectors.Target = 100
                AchievementObjects.DeepScannedAllSectors.Target = 100
                AchievementObjects.SpaceExplorer.Target = #Presets.TechPreset.ReconAndExpansion -- = 0... data must not be initialized yet, updated later

                --boo for using the wrong scale
                AchievementObjects.IndiaConvertedWasteRock.Type = "Resource"
                AchievementObjects.BrazilConvertedWasteRock.Type = "Resource"
                AchievementObjects.RussiaExtractedAlot.Type = "Resource"
                AchievementObjects.BlueSunProducedFunding.Type = "Resource"
                AchievementObjects.BlueSunExportedAlot.Type = "Resource"
            end)
        end
    end
    InitDone = true
    CreateOSD()
end


--achievement triggers below
function OnMsg.MarkPreciousMetalsExport(city, _)

    if not InitDone then
        return
    end

    --BlueSunExportedAlot
    if GetMissionSponsor().id == "BlueSun" and UIColony.day < 100 then
        AchievementObjects.BlueSunExportedAlot:UpdateValue(city.total_export)
    end
end

function OnMsg.RocketLanded(rocket)

    if not InitDone then
        return
    end

    --AsteroidHopping
    if rocket:IsKindOf("LanderRocketBase") then
        local has_landed_on_asteroid = ObjectIsInEnvironment(rocket, "Asteroid")
        if has_landed_on_asteroid and rocket.asteroids_visited_this_trip <= 10 then
            AchievementObjects.AsteroidHopping:UpdateValue(#rocket.asteroids_visited_this_trip)
        end
    end
    --Landed50Rockets
    if g_RocketsLandedCount <= AchievementPresets.Landed50Rockets.target then
        AchievementObjects.Landed50Rockets:UpdateValue(g_RocketsLandedCount)
    end
end

function OnMsg.TechResearched(_, research, first_time)
    if not first_time or not InitDone then
        return
    end
    --SpaceExplorer
    if AchievementObjects.SpaceExplorer.Target == 0 then
        AchievementObjects.SpaceExplorer.Target = #Presets.TechPreset.ReconAndExpansion
    end
    for field_id, field in pairs(TechFields) do
        if field:HasMember("save_in") and field.save_in == "picard" then
            local researched, total = research:TechCount(field_id, "researched")
            if researched < total then
                if AchievementObjects.SpaceExplorer.Target > 0 then
                    AchievementObjects.SpaceExplorer:UpdateValue(researched)
                    return
                end
            end
        end
    end
    --USAResearchedEngineering
    if sponsor.id == "NASA" and UIColony.day < 100 and research:TechCount("Engineering", "researched") <= #research.tech_field.Engineering then
        AchievementObjects.USAResearchedEngineering:UpdateValue(#research.tech_field.Engineering)
        --EuropeResearchedBreakthroughs
    elseif sponsor.id == "ESA" and UIColony.day < 100 and research:TechCount("Breakthroughs", "researched") <= AchievementPresets.EuropeResearchedBreakthroughs.target then
        AchievementObjects.EuropeResearchedBreakthroughs:UpdateValue(research:TechCount("Breakthroughs", "researched"))
    end
end

function OnMsg.AsteroidRocketLanded(rocket)

    if not InitDone then
        return
    end

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
        AchievementObjects.Multitasking:UpdateValue(num_astroids_visiting)
    end
end

function OnMsg.NewDay(Day)
    if not InitDone then
        return
    end

    if Day == 100 then
        if GetMissionSponsor().id == "BlueSun" then
            AchievementObjects.BlueSunExportedAlot:SetFailed()
            AchievementObjects.BlueSunProducedFunding:SetFailed()
        elseif GetMissionSponsor().id == "CNSA" then
            AchievementObjects.ChinaTaiChiGardens:SetFailed()
            AchievementObjects.ChinaReachedHighPopulation:SetFailed()
        elseif GetMissionSponsor().id == "Japan" then
            AchievementObjects.JapanTrainedSpecialists:SetFailed()
        elseif GetMissionSponsor().id == "ESA" then
            AchievementObjects.EuropeResearchedBreakthroughs:SetFailed()
            AchievementObjects.EuropeResearchedAlot:SetFailed()
        elseif GetMissionSponsor().id == "ISRO" then
            AchievementObjects.IndiaConvertedWasteRock:SetFailed()
            AchievementObjects.IndiaBuiltDomes:SetFailed()
        elseif GetMissionSponsor().id == "Roscosmos" then
            AchievementObjects.RussiaExtractedAlot:SetFailed()
        elseif GetMissionSponsor().id == "NewArk" then
            AchievementObjects.NewArkChurchHappyColonists:SetFailed()
            AchievementObjects.NewArcChurchMartianborns:SetFailed()
        elseif GetMissionSponsor().id == "NASA" then
            AchievementObjects.USAResearchedEngineering:SetFailed()
        elseif GetMissionSponsor().id == "Brazil" then
            AchievementObjects.BrazilConvertedWasteRock:SetFailed()
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
        AchievementObjects.SpaceDwarves:UpdateValue(number_underground_colonists)
    end
end

function OnMsg.PreventedCaveIn(_)
    if not InitDone then
        return
    end

    --Willtheyhold
    if PreventedCaveIns < 100 then
        AchievementObjects.Willtheyhold:UpdateValue(PreventedCaveIns)
    end
end

function OnMsg.BuildingInit(bld)
    if not InitDone then
        return
    end

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
                AchievementObjects.ChinaTaiChiGardens:UpdateValue(table.count(domes_with_garden))
            end
        end
    end
end

function OnMsg.TrainingComplete(building, _)
    if not InitDone then
        return
    end

    --JapanTrainedSpecialists
    if UIColony.day <= 100 and building.training_type == "specialization" and GetMissionSponsor().id == "Japan" then
        if TotalTrainedSpecialists <= AchievementPresets.JapanTrainedSpecialists.target then
            AchievementObjects.JapanTrainedSpecialists:UpdateValue(TotalTrainedSpecialists)
        end
    end
end

function OnMsg.FundingChanged(colony, amount)
    if not InitDone then
        return
    end

    --BlueSunProducedFunding
    if GameTime() > 1 and GetMissionSponsor().id == "BlueSun" and UIColony.day <= 100 and 0 < amount then
        if FundingGenerated <= AchievementPresets.BlueSunProducedFunding.target * 1000000 then
            AchievementObjects.BlueSunProducedFunding:UpdateValue(FundingGenerated)
        end
    end
    --GatheredFunding
    if colony.funding <= AchievementPresets.GatheredFunding.target then
        AchievementObjects.GatheredFunding:UpdateValue(colony.funding)
    end
end

function OnMsg.NewHour(_)
    if not InitDone then
        return
    end

    --EuropeResearchedAlot
    local sponsor = GetMissionSponsor().id
    if sponsor == "ESA" and UIColony.day <= 100 and UIColony:GetEstimatedRP() <= AchievementPresets.EuropeResearchedAlot.target then
        AchievementObjects.EuropeResearchedAlot:UpdateValue(UIColony:GetEstimatedRP())
    end
    --NewArkChurchHappyColonists
    if sponsor == "NewArk" and UIColony.day <= 100 then
        local colonists = UIColony:GetCityLabels("Colonist") or empty_table
        local count = 0
        for _, colonist in ipairs(colonists) do
            if colonist.stat_comfort >= 70 * const.Scale.Stat then
                count = count + 1
                if count <= AchievementPresets.NewArkChurchHappyColonists.target then
                    AchievementObjects.NewArkChurchHappyColonists:UpdateValue(count)
                end
            end
        end
    end
    --RussiaHadManyColonists
    if sponsor == "Roscosmos" and CalcChallengeRating() + 100 >= 500 and #(UIColony:GetCityLabels("Colonist") or empty_table) <= AchievementPresets.RussiaHadManyColonists.target then
        AchievementObjects.RussiaHadManyColonists:UpdateValue(#(UIColony:GetCityLabels("Colonist") or empty_table))
    end
end

function OnMsg.WasteRockConversion(amount, producers)
    if not InitDone then
        return
    end

    local sponsor = GetMissionSponsor().id
    WasteRockConverted = WasteRockConverted + amount
    if producers.PreciousMetals then
        WasteRockConvertedToRareMetals = WasteRockConvertedToRareMetals + amount
    end
    --IndiaConvertedWasteRock
    if sponsor == "ISRO" and UIColony.day <= 100 and WasteRockConverted / const.ResourceScale <= AchievementPresets.IndiaConvertedWasteRock.target then
        AchievementObjects.IndiaConvertedWasteRock:UpdateValue(WasteRockConverted / const.ResourceScale)
        --BrazilConvertedWasteRock
    elseif sponsor == "Brazil" and UIColony.day <= 100 and WasteRockConvertedToRareMetals / const.ResourceScale <= AchievementPresets.BrazilConvertedWasteRock.target then
        AchievementObjects.BrazilConvertedWasteRock:UpdateValue(WasteRockConverted / const.ResourceScale)
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
--2do: update/fix this
function OnMsg.TerraformParamChanged()
    if not InitDone then
        return
    end

    if not AllTerraformParamsMaxed() then
        local Notification = {
            id = "MaxedAllTPs",
            Title = "Creator of Worlds Progress",
            Message = "Atmosphere: " .. GetTerraformParamPct("Atmosphere") .. " / 100 " .. "Temperature: " .. GetTerraformParamPct("Temperature") .. " / 100 " .. "Water: " ..
                    GetTerraformParamPct("Water") .. " / 100 " .."Vegetation: " .. GetTerraformParamPct("Vegetation") .. " / 100 ",
            Icon = "UI/Achievements/" .. Achievement.Image .. ".dds",
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
                AchievementObjects.ColonistWithRareTraits:UpdateValue(rare_traits_count)
            end
            --HadColonistWith5Perks
            if perks_count <= HadColonistWith5Perks_target then
                AchievementObjects.HadColonistWith5Perks:UpdateValue(perks_count)
            end
        end
        if c.traits.Vegan then
            vegans_count = vegans_count + 1
        end
    end
    --HadVegans
    if vegans_count <= HadVegans_target then
        AchievementObjects.HadVegans:UpdateValue(vegans_count)
    end
end
function OnMsg.ColonistAddTrait()
    DelayedCall(30000, CheckTraitsAchievements)
end

function OnMsg.SectorScanned()
    if not InitDone then
        return
    end

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
        AchievementObjects.ScannedAllSectors:UpdateValue(SectorsScanned)
    end
    --DeepScannedAllSectors
    if SectorsDeepScanned <= SectorCount then
        AchievementObjects.DeepScannedAllSectors:UpdateValue(SectorsDeepScanned)
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
    if not InitDone then
        return
    end

    if IsKindOf(bld, "RocketLandingSite") then
        return
    end
    local city = bld.city
    --Built1000Buildings
    if g_BuildingsBuilt <= AchievementPresets.Built1000Buildings.target then
        AchievementObjects.Built1000Buildings:UpdateValue(g_BuildingsBuilt)
    end
    --IndiaBuiltDomes
    if IsKindOf(bld, "Dome") and GetMissionSponsor().id == "ISRO" and UIColony.day < 100 and not GetAchievementFlags("IndiaBuiltDomes") and
            CountNonConstructionSitesInLabel(city, "Dome") <= AchievementPresets.IndiaBuiltDomes.target - 1 then
        AchievementObjects.IndiaBuiltDomes:UpdateValue(CountNonConstructionSitesInLabel(city, "Dome"))
    end
    --BuiltSeveralWonders
    if bld.build_category == "Wonders" and not GetAchievementFlags("BuiltSeveralWonders") and
            CountNonConstructionSitesInLabel(city, "Wonders") <= AchievementPresets.BuiltSeveralWonders.target - 1
    then
        AchievementObjects.BuiltSeveralWonders:UpdateValue(CountNonConstructionSitesInLabel(city, "Wonders"))
    end
end

function OnMsg.ResourceExtracted()
    if not InitDone then
        return
    end

    --RussiaExtractedAl1ot
    if GetMissionSponsor().id == "Roscosmos" and UIColony.day < 100 and g_TotalExtractedResources <= RussiaExtractedAlot_target then
        AchievementObjects.RussiaExtractedAlot:UpdateValue(g_TotalExtractedResources)
    end
end

local CheckColonistCountAchievements = function()
    local total_colonists = #(UIColony:GetCityLabels("Colonist") or empty_table)
    --ChinaReachedHighPopulation
    if GetMissionSponsor().id == "CNSA" and UIColony.day < 100 and total_colonists <= ChinaReachedHighPopulation_target then
        AchievementObjects.ChinaReachedHighPopulation:UpdateValue(total_colonists)
    end
    --Reached1000Colonists
    if total_colonists <= Reached1000Colonists_target then
        AchievementObjects.Reached1000Colonists:UpdateValue(total_colonists)
    end
    --Reached250Colonists
    if total_colonists <= Reached250Colonists_target then
        AchievementObjects.Reached250Colonists:UpdateValue(total_colonists)
    end
end
function OnMsg.ColonistBorn(colonist)
    if not InitDone then
        return
    end

    --NewArcChurchMartianborns
    if colonist.traits.Child and colonist.age == 0 then
        if GetMissionSponsor().id == "NewArk" and UIColony.day < 100 and g_TotalChildrenBornWithMating <= AchievementPresets.NewArcChurchMartianborns.target then
            AchievementObjects.NewArcChurchMartianborns:UpdateValue(g_TotalChildrenBornWithMating)
        end
    end
    DelayedCall(1000, CheckColonistCountAchievements)
end
function OnMsg.ColonistArrived()
    DelayedCall(1000, CheckColonistCountAchievements)
end

function OnMsg.ColonistCured(_, bld)
    if not InitDone then
        return
    end

    --CuredColonists
    if bld.total_cured <= AchievementPresets.CuredColonists.target then
        AchievementObjects.CuredColonists:UpdateValue(bld.total_cured)
    end
end

function OnMsg.ColonistJoinsDome(_, dome)
    if not InitDone then
        return
    end

    --Had100ColonistsInDome
    if #(dome.labels.Colonist or empty_table) <= AchievementPresets.Had100ColonistsInDome.target then
        AchievementObjects.Had100ColonistsInDome:UpdateValue(#(dome.labels.Colonist or empty_table))
    end
    --Had50AndroidsInDome
    if #(dome.labels.Android or empty_table) >= AchievementPresets.Had50AndroidsInDome.target then
        AchievementObjects.Had50AndroidsInDome:UpdateValue(#(dome.labels.Android or empty_table))
    end
end

--event handling
function OnMsg.ModsReloaded()
    if MainCity then
        MainCity.labels.TrackedAchievement = nil
        Init()
    end
end
function OnMsg.ApplyModOptions()
    CreateOSD()
end
OnMsg.CityStart = Init
OnMsg.LoadGame = Init