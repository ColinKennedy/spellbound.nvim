--- Integrate `spellbound` as a Lualine component.
---
--- @module 'lualine.components.spellbound`
---

local configuration = require("spellbound._core.configuration")
local lualine_require = require("lualine_require")
local modules = lualine_require.lazy_require({ highlight = "lualine.highlight" })

local _LOGGER = require("_spellbound_vendors.vlog")

--- @class SpellboundLualineConfiguration
---     Raw user settings from lualine's configuration which controls the
---     `spellbound` component.
--- @field colored boolean?
---     If `true` or undefined, `spellbound` profiles can render with colors.
---     Otherwise if `false`, Lualine will display the default color instead.
--- @field fallback_profile SpellboundLualineConfigurationFallbackProfile
---     What `spellbound` will show whenever there is no active profile.
--- @field profiles table<string, SpellboundLualineConfigurationProfile>
---     The name of every profile followed by its display settings.

--- @class SpellboundLualineConfigurationFallbackProfile
---     What `spellbound` will show whenever there is no active profile.
--- @field text string?
---     The text to display for the fallback. If not provided then the
---     `spellbound` Lualine component will be hidden when there is not active
---     profile.

--- @class SpellboundLualineConfigurationProfile
---     An individual profile's display settings.
--- @field color string | table?
---     A description of how to highlight the section. See `:help nvim_set_hl()`

local M = require("lualine.component"):extend()

--- Check if `options` is allowed to show colors in the `spellbound` Lualine component.
---
--- @param options SpellboundLualineConfiguration
---     Raw user settings from lualine's configuration which controls the
---     `spellbound` component.
--- @return boolean
---     If `true`, `spellbound` profiles will render with colors.
---     Otherwise if `false`, Lualine will display the default color instead.
---
local function _is_colors_enabled(options)
  return options.colored == nil or options.colored or true
end

--- Set-up the `spellbound` Lualine component + the user's settings.
---
--- @param options SpellboundLualineConfiguration?
---     The options to pass from Lualine to `spellbound`.
---
function M:init(options)
  _LOGGER.debug("Initializing spellbound lualine.")

  if package.loaded["spellbound"] == nil then
    _LOGGER.debug("Not updating status. spellbound plugin is not loaded.")

    return
  end

  local success, _ = pcall(require, "spellbound")

  if not success then
    _LOGGER.error("spellbound could not be imported.")

    return
  end

  M.super.init(self, options)

  self._fallback_profile = "none"
  self._status_format = " %s"

  if self.options.text then
    _LOGGER.debug(
      string.format('Using "%s" status fallback.', self.options.fallback_profile.text)
    )
    self._status_format = self.options.text.format
  end

  if self.options.fallback_profile then
    self._fallback_profile = self.options.fallback_profile.text
  end

  self._highlight_groups = {}

  if
    _is_colors_enabled(self.options)
    and configuration.DATA.profiles
    and self.options.profiles
  then
    _LOGGER.debug("Colors is enabled.")

    for _, name in ipairs(vim.tbl_keys(configuration.DATA.profiles)) do
      if self.options.profiles[name] and self.options.profiles[name].color then
        self._highlight_groups[name] =
          modules.highlight.create_component_highlight_group(
            self.options.profiles[name].color,
            string.format("spellbound_profile_%s", name),
            self.options
          )
      end
    end
  end
end

--- Get the current `spellbound` profile and display it
function M:update_status()
  if not vim.g.spellbound_active_profile and not self._fallback_profile then
    return nil
  end

  local prefix = ""
  local text = ""

  if not vim.g.spellbound_active_profile then
    prefix = ""
    text = self._fallback_profile
  elseif self._highlight_groups[vim.g.spellbound_active_profile] then
    local color = self._highlight_groups[vim.g.spellbound_active_profile]
    prefix = modules.highlight.component_format_highlight(color) or ""
    text = vim.g.spellbound_active_profile
  elseif self._fallback_profile ~= "" then
    prefix = ""
    text = vim.g.spellbound_active_profile
  end

  return string.format(self._status_format, prefix .. text)
end

return M
