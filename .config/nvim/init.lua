vim.cmd.colorscheme("catppuccin")

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

-- ==========
-- Options
-- ==========
vim.opt.number = true -- line number
vim.opt.relativenumber = true -- relative line number
