--- Make sure user-provided settings are defined correctly.
---
--- @module 'spellbound._core.validation'
---

local constant = require("spellbound._core.constant")

local M = {}

--- Make sure `profiles.foo.dictionaries[n].watcher.run_on` is defined correctly.
---
--- @param values SpellboundWatcherRunOn[]
---     All user-provided `run_on` values.
---
local function _validate_run_on(values)
  for _, run_on in ipairs(values) do
    if run_on ~= constant.Watcher.run_on.start then
      error(
        string.format(
          'run_on "%s" only supports "%s" currently.',
          run_on,
          constant.Watcher.run_on.start
        )
      )
    end
  end
end

--- Make sure `profiles.foo.dictionaries[n].watcher` is defined correctly.
---
--- @param watcher SpellboundWatcherConfiguration
---     A description of when a dictionary is allowed to rebuild, if at all.
---
local function _validate_dictionary_watcher(watcher)
  local type_ = type(watcher)

  if type_ == "boolean" then
    if watcher then
      error(
        string.format(
          'Watcher "%s" must either be a table or false.',
          vim.inspect(watcher)
        )
      )

      return
    end
  elseif type_ ~= "table" then
    error(
      string.format(
        'Watcher "%s" must either be a table or false.',
        vim.inspect(watcher)
      )
    )

    return
  else
    if type(watcher.calculation_method) ~= "string" then
      error(
        string.format(
          'watcher.calculation_method "%s" must be a string.',
          vim.inspect(watcher)
        )
      )

      return
    end

    if not constant.Watcher.calculation_method[watcher.calculation_method] then
      error(
        string.format(
          'watcher.calculation_method "%s" only supports "%s".',
          vim.inspect(watcher),
          vim.inspect(constant.Watcher.calculation_method)
        )
      )

      return
    end

    if watcher.run_on then
      _validate_run_on(watcher.run_on)

      return
    else
      -- NOTE: Add a default value if there is none. It makes later code easier to run
      watcher.run_on = { constant.Watcher.run_on.start }
    end
  end
end

--- Make sure `logging` configuration settings are valid.
---
--- @param data SpellboundLoggingConfiguration Decide how to log, and where.
---
local function _validate_logging(data)
  local level = data.level

  if level == nil then
    -- NOTE: Set a default level if none is written
    data.level = "info"
  else
    if type(level) ~= "string" then
      error(string.format('Option level "%s / %s" must be a string.', data, level))

      return
    end

    local options = { "trace", "debug", "info", "warn", "error" }

    if not vim.tbl_contains(options, level) then
      error(
        string.format(
          'Level "%s" is not allowed. Options were "%s".',
          level,
          vim.inspect(options)
        )
      )

      return
    end
  end

  if data.use_console == nil then
    -- NOTE: Don't print to Neovim (so we don't spam the user)
    data.use_console = false
  else
    if type(data.use_console) ~= "boolean" then
      error(
        string.format(
          'Option use_console "%s / %s" must be a boolean.',
          data,
          data.use_console
        )
      )

      return
    end
  end

  if data.use_file == nil then
    -- NOTE: Don't make files on-disk by default
    data.use_file = false
  else
    if type(data.use_file) ~= "boolean" then
      error(
        string.format(
          'Option use_file "%s / %s" must be a boolean.',
          data,
          data.use_file
        )
      )

      return
    end
  end
end

--- Make sure a profile from the `profiles` configuration settings is valid.
---
--- @param data SpellboundProfileAppendOption | SpellboundProfileOption
---     Describe what spell data to use.
--- @param append_only boolean?
---     If `true`, then `data.operation` must be append. If not, it can be any
---     of the other allowed values.
---
local function _validate_profile_option(data, append_only)
  if not data then
    return
  end

  append_only = append_only or false

  if type(data.operation) ~= "string" then
    error(string.format('The operation "%s" must be a string.', data.operation))

    return
  end

  if append_only and data.operation ~= "append" then
    error(string.format('The operation "%s" must be "append".', data.operation))

    return
  elseif data.operation ~= "append" and data.operation ~= "replace" then
    error(
      string.format('The operation "%s" must be "append" or "replace".', data.operation)
    )

    return
  end

  local type_ = type(data.text)

  if type_ ~= "string" and type_ ~= "function" then
    error(
      string.format(
        'Profile text "%s" must be a string for a callable function.',
        data.text
      )
    )

    return
  end
end

--- Make sure a profile's `dictionary` is defined as expected.
---
--- @param dictionary SpellboundDictionary One of the profile's dictionaries.
---
local function _validate_profile_dictionary(dictionary)
  local type_ = type(dictionary.name)

  if type_ ~= "string" then
    error(
      string.format(
        'Dictionary name "%s" must be a defined string.',
        vim.inspect(dictionary)
      )
    )

    return
  end

  type_ = type(dictionary.output_path)

  if type_ ~= "string" and type_ ~= "function" then
    error(
      string.format(
        'Dictionary output_path "%s" must be a defined string or function that returns a string.',
        vim.inspect(dictionary)
      )
    )

    return
  end

  if dictionary.watcher then
    _validate_dictionary_watcher(dictionary.watcher)
  end

  type_ = type(dictionary.input_paths)

  if type_ ~= "table" and type_ ~= "function" then
    error(
      string.format(
        'Dictionary input_paths "%s" must be a defined string[] or function that returns a string[].',
        vim.inspect(dictionary)
      )
    )

    return
  end

  if type_ == "table" then
    local paths = dictionary.input_paths

    --- @cast paths string[]
    for _, item in ipairs(paths) do
      if type(item) ~= "string" then
        error(
          string.format('Dictionary item "%s" must be a string.', vim.inspect(item))
        )

        return
      end
    end
  end
end

--- Make sure `dictionaries` is defined as expected.
---
--- @param dictionaries SpellboundDictionary[]? A profile's expected dictionaries, if any.
---
local function _validate_profile_dictionaries(dictionaries)
  if not dictionaries then
    return
  end

  if type(dictionaries) ~= "table" then
    error(
      string.format(
        'Profile dictionaries "%s" must be a table.',
        vim.inspect(dictionaries)
      )
    )
  end

  if vim.tbl_isempty(dictionaries) then
    error(string.format("Profile dictionaries cannot be empty."))
  end

  for _, dictionary in ipairs(dictionaries) do
    _validate_profile_dictionary(dictionary)
  end
end

--- Make sure `profiles` configuration settings are valid.
---
--- @param data table<string, SpellboundProfile> Describe what spell data to use.
---
local function _validate_profiles(data)
  for name, profile in pairs(data) do
    if type(name) ~= "string" then
      error(string.format('Profile "%s" must be a string.', name))

      return
    end

    if type(profile) ~= "table" then
      error(string.format('Profile "%s" must be a table.', vim.inspect(profile)))

      return
    end

    _validate_profile_option(profile.runtimepath, true)
    _validate_profile_option(profile.spelllang)
    _validate_profile_option(profile.spellsuggest)

    _validate_profile_dictionaries(profile.dictionaries)
  end
end

--- Make sure a `wrap_*` configuration setting works as expected.
---
--- @param option ...? The user configuration value, if any.
---
local function _validate_wrap(option)
  if not option then
    return
  end

  local type_ = type(option)

  if type_ == "boolean" or type_ == "function" then
    return
  end

  error(
    string.format(
      'Option / Type "%s / %s" is not a boolean or a function.',
      option,
      type_
    )
  )
end

--- Make sure the user's full configuration works as expected.
---
--- @param data SpellboundConfiguration?
---     Raw user setup() values to check for correctness.
---
function M.validate_data(data)
  if not data then
    return
  end

  if data.behavior ~= nil then
    if type(data.behavior) ~= "table" then
      error(string.format('Behavior "%s" must be a table.', data.behavior))
    end

    _validate_wrap(data.behavior.wrap_next_recommendation)
    _validate_wrap(data.behavior.wrap_previous_recommendation)
  end

  if data.logging ~= nil then
    if type(data.logging) ~= "table" then
      error(string.format('Logging "%s" must be a table.', data.logging))
    end

    _validate_logging(data.logging)
  end

  if data.profiles ~= nil then
    if type(data.profiles) ~= "table" then
      error(string.format('Profiles "%s" must be a table.', data.profiles))
    end

    _validate_profiles(data.profiles)
  end
end

return M
