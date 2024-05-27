--- Control enabling, disabling, and toggling `spellbound` profiles.
---
--- @module 'spellbound._core.commands.profile_manager'
---

local build_profile = require("spellbound._core.commands.build_profile")
local configuration = require("spellbound._core.configuration")
local constant = require("spellbound._core.constant")

local M = {}

local _PROFILE_STARTUP_CACHE = {}

--- @class ProfileStackFrame
---     An enabled profile + all of the Vim settings from before this profile
---     was enabled. If the profile is disabled, these past settings are re-used.
--- @field name string
---     The profile to enable.
--- @field previous PreviousVimOptions
---     Any spell / dictionary settings to remember.

--- @class PreviousVimOptions
---     Vanilla Vim settings that `spellbound` needs to remember / revert to.
--- @field runtimepath string
---     The path used to search for spell files. See `:help spell-load`.
--- @field spellfile string
---     The paths to "spellrare" words. See `:help :spellrare`.
--- @field spelllang string
---     The names of the dictionaries currently applied.
--- @field spellsuggest string
---     Any paths on-disk to thesauruses.

--- @class ProfileStackFrame
M.PROFILE_STACK = {}

--- Re-build a profile's dictionaries if needed.
---
--- A dictionary does not get rebuilt if they don't need to be.
---
--- @param name string
---     The name of the profile to apply or remove.
--- @param profile SpellboundProfile
---     The main definition of a `spellbound` recommendation (the dictionaries,
---     thesauruses, etc).
---
local function _build_dictionaries_if_needed(name, profile)
  if _PROFILE_STARTUP_CACHE[name] then
    return
  end

  build_profile.build_profile_dictionaries(profile, { constant.Watcher.run_on.start })
  _PROFILE_STARTUP_CACHE[name] = true
end

--- Read that value of `data`.
---
--- Note:
---     We can assume that this function will not return nil because the
---     configuration was already validated.
---
--- @param data string | fun(): string The value to read.
--- @return string # The found text, if any.
---
local function _read_text(data)
  local type_ = type(data)

  if type_ == "string" then
    return data
  end

  if type_ == "function" then
    return data()
  end

  return ""
end

--- Delete `text` from Vim's `vim_option`.
---
--- @param text string Some text to remove, if found.
--- @param vim_option string A comma-separated string to edit.
---
local function _remove_text_from_option(text, vim_option)
  local pattern = string.format("(,?)%s,?", text)
  local replaced = string.gsub(vim.o[vim_option], pattern, "%1")
  replaced = string.gsub(replaced, ",*$", "")

  vim.o[vim_option] = replaced
end

--- Change `vim_option` to `profile_option` if `enabled`.
---
--- @param profile_option SpellboundProfileAppendOption | SpellboundProfileOption
---     The user's description of the profile to remove or apply.
--- @param vim_option string
---     Some Vim setting name. e.g. `"runtimepath"`, `"spelllang"`, `"spellsuggest"`.
--- @param enabled boolean
---     If `false`, `profile_option` will be removed from `vim_option`. If
---     `true`, the option is applied.
---
local function _set_comma_option(profile_option, vim_option, enabled)
  if not profile_option then
    return
  end

  if profile_option.operation == "append" then
    local text = _read_text(profile_option.text)

    _remove_text_from_option(text, vim_option)

    if enabled then
      vim.o[vim_option] = vim.o[vim_option] .. "," .. text
    end

    return
  end

  if profile_option.operation == "replace" then
    local text = _read_text(profile_option.text)

    _remove_text_from_option(text, vim_option)

    if enabled then
      vim.o[vim_option] = text
    end

    return
  end
end

--- Apply or remove `profile` from the user's environment, using `enabled`.
---
--- @param name string
---     The name of the profile to apply or remove.
--- @param profile SpellboundProfile
---     The main definition of a `spellbound` recommendation (the dictionaries,
---     thesauruses, etc).
--- @param enabled boolean
---     If `true`, add the profile. If `false`, remove it.
---
local function _set_profile_enabled(name, profile, enabled)
  local previous_runtimepath = vim.o.runtimepath
  local previous_spellfile = vim.o.spellfile
  local previous_spelllang = vim.o.spelllang
  local previous_spellsuggest = vim.o.spellsuggest

  local function _append_profile_stack()
    table.insert(M.PROFILE_STACK, {
      name = name,
      previous = {
        runtimepath = previous_runtimepath,
        spellfile = previous_spellfile,
        spelllang = previous_spelllang,
        spellsuggest = previous_spellsuggest,
      },
    })

    vim.g.spellbound_active_profile = name
  end

  local function _pop_profile_stack()
    local latest = M.PROFILE_STACK[#M.PROFILE_STACK]

    if latest then
      vim.o.runtimepath = latest.previous.runtimepath
      vim.o.spellfile = latest.previous.spellfile
      vim.o.spelllang = latest.previous.spelllang
      vim.o.spellsuggest = latest.previous.spellsuggest
    end

    M.PROFILE_STACK[#M.PROFILE_STACK] = nil -- Pop the end of the stack

    if M.PROFILE_STACK[#M.PROFILE_STACK] then
      vim.g.spellbound_active_profile = M.PROFILE_STACK[#M.PROFILE_STACK].name -- Get the 2nd to the end of the stack
    else
      vim.g.spellbound_active_profile = nil
    end
  end

  _set_comma_option(profile.runtimepath, "runtimepath", enabled)
  _set_comma_option(profile.spellfile, "spellfile", enabled)
  _set_comma_option(profile.spelllang, "spelllang", enabled)
  _set_comma_option(profile.spellsuggest, "spellsuggest", enabled)

  if enabled then
    vim.opt_local.spell = true
    _append_profile_stack()
    _build_dictionaries_if_needed(name, profile)
  else
    _pop_profile_stack()
  end
end

--- Turn on or off `profile` in the current Neovim session.
---
--- @param profile string
---     The name of some user-defined dictionary/setting.
---
function M.toggle_profile(profile)
  if not configuration.DATA.profiles[profile] then
    error(
      string.format(
        'Profile "%s" does not exist. Options are, "%s".',
        profile,
        vim.inspect(vim.tbl_keys(configuration.DATA.profiles))
      )
    )

    return
  end

  local enabled

  if not M.PROFILE_STACK[#M.PROFILE_STACK] then
    enabled = true
  elseif M.PROFILE_STACK[#M.PROFILE_STACK].name == profile then
    enabled = false
  else
    enabled = true
  end

  _set_profile_enabled(profile, configuration.DATA.profiles[profile], enabled)
end

return M
