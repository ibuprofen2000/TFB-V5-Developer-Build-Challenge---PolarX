---@diagnostic disable: param-type-mismatch

local activeGarage = nil
local isUIOpen     = false

local function CreateGarageBlip(garageId, garageCfg)
    local blip = AddBlipForCoord(garageCfg.trigger.x, garageCfg.trigger.y, garageCfg.trigger.z)
    SetBlipSprite(blip, garageCfg.blip.sprite)
    SetBlipColour(blip, garageCfg.blip.colour)
    SetBlipScale(blip,  garageCfg.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(garageCfg.label)
    EndTextCommandSetBlipName(blip)
end

local function DrawZoneMarker(pos)
    DrawMarker(
        1,
        pos.x, pos.y, pos.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        3.0, 3.0, 0.5,
        30, 144, 255, 100,
        false, false, 2, false, false, false, false
    )
end

local function DrawHelpText(label, text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

CreateThread(function()
    for garageId, garageCfg in pairs(Config.Garages) do
        CreateGarageBlip(garageId, garageCfg)
    end
end)

CreateThread(function()
    while true do
        local sleep    = 1000
        local ped      = PlayerPedId()
        local pedCoord = GetEntityCoords(ped)

        for garageId, garageCfg in pairs(Config.Garages) do
            local dist = #(pedCoord - garageCfg.trigger)
            if dist < 50.0 then
                sleep = 0

                DrawZoneMarker(garageCfg.trigger)

                if dist < Config.InteractRadius and not isUIOpen then
                    activeGarage = garageId
                    DrawHelpText(garageId, ('~INPUT_CONTEXT~ Open %s'):format(garageCfg.label))

                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('tfb-parking:server:OpenGarage', garageId)
                    end
                end
            end
        end

        if sleep > 0 then
            activeGarage = nil
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('tfb-parking:client:OpenGarage', function(garageId, vehicles)
    if isUIOpen then return end
    isUIOpen = true

    local garageCfg = Config.Garages[garageId]
    SendNUIMessage({
        action  = 'openGarage',
        garage  = {
            id    = garageId,
            label = garageCfg and garageCfg.label or garageId,
        },
        vehicles = vehicles,
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('parkVehicle', function(data, cb)
    cb('ok')
    -- Close the UI before checking the player's current vehicle.
    SetNuiFocus(false, false)
    isUIOpen = false

    local garageId = data.garageId
    local ped      = PlayerPedId()
    local veh      = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(veh) or veh == 0 then
        Config.Notify('You must be in a vehicle to park it.', 'error')
        return
    end

    local props = _G.GetVehicleProps(veh)
    local netId = VehToNet(veh)

    TriggerServerEvent('tfb-parking:server:ParkVehicle', garageId, netId, props)
end)

RegisterNUICallback('retrieveVehicle', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    isUIOpen = false

    TriggerServerEvent('tfb-parking:server:RetrieveVehicle', data.garageId, data.vehicleId)
end)

RegisterNUICallback('closeGarage', function(_, cb)
    cb('ok')
    SetNuiFocus(false, false)
    isUIOpen = false
    SendNUIMessage({ action = 'closeGarage' })
end)
