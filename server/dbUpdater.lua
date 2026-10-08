CreateThread(function()
    -- Create the bcc_crafting_log table if it doesn't exist
    DB.exec([[
        CREATE TABLE IF NOT EXISTS `bcc_crafting_log` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `charidentifier` varchar(50) NOT NULL,
            `itemName` varchar(100) NOT NULL,
            `itemLabel` varchar(100) NOT NULL,
            `itemAmount` int(11) NOT NULL,
            `requiredItems` text NOT NULL,
            `timestamp` bigint(20) NOT NULL,
            `status` varchar(20) NOT NULL,
            `duration` int(11) NOT NULL,
            `rewardXP` int(11) NOT NULL,
            `completed_at` datetime DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Create the bcc_craft_progress table if it doesn't exist
    DB.exec([[
        CREATE TABLE IF NOT EXISTS `bcc_craft_progress` (
            `charidentifier` varchar(50) NOT NULL,
            `currentXP` int(11) NOT NULL DEFAULT 0,
            `currentLevel` int(11) NOT NULL DEFAULT 1,
            PRIMARY KEY (`charidentifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Add the lastLevel column if it doesn't already exist
    DB.exec([[
        ALTER TABLE `bcc_craft_progress` ADD COLUMN IF NOT EXISTS `lastLevel` int(11) NOT NULL DEFAULT 1;
    ]])

    -- Update lastLevel to match currentLevel for all existing records
    DB.exec([[
        UPDATE `bcc_craft_progress`
        SET `lastLevel` = `currentLevel`;
    ]])

    -- Craft books are feather-inventory items. Every book named in the config
    -- (location craftbookCategory and category craftBookItem) is added once;
    -- existing items keep their IDs and settings.
    local books = {}
    for _, location in ipairs(CraftingLocations) do
        if location.craftbookCategory and location.craftbookCategory ~= "" then
            books[location.craftbookCategory] = (location.blip and location.blip.label or "Crafting") .. " Craftbook"
        end
        for _, category in ipairs(location.categories or {}) do
            if category.craftBookItem and category.craftBookItem ~= "" then
                books[category.craftBookItem] = (category.label or "Crafting") .. " Craftbook"
            end
        end
    end
    for name, label in pairs(books) do
        pcall(DB.exec, [[
            INSERT INTO `items`
                (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
            SELECT ?, ?, 'Used to open the crafting menu.', 1, 1, 0.1, 1,
                (SELECT `id` FROM `categories` ORDER BY (`name` = 'documents') DESC, (`name` = 'other') DESC, `id` LIMIT 1),
                'item_item', 'stack'
            WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = ?)
        ]], name, label, name)
    end

    --  Added locationId to be able to collect the crafted items from where start the crafting
    DB.exec([[
        ALTER TABLE `bcc_crafting_log` ADD COLUMN IF NOT EXISTS `locationId` VARCHAR(50) DEFAULT NULL;
    ]])
    
    -- Print a success message to the console
    print("Database tables for \x1b[35m\x1b[1m*bcc-crafting*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
end)
