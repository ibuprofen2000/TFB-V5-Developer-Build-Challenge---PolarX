---@diagnostic disable: undefined-global

local DB = {}

function DB.Init()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfb_parked_vehicles` (
            `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
            `owner`         VARCHAR(60)     NOT NULL,
            `garage`        VARCHAR(60)     NOT NULL,
            `model`         VARCHAR(60)     NOT NULL,
            `plate`         VARCHAR(20)     NOT NULL,
            `props`         LONGTEXT        NOT NULL DEFAULT '{}',
            `parked_at`     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `retrieved_at`  TIMESTAMP       NULL      DEFAULT NULL,
            `is_parked`     TINYINT(1)      NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`),
            KEY `idx_owner`  (`owner`),
            KEY `idx_garage` (`garage`),
            KEY `idx_plate`  (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

---@param owner string  citizen/license identifier
---@return table[]
function DB.GetParkedVehicles(owner)
    return MySQL.query.await(
        'SELECT * FROM `tfb_parked_vehicles` WHERE `owner` = ? AND `is_parked` = 1 ORDER BY `parked_at` DESC',
        { owner }
    ) or {}
end

---@param owner  string
---@param garage string
---@return table[]
function DB.GetGarageVehicles(owner, garage)
    return MySQL.query.await(
        'SELECT * FROM `tfb_parked_vehicles` WHERE `owner` = ? AND `garage` = ? AND `is_parked` = 1 ORDER BY `parked_at` DESC',
        { owner, garage }
    ) or {}
end

---@param owner  string
---@param garage string
---@param model  string   hash name (e.g. "adder")
---@param plate  string
---@param props  string   JSON-encoded vehicle properties
---@return integer  new row id
function DB.ParkVehicle(owner, garage, model, plate, props)
    return MySQL.insert.await(
        'INSERT INTO `tfb_parked_vehicles` (`owner`, `garage`, `model`, `plate`, `props`) VALUES (?, ?, ?, ?, ?)',
        { owner, garage, model, plate, props }
    )
end

---@param id    integer  row id
---@param owner string   safety-check: only let the owner retrieve
---@return boolean success
function DB.RetrieveVehicle(id, owner)
    local rows = MySQL.query.await(
        'UPDATE `tfb_parked_vehicles` SET `is_parked` = 0, `retrieved_at` = NOW() WHERE `id` = ? AND `owner` = ? AND `is_parked` = 1',
        { id, owner }
    )
    return (rows and rows > 0)
end

---@param id    integer
---@param owner string
---@param props string  JSON
function DB.UpdateProps(id, owner, props)
    MySQL.query.await(
        'UPDATE `tfb_parked_vehicles` SET `props` = ? WHERE `id` = ? AND `owner` = ? AND `is_parked` = 1',
        { props, id, owner }
    )
end

---@param owner string
---@return integer
function DB.CountParked(owner)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM `tfb_parked_vehicles` WHERE `owner` = ? AND `is_parked` = 1',
        { owner }
    ) or 0
end

return DB
