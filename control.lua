local arrow = require("__arrowlib__/arrow")

local function global_init()
    global.players = {}
    arrow.init({
        raise_warnings = true
    })
end

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

    -- Remove the map tag
    destination.tag.destroy()
end

------------------------------------------------------------------------------------------
-- Game mechanics
------------------------------------------------------------------------------------------

script.on_event(defines.events.on_tick, function()
    arrow.tick_update()
    -- Update arrows if any
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
                    -- Set destination reached
                    d.destination_reached = true

                    -- Clear rendering (will raise on_chart_tag_removed)
                    clear_destination(d)

                    -- Clear the data array
                    p.destinations[j] = nil

                    -- Ping the player
                    player.print("[GPS] Destination reached!")
                end
            end
        end
    end
end)

script.on_init(function()
    global_init()
end)

script.on_event(defines.events.on_player_created, function(e)
    if not global then
        global_init()
    end

    global.players[e.player_index] = {
        destinations = {}
    }
end)

script.on_event(defines.events.on_chart_tag_added, function(e)
    -- Check if tag is GPS tag
    if e.tag.text ~= settings.global["gps_tag-name"].value then
        return
    end

    -- Get some variables to work with
    local player = game.get_player(e.player_index)

    -- Sanity checks
    if not player then
        -- Remove the tag
        e.tag.destroy()

        -- Raise error
        game.print("[GPS] ERROR: Unable to find player with index " .. e.player_index ..
                       ", no GPS destination set and the tag has been removed")
        return
    end
    if not player.character then
        -- Remove the tag
        e.tag.destroy()

        -- Notify the player
        player.print("[GPS] Unable to set GPS destination when there is no character, the tag has been removed")
        return
    end

    if player.character.surface ~= e.tag.surface then
        -- Remove the tag
        e.tag.destroy()

        -- Notify the player
        player.print(
            "[GPS] Unable to set GPS destination the character is on a different surface than the tag, the tag has been removed")
        return
    end

    -- Update tag icon
    e.tag.icon = {
        type = "virtual",
        name = "signal-dot"
    }

    -- Create arrow
    local data = {
        source = player.character,
        target = e.tag.position
    }
    local arrow_id = arrow.create(data)

    -- Create destination sprite
    local destination_id = draw_new_destination(player, e.tag.position)

    -- Store in global
    global.players[e.player_index].destinations[e.tag.tag_number] = {
        tag = e.tag,
        destination_id = destination_id,
        arrow_id = arrow_id,
        destination_reached = false
    }

    -- Notify player
    player.print("[GPS] Setting destination: [gps=" .. (e.tag.position.x) .. "," .. (e.tag.position.y) .. "," ..
                     player.surface.name .. "]")
end)

script.on_event(defines.events.on_chart_tag_removed, function(e)
    -- Loop through all destinations to check if this was one of our destination tags
    for i, p in pairs(global.players or {}) do
        local player = game.get_player(i)
        if player then
            for j, d in pairs(p.destinations) do

                if d.tag.tag_number == e.tag.tag_number then
                    -- Clear the destination
                    clear_destination(d)

                    -- Clear the array
                    p.destinations[j] = nil

                    -- Notify the player if this event was not raised by reaching the destination
                    if not d.destination_reached then
                        player.print("[GPS] Destination tag [gps=" .. (e.tag.position.x) .. "," .. (e.tag.position.y) ..
                                         "," .. player.surface.name .. "] was removed")
                    end
                end
            end
        end
    end
end)
