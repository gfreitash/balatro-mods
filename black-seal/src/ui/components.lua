--- Helper function to create the standard option box container
---@param content UIBox[] The UI nodes to place inside the box
---@return UIBox The definihtion for the option box
function BSM.UI.create_option_box(content)
    return {
        n = G.UIT.R,
        config = {
            align = "cm",
            colour = G.C.L_BLACK,
            r = 0.1,
            padding = 0.1,
        },
        nodes = content
    }
end



--- Helper function to create a toggle widget
--- @param args table The arguments for the toggle widget
--- @return UIBox The definition for the toggle widget
function BSM.UI.create_option_toggle(args)
    local toggle_args = args or {}
    toggle_args.inactive_colour = args.inactive_colour or G.C.WHITE
    toggle_args.active_colour = args.active_colour or G.C.BLUE
    toggle_args.info = type(args.info) == 'string' and { args.info } or args.info

    local toggle = create_toggle(toggle_args)

    -- Create info text rows
    if args.info then
        local info = {}
        for _, v in ipairs(args.info --[=[@as string[]]=]) do
            table.insert(info, { n = G.UIT.R, config = { align = "cm", minh = 0.005, }, nodes = {{
                n = G.UIT.T,
                config = { text = v, scale = 0.3, colour = HEX("b8c7d4"), },
            }}})
        end

        -- Replace info with ours
        if info then
            info = { n = G.UIT.R, config = { align = "cm" }, nodes = info }
            toggle.nodes[2] = info
        end
    end

    return toggle
end


--- Helper function to create a slider widget
---@param args table The arguments for the slider widget
---@return table
function BSM.UI.create_option_slider(args)
    local slider_args = args or {}
    slider_args.w = args.w or 3 -- Default width
    slider_args.h = args.h or 0.5 -- Default height
    slider_args.info = type(args.info) == 'string' and { args.info } or args.info

    local slider = create_slider(slider_args)

    -- Create info text rows
    if args.info then
        local info = {}
        for _, v in ipairs(args.info --[=[@as string[]]=]) do
            table.insert(info, { n = G.UIT.R, config = { align = "cm", minh = 0.005, }, nodes = {{
                n = G.UIT.T,
                config = { text = v, scale = 0.3, colour = HEX("b8c7d4"), },
            }}})
        end

        -- Add info to the slider nodes
        if info then
            info = { n = G.UIT.R, config = { align = "cm" }, nodes = info }
            slider.nodes[#slider.nodes+1] = info
        end
    end

    return slider
    
end