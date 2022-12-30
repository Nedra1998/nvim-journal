# nvim-journal

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/default.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

**nvim-journal** is a small plugin to provide a convenient way to create and
manage journals in Neovim.

## :sparkles: Features

- Manage multiple different journals
- Support for different journal frequencies for each journal
- Support for custom frequencies
- Optional templates for new journal entries.

## :zap: Requirements

- [Neovim >= **0.8.0**](https://github.com/neovim/neovim/wiki/Installing-Neovim)

## :package: Installation

Install with [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'Nedra1998/nvim-journal'
```

or with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use { 'Nedra1998/nvim-journal' }
```

or with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ 'Nedra1998/nvim-journal' }
```

## :gear: Configuration

```lua
require('nvim-journal').setup({
  default = nil,
  journals = {
    ["journal"] = {
      path = "~/Documents/Journal",
      frequency = "daily",
      filename = "%Y-%m-%d.md",
      template = {
        title = "# %a %b %d %T %Y\n\n",
        entry = "## %H:%M\n\n",
      },
    },
})
```

For a complete list of available configuration options see [:help
nvim-journal-configuration](https://github.com/Nedra1998/nvim-journal/blob/master/doc/nvim-journal.txt).

Each option is documented in `:help nvim-journal.OPTION_NAME`. Nested options
can be accessed by appending `.`., for example `:help
nvim-journal.journals.frequency`.

## :rocket: Usage

**nvim-journal** does _not_ create any key bindings, all interaction with the
plugin is through the user commands or through the lua API.

### Commands

See [:help nvim-journal-commands](https://github.com/Nedra1998/nvim-journal/blob/master/doc/nvim-journal.txt).

| Command                         | Description                          |
| ------------------------------- | ------------------------------------ |
| `:JournalOpen {date} [journal]` | Open a journal at a specific date    |
| `:JournalCurrent [journal]`     | Open a journal for the current entry |
| `:JournalNext [journal]`        | Open the next journal entry          |
| `:JournalPrevious [journal`     | Open the previous journal entry      |
