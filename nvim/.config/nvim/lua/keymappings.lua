-- Mappings
-- vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Bottom", remap = true })
vim.keymap.set("n", "<leader><Space>", ":noh<CR>", { desc = "disable the highlighting of current text" })
vim.keymap.set("n", "<leader>o", ":update<cr> :so<cr>", { desc = "update file and source" })
vim.keymap.set("n", "<leader>wq", ":write<cr> :qa<cr>", { desc = "Write file and quit all" })

-- reformat file with current pointer memory
vim.keymap.set('n', '<leader>f', function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd('normal! ggVG=')
    vim.api.nvim_win_set_cursor(0, pos)
end, {desc = 'Format file and restore cursor position'} )
