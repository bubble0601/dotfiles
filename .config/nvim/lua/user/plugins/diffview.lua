---@type LazySpec
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>q", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
  },
  opts = {},
}
