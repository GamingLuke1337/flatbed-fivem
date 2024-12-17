--[[
  _____   _                                 _   _   _
 |_   _| (_)  _ __    _   _   ___          | \ | | | |
   | |   | | | '_ \  | | | | / __|         |  \| | | |    
   | |   | | | | | | | |_| | \__ \         | |\  | | |___ 
   |_|   |_| |_| |_|  \__,_| |___/  _____  |_| \_| |_____|
                                   |_____|
]]--

local LastVehicle = nil
local LastStatus = false
local LastAttach = false
local Busy = false

--- Helper Function: Ensure Config is available
local function IsConfigValid()
    if not Config or not Config.Flatbeds or not Config.Blacklist or not Config.Translation then
        print("Error: Config is incomplete!")
        return false
    end
    return true
end

--- Helper Function: Retrieve vehicle information from Config
local function GetVehicleInfo(VehicleHash)
    for _, Flatbed in pairs(Config.Flatbeds) do
        if VehicleHash == GetHashKey(Flatbed.Hash) then
            return Flatbed
        end
    end
    return nil
end

--- Helper Function: Send notifications to the player
local function Notify(Text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(Text)
    DrawNotification(false, true)
end

--- Helper Function: Retrieve all vehicles in the world
local function GetVehicles()
    local AllVehicles = {}
    local Handle, Vehicle = FindFirstVehicle()
    local IsNext = true

    while IsNext do
        table.insert(AllVehicles, Vehicle)
        IsNext, Vehicle = FindNextVehicle(Handle)
    end

    EndFindVehicle(Handle)
    return AllVehicles
end

--- Helper Function: Check if a vehicle is allowed (not blacklisted)
local function IsAllowed(Vehicle)
    local VehicleClass = GetVehicleClass(Vehicle)
    for _, BlacklistedClass in pairs(Config.Blacklist) do
        if VehicleClass == BlacklistedClass then
            return false
        end
    end
    return true
end

--- Helper Function: Get the nearest vehicle within a certain radius
local function GetNearestVehicle(CheckCoords, Radius)
    local ClosestVehicle, ClosestDistance = nil, math.huge
    for _, Vehicle in pairs(GetVehicles()) do
        if DoesEntityExist(Vehicle) and IsAllowed(Vehicle) then
            local Distance = #(CheckCoords - GetEntityCoords(Vehicle))
            if Distance < Radius and Distance < ClosestDistance then
                ClosestVehicle, ClosestDistance = Vehicle, Distance
            end
        end
    end
    return ClosestVehicle
end

--- Movement logic for the flatbed
local function MoveFlatbed(PropID, VehicleInfo, TargetPos, TargetRot, Step)
    local BedPos = VehicleInfo.Default.Pos
    local BedRot = VehicleInfo.Default.Rot

    while true do
        Wait(10)

        -- Adjust position
        BedPos = BedPos + Step.Pos
        BedRot = BedRot + Step.Rot

        if (Step.Pos.y > 0 and BedPos.y >= TargetPos.y) or
           (Step.Pos.y < 0 and BedPos.y <= TargetPos.y) then
            BedPos = TargetPos
        end
        if (Step.Rot.x > 0 and BedRot.x >= TargetRot.x) or
           (Step.Rot.x < 0 and BedRot.x <= TargetRot.x) then
            BedRot = TargetRot
        end

        DetachEntity(PropID, false, false)
        AttachEntityToEntity(PropID, LastVehicle, nil, BedPos, BedRot, true, false, true, false, nil, true)

        if BedPos == TargetPos and BedRot == TargetRot then
            break
        end
    end
end

--- Event: Handle flatbed actions (lower, raise, attach, detach)
RegisterNetEvent('ti_flatbed:action')
AddEventHandler('ti_flatbed:action', function(BedInfo, Action)
    if not BedInfo then return end
    local PropID = NetworkGetEntityFromNetworkId(BedInfo.Prop)
    if not DoesEntityExist(PropID) then return end

    local VehicleInfo = GetVehicleInfo(GetEntityModel(LastVehicle))
    if not VehicleInfo then return end

    if Action == "lower" then
        MoveFlatbed(PropID, VehicleInfo, VehicleInfo.Active.Pos, VehicleInfo.Active.Rot, {Pos = vector3(0.0, -0.02, -0.0105), Rot = vector3(0.15, 0, 0)})
        LastStatus = true

    elseif Action == "raise" then
        MoveFlatbed(PropID, VehicleInfo, VehicleInfo.Default.Pos, VehicleInfo.Default.Rot, {Pos = vector3(0.0, 0.02, 0.0105), Rot = vector3(-0.15, 0, 0)})
        LastStatus = false

    elseif Action == "attach" then
        local AttachCoords = GetOffsetFromEntityInWorldCoords(PropID, VehicleInfo.Attach)
        local ClosestVehicle = GetNearestVehicle(AttachCoords, VehicleInfo.Radius)
        if DoesEntityExist(ClosestVehicle) and ClosestVehicle ~= LastVehicle then
            AttachEntityToEntity(ClosestVehicle, PropID, nil, AttachCoords, vector3(0, 0, 0), true, false, true, false, nil, true)
            TriggerServerEvent("ti_flatbed:editProp", NetworkGetNetworkIdFromEntity(LastVehicle), "Attached", NetworkGetNetworkIdFromEntity(ClosestVehicle))
        end

    elseif Action == "detach" then
        local AttachedVehicle = NetworkGetEntityFromNetworkId(BedInfo.Attached)
        if DoesEntityExist(AttachedVehicle) then
            DetachEntity(AttachedVehicle, true, true)
            TriggerServerEvent("ti_flatbed:editProp", NetworkGetNetworkIdFromEntity(LastVehicle), "Attached", nil)
        end
    end
    Busy = false
end)

--- Main Thread: Monitor player's vehicle and handle actions
CreateThread(function()
    while true do
        Wait(1)
        if not IsConfigValid() then return end

        local PlayerPed = PlayerPedId()
        local PlayerVehicle = GetVehiclePedIsIn(PlayerPed, false)

        if PlayerVehicle ~= 0 and PlayerVehicle ~= LastVehicle then
            LastVehicle = PlayerVehicle
            TriggerServerEvent("ti_flatbed:getProp", NetworkGetNetworkIdFromEntity(PlayerVehicle))
        end
    end
end)
