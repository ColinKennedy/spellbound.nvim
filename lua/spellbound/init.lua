--- The initial file that boostraps `spellbound.nvim`.
---
--- @module 'spellbound'
---

local actions = require("spellbound._core.actions")
local configuration = require("spellbound._core.configuration")
local validation = require("spellbound._core.validation")
local vlog = require("_spellbound_vendors.vlog")

local M = {}

--- Find the next `spellbound` recommendation and go to it.
M.go_to_next_recommendation = actions.go_to_next_recommendation

--- Find the previous `spellbound` recommendation and go to it.
M.go_to_previous_recommendation = actions.go_to_previous_recommendation

--- Override default configuration with user settings.
---
--- @param data SpellboundConfiguration? Any extra settings to add to the defaults.
---
function M.setup(data)
  validation.validate_data(data or {})
  configuration.DATA = vim.tbl_deep_extend("force", configuration.DATA, data)

  vlog.new(configuration.DATA.logging or {}, true)
end

return M
