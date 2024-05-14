--- Extra functions for handling Neovim and unittest details.
---
--- @module 'tests.testmate'
---

local constant = require("spellbound._core.constant")
local actions = require("spellbound._core.actions")

local textmate = require("tests.textmate")

local M = {}

--- Find the function that will move the user's cursor towards `direction`.
---
--- @param direction "backwards" | "forwards" An allowed cursor movement.
--- @return fun()? # The found function, if any.
---
local function _get_direction_caller(direction)
  if direction == constant.Direction.forwards then
    return actions.go_to_next_recommendation
  elseif direction == constant.Direction.backwards then
    return actions.go_to_previous_recommendation
  end

  error(
    string.format(
      'Direction "%s" is unknown. Please check spelling and try again.',
      direction
    )
  )

  return nil
end

--- Create a Lua buffer and set + move the cursor in `direction`.
---
--- Warning:
---     Running this function affects your global Neovim state. Be careful!
---
--- @param template string
---     Some pseudo-source code that contains `"|start|"` and `"|end|"` cursor
---     markers. The cursor will be placed at `"|start|"` and then the unittest
---     will check if calling `direction` causes the cursor to move to the
---     `"|end|"` marker.
--- @param recommendations TemporaryTestData
---     A collection dictionary and thesaurus data used for unittests.
--- @param direction "backwards" | "forwards"
---     An allowed cursor movement.
---
function M.assert_go_to_lua(template, recommendations, direction)
  local cursor_range, source = unpack(textmate.parse_source(template))

  if vim.tbl_isempty(cursor_range) then
    error("Template found no start/end cursors. Did you define a |start| and |end|?")

    return
  end

  local caller = _get_direction_caller(direction)

  if not caller then
    return
  end

  local window = textmate.switch_to_temporary_lua_buffer(source)
  vim.o.runtimepath = vim.o.runtimepath .. "," .. recommendations.runtimepath
  vim.o.spelllang = "en_us," .. recommendations.spelllang
  vim.o.spellsuggest = recommendations.spellsuggest
  vim.wo[window].spell = true

  for _, cursors in ipairs(cursor_range) do
    vim.api.nvim_win_set_cursor(window, cursors.start_cursor)
    caller()
    -- luacheck: push ignore 143
    assert.are.same(cursors.end_cursor, vim.api.nvim_win_get_cursor(window))
    -- luacheck: pop
  end
end

return M
