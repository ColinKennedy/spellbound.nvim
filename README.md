# spellbound.nvim
`spellbound.nvim` - Alternative word recommendations that you can control.

[![Neovim](https://img.shields.io/badge/Neovim%200.10+-brightgreen?style=for-the-badge)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)](https://www.lua.org)
[![Stylua](https://img.shields.io/github/actions/workflow/status/ColinKennedy/spellbound.nvim/stylua.yml?branch=main&style=for-the-badge&label=stylua)](https://github.com/ColinKennedy/spellbound.nvim/actions/workflows/stylua.yml)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/spellbound.nvim/luacheck.yml?branch=main&style=for-the-badge&label=luacheck)](https://github.com/ColinKennedy/spellbound.nvim/actions/workflows/luacheck.yml)
[![Lua-Typecheck](https://img.shields.io/github/actions/workflow/status/ColinKennedy/spellbound.nvim/lua-typecheck.yml?branch=main&style=for-the-badge&label=lua-typecheck)](https://github.com/ColinKennedy/spellbound.nvim/actions/workflows/lua-typecheck.yml)
[![Test](https://img.shields.io/github/actions/workflow/status/ColinKennedy/spellbound.nvim/test.yml?branch=main&style=for-the-badge&label=test)](https://github.com/ColinKennedy/spellbound.nvim/actions/workflows/test.yml)


# Features
- Go to next / previous recommendation
- Show recommendations
- Native tree-sitter support
- Auto-rebuilds dictionary parts
    - Note: Is compatible with [vim-spellsync](https://github.com/micarmst/vim-spellsync)


# Disclaimer
`spellbound.nvim` is both a plugin and a workflow. You might get decent results
using this plugin's default values but, for best performance, you should make
your own recommendations. You only get out of `spellbound.nvim` what you're
willing to put into it.


# Install
- [lazy.nvim](https://github.com/folke/lazy.nvim)

## Defaults
```lua
{
  "ColinKennedy/spellbound.nvim",
  cmd = {"Spellbound"},
  config = ..., -- Add your personal configuration (See the Setup section)
  keys = {
    {
      "[r",
      "<Plug>(SpellboundGoToPreviousRecommendation)",
      desc = "Go to the previous recommendation.",
    },
    {
      "]r",
      "<Plug>(SpellboundGoToNextRecommendation)",
      desc = "Go to the next recommendation.",
    },
  }
}
```


## Lualine
```lua
local utils = require("lualine.utils.utils")

require("lualine").setup {
    sections = {
        lualine_y = {
            {
                "spellbound",
                fallback_profile = { text = "none" },
                profiles = {
                    my_profile = {
                        color = {
                            fg = utils.extract_color_from_hllist(
                                { "fg", "sp" },
                                { "Title" },
                                "#ffcc00"
                            ),
                        },
                    },
                },
            }
        }
    }
}
```


# Setup
## Built-in Example
`spellbound.nvim` comes with a starting example configuration.

```lua
config = function()
  require("spellbound").setup{
    profiles = { my_profile = require("spellbound.profiles.example_me") }
  }
end
```

To see what's in the profile, print its contents

```lua
print(vim.inspect(require("spellbound.profiles.example_me")))
```

You can use this to build your own configuration.


## Dynamic Example
This shows every feature at once. Most of the time you won't need all of this.

```lua
{
  "ColinKennedy/spellbound.nvim",
  cmd = {"Spellbound"},
  config = function()
    local dictionary = "en-strict"

    require("spellbound").setup{
      profiles = {
        strict = {
          dictionaries = {
            name = dictionary,
            input_paths = function()
              local pattern = vim.fs.joinpath(
                _CURRENT_DIRECTORY,
                "spell",
                "parts",
                "*"
              )

              return vim.fn.glob(pattern, true, false)
            end,
            output_path = vim.fs.joinpath(
              _CURRENT_DIRECTORY,
              "spell",
              dictionary .. ".dic"
            ),
          },
          spellfile = {
            operation = "append",
            text = function()
              return "file:" .. vim.fs.joinpath(
                _CURRENT_DIRECTORY,
                "spell",
                dictionary .. ".utf-8.add"
              )
            end,
          },
          spelllang = { operation = "replace", text = dictionary .. ",cjk" },
          spellsuggest = {
            operation = "replace",
            text = function()
              return "file:" .. vim.fs.joinpath(
                _CURRENT_DIRECTORY,
                "spell",
                "strict_thesaurus.txt"
              )
            end,
          },
        },
      },
    }
  end,
  keys = {
    {
      "[r",
      "<Plug>(SpellboundGoToPreviousRecommendation)",
      desc = "Go to the previous recommendation.",
    },
    {
      "]r",
      "<Plug>(SpellboundGoToNextRecommendation)",
      desc = "Go to the next recommendation.",
    },
    {
      "<leader>tss",
      ":Spellbound toggle-profile strict<CR>",
      desc = "[t]oggle all [s]trict [s]pelling mistakes.",
    },
  }
}
```


# Motivation
My coworkers who speak English as a second or even third language sometimes
find documentation hard to read.

To make my docstrings and documentation easier to understand, I added
a restriction - "You may only use 1000 unique words" and made myself a list.
Unfortunately, old habits die hard and sometimes I would forget my list or
fall back to words that are hard for non-native speakers to understand.

`spellbound.nvim` exists in order to:

- Help point out hard words and suggest easier words instead
- Jump to these suggested words easily
- View suggestions entire projects

A nice side effect of this plugin - if docstrings are easier for second/third
English speakers, chances are its even easier to read for native speakers too.


# Alternatives
If you don't create about highlighting text in the current file and just want
(Neo)vim to auto-correct your words as you type, you don't need `spellbound.nvim`.
Look up [:help Abbreviations](https://neovim.io/doc/user/usr_24.html#24.7)
instead.
