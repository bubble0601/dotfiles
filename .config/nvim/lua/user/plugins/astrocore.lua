---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        ["]e"] = {
          function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end,
          desc = "Next error",
        },
        ["[e"] = {
          function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end,
          desc = "Previous error",
        },
      },
    },
  },
}
