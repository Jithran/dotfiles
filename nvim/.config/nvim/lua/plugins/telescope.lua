return {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        -- Telescope plugin settings
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<C-p>', builtin.find_files)
        vim.keymap.set('n', '<leader>buf', builtin.buffers)
        vim.keymap.set('n', '<leader>gp', builtin.live_grep)
    end
}
