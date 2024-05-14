--- Settings zoot that control how `spellbound.nvim` works.
---
--- @module 'spellbound._core.configuration'
---

--- @class SpellboundConfiguration
---     All options for `spellbound`.
--- @field behavior? SpellboundBehaviorConfiguration
---     Control how `spellbound` generally works.
--- @field logging? SpellboundLoggingConfiguration
---     Control whether or not logging is printed to the console or to disk.
--- @field profiles? table<string, SpellboundProfile>
---     The main definition of `spellbound` recommendations (the dictionaries,
---     thesauruses, etc).

--- @class SpellboundBehaviorConfiguration
---     Control how `spellbound` generally works.
--- @field wrap_next_recommendation boolean | fun(): boolean
---     If `true` or returns `true`, search from the start of the buffer if no
---     more matches are found at the current position.
--- @field wrap_previous_recommendation boolean | fun(): boolean
---     If `true` or returns `true`, search from the bottom of the buffer if no
---     more matches are found at the current position.

--- @class SpellboundLoggingConfiguration
---     Control whether or not logging is printed to the console or to disk.
--- @field level "trace" | "debug" | "info" | "warn" | "error" | "fatal"
---     Any messages above this level will be logged.
--- @field use_console boolean
---     Should print the output to neovim while running. Warning: This is very
---     spammy. You probably don't want to enable this unless you have to.
--- @field use_file boolean
---     Should write to a file.

--- @class SpellboundProfile
---     The main definition of a `spellbound` recommendation (the dictionaries,
---     thesauruses, etc).
--- @field dictionaries SpellboundDictionary[]?
---     The dictionaries to create as a part of `spellbound`.
--- @field runtimepath SpellboundProfileAppendOption?
---     Define wherer to look for a dictionary file. Important: read
---     `:help spell-load`. The path must contain a spell
---     subdirectory and then, inside there, it needs to be
---     a LL.EEE.spl file.
--- @field spellfile SpellboundProfileOption?
---     The paths to "spellrare" words. See `:help :spellrare`.
--- @field spelllang SpellboundProfileOption?
---     The name of the dictionary to load for this profile.
--- @field spellsuggest SpellboundProfileOption?
---     The URI/path to a thesaurus file. e.g. `"file:/path/to/thesaurus.txt"`.
---     See `:help 'spellsuggest' for details.

--- @class SpellboundDictionary
---     The dictionary that is created from `input_paths` and write to `output_path`.
--- @field name string
---     The name of the dictionary file to create.
--- @field watcher (SpellboundWatcherConfiguration | false)?
---     If defined, changes to `input_paths` or `output_path` may trigger
---     commands to rebuild your dictionary. Set to `false` to explicitly
---     disable this behavior.
--- @field input_paths string[] | fun(): string[]
---     Every file on-disk that will be combined together into a single dictionary.
--- @field output_path string | fun(): string
---     The path on-disk to write the dictionary to and call `:mkspell` on.

--- @class SpellboundWatcherConfiguration
---     Used to control how dictionaries rebuild, if at all.
--- @field run_on SpellboundWatcherRunOn[]
---     Declare when this watcher should be doing its work (or not).
--- @field calculation_method ("sha256" | "last_modified_time")?
---     `spellbound` checks if files have changed by using this comparison
---     function. Currently only sha256 is supported. Most of the time you don't
---     need to define this.

--- @alias SpellboundWatcherRunOn "start"
---     If `"start"`, this watcher only checks once at the start of Neovim.

--- @class SpellboundProfileAppendOption
---     An Vim option + describe how it should affect the user's current Vim session.
--- @field operation "append"
---     If `"append"`, the current option is kept and the profile is added last.
--- @field text string | fun(): string
---     The value(s) to append to the option.

--- @class SpellboundProfileOption
---     An Vim option + describe how it should affect the user's current Vim session.
--- @field operation "append" | "replace"
---     If `"append"`, the current option is kept and the profile is added last.
--- @field text string | fun(): string
---     The value(s) to append to the option.

local _LOGGER = require("_spellbound_vendors.vlog")

local M = {}

M.DATA = {
  behavior = {
    wrap_next_recommendation = function()
      return vim.o.wrapscan
    end,
    wrap_previous_recommendation = function()
      return vim.o.wrapscan
    end,
  },
  logging = {
    level = "info",
    use_console = false,
    use_file = false,
  },
  profiles = {},
}

--- @return boolean # Check if `[r` can search from the top of the buffer.
function M.is_wrap_next_recommendation_enabled()
  local value = M.DATA.behavior.wrap_next_recommendation

  if type(value) == "boolean" then
    return value
  elseif type(value) == "function" then
    return value()
  end

  _LOGGER.fmt_warn('Value "%s" is unknown. It should be a boolean or function.', value)

  return false
end

--- @return boolean # Check if `[r` can search from the bottom of the buffer.
function M.is_wrap_previous_recommendation_enabled()
  local value = M.DATA.behavior.wrap_previous_recommendation

  if type(value) == "boolean" then
    return value
  elseif type(value) == "function" then
    return value()
  end

  _LOGGER.fmt_warn('Value "%s" is unknown. It should be a boolean or function.', value)

  return false
end

return M
