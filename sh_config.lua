Config = {}

Config.Debug = false
Config.SpawnTimeout = 10000
Config.MaxSlotsPerPlayer = 10

Config.InteractRadius = 5.0

Config.Garages = {

    ['pillbox'] = {
        label = 'Pillbox Hill Garage',
        blip  = { sprite = 357, colour = 3, scale = 0.8 },
        trigger    = vector3(215.0, -810.0, 30.7),
        spawnPoint = vector4(209.0, -803.0, 30.7, 250.0),
    },

    ['airport'] = {
        label = 'LSIA Garage',
        blip  = { sprite = 357, colour = 5, scale = 0.8 },
        trigger    = vector3(-1044.0, -2913.0, 13.8),
        spawnPoint = vector4(-1053.0, -2921.0, 13.8, 330.0),
    },

    ['ls_customs'] = {
        label = 'LS Customs',
        blip  = { sprite = 357, colour = 69, scale = 0.8 },
        trigger    = vector3(-347.0, -137.0, 38.6),
        spawnPoint = vector4(-338.0, -130.0, 38.6, 250.0),
    },

    ['sandy'] = {
        label = 'Sandy Shores Garage',
        blip  = { sprite = 357, colour = 2, scale = 0.8 },
        trigger    = vector3(1869.0, 3696.0, 34.3),
        spawnPoint = vector4(1878.0, 3704.0, 34.3, 230.0),
    },

    ['paleto'] = {
        label = 'Paleto Bay Garage',
        blip  = { sprite = 357, colour = 25, scale = 0.8 },
        trigger    = vector3(-125.0, 6469.0, 31.6),
        spawnPoint = vector4(-135.0, 6460.0, 31.6, 140.0),
    },
}

Config.SavedProps = {
    'colour',
    'extras',
    'mods',
    'plate',
    'plateIndex',
    'fuel',
    'bodyHealth',
    'engineHealth',
    'dirtLevel',
}

-- Replace this with your framework notification if needed.
Config.Notify = function(msg, type)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('[TFB Parking] %s'):format(msg))
    EndTextCommandThefeedPostTicker(false, true)
end
