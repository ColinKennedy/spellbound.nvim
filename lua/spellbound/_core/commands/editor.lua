--- The functions for `Spellbound edit` subcommand.
---
--- @module 'spellbound._core.commands.editor'
---

local M = {}

--- Open every spellsuggest file that contributes to `spellbound` recommendations.
function M.edit_all_recommendations()
  local items = vim.split(vim.o.spellsuggest, ",")

  for _, item in ipairs(items) do
    local match = string.match(item, "^file:(.+)")

    if match then
      vim.cmd("edit " .. match)
    end
  end
end

return M
