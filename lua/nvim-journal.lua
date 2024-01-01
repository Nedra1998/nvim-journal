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

local DEFAULT_JOURNAL = {
  path = ".",
  filename = "%Y-%m-%d.md",
  frequency = "daily",
  template = nil,
  index = {
    filename = "README.md",
    header = "# Journal Index\n\n",
    sort = "descending",
    entry = "%Y-%m-%d",
    sections = { "## %Y", "### %B" },
  },
}

M.setup = function(args)
  M.current_journal = nil
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

local function find_journal(name)
  local j = nil
  if name ~= nil then
    -- Look up the specified name if present
    j = M.config.journals[name]
  else
    -- Look for any currently open journals
    local cwd = vim.fn.getcwd() .. PATHSEP
    for _, value in pairs(M.config.journals) do
      local path = vim.fn.expand(value.path) .. PATHSEP
      if vim.startswith(cwd, path) then
        j = value
        break
      end
    end

    -- Look for the default journal if set
    if M.config.default ~= nil then
      j = M.config.journals[M.config.default]
    end
  end

  if j ~= nil then
    return vim.tbl_deep_extend("force", DEFAULT_JOURNAL, j)
  else
    return nil
  end
end

M.open_index = function(name)
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

  local index_path = vim.fn.join({ journal.path, journal.index.filename }, PATHSEP)
  index_path = vim.fn.expand(index_path)

  -- Open the journal file
  vim.cmd("edit " .. index_path)
end

M.generate_index = function(name)
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

  -- List all files in the journal directory
  local files = vim.fs.find(function(fname, _)
    return fname:match(".*%.md$") and fname ~= journal.index.filename
  end, { limit = math.huge, type = "file", path = journal.path })

  -- Sort the files
  table.sort(files, function(a, b)
    if journal.index.sort == "descending" then
      return a > b
    end
    return a < b
  end)

  -- Create the index file
  local body = journal.index.header

  local sections = {}

  for _, file in ipairs(files) do
    local basename = vim.fn.fnamemodify(file, ":t")
    local filename = vim.fn.fnamemodify(file, ":t:r")
    local entrydate = date(filename)

    -- Format the section string
    local first_section = true
    for i, section in ipairs(journal.index.sections) do
      local section_str = ""
      if type(section) == "string" then
        section_str = entrydate:fmt(section)
      else
        section_str = section(entrydate)
      end
      if sections[i] ~= section_str then
        if first_section and #sections ~= 0 then
          body = body .. "\n"
        end

        first_section = false
        sections[i] = section_str
        body = body .. section_str .. "\n\n"
      end
    end

    -- Format the title string
    local title = ""
    if type(journal.index.entry) == "string" then
      title = entrydate:fmt(journal.index.entry)
    else
      title = journal.index.entry(entrydate)
    end
    -- Add the entry to the index
    body = body .. "- [" .. title .. "](" .. basename .. ")\n"
  end

  -- Write the index file
  local index_path = vim.fn.join({ journal.path, journal.index.filename }, PATHSEP)
  index_path = vim.fn.expand(index_path)
  local out = io.open(index_path, "w+")
  if out == nil then
    vim.notify(
      'Failed to open index file "' .. index_path .. '" for writing.',
      vim.log.levels.ERROR,
      { title = PLUGIN }
    )
    return
  end

  out:write(body)
  out:close()
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
