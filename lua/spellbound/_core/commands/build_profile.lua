--- Build a profile's dictionaries as needed.
---
--- @module 'spellbound._core.commands.build_profile'
---

local watchman = require("spellbound._core.watchman")

local M = {}

--- Build all dictionaries within `profile`.
---
--- Only rebuild if a rebuild is needed.
---
--- @param dictionaries SpellboundDictionary[]
---     All of the dictionaries to rebuild.
--- @param run_on string[]
---     The caller context (do we want to build all dictionaries? Some? Maybe
---     only dictionaries that are allowed to build on start-up?)
---
function M.build_dictionaries(dictionaries, run_on)
  local function _is_enabled(enabled_run_ons, current_run_on_context)
    for _, current in ipairs(current_run_on_context) do
      if vim.tbl_contains(enabled_run_ons, current) then
        return true
      end
    end

    return false
  end

  for _, dictionary in ipairs(dictionaries) do
    if
      dictionary.watcher == nil
      or dictionary.watcher ~= false
        and _is_enabled(dictionary.watcher.run_on, run_on)
    then
      watchman.build_if_needed(dictionary)
    end
  end
end

--- Build all dictionaries across all profiles.
---
--- Only rebuild if a rebuild is needed.
---
--- @param profiles SpellboundProfile[]
---     All of the profiles that check + rebuild.
--- @param run_on string[]
---     The caller context (do we want to build all dictionaries? Some? Maybe
---     only dictionaries that are allowed to build on start-up?)
---
function M.build_profile_dictionaries(profiles, run_on)
  for _, profile in ipairs(profiles) do
    if profile.dictionaries then
      M.build_dictionaries(profile.dictionaries, run_on)
    end
  end
end

return M
