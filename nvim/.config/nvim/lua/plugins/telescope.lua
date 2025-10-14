return {
    {
        "nvim-telescope/telescope-ui-select.nvim",
    },
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })

            -- Telescope plugin settings
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<C-p>', builtin.find_files)
            vim.keymap.set('n', '<C-g>', builtin.git_files)
            vim.keymap.set('n', '<leader>buf', builtin.buffers)
            vim.keymap.set('n', '<leader>gp', builtin.live_grep)

            require("telescope").load_extension("ui-select")
        end
    }
}
