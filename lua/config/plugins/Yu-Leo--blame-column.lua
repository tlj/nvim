-- Plugin config for Yu-Leo/blame-column.nvim
return {
  src = "https://github.com/Yu-Leo/blame-column.nvim",
  data = {
    setup = function()
      require("blame-column").setup()
    end,
    keys = {
      ["<leader>bs"] = { cmd = "<cmd>BlameColumnToggle<cr>", desc = "Blame column" },
    },
  },
}
