-- Upgrade to v1.1.0: Add name, description, and image fields for single API call
ALTER TABLE `PREFIX_product_enriched`
    ADD COLUMN `name` VARCHAR(255) DEFAULT NULL AFTER `manufacturer_name`,
    ADD COLUMN `description_short` TEXT DEFAULT NULL AFTER `name`,
    ADD COLUMN `id_default_image` INT(10) UNSIGNED DEFAULT NULL AFTER `description_short`,
    ADD INDEX `idx_name` (`name`);
