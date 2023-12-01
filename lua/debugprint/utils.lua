local M = {}

local get_node_at_cursor = function()
    if vim.fn.has("nvim-0.9.0") == 1 then
        local success, is_node = pcall(vim.treesitter.get_node)

        -- This will fail if this language is not supported by Treesitter, e.g.
        -- Powershell/ps1
        if success and is_node then
            return is_node
        else
            return nil
        end
    else
        local function requiref(module)
            require(module)
        end

        local ts_utils_test = pcall(requiref, "nvim-treesitter.ts_utils")

        if not ts_utils_test then
            return nil
        else
            local ts_utils = require("nvim-treesitter.ts_utils")
            return ts_utils.get_node_at_cursor()
        end
    end
end

M.find_treesitter_variable = function()
    local node = get_node_at_cursor()

    if node == nil then
        return nil
    else
        local node_type = node:type()
        local parent_node_type = node:parent():type()

        local variable_name

        if vim.treesitter.get_node_text then
            -- vim.treesitter.query.get_node_text deprecated as of NeoVim
            -- 0.9
            variable_name = vim.treesitter.get_node_text(node, 0)
        else
            variable_name = vim.treesitter.query.get_node_text(node, 0)
        end

        -- lua, typescript -> identifier
        -- sh              -> variable_name
        -- typescript      -> shorthand_property_identifier_pattern (see issue #60)
        -- Makefile        -> variable_reference
        if
            node_type == "identifier"
            or node_type == "variable_name"
            or node_type == "shorthand_property_identifier_pattern"
            or parent_node_type == "variable_reference"
        then
            return variable_name
        else
            return nil
        end
    end
end

M.get_visual_selection = function()
    local mode = vim.fn.mode():lower()
    if not (mode:find("^v") or mode:find("^ctrl-v")) then
        return nil
    end

    local first_pos, last_pos = vim.fn.getpos("v"), vim.fn.getpos(".")

    local line1 = first_pos[2] - 1
    local line2 = last_pos[2] - 1
    local col1 = first_pos[3] - 1
    local col2 = last_pos[3]

    if line2 < line1 or (line1 == line2 and col2 < col1) then
        local linet = line2
        line2 = line1
        line1 = linet

        local colt = col2
        col2 = col1
        col1 = colt

        col1 = col1 - 1
        col2 = col2 + 1
    end

    if line1 ~= line2 then
        vim.notify(
            "debugprint not supported when multiple lines selected.",
            vim.log.levels.ERROR
        )
        return false
    end

    return vim.api.nvim_buf_get_text(0, line1, col1, line2, col2, {})[1]
end

M.get_operator_selection = function()
    local first_pos, last_pos = vim.fn.getpos("'["), vim.fn.getpos("']")

    local line1 = first_pos[2] - 1
    local line2 = last_pos[2] - 1
    local col1 = first_pos[3] - 1
    local col2 = last_pos[3]

    if line1 ~= line2 then
        vim.notify(
            "debugprint not supported when multiple lines in motion.",
            vim.log.levels.ERROR
        )
        return false
    end

    return vim.api.nvim_buf_get_text(0, line1, col1, line2, col2, {})[1]
end

M.get_node_range = function(row, col)
    local node = vim.treesitter.get_node({ bufnr = 0, pos = { row, col } })
    return node:range()
end
return M
