-- Plugin config for luisiacc/gruvbox-baby
return {
  src = "https://github.com/luisiacc/gruvbox-baby",
  data = {
    setup = function()
      vim.g.gruvbox_baby_use_original_palette = true
      vim.g.gruvbox_baby_background_color = "medium"
      vim.g.gruvbox_baby_comment_style = "italic"
      vim.g.gruvbox_baby_keyword_style = "NONE"
      vim.g.gruvbox_baby_transparent_mode = false
      vim.cmd("colorscheme gruvbox-baby")
    end,
  },
}
