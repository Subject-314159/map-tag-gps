local gui = {}

local MAIN_FRAME = "mt_main-frame"

local get_main = function(player)
    return player.gui.left[MAIN_FRAME]
end

local int_to_str = function(number, decimals)
    local shift = (10 ^ decimals)
    return math.floor(number * shift) / shift
end

local add_tag_element = function(scroll, tag)
    local flow = scroll.add {
        type = "flow",
        direction = "horizontal"
    }
    local btn = flow.add {
        type = "sprite-button",
        name = "mt_tag-button",
        tags = {
            tag_id = tag.tag_number,
            surface = tag.surface.index,
            position = tag.position
        }
    }
    if tag.icon and tag.icon.name then
        local type = tag.icon.type
        if type == "virtual" then
            type = type .. "-signal"
        end
        btn.sprite = type .. "/" .. tag.icon.name
    end

    local txt = flow.add {
        type = "flow",
        direction = "vertical"
    }
    txt.style.padding = 0
    txt.style.left_margin = 5
    local l = txt.add {
        type = "label",
        caption = tag.text
    }
    l.style.padding = 0
    l.style.top_margin = -3
    l.style.font = "debug"

    l = txt.add {
        type = "label",
        caption = "[ " .. int_to_str(tag.position.x, 1) .. " , " .. int_to_str(tag.position.y, 1) .. " ]"
    }
    l.style.padding = 0
    l.style.top_margin = -8
    l.style.font_color = {0, 150, 0}
    l.style.font = "count-font"
end

gui.build_main = function(player)
    local gui = get_main(player)
    if gui then
        return gui
    end

    gui = player.gui.left.add {
        type = "frame",
        name = MAIN_FRAME,
        caption = "Map tag GPS",
        direction = "vertical"
    }

    gui.add {
        type = "label",
        caption = "Set or cancel destination per tag"
    }

    local sf = gui.add {
        type = "frame",
        name = "subframe",
        style = "inside_shallow_frame"
    }
    local scroll = sf.add {
        type = "scroll-pane",
        name = "scrollpane",
        direction = "vertical"

    }
    scroll.style.height = 400
    scroll.style.width = 250
    scroll.style.padding = 10
    -- scroll.style.margin = 1
    scroll.style.extra_padding_when_activated = 0
    scroll.style.extra_margin_when_activated = 0

    -- Generate table of tag names (with tag number appended)
    local tags = {}
    local indexes = {}
    for _, t in pairs(player.force.find_chart_tags(player.surface)) do
        local id = t.text .. "_" .. t.tag_number
        table.insert(tags, id)
        indexes[id] = t
    end

    -- Sort the tags by name
    table.sort(tags, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    -- Loop through all tags and add them to the GUI
    for _, id in pairs(tags) do
        local t = indexes[id]
        add_tag_element(scroll, t)
    end

    local btn = gui.add {
        type = "button",
        name = "mt_remove-all-destinations",
        caption = "Remove all destinations"
    }
    btn.style.top_margin = 10
    btn.style.bottom_margin = 5

end

gui.destroy_main = function(player)
    local gui = get_main(player)
    if gui then
        gui.destroy()
    end
end

gui.toggle = function(player_index)
    -- Get the player or early exit
    local player = game.players[player_index]
    if not player then
        return
    end

    -- Toggle the gui
    if get_main(player) then
        -- Destroy the gui because it is open
        gui.destroy_main(player)
    else
        -- Show the gui because it is closed
        gui.build_main(player)
    end
end

gui.init = function()
    -- Destroy any open GUIs
    if game then
        for _, p in pairs(game.players) do
            gui.destroy_main(p)
        end
    end

end

gui.tick_update = function()
    -- Update the labels in the gui
    for _, p in pairs(game.players) do
        local gui = get_main(p)
        if not gui then
            return
        end

        local scroll = gui.subframe.scrollpane
        local all_tags = p.force.find_chart_tags(p.surface)

        -- Add new tags
        for _, t in pairs(all_tags) do
            -- Check if the current tag occurs in the scroll list
            local present = false
            for _, f in pairs(scroll.children) do
                local id = f["mt_tag-button"].tags.tag_id
                if id == t.tag_number then
                    present = true
                end

            end

            -- Add if not present
            if not present then
                add_tag_element(scroll, t)
            end

        end

        -- Remove obsolete tags
        for _, f in pairs(scroll.children) do
            -- Check if current tag occurs as map tag
            local present = false
            local btn = f["mt_tag-button"]
            local id = btn.tags.tag_id
            for _, t in pairs(all_tags) do
                if id == t.tag_number then
                    present = true
                end
            end

            -- Remove if no longer exists
            if not present then
                f.destroy()
            else

                -- Set button selected/deselected based on if it is a destination
                if global.players[p.index].destinations[id] then
                    if btn and not btn.toggled then
                        btn.toggled = true
                    end
                else
                    if btn and btn.toggled then
                        btn.toggled = false
                    end
                end
            end
        end
    end
end

return gui
