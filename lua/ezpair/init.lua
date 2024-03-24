local M = {}

M._b = nil -- buffer

local criticalSrSoftwareDev = "You are a Senior software developer. Review the function passed to you and provide critical feedback. Do not discuss 'being a developer', only talk about the code. Do not provide cavets or soften your responses. Your partner already knows this feedback isn't personal. Provide actionable code samples when appropriate. Your feedback will be in a console window, format it acordingly."

local helpfulSrSoftwareDev = "You are a Senior software developer. Review my question an provide suggestions and solutions. Do not discuss 'being a developer', only talk about code and solutions for this issue. Do not provide cavets or soften your responses. Your partner already knows this feedback isn't personal. Provide actionable code samples when appropriate. Your feedback will be in a console window, format it acordingly."

local getSelected = function()

    local prev_mark = vim.api.nvim_buf_get_mark(0, "<")
    local next_mark = vim.api.nvim_buf_get_mark(0, ">")

    local lines = vim.api.nvim_buf_get_lines(0, prev_mark[1] - 1, next_mark[1] + 1, false)

    return lines
end

local buffIsOpen = function()
    local win_list = vim.api.nvim_list_wins()
    for _, winid in ipairs(win_list) do
        if vim.api.nvim_win_get_buf(winid) == M._b then
            return true
        end
    end
    return false
end

local runGpt = function(content, system)

    local escapedContent = table.concat(content, "\\n")

    local curl = require "plenary.curl"

    local b = {
        model = "gpt-4-turbo-preview",
        messages = {
            {
                role = "system",
                content = system
            },
            {
                role = "user",
                content = escapedContent
            }
        },
        temperature=1,
        max_tokens=1000,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0
    }

    local json = vim.fn.json_encode(b)

    local res = curl.post("https://api.openai.com/v1/chat/completions", 
    {
        timeout = 60000,
        headers = {
            content_type = "application/json",
            authorization = "Bearer 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"
        },
        body = json
    })

    local body = vim.fn.json_decode(res.body)

    local message = {}

    if res.status == 200 then
        message = body.choices[1].message.content
    else
        return { "error", body.error.type, body.error.message }
    end


    local newLines = {}

    for line in message:gmatch("[^\n]+") do
        table.insert(newLines, line)
    end
   
    return newLines
end

local addBanner = function(messages, type, banner)
    P(messages) 

    local newLines = {}

    table.insert(newLines, "New " .. type .. ": " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(newLines, banner)
    table.insert(newLines, " ")

    for _, line in ipairs(messages) do
        table.insert(newLines, line)
    end

    return newLines
end

local openBuff = function()
    if not buffIsOpen() then
        vim.cmd('vsplit')

    end

    vim.api.nvim_command('wincmd l')
    vim.api.nvim_win_set_buf(0, M._b)
    local line_count = vim.api.nvim_buf_line_count(M._b)
    vim.api.nvim_win_set_cursor(0, {line_count, 0})
end

local makeBuff = function()

    if M._b == nil then
        M._b = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_option(M._b, 'filetype', vim.api.nvim_buf_get_option(0, 'filetype'))
    end

end

local getFunctionAtPoint = function()
    -- Get the current cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    -- Get the Treesitter node at the cursor position
    local node = vim.treesitter.get_node()

    -- Traverse up the tree to find the function node
    while node do
        if node:type() == 'function_definition' or node:type() == 'declaration_list' then
            local start_row, start_col, end_row, end_col = node:range()
            local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
            return lines
        end
        node = node:parent()
    end

    return {"error", "No function found at the current cursor position."}
end

local append = function(selected, banner)

    local newLines = {}
    
    if selected[1] == "error" then
        table.insert(newLines, "Error: " .. os.date("%Y-%m-%d %H:%M:%S"))
        table.insert(newLines, " ")
    end

    for _, line in ipairs(selected) do
        table.insert(newLines, line)
    end

    table.insert(newLines, " ")
    vim.api.nvim_buf_set_lines(M._b, -1, -1, false, newLines)

end

local critFunc = function() 

    local selected = getFunctionAtPoint()

    makeBuff()
    local selectedWithBanner = addBanner(selected, "Request", "Getting critical feed back for:")
    append(selectedWithBanner)
    openBuff()

    local a = runGpt(selected, criticalSrSoftwareDev)

    local withBanner = addBanner(a, "Response", "Here's my feedback on your function:")
    append(withBanner)

end

M.CritFunc = function()
    critFunc()
end

M.Ask = function()

    local input = vim.fn.input("Ask a question: ")
    makeBuff()
    openBuff()

    if input == nil or input == '' then
        append({"error", "You didn't seem to ask a question..."})
    else
        local inputWithBanner = addBanner({input}, "Request", "Asking...:")
        append(inputWithBanner)

        local gptResponse = runGpt({input}, helpfulSrSoftwareDev)
        local withBanner = addBanner(gptResponse, "Response", "Here's what I think:")
        append(withBanner)
    end
end

return M
