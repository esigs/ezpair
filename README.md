# Eze Pair Programmer

Mostly used to learn about nvim plugins.

A simple OpenApi Gpt-4 wrapper to ask questions from within nvim about functions or ask explicit questions

## Dependencies

- [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Plenary](https://github.com/nvim-lua/plenary.nvim)

## Example key binds
```
local ezpair = require('ezpair')
    
vim.keymap.set('n', '<leader>ac', ezpair.CritFunc) -- GPT4 will suggest edits for the function the cursor is currently on
vim.keymap.set('n', '<leader>aa', ezpair.Ask) -- Ask a question and GPT4 will do it's best to answer.

```

