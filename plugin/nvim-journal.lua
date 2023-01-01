local open = require("nvim-journal").open
vim.api.nvim_create_user_command("JournalOpen", function(opts)
  require("nvim-journal").open_date(opts.fargs[2], opts.fargs[1])
end, { nargs = "+" })

vim.api.nvim_create_user_command("JournalCurrent", function(opts)
  require("nvim-journal").open(opts.fargs[1], 0)
end, {
  nargs = "?",
  complete = function(ArgLead, _, _)
    local keys = {}
    for key in pairs(require("nvim-journal").config.journals) do
      if vim.startswith(key, ArgLead) then
        table.insert(keys, key)
      end
    end
    return keys
  end,
})
vim.api.nvim_create_user_command("JournalNext", function(opts)
  require("nvim-journal").open(opts.fargs[1], 1)
end, {
  nargs = "?",
  complete = function(ArgLead, _, _)
    local keys = {}
    for key in pairs(require("nvim-journal").config.journals) do
      if vim.startswith(key, ArgLead) then
        table.insert(keys, key)
      end
    end
    return keys
  end,
})
vim.api.nvim_create_user_command("JournalPrevious", function(opts)
  require("nvim-journal").open(opts.fargs[1], -1)
end, {
  nargs = "?",
  complete = function(ArgLead, _, _)
    local keys = {}
    for key in pairs(require("nvim-journal").config.journals) do
      if vim.startswith(key, ArgLead) then
        table.insert(keys, key)
      end
    end
    return keys
  end,
})
