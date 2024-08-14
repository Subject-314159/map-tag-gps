local arrow = require("__arrowlib__/arrow")
local sprites = {
    ["Navigation"] = arrow.defines.arrow.navigation,
    ["Vanilla"] = arrow.defines.arrow.default,
    ["Better"] = arrow.defines.arrow.better_solid_outline
}

local gps = {}

------------------------------------------------------------------------------------------
-- Destination helpers
------------------------------------------------------------------------------------------

local function draw_new_destination(player, position)
    local prop = {
        sprite = "virtual-signal/signal-dot",
        target = position,
        surface = player.surface
        -- time_to_live = 10 * 60
    }

    -- Draw & return the id
    return rendering.draw_sprite(prop)
end

local function clear_destination(destination)
    -- Destroy the sprites
    arrow.remove(destination.arrow_id)
    rendering.destroy(destination.destination_id)

    -- Remove the map tag if it is our GPS destination tag
    if destination.tag.text == settings.global["gps_tag-name"].value then
        destination.tag.destroy()
    end
end

local function get_tag_annotation(tag)
    local icn = ""
    if tag.icon and tag.icon.name then
        local type = tag.icon.type
        if type == "virtual" then
            type = type .. "-signal"
        end
        icn = "[img=" .. type .. "." .. tag.icon.name .. "]"
    end
    local str = " [font=default-large-bold]" .. icn .. tag.text .. "[/font] "
    -- local str = "[font=debug-mono]" .. icn .. tag.text .. "[/font]"
    return str
end

gps.give_selection_tool = function(player_index)
    local player = game.get_player(player_index)

    -- Get/clear player item stack

    -- Set selection tool 
end

gps.invalidate_tag = function(tag)

    -- Loop through all destinations to check if this was one of our destination tags
    for i, p in pairs(global.players or {}) do
        local player = game.get_player(i)
        if player then
            for j, d in pairs(p.destinations) do

                if d and d.tag and d.tag.valid and tag and tag.valid and d.tag.tag_number == tag.tag_number then

                    -- Notify the player if this event was not raised by reaching the destination
                    if not d.destination_reached then
                        player.print("[GPS] Destination tag " .. get_tag_annotation(tag) .. "  [gps=" ..
                                         (tag.position.x) .. "," .. (tag.position.y) .. "," .. player.surface.name ..
                                         "] was removed")
                    end

                    -- Clear the destination
                    clear_destination(d)

                    -- Clear the array
                    p.destinations[j] = nil

                end
            end
        end
    end
end

gps.remove_all = function(player_index)
    for _, d in pairs(global.players[player_index].destinations) do
        gps.invalidate_tag(d.tag)
    end
end

gps.set_destination = function(player_index, tag)
    -- Check if we have a player
    if not player_index then
        return
    end

    -- Get some variables to work with
    local player = game.get_player(player_index)
    local is_temporary = tag.text == settings.global["gps_tag-name"].value

    -- Check if this destination is already set, if so remove the destination instead
    -- This happens when the destination is clicked from the GUI
    for j, d in pairs(global.players[player_index].destinations) do
        if d.tag.tag_number == tag.tag_number then
            -- Notify player first (we need the tag info for the message)
            game.print(
                "[GPS] Cancelled destination for tag " .. get_tag_annotation(tag) .. " [gps=" .. (tag.position.x) .. "," ..
                    (tag.position.y) .. "," .. d.tag.surface.name .. "]")

            -- Clear the array before we remove the tag
            global.players[player_index].destinations[j] = nil

            -- Remove the tag last (which will trigger event on tag removed)
            clear_destination(d)

            return
        end
    end

    -- Sanity checks
    if not player then
        -- Remove the tag
        if is_temporary then
            tag.destroy()
        end

        -- Raise error
        game.print("[GPS] ERROR: Unable to find player with index " .. player_index .. ", no GPS destination set")
        return
    end
    if not player.character then
        -- Remove the tag
        if is_temporary then
            tag.destroy()
        end

        -- Notify the player
        player.print("[GPS] Unable to set GPS destination when there is no character")
        return
    end

    if player.character.surface ~= tag.surface then
        -- Remove the tag
        if is_temporary then
            tag.destroy()
        end

        -- Notify the player
        player.print("[GPS] Unable to set GPS destination the character is on a different surface than the tag")
        return
    end

    if is_temporary then
        -- Update tag icon
        tag.icon = {
            type = "virtual",
            name = "signal-dot"
        }
    end

    -- Create arrow

    local s = sprites[settings.global["gps_arrow-sprite"].value]
    local data = {
        arrow_sprite = s,
        source = player.character,
        target = tag.position
    }
    local arrow_id = arrow.create(data)

    -- Create destination sprite
    local destination_id = draw_new_destination(player, tag.position)

    -- Store in global
    global.players[player_index].destinations[tag.tag_number] = {
        tag = tag,
        destination_id = destination_id,
        arrow_id = arrow_id,
        destination_reached = false
    }

    -- Notify player
    player.print(
        "[GPS] Setting destination for tag " .. get_tag_annotation(tag) .. " [gps=" .. (tag.position.x) .. "," ..
            (tag.position.y) .. "," .. player.surface.name .. "]")
end

gps.create_from_selection = function(player_index, surface, area)
    local player = game.get_player(player_index)
    if not player then
        return
    end

    -- Create tag
    local pos = {
        x = (area.left_top.x + area.right_bottom.x) / 2,
        y = (area.left_top.y + area.right_bottom.y) / 2

    }
    local data = {
        position = pos,
        text = settings.global["gps_tag-name"].value
    }
    local tag = player.force.add_chart_tag(surface, data)
    if not tag then
        game.print("Hmm we did not create a tag?")
    end

    -- Set destination to tag
    gps.set_destination(player_index, tag)
end

gps.tick_update = function()
    -- Update all arrows
    arrow.tick_update()

    -- Update specific arrows if any
    for i, p in pairs(global.players or {}) do
        -- Get the player & character
        local player = game.get_player(i)
        if not player or not player.character then
            return
        end
        for j, d in pairs(p.destinations) do
            -- Recalculate arrow position & orientation
            if not d.tag then
                d = nil
            else
                -- Remove tag & announce when less than 5m
                if arrow.get_distance(d.arrow_id) < settings.global["gps_destination-distance"].value then
                    -- Ping the player
                    player.print("[GPS] Destination tag " .. get_tag_annotation(d.tag) .. " reached!")

                    -- Set destination reached
                    d.destination_reached = true

                    -- Clear rendering (will raise on_chart_tag_removed)
                    clear_destination(d)

                    -- Clear the data array
                    p.destinations[j] = nil

                end
            end
        end
    end
end

gps.init = function()
    arrow.init({
        arrow_sprite = arrow.defines.arrow.navigation,
        raise_warnings = true
    })
end
return gps
