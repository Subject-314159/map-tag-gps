------------------------------------------------------------------------------------------
-- Helper functions
------------------------------------------------------------------------------------------
local get_pt = function(character, tag)
    local pt = {
        first = {
            x = character.position.x,
            y = character.position.y
        },
        second = {
            x = tag.position.x,
            y = tag.position.y
        }
    }
    pt.delta = {
        -- x = pt.second.x - pt.first.x,
        -- y = pt.second.y - pt.first.y
        x = pt.first.x - pt.second.x,
        y = pt.second.y - pt.first.y
    }
    return pt
end

local get_distance = function(character, tag)
    local pt = get_pt(character, tag)
    local distance = math.sqrt(pt.delta.x ^ 2 + pt.delta.y ^ 2) - 0.5
    return distance
end

local calculate = function(character, tag)

    -- Get some variables to work with
    local pt = get_pt(character, tag)

    -- Prepare the return array
    local prop = {}

    -- Do the calculations
    -- Angle calculations
    prop.angle_rad = math.atan2(pt.delta.x, pt.delta.y) + (math.pi / 2)
    prop.angle_deg = prop.angle_rad * (180 / math.pi)

    -- Segmented angle
    local deg_seg = 20
    local angle_corr = prop.angle_deg - (deg_seg / 2)
    prop.angle_deg_seg = math.floor((angle_corr) / deg_seg) * deg_seg

    prop.distance = get_distance(character, tag)
    prop.offset = math.min(prop.distance, settings.global["gps_arrow-offset"].value) -- Draw the arrow at max 20 meter
    prop.offx = prop.offset * math.cos(prop.angle_rad)
    prop.offy = prop.offset * math.sin(prop.angle_rad)

    return prop

end

local get_angle_corrected = function(angle)
    if not angle then
        return 0
    end
    return ((angle + 90) / 360) or 0
end

local function global_init()
    global.players = {}
end

------------------------------------------------------------------------------------------
-- Tracking arrow
------------------------------------------------------------------------------------------

local function draw_new_arrow(player, data)
    local prop = {
        sprite = "utility/alert_arrow",
        orientation = get_angle_corrected(data.angle_deg),
        -- orientation_target = e,
        target = player.character,
        target_offset = {
            x = data.offx,
            y = data.offy
        },
        surface = player.surface,
        -- time_to_live = 10 * 60,
        x_scale = settings.global["gps_arrow-size"].value,
        y_scale = settings.global["gps_arrow-size"].value
    }

    -- Draw & return the id
    return rendering.draw_sprite(prop)
end

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

local function update_arrow(id, player, data)

    -- Update orientation
    rendering.set_orientation(id, get_angle_corrected(data.angle_deg))

    local target = player.character
    local target_offset = {
        x = data.offx,
        y = data.offy
    }
    -- Update offset
    rendering.set_target(id, target, target_offset)

end

local function clear_destination(destination)
    -- Destroy the sprites
    rendering.destroy(destination.arrow)
    rendering.destroy(destination.destination)

    -- Remove the map tag
    destination.tag.destroy()
end

------------------------------------------------------------------------------------------
-- Game mechanics
------------------------------------------------------------------------------------------

script.on_event(defines.events.on_tick, function()
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
                d.data = calculate(player, d.tag)

                -- Update the arrow
                update_arrow(d.arrow, player, d.data)

                -- Remove tag & announce when less than 5m
                if d.data.distance < settings.global["gps_destination-distance"].value then
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
    if e.tag.text ~= "gps-destination" then
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

    -- Calculate arrow data
    local data = calculate(player, e.tag)

    -- Create arrow
    local arrow = draw_new_arrow(player, data)

    -- Create destination sprite
    local destination = draw_new_destination(player, e.tag.position)

    -- Store in global
    global.players[e.player_index].destinations[e.tag.tag_number] = {
        tag = e.tag,
        destination = destination,
        arrow = arrow,
        data = data,
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
