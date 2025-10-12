return {
    "nvim-treesitter/nvim-treesitter",
    branch = 'master',
    lazy = false,
    build = ":TSUpdate",
    config = function() 
        -- Treesitter plugin settings
        local treesitterConfig = require("nvim-treesitter.configs")
        treesitterConfig.setup({
            ensure_installed = {"lua", "vim", "php", "markdown", "markdown_inline", "query", "c"}, 
            highlight = { enable = true },
            indent = { enable = true },
        })

    end
}
