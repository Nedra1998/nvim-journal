local PLUGIN = "nvim-journal"
local date = require("nvim-journal.date")

local FREQUENCY = {
  ["daily"] = function(current, offset)
    return current:adddays(offset)
  end,
  ["weekly"] = function(current, offset)
    return current:adddays(7 * offset)
  end,
  ["monthly"] = function(current, offset)
    current:setday(1)
    return current:addmonths(offset)
  end,
  ["yearly"] = function(current, offset)
    current:setmonth(1, 1)
    return current:addyears(offset)
  end,
}
local PATHSEP = "/"
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  PATHSEP = "\\"
end

local M = {}
M.config = {
  default = nil,
  journals = {},
}

M.setup = function(args)
  M.current_journal = nil
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

local function find_journal(name)
  if name ~= nil then
    -- Look up the specified name if present
    return M.config.journals[name]
  else
    -- Look for any journals within the CWD
    local cwd = vim.fn.getcwd() .. PATHSEP
    for _, value in pairs(M.config.journals) do
      local path = vim.fn.expand(value.path) .. PATHSEP
      if vim.startswith(path, cwd) then
        return value
      end
    end

    -- Look for the default journal if set
    if M.config.default ~= nil then
      return M.config.journals[M.config.default]
    end
  end
  return nil
end

M.open = function(name, offset)
  -- Find the journal configuration
  local journal = find_journal(name)
  if journal == nil then
    if name ~= nil then
      vim.notify(
        'Failed to find configuration for journal "' .. vim.inspect(name) .. '".',
        vim.log.levels.WARN,
        { title = PLUGIN }
      )
    elseif M.config.default ~= nil then
      vim.notify(
        'Failed to find configuration for default journal "' .. M.config.default .. '".',
        vim.log.levels.WARN,
        { title = PLUGIN }
      )
    else
      vim.notify(
        'Failed to find a journal within the working directory "' .. vim.fn.getcwd() .. '".',
        vim.log.levels.WARN,
        { title = PLUGIN }
      )
    end
    return
  end

  -- Determine the date for the journal entry
  local entrydate = date(false)
  if type(journal.frequency) == "string" then
    entrydate = FREQUENCY[journal.frequency](entrydate, offset)
  else
    entrydate = journal.frequency(entrydate, offset)
  end

  local path = vim.fn.join({ journal.path, entrydate:fmt(journal.filename) }, PATHSEP)
  local parts = vim.fn.split(path, PATHSEP)

  -- Create the directory
  local filename = table.remove(parts)
  vim.fn.mkdir(vim.fn.expand(vim.fn.join(parts, PATHSEP)), "p")
  path = vim.fn.expand(path)

  -- Open the journal file
  vim.cmd("edit " .. path)

  -- Add create template
  if journal.template ~= nil and journal.template.create ~= nil and vim.fn.glob(path) == "" then
    -- Format the title string
    local title = ""
    if type(journal.template.create) == "string" then
      title = entrydate:fmt(journal.template.create)
    else
      title = journal.template.create(entrydate)
    end

    -- Write the title string into the buffer
    local lines = vim.fn.split(title, "\n")
    if next(lines) ~= nil then
      local bufnr = vim.fn.bufnr(path)
      vim.api.nvim_buf_set_lines(bufnr, 0, #lines, false, lines)

      -- Move cursor to after the title
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      vim.api.nvim_win_set_cursor(0, { line_count, 0 })
    end
  end

  -- Add update template
  if journal.template ~= nil and journal.template.update ~= nil then
    -- Format the entry header string
    local nowtime = date(false)
    local entry = ""
    if type(journal.template.update) == "string" then
      entry = nowtime:fmt(journal.template.update)
    else
      entry = journal.template.update(nowtime)
    end

    -- Check if the buffer contains the header
    local bufnr = vim.fn.bufnr(path)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local buffer = table.concat(lines, "\n")
    local idx, _ = buffer:find(entry)
    if idx == nil then
      -- Append the header string if it is not already present
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.fn.split(entry, "\n"))

      -- Move cursor to after the new header
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      vim.api.nvim_win_set_cursor(0, { line_count, 0 })
    end
  end
end

M.open_date = function(name, input)
  -- Find the journal configuration
  local journal = find_journal(name)
  if journal == nil then
    if name ~= nil then
      vim.notify(
        'Failed to find configuration for journal "' .. vim.inspect(name) .. '".',
        vim.log.levels.WARN,
        { title = PLUGIN }
      )
    elseif M.config.default ~= nil then
      vim.notify(
        'Failed to find configuration for default journal "' .. M.config.default .. '".',
        vim.log.levels.WARN,
        { title = PLUGIN }
      )
    else
      vim.notify(
        'Failed to find a journal within the working directory "' .. vim.fn.getcwd() .. '".',
        vim.log.levels.WARN,
        { title = PLUGIN }
      )
    end
    return
  end

  -- Determine the date for the journal entry
  local entrydate = date(input)
  if type(journal.frequency) == "string" then
    entrydate = FREQUENCY[journal.frequency](entrydate, 0)
  else
    entrydate = journal.frequency(entrydate, 0)
  end

  local path = vim.fn.join({ journal.path, entrydate:fmt(journal.filename) }, PATHSEP)
  local parts = vim.fn.split(path, PATHSEP)

  -- Create the directory
  local filename = table.remove(parts)
  vim.fn.mkdir(vim.fn.expand(vim.fn.join(parts, PATHSEP)), "p")
  path = vim.fn.expand(path)

  -- Open the journal file
  vim.cmd("e " .. path)

  -- Add create template
  if journal.template.create ~= nil and vim.fn.glob(path) == "" then
    -- Format the title string
    local title = ""
    if type(journal.template.create) == "string" then
      title = entrydate:fmt(journal.template.create)
    else
      title = journal.template.create(entrydate)
    end

    -- Write the title string into the buffer
    local lines = vim.fn.split(title, "\n")
    if next(lines) ~= nil then
      local bufnr = vim.fn.bufnr(path)
      vim.api.nvim_buf_set_lines(bufnr, 0, #lines, false, lines)

      -- Move cursor to after the title
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      vim.api.nvim_win_set_cursor(0, { line_count, 0 })
    end
  end
end

return M
