--- A sample Neovim configuration with some base thesaurus values.
---
--- Load this file with `nvim -u init.lua init.lua` and the word something
--- should be highlighted. It can be replaced with its alternative
--- recommendation with `1z=` (the default Vim mapping to choosing the first
--- thesaurus suggestion).
---

local _CURRENT_DIRECTORY =
  vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand("<sfile>:p")), ":h")

vim.o.runtimepath = vim.o.runtimepath .. "," .. _CURRENT_DIRECTORY
vim.o.spelllang = "en_us,dictionary"
vim.o.spellsuggest = "file:" .. vim.fs.joinpath(_CURRENT_DIRECTORY, "thesaurus.txt")
vim.wo.spell = true
