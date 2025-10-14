return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()

            -- add mason's bin too the PATH
            local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
            vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = {
            auto_install = true,
        },
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            -- HTML
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'html',
                callback = function()
                    vim.lsp.start({
                        name = 'html',
                        cmd = { 'vscode-html-language-server', '--stdio' },
                        root_dir = vim.fs.root(0, {'.git'}),
                        capabilities = capabilities,
                    })
                end,
            })

            -- Lua
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'lua',
                callback = function()
                    vim.lsp.start({
                        name = 'lua_ls',
                        cmd = { 'lua-language-server' },
                        root_dir = vim.fs.root(0, {'.git'}),
                        capabilities = capabilities,
                    })
                end,
            })

            -- PHP
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'php',
                callback = function()
                    vim.lsp.start({
                        name = 'phpactor',
                        cmd = { 'phpactor', 'language-server' },
                        root_dir = vim.fs.root(0, {'.git'}),
                        capabilities = capabilities,
                    })
                end,
            })

            -- Bash
            vim.api.nvim_create_autocmd('FileType', {
                pattern = {'sh', 'bash'},
                callback = function()
                    vim.lsp.start({
                        name = 'bashls',
                        cmd = { 'bash-language-server', 'start' },
                        root_dir = vim.fs.root(0, {'.git'}),
                        capabilities = capabilities,
                    })
                end,
            })

            -- keymaps
            vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
            vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
        end,
    },
}
