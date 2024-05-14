--- Any "important" constant values for `spellbound.nvim`.
---
--- @module 'spellbound._core.constant'
---

local M = {}

local _IS_BUILTIN_MAPPING_SUPPORTED = nil

M.Direction = { backwards = "backwards", forwards = "forwards" }

M.Watcher = {
  calculation_method = {
    last_modified_time = "last_modified_time",
    sha256 = "sha256",
  },
  run_on = {
    start = "start",
  },
}

--- @return boolean # If the ]r / [r mappings exist, return `true`.
function M.is_builtin_mapping_supported()
  if _IS_BUILTIN_MAPPING_SUPPORTED ~= nil then
    return _IS_BUILTIN_MAPPING_SUPPORTED
  end

  -- Reference: https://github.com/theofabilous/neovim/commit/78e354b77bb49480c86aa87571345d157099b17c
  -- Reference: https://github.com/neovim/neovim/issues/9635
  --
  local result = vim.version.ge(vim.version(), "0.10.1")

  _IS_BUILTIN_MAPPING_SUPPORTED = result

  return _IS_BUILTIN_MAPPING_SUPPORTED
end

return M
