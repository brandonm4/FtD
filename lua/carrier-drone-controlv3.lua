-- GLOBALS
droneState = {}
ColorRed = {1, 0, 0}
ColorGreen = {0, 1, 0}
ColorBlue = {0, 0, 1}
ColorYellow = {.5, .5, 0}
numberTicks = 0

-- USER SETTINGS
-- Recall Fractions (When below this amount)
recallHealthFraction = .9
recallFuelFraction = 0
recallAmmoFraction = 0
-- Launch settings
launchHealth = 1
launchFuel = .5
launchAmmo = .5
-- Light Colors
colorDocked = colorRed
colorOpen = colorGreen
colorUndocked = colorYellow
-- UpdateRate - how often to run script
updateRate = 10

forceRecall = false
logDebug = true
-- END SETTINGS

function Update(I)

    numberTicks = numberTicks + 1
    if (numberTicks > updateRate) then
        numberTicks = 0
        
        local targetCount = 0
        local releaseDrones = 0
        -- Do we have any targets?
        for i = 0, I:GetNumberOfMainframes() - 1 do
            targetCount = targetCount + I:GetNumberOfTargets(i)
        end
        CheckDocks(I, targetCount)
    end
end



function CheckDocks(I, targetCount)
    for i = 0, I:Component_GetCount(7) - 1 do

        local binfo = I:Component_GetBlockInfo(7, i)
        local lightIdx = GetComponentIndexByName(I, 30, binfo.CustomName .. " Light")

        local fId = I:Component_GetIntLogic_1(7, i, 0)

        if fId > 0 then
            local finfo = GetFriendlyInfo(I, fId)
            if droneState[fId] == nil then
                droneState[fId] = false
            end

            droneState[fId] = ShouldDroneRecall(I, finfo)

            if I:Component_GetBoolLogic_1(7, i, 0) then
                SetLightColor(I, lightIdx, colorDocked)
            else
                SetLightColor(I, lightIdx, colorUndocked)
            end

            if forceRecall == true then
                droneState[fId] = true
            end

            if targetCount > 0 then
                I:Component_SetBoolLogic_1(7, i, 0, droneState[fId])
            else

                I:Component_SetBoolLogic_1(7, i, 0, true)
            end
        else
            SetLightColor(I, lightIdx, colorOpen)
        end
    end
end

function GetFriendlyInfo(I, friendId)
    for i = 1, I.Fleet.Members.Length do
        local finfo = I.Fleet.Members[i]
        if (finfo.Valid) then
            if finfo.Id == friendId then
                return finfo
            end
        end
    end
end

-- 7 = tractor_beam
-- 30 = light
function GetComponentIndexByName(I, type, name)
    for i = 0, I:Component_GetCount(7) - 1 do
        local cInfo = I:Component_GetBlockInfo(type, i)
        if (cInfo.Valid and cInfo.CustomName == name) then
            -- I:Log("Found Light: "..name.." at "..i)
            return i
        end
    end
end

function SetLightColor(I, lightIndex, color)
    if (lightIndex == nil) then
        return
    end
    -- I:Log(lightIndex)
    -- I:Log("Setting Light Color Light")
    I:Component_SetFloatLogic_1(30, lightIndex, 2, color[1])
    I:Component_SetFloatLogic_1(30, lightIndex, 3, color[2])
    I:Component_SetFloatLogic_1(30, lightIndex, 4, color[3])

end

function ShouldDroneRecall(I, droneFriendlyInfo)
    -- if drone is all fixed up it can be released
    if (droneFriendlyInfo.HealthFraction >= launchHealth and droneFriendlyInfo.FuelFraction >= launchFuel and droneFriendlyInfo.AmmoFraction >= launchAmmo) then
        return false
    end
    if (droneFriendlyInfo.HealthFraction <= recallHealthFraction) then
        return true
    end
    if droneFriendlyInfo.FuelFraction <= recallFuelFraction then
        return true
    end
    if droneFriendlyInfo.AmmoFraction <= recallAmmoFraction then
        return true
    end
    return false
end


-- utility
function contains(arr, val, I)

    consoleLog(I, "Searching For" .. val)
    for i, v in ipairs(arr) do
        consoleLog(I, "Comparing:" .. val .. " , " .. v)
        if v == val then
            consoleLog(I, "Found")
            return true
        end
    end
    consoleLog(I, "NotFound")
    return false
end
function consoleLog(I, msg)
    if logDebug then
        I:Log(msg)
    end
end