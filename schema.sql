-- ===================================================
--  tfb-parking  |  SQL Schema
--  Compatible with: MySQL 5.7+ / MariaDB 10.3+
--  Run this once (or let the resource auto-create it
--  via the CREATE TABLE IF NOT EXISTS in database.lua)
-- ===================================================

CREATE TABLE IF NOT EXISTS `tfb_parked_vehicles` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT  COMMENT 'Unique row id',
    `owner`         VARCHAR(60)     NOT NULL                 COMMENT 'Player license identifier',
    `garage`        VARCHAR(60)     NOT NULL                 COMMENT 'Garage key from Config.Garages',
    `model`         VARCHAR(60)     NOT NULL                 COMMENT 'Vehicle model name (lower-case)',
    `plate`         VARCHAR(20)     NOT NULL                 COMMENT 'Number plate text',
    `props`         LONGTEXT        NOT NULL DEFAULT '{}'    COMMENT 'JSON-encoded vehicle properties',
    `parked_at`     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the vehicle was parked',
    `retrieved_at`  TIMESTAMP       NULL      DEFAULT NULL   COMMENT 'When the vehicle was last retrieved',
    `is_parked`     TINYINT(1)      NOT NULL DEFAULT 1       COMMENT '1 = currently parked; 0 = retrieved',
    PRIMARY KEY (`id`),
    KEY `idx_owner`  (`owner`),
    KEY `idx_garage` (`garage`),
    KEY `idx_plate`  (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Stores persistently parked player vehicles for tfb-parking';
