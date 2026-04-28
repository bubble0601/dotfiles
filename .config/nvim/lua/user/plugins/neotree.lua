---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
        never_show = { ".git" },
      },
      commands = {
        diffview_open = function()
          vim.cmd("DiffviewOpen")
        end,
        diffview_file_history = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(path))
        end,
      },
      window = {
        mappings = {
          ["gd"] = "diffview_open",
          ["gh"] = "diffview_file_history",
        },
      },
    },
    git_status = {
      commands = {
        diffview_open = function()
          vim.cmd("DiffviewOpen")
        end,
        diffview_file_history = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(path))
        end,
      },
      window = {
        mappings = {
          ["gd"] = "diffview_open",
          ["gh"] = "diffview_file_history",
        },
      },
    },
    window = {
      mappings = {
        ["<D-c>"] = "copy_selector",
      },
    },
  },
}
