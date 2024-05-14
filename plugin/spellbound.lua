--- All `spellbound` command definitions.

--- @class NeovimCommandAttributes
---     The options that Neovim sends to functions
---     `:help nvim_create_user_command()`
--- @field fargs string[]
---     All space-separated arguments that the user sent when they called the command.

--- @class SpellboundSubcommand
---     A Python subparser's definition.
--- @field run fun(args:string[], opts: table)
---     The function to run when the subcommand is called.
--- @field complete? fun(args: string): string[]
---     Command completions callback, the `args` are  the lead of the subcommand's arguments

local _PREFIX = "Spellbound"

--- Get profile names and return them as completion options.
---
--- @param args string[]
---     All arguments to pass to the sub-command. e.g. `{}`, `{"some_profile_name"}`.
--- @return string[]
---     All of the matching profile names.
---
local function _complete_profiles(args)
  local configuration = require("spellbound._core.configuration")
  local keys = vim.tbl_keys(configuration.DATA.profiles)

  return vim
    .iter(keys)
    :filter(function(install_arg)
      return install_arg:find(args) ~= nil
    end)
    :totable()
end

--- Get some user arguments, filter the arguments that do not match `keys`.
---
--- @param keys string[]
---     Any matchable text. e.g. `{"foo"}`.
--- @return fun(args: string[]): string[]
---     The resulting function that can be used for Vim's auto-complete. If
---     a user's `args` is `{"f"}` then it will match because there is `"foo"`
---     in the `keys`.
---
local function _filter_by_keys(keys)
  return function(args)
    return vim
      .iter(keys)
      :filter(function(install_arg)
        -- If the user has typed `:Rocks install ne`,
        -- this will match 'neorg'
        return install_arg:find(args) ~= nil
      end)
      :totable()
  end
end

--- @type table<string, SpellboundSubcommand>
local _SUBCOMMANDS = {
  ["build-profile"] = {
    complete = _complete_profiles,
    run = function(args, _)
      local profile_name = args[1]
      local build_profile = require("spellbound._core.commands.build_profile")
      local constant = require("spellbound._core.constant")
      local data = require("spellbound._core.configuration").DATA

      if profile_name then
        local profile = data.profiles[profile_name]

        if not profile then
          error(string.format('Profile "%s" does not exist.', profile_name))
        end

        if profile.dictionaries then
          build_profile.build_dictionaries(
            profile.dictionaries,
            { constant.Watcher.run_on.start }
          )
        end
      else
        build_profile.build_profile_dictionaries(
          vim.tbl_values(data.profiles),
          { constant.Watcher.run_on.start }
        )
      end
    end,
  },
  edit = {
    complete = _filter_by_keys({ "all-recommendations" }),
    run = function(_, _)
      local editor = require("spellbound._core.commands.editor")
      editor.edit_all_recommendations()
    end,
  },
  ["toggle-profile"] = {
    complete = _complete_profiles,
    run = function(args, _)
      local profile = args[1]
      local profile_manager = require("spellbound._core.commands.profile_manager")

      if not profile then
        error("You need to specify a profile name.")

        return
      end

      profile_manager.toggle_profile(profile)
    end,
  },
}

--- Check if `full` contains `prefix` + whitespace.
---
--- @param full string Some full text like `"Spellbound blah"`.
--- @param prefix string The expected starting text. e.g. `"Spellbound"`.
--- @return boolean # If a subcommand syntax was found, return true.
---
local function _is_subcommand(full, prefix)
  local expression = "^" .. prefix .. "%s+%w*$"

  return full:match(expression)
end

--- Get the auto-complete, if any, for a subcommand.
---
--- @param text string Some full text like `"Spellbound blah"`.
--- @param prefix string The expected starting text. e.g. `"Spellbound"`.
---
local function _get_subcommand_completion(text, prefix)
  local expression = "^" .. prefix .. "*%s(%S+)%s(.*)$"
  local subcommand, arguments = text:match(expression)

  if not subcommand or not arguments then
    return nil
  end

  if _SUBCOMMANDS[subcommand] and _SUBCOMMANDS[subcommand].complete then
    return _SUBCOMMANDS[subcommand].complete(arguments)
  end

  return nil
end

--- Check for a subcommand and, if found, call its `run` caller field.
---
--- @source `:h lua-guide-commands-create`
---
--- @param opts table
---
local function _command_triage(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = _SUBCOMMANDS[subcommand_key]

  if not subcommand then
    vim.notify("Spellbound: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)

    return
  end

  subcommand.run(args, opts)
end

vim.api.nvim_create_user_command(_PREFIX, _command_triage, {
  nargs = "+",
  desc = "Spellbound's command API.",
  complete = function(args, text, _)
    local completion = _get_subcommand_completion(text, _PREFIX)

    if completion then
      return completion
    end

    if _is_subcommand(text, _PREFIX) then
      local keys = vim.tbl_keys(_SUBCOMMANDS)
      return vim
        .iter(keys)
        :filter(function(key)
          return key:find(args) ~= nil
        end)
        :totable()
    end

    return nil
  end,
})

vim.keymap.set("n", "<Plug>(SpellboundGoToPreviousRecommendation)", function()
  require("spellbound").go_to_previous_recommendation()
end, { desc = "Go to the previous recommendation." })

vim.keymap.set("n", "<Plug>(SpellboundGoToNextRecommendation)", function()
  require("spellbound").go_to_next_recommendation()
end, { desc = "Go to the next recommendation." })
