--- Collect every relevant property from a vehicle entity.
---@param veh integer  entity handle
---@return table
local function GetVehicleProps(veh)
    local mods = {}
    SetVehicleModKit(veh, 0)
    for i = 0, 49 do
        mods[i] = GetVehicleMod(veh, i)
    end

    local extras = {}
    for i = 1, 12 do
        extras[i] = IsVehicleExtraTurnedOn(veh, i)
    end

    local r1, g1, b1 = GetVehicleCustomPrimaryColour(veh)
    local r2, g2, b2 = GetVehicleCustomSecondaryColour(veh)

    return {
        model            = GetEntityModel(veh),
        plate            = GetVehicleNumberPlateText(veh),
        plateIndex       = GetVehicleNumberPlateTextIndex(veh),
        primaryColor     = GetVehicleColours(veh),
        secondaryColor   = select(2, GetVehicleColours(veh)),
        customPrimary    = GetIsVehiclePrimaryColourCustom(veh)   and { r = r1, g = g1, b = b1 } or nil,
        customSecondary  = GetIsVehicleSecondaryColourCustom(veh) and { r = r2, g = g2, b = b2 } or nil,
        pearlescentColor = GetVehicleExtraColours(veh),
        wheelColor       = select(2, GetVehicleExtraColours(veh)),
        dashboardColor   = GetVehicleDashboardColour(veh),
        interiorColor    = GetVehicleInteriorColour(veh),
        wheels           = GetVehicleWheelType(veh),
        windowTint       = GetVehicleWindowTint(veh),
        neonEnabled      = {
            IsVehicleNeonLightEnabled(veh, 0),
            IsVehicleNeonLightEnabled(veh, 1),
            IsVehicleNeonLightEnabled(veh, 2),
            IsVehicleNeonLightEnabled(veh, 3),
        },
        neonColor        = table.pack(GetVehicleNeonLightsColour(veh)),
        xenonColor       = GetVehicleXenonLightsColour(veh),
        mods             = mods,
        extras           = extras,
        bodyHealth       = math.floor(GetVehicleBodyHealth(veh)   + 0.5),
        engineHealth     = math.floor(GetVehicleEngineHealth(veh) + 0.5),
        tankHealth       = math.floor(GetVehiclePetrolTankHealth(veh) + 0.5),
        dirtLevel        = GetVehicleDirtLevel(veh),
        fuelLevel        = GetVehicleFuelLevel(veh),
        modelName        = GetDisplayNameFromVehicleModel(GetEntityModel(veh)):lower(),
    }
end

--- Apply a props table back onto a freshly spawned vehicle.
---@param veh   integer  entity handle
---@param props table
local function SetVehicleProps(veh, props)
    if not props then return end

    SetVehicleModKit(veh, 0)

    if props.plate then
        SetVehicleNumberPlateText(veh, props.plate)
    end
    if props.plateIndex then
        SetVehicleNumberPlateTextIndex(veh, props.plateIndex)
    end

    if props.primaryColor   then SetVehicleColours(veh, props.primaryColor, props.secondaryColor or 0) end
    if props.customPrimary  then SetVehicleCustomPrimaryColour(veh, props.customPrimary.r,   props.customPrimary.g,   props.customPrimary.b) end
    if props.customSecondary then SetVehicleCustomSecondaryColour(veh, props.customSecondary.r, props.customSecondary.g, props.customSecondary.b) end
    if props.pearlescentColor then SetVehicleExtraColours(veh, props.pearlescentColor, props.wheelColor or 0) end
    if props.dashboardColor   then SetVehicleDashboardColour(veh, props.dashboardColor) end
    if props.interiorColor    then SetVehicleInteriorColour(veh, props.interiorColor) end

    if props.wheels     then SetVehicleWheelType(veh, props.wheels) end
    if props.windowTint then SetVehicleWindowTint(veh, props.windowTint) end

    if props.neonEnabled then
        for i, enabled in ipairs(props.neonEnabled) do
            SetVehicleNeonLightEnabled(veh, i - 1, enabled)
        end
    end
    if props.neonColor then
        SetVehicleNeonLightsColour(veh, props.neonColor[1] or 0, props.neonColor[2] or 0, props.neonColor[3] or 0)
    end
    if props.xenonColor then SetVehicleXenonLightsColour(veh, props.xenonColor) end

    if props.mods then
        for modIndex, modValue in pairs(props.mods) do
            local slot = tonumber(modIndex)
            if slot then
                SetVehicleMod(veh, slot, modValue, false)
            end
        end
    end

    if props.extras then
        for extraIndex, enabled in pairs(props.extras) do
            local extra = tonumber(extraIndex)
            if extra then
                SetVehicleExtra(veh, extra, not enabled)
            end
        end
    end

    if props.bodyHealth   then SetVehicleBodyHealth(veh, props.bodyHealth)     end
    if props.engineHealth then SetVehicleEngineHealth(veh, props.engineHealth) end
    if props.tankHealth   then SetVehiclePetrolTankHealth(veh, props.tankHealth) end
    if props.dirtLevel    then SetVehicleDirtLevel(veh, props.dirtLevel)       end
    if props.fuelLevel    then SetVehicleFuelLevel(veh, props.fuelLevel)       end
end

---@param modelHash integer|string
---@param props     table
---@param spawnPoint vector4
local function SpawnVehicle(modelHash, props, spawnPoint)
    if type(modelHash) == 'string' then
        modelHash = GetHashKey(modelHash)
    end

    if not IsModelValid(modelHash) then
        Config.Notify('Invalid vehicle model.', 'error')
        return
    end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + Config.SpawnTimeout
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > deadline then
            Config.Notify('Vehicle failed to load. Try again.', 'error')
            return
        end
        Wait(100)
    end

    local veh = CreateVehicle(
        modelHash,
        spawnPoint.x, spawnPoint.y, spawnPoint.z,
        spawnPoint.w,
        true,
        false
    )

    deadline = GetGameTimer() + Config.SpawnTimeout
    while not DoesEntityExist(veh) do
        if GetGameTimer() > deadline then
            Config.Notify('Vehicle entity failed to create.', 'error')
            SetModelAsNoLongerNeeded(modelHash)
            return
        end
        Wait(100)
    end

    SetModelAsNoLongerNeeded(modelHash)
    SetVehicleProps(veh, props)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetEntityAsNoLongerNeeded(veh)

    Config.Notify('Vehicle retrieved successfully!', 'success')
end

RegisterNetEvent('tfb-parking:client:SpawnVehicle', function(model, props, spawnPoint)
    SpawnVehicle(props.model or model, props, spawnPoint)
end)

RegisterNetEvent('tfb-parking:client:VehicleParked', function(vehicleNet, newId)
    local veh = NetToVeh(vehicleNet)
    if DoesEntityExist(veh) then
        -- Request control before deleting a networked entity.
        NetworkRequestControlOfEntity(veh)
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(veh) do
            if GetGameTimer() - t > 3000 then break end
            Wait(50)
        end
        DeleteEntity(veh)
    end
    Config.Notify('Vehicle parked successfully!', 'success')
end)

RegisterNetEvent('tfb-parking:client:Notify', function(msg, notifyType)
    Config.Notify(msg, notifyType or 'info')
end)

exports('GetVehicleProps', GetVehicleProps)
_G.GetVehicleProps = GetVehicleProps
