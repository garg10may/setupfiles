return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = true },
    },
    keys = {
      { "<leader>e", function() Snacks.explorer() end, desc = "Explorer" },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-storm",
    },
  },
}
