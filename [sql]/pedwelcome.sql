-- ===============================
-- nb-pedwelcome TABLES
-- Run this once. Safe to re-run.
-- ===============================

CREATE TABLE IF NOT EXISTS `nb_pedwelcome_received` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `identifier`  VARCHAR(60) NOT NULL,
    `received_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `idx_pedwelcome_identifier` (`identifier`)
) ENGINE=InnoDB;
