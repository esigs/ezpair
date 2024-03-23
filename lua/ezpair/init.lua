local M = {}

M._bufnr = nil

M._openPane = function(selected_text)
    -- make a buffer if i need it
    if M._bufnr then

    else
        M._bufnr = vim.api.nvim_create_buf(true, true)
    end

    --vim.api.nvim_buf_set_lines(M._bufnr, 0, -1, false, text)
    vim.api.nvim_buf_set_lines(M._bufnr, 0, -1, false, selected_text)

    -- Open the scratch buffer in a split to the right
    vim.cmd('vsplit')
    vim.api.nvim_command('wincmd l')
    vim.api.nvim_win_set_buf(0, M._bufnr)

end

M._getSelected = function()
    local prev_mark = vim.api.nvim_buf_get_mark(0, "<")
    local next_mark = vim.api.nvim_buf_get_mark(0, ">")

    local start_line = prev_mark[1]
    local end_line = next_mark[1]

    local selected_lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)

    return selected_lines
end

M._getFunctionAtPoint = function()
    -- Get the current cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    -- Get the Treesitter node at the cursor position
    local node = vim.treesitter.get_node()

    -- Traverse up the tree to find the function node
    while node do
        if node:type() == 'function_definition' then
            local start_row, start_col, end_row, end_col = node:range()
            local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
            return lines
            --local function_text = table.concat(lines, '\n')
            --return function_text
        end
        node = node:parent()
    end

    print("No function found at the current cursor position.")
end

M.CritFunc = function() 
    M._openPane(M._getFunctionAtPoint())
end

return M
