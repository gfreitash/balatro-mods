--- Shared UI component definitions for mods
--- This file was extracted from Black Seal's src/ui/components.lua
--- Loaded via SMODS.load_file('common/ui/components.lua', current_mod.id)

--- Helper function to create the standard option box container
---@param content UIBox[] The UI nodes to place inside the box
---@return UIBox The definition for the option box
function RIOSODU_SHARED.UIDEF.create_option_box(content)
    return {
        n = G.UIT.R,
        config = {
            align = "cm",
            colour = G.C.L_BLACK,
            r = 0.1,
            padding = 0.15,
            emboss = 0.1,
        },
        nodes = content
    }
end

--- Helper function to create a toggle widget
--- @param args table The arguments for the toggle widget
--- @return UIBox The definition for the toggle widget
function RIOSODU_SHARED.UIDEF.create_option_toggle(args)
    local toggle_args = args or {}
    toggle_args.inactive_colour = args.inactive_colour or G.C.WHITE
    toggle_args.active_colour = args.active_colour or G.C.BLUE
    toggle_args.info = type(args.info) == 'string' and { args.info } or args.info

    local toggle = create_toggle(toggle_args)

    -- Create info text rows
    if args.info then
        local info = {}
        for _, v in ipairs(args.info) do
            table.insert(info, {
                n = G.UIT.R,
                config = { align = "cm", minh = 0.005 },
                nodes = {{
                    n = G.UIT.T,
                    config = { text = v, scale = 0.3, colour = HEX("b8c7d4") },
                }},
            })
        end

        -- Add restart warning if specified
        if args.requires_restart then
            local restart_text = "Requires restart"  -- Fallback text
            -- Try to get localized text if available
            if G and G.localization and G.localization.misc and G.localization.misc.dictionary then
                restart_text = G.localization.misc.dictionary.requires_restart or restart_text
            end
            
            table.insert(info, {
                n = G.UIT.R,
                config = { align = "cm", minh = 0.005 },
                nodes = {{
                    n = G.UIT.T,
                    config = { text = restart_text, scale = 0.25, colour = HEX("ff9f43") }, -- Orange color for warning
                }},
            })
        end

        -- Replace info with ours
        info = { n = G.UIT.R, config = { align = "cm" }, nodes = info }
        toggle.nodes[2] = info
    end

    return toggle
end

--- Helper function to create a slider widget
---@param args table The arguments for the slider widget
---@return table
function RIOSODU_SHARED.UIDEF.create_option_slider(args)
    local slider_args = args or {}
    slider_args.w = args.w or 3 -- Default width
    slider_args.h = args.h or 0.5 -- Default height
    slider_args.info = type(args.info) == 'string' and { args.info } or args.info

    local slider = create_slider(slider_args)

    -- Create info text rows
    if args.info then
        local info = {}
        for _, v in ipairs(args.info) do
            table.insert(info, {
                n = G.UIT.R,
                config = { align = "cm", minh = 0.005 },
                nodes = {{
                    n = G.UIT.T,
                    config = { text = v, scale = 0.3, colour = HEX("b8c7d4") },
                }},
            })
        end

        -- Add info to the slider nodes
        info = { n = G.UIT.R, config = { align = "cm" }, nodes = info }
        slider.nodes[#slider.nodes + 1] = info
    end

    return slider
end
