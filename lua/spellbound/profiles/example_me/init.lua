--- An example configuration for programming. It's minimal and should be extended.
---
--- @module 'spellbound.profiles.example_me'
---

local M = {}

-- TODO: Make sure this works

local _STRICT_DICTIONARY = "en-strict"

--- @return string # The directory that this file lives in.
local function _get_current_directory()
  return vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h")
end

--- @type SpellboundProfileAppendOption
M.runtimepath = {
  operation = "append",
  text = function()
    return _get_current_directory()
  end,
}

--- @type SpellboundProfileOption
M.spelllang = { operation = "replace", text = _STRICT_DICTIONARY .. ",cjk" }

--- @type SpellboundProfileOption
M.spellsuggest = {
  operation = "replace",
  text = function()
    return "file:" .. vim.fs.joinpath(_get_current_directory(), "thesaurus.txt")
  end,
}

return M
