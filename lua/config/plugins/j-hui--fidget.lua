-- Plugin config for j-hui/fidget.nvim
return {
  src = "https://github.com/j-hui/fidget.nvim",
  data = {
    setup = function() require("fidget").setup() end,
  },
}
