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
                defaults = {
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--hidden',
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })

            -- Telescope plugin settings
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<C-p>', function() builtin.find_files({ hidden = true }) end)
            vim.keymap.set('n', '<C-g>', builtin.git_files)
            vim.keymap.set('n', '<leader>buf', builtin.buffers)
            vim.keymap.set('n', '<leader>gp', builtin.live_grep)

            require("telescope").load_extension("ui-select")
        end
    }
}
