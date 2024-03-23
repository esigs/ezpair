local M = {}

M._bufnr = nil


M._AppendText = function(text)
    vim.api.nvim_buf_set_lines(M._bufnr, 0, -1, false, text)
end

M._CallScript = function(content)

    P(content)

    local curl = require "plenary.curl"

    local b = {
        model = "gpt-3.5-turbo",
        messages = {
            {
                role = "system",
                content = "You are a Senior software developer. Review the function passed to you and provide critical feedback. Do not discuss 'being a developer', only talk about the code. Do not provide cavets or soften your responses. Your partner already knows this feedback isn't personal. Provide actionable code samples when appropriate. Your feedback will be in a console window, format it acordingly."
            },
            {
                role = "user",
                content = content
            }
        }
    }

    local res = curl.post("https://api.openai.com/v1/chat/completions", 
    {
        headers = {
            content_type = "application/json",
            authorization = "Bearer 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"
        },
        body = vim.fn.json_encode(b)
    })

    local body = vim.fn.json_decode(res.body)

    local message = body.choices[1].message.content

    local lines = {}
    for line in message:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    P(lines)
    
    return lines
end

M._doOpenBuffer = function()
    vim.cmd('vsplit')
    vim.api.nvim_command('wincmd l')
    vim.api.nvim_win_set_buf(0, M._bufnr)
end

M.IsBufferInPane = function()
    local win_list = vim.api.nvim_list_wins()
    for _, winid in ipairs(win_list) do
        if vim.api.nvim_win_get_buf(winid) == M._bufnr then
            return true
        end
    end
    return false
end

M.OpenBuffer = function()
    if not M._bufnr then
        M._bufnr = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_option(M._bufnr, 'filetype', vim.bo.filetype)
        M._AppendText({"Welcome to EzPair", "Any Function passed to this pane via '<leader>a' will be criticized by a LLM"})
    end

    if not M.IsBufferInPane() then
        M._doOpenBuffer()
    end
end

M._openPane = function(selected_text)

    M.OpenBuffer()

    -- Get the current lines in the buffer
    local current_lines = vim.api.nvim_buf_get_lines(M._bufnr, 0, -1, false)

    -- Append the new lines after the existing lines
    local new_lines = {}
    for _, line in ipairs(current_lines) do
        table.insert(new_lines, line)
    end

    M._AppendText(new_lines)

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
        if node:type() == 'function_definition' or node:type() == 'declaration_list' then
            local start_row, start_col, end_row, end_col = node:range()
            local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row + 1, false)
            return lines
        end
        node = node:parent()
    end

    return {"error", "No function found at the current cursor position."}
end

M.CritFunc = function() 
    local func = M._getFunctionAtPoint()

    if(func[1] == "error")

    end
    M._openPane(func)
    local foo = table.concat(func, "\n")   
    local crit = M._CallScript(foo)
    M._AppendText(crit)

end

return M
