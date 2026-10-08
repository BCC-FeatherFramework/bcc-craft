-- bcc-craft item definitions for feather-inventory.
-- Safe to run more than once: existing items keep their IDs, stock and settings.
-- Tools are unique so feather-inventory can track their condition (durability).
-- Apply once, then restart feather-inventory and bcc-craft.
-- Ammunition recipes produce feather-weapons ammo items (installed by feather-weapons).

-- Tools
INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'hammer', 'Hammer', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'hammer');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'ironhammer', 'Iron Hammer', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'ironhammer');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'pan', 'Pan', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'pan');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'pliers', 'Pliers', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'pliers');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'screwdriver', 'Screwdriver', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'screwdriver');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'bulletsmould', 'Bullet Mold', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'bulletsmould');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'lockpickmold', 'Lockpick Mold', 'A crafting tool that wears with use.', 5, 1, 1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'lockpickmold');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'lockpick', 'Lockpick', 'Used to pick locks. Breaks on a failed attempt.', 20, 10, 0.1, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'tools'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'lockpick');

-- Materials
INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'bulletscase', 'Bullet Casings', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'bulletscase');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'powdergun', 'Gunpowder', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'powdergun');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'ironbar', 'Iron Ingot', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'ironbar');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'copperbar', 'Copper Ingot', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'copperbar');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'knivehandle', 'Knife Handle', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'knivehandle');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'nails', 'Nails', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'nails');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'revolverbarrel', 'Revolver Barrel', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'revolverbarrel');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'revolvercylinder', 'Revolver Cylinder', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'revolvercylinder');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'revolverhandle', 'Revolver Handle', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'revolverhandle');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'rope', 'Rope', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'rope');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'paper', 'Paper', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'paper');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'rollingpaper', 'Rolling Paper', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'rollingpaper');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'tobacco_leafs', 'Tobacco Leaves', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'tobacco_leafs');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'petroleum', 'Crude Oil', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'petroleum');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'petrol', 'Petrol', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'petrol');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'trainoil', 'Train Oil', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'trainoil');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'salt', 'Salt', 'A crafting material.', 200, 50, 0.2, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'materials'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'salt');

-- Provisions
INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'Mutton', 'Mutton', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'Mutton');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'biggame', 'Big Game Meat', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'biggame');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'bird', 'Bird Meat', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'bird');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'game', 'Game Meat', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'game');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'meat', 'Meat', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'meat');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'pork', 'Pork', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'pork');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'venison', 'Venison', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'venison');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'fish', 'Fish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'fish');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'egg', 'Egg', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'egg');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'steak', 'Grilled Meat', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'steak');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cooked_biggame', 'Salted Big Game Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cooked_biggame');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cooked_bird', 'Bird Meat Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cooked_bird');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cooked_game', 'Salted Game Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cooked_game');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cooked_mutton', 'Mutton Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cooked_mutton');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cooked_pork', 'Pork Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cooked_pork');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cooked_venison', 'Venison Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cooked_venison');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'consumable_breakfast', 'Breakfast', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'consumable_breakfast');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'consumable_bluegil', 'Fish Dish', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'consumable_bluegil');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'tobaccopipe', 'Dried Tobacco', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'tobaccopipe');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cigar', 'Cigar', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cigar');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cigarette', 'Cigarette', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cigarette');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cigaret', 'Cigarette Pack', 'Food or tobacco made or used in crafting.', 50, 10, 0.3, 0,
    (SELECT `id` FROM `categories` WHERE `name` = 'provisions'), 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cigaret');
