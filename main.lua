---@diagnostic disable: undefined-global

local DB = require('server.sv_database')

--- Returns the primary identifier of a player (license: preferred).
---@param src integer  player server-id
---@return string|nil
local function GetOwnerIdentifier(src)
    local playerSrc = tostring(src)

    for i = 0, GetNumPlayerIdentifiers(playerSrc) - 1 do
        local id = GetPlayerIdentifier(playerSrc, i)
        if id and id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return GetPlayerIdentifier(playerSrc, 0)
end

--- Decode JSON safely; return empty table on failure.
---@param raw string
---@return table
local function SafeDecode(raw)
    local ok, result = pcall(json.decode, raw)
    if ok and type(result) == 'table' then return result end
    return {}
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    DB.Init()
    if Config.Debug then
        print('[tfb-parking] Database initialised.')
    end
end)

RegisterNetEvent('tfb-parking:server:OpenGarage', function(garageId)
    local src   = source
    local owner = GetOwnerIdentifier(src)
    if not owner then return end

    if not Config.Garages[garageId] then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Invalid garage.', 'error')
        return
    end

    local vehicles = DB.GetGarageVehicles(owner, garageId)
    local list = {}
    for _, v in ipairs(vehicles) do
        list[#list + 1] = {
            id       = v.id,
            model    = v.model,
            plate    = v.plate,
            garage   = v.garage,
            parkedAt = tostring(v.parked_at),
            props    = SafeDecode(v.props),
        }
    end
    TriggerClientEvent('tfb-parking:client:OpenGarage', src, garageId, list)
end)

RegisterNetEvent('tfb-parking:server:ParkVehicle', function(garageId, vehicleNet, props)
    local src   = source
    local owner = GetOwnerIdentifier(src)
    if not owner then return end

    if not Config.Garages[garageId] then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Invalid garage.', 'error')
        return
    end

    if type(props) ~= 'table' then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Malformed vehicle data.', 'error')
        return
    end

    local count = DB.CountParked(owner)
    if count >= Config.MaxSlotsPerPlayer then
        TriggerClientEvent('tfb-parking:client:Notify', src, ('You have reached the parking limit (%d vehicles).'):format(Config.MaxSlotsPerPlayer), 'error')
        return
    end

    local model = tostring(props.model or ''):sub(1, 60)
    local plate = tostring(props.plate or ''):sub(1, 20)

    if model == '' or plate == '' then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Vehicle data incomplete.', 'error')
        return
    end

    local propsJson = json.encode(props)
    local newId     = DB.ParkVehicle(owner, garageId, model, plate, propsJson)

    if not newId then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Database error. Try again.', 'error')
        return
    end

    TriggerClientEvent('tfb-parking:client:VehicleParked', src, vehicleNet, newId)

    if Config.Debug then
        print(('[tfb-parking] %s parked "%s" (%s) at %s [id=%d]'):format(owner, model, plate, garageId, newId))
    end
end)

RegisterNetEvent('tfb-parking:server:RetrieveVehicle', function(garageId, vehicleId)
    local src   = source
    local owner = GetOwnerIdentifier(src)
    if not owner then return end

    if not Config.Garages[garageId] then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Invalid garage.', 'error')
        return
    end

    local success = DB.RetrieveVehicle(vehicleId, owner)
    if not success then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Vehicle not found or already retrieved.', 'error')
        return
    end

    local rows = MySQL.query.await(
        'SELECT `model`, `props` FROM `tfb_parked_vehicles` WHERE `id` = ?',
        { vehicleId }
    )

    if not rows or not rows[1] then
        TriggerClientEvent('tfb-parking:client:Notify', src, 'Could not load vehicle data.', 'error')
        return
    end

    local row        = rows[1]
    local props      = SafeDecode(row.props)
    local spawnPoint = Config.Garages[garageId].spawnPoint

    TriggerClientEvent('tfb-parking:client:SpawnVehicle', src, row.model, props, spawnPoint)

    if Config.Debug then
        print(('[tfb-parking] %s retrieved vehicle id=%d from %s'):format(owner, vehicleId, garageId))
    end
end)

exports('GetParkedVehicles', function(src)
    local owner = GetOwnerIdentifier(src)
    if not owner then return {} end
    return DB.GetParkedVehicles(owner)
end)
