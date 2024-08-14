data:extend({{
    type = "custom-input",
    name = "mt_give-gps-selection-tool",
    key_sequence = "SHIFT + ALT + G",
    action = "spawn-item",
    item_to_spawn = "mt_gps-selection-tool",
    order = "a"
}, {
    type = "shortcut",
    name = "mt_give-gps-selection-tool",
    icon = {
        filename = "__map-tag-gps__/graphics/icons/pin.png",
        size = 64
    },
    action = "spawn-item",
    item_to_spawn = "mt_gps-selection-tool"
}, {
    type = "selection-tool",
    name = "mt_gps-selection-tool",
    icon = "__map-tag-gps__/graphics/icons/pin.png",
    icon_size = 64,
    stack_size = 1,
    flags = {"only-in-cursor", "hidden", "spawnable", "not-stackable"},
    selection_mode = "nothing",
    alt_selection_mode = "nothing",
    selection_color = {1, 1, 1},
    alt_selection_color = {0, 0, 0, 0},
    selection_cursor_box_type = "not-allowed",
    alt_selection_cursor_box_type = "not-allowed"
} --[[@as data.SelectionToolPrototype]] })

--     {
--     type = "custom-input",
--     name = "mt_toggle-gui",
--     key_sequence = "SHIFT + ALT + G",
--     action = "lua",
--     order = "a"
-- }, {
--     type = "shortcut",
--     name = "mt_toggle-gui",
--     action = "lua",
--     icon = {
--         filename = "__map-tag-gps__/graphics/icons/route.png",
--         size = 64
--     }
-- }, {
--     type = "sprite",
--     name = "icon-gps",
--     filename = "__map-tag-gps__/graphics/icons/route.png",
--     size = 64
-- }, 
