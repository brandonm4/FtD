
-- settings
 -- exact full name
recallHealthFraction = .9

-- debug/fix
 -- if the drones crash in the water, 10000m away and you keep getting attacked, 
 -- set this to true to force the drones to return.  Then set back to false once they are good to use again.
 -- Mainly used in adventure mode on higher difficulty where the enemies don't give you a break but you need to recall 
 -- the drones.
forceRecall = false
logDebug = true 
-- end settings

droneState = {}
colorRed = {1,0,0}

colorGreen = {0,1,0}
colorBlue = {0,0,1}
colorYellow = {.5,.5,0}

function Update(I)
    local targetCount = 0
    local releaseDrones = 0
    -- Do we have any targets?
    for i = 0, I:GetNumberOfMainframes() - 1 do
        targetCount = targetCount + I:GetNumberOfTargets(i)
    end

    CheckDocks(I, targetCount)
    --I:Log(I:Component_GetCount(7))
end

-- utility
function contains(arr, val, I)
    
    consoleLog(I, "Searching For"..val)
    for i,v in ipairs(arr) do
       consoleLog(I, "Comparing:"..val.." , "..v)
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

function CheckDocks(I, targetCount)
    for i = 0, I:Component_GetCount(7) - 1 do
        
        local binfo = I:Component_GetBlockInfo(7,i)
        local lightIdx = GetComponentIndexByName(I, 30, binfo.CustomName.." Light")

        local fId = I:Component_GetIntLogic_1(7, i, 0)
        


        if fId > 0 then
             local finfo = GetFriendlyInfo(I, fId)
             if droneState[fId] == nil then
                 droneState[fId] = false
             end
             
             droneState[fId] = ShouldDroneRecall(I, finfo)
             
             if I:Component_GetBoolLogic_1(7, i, 0) then
                  SetLightColor(I,lightIdx, colorRed) 
             else
                  SetLightColor(I,lightIdx, colorYellow) 
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
            SetLightColor(I,lightIdx, colorGreen)
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
      --I:Log("Found Light: "..name.." at "..i)
      return i
   end
end
end

function SetLightColor(I, lightIndex, color)
    if (lightIndex == nil) then return end
    --I:Log(lightIndex)
    --I:Log("Setting Light Color Light")
    I:Component_SetFloatLogic_1(30, lightIndex, 2, color[1])
    I:Component_SetFloatLogic_1(30, lightIndex, 3, color[2])
    I:Component_SetFloatLogic_1(30, lightIndex, 4, color[3])

end

function ShouldDroneRecall(I, droneFriendlyInfo)
    -- if drone is all fixed up it can be released
    if droneFriendlyInfo.HealthFraction == 1 and droneFriendlyInfo.FuelFraction == 1 and droneFriendlyInfo.AmmoFraction ==
        1 then
        return false
    end
    if droneFriendlyInfo.HealthFraction < recallHealthFraction then
        return true
    end
    if droneFriendlyInfo.FuelFraction < .25 then
        return true
    end
    if droneFriendlyInfo.AmmoFraction == 0 then
        return true
    end
    return false
end