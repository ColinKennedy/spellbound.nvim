--- The file that defines the "go to" next/previous recommendation keymap logic.
---
--- @module 'spellbound._core.actions'
---

--- @class ColumnRange
--- @field [1] number The starting column.
--- @field [2] number The last column.

local configuration = require("spellbound._core.configuration")
local constant = require("spellbound._core.constant")

local _LOGGER = require("_spellbound_vendors.vlog")

local M = {}

--- Check if `text` represents `:help SpellRare` text.
---
--- @param type_name string Some `:help vim.spell.check` value. e.g. `"bad"`, `"rare"`.
--- @return boolean # If `true`, then `text` is a `SpellRare`.
---
local function _is_rare(type_name)
  return type_name == "rare"
end

--- Warn the user that the actions needs to jump to the top or bottom of the buffer.
---
--- @param direction "backwards" | "forwards"
---
local function _warn_wrap(direction)
  local message

  if direction == constant.Direction.forwards then
    message = "search hit BOTTOM, continuing at TOP"
  else
    message = "search hit TOP, continuing at BOTTOM"
  end

  vim.notify(message, vim.log.levels.WARN)
end

--- Reverse `iterator` and yield a function that can be used in for-loops.
---
--- @param iterator fun(end_line: integer?): integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch
---     Basically, it's `:h Query:iter_captures()`
--- @return (fun(end_line: integer?): integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch)?
---     A reversed `:h Query:iter_captures()`.
---
local function _get_reverse_array(iterator)
  local items = {}

  for id, node, metadata in iterator do
    table.insert(items, { id, node, metadata })
  end

  if vim.tbl_isempty(items) then
    _LOGGER.error("No iterator items were found.")

    return nil
  end

  local index = #items

  local function iter()
    if index == 1 then
      return nil
    end

    index = index - 1
    local item = items[index]

    return unpack(item)
  end

  return iter
end

--- Find the first spelling recommendation in `captures` that we can find.
---
--- @param captures (fun(end_line: integer?): integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch)?
---     Some `:h Query:iter_captures` to run.
--- @param query vim.treesitter.Query
---     A tree-sitter query to check for spell data.
--- @param buffer number
---     A 1-or-more value indicating the buffer of text that `query` is meant for.
--- @param current_row number
---     The current window's cursor row. A 1-or-more value.
--- @param current_column number
---     The current window's cursor column. A 1-or-more value.
--- @param direction "forwards" | "backwards"
---     If "forwards", search from the top of the buffer. If "backwards", search from the bottom.
--- @return ColumnRange?
---     The found row and column, if any.
---
local function _get_first_match(
  captures,
  query,
  buffer,
  current_row,
  current_column,
  direction
)
  for id, node, _ in captures do
    if query.captures[id] == "spell" then
      local node_row_start, _, node_row_end, _ = node:range()

      for row = node_row_start + 1, node_row_end + 1 do
        local _, start_column, _, end_column = node:range()

        local line = vim.api.nvim_buf_get_lines(buffer, row - 1, row, true)[1]
        local sub_line = line:sub(start_column, end_column)

        local spells

        if direction == constant.Direction.forwards then
          spells = vim.spell.check(sub_line)
        elseif direction == constant.Direction.backwards then
          spells = vim.fn.reverse(vim.spell.check(sub_line))
        else
          _LOGGER.fmt_warn('Direction "%s" is unknown.', direction)
        end

        for _, entry in ipairs(spells) do
          local type_ = entry[2]
          local column = start_column + entry[3] - 1

          if _is_rare(type_) then
            if
              direction == constant.Direction.forwards
              and (row > current_row or column > current_column + #entry[1] - 2)
            then
              return { row, column - 1 }
            elseif
              direction == constant.Direction.backwards
              and (row < current_row or column < current_column)
            then
              return { row, column - 1 }
            end
          end
        end
      end
    end
  end

  return nil
end

--- Check the start or end of the buffer for a spelling recommendation.
---
--- @param direction "forwards" | "backwards"
---     If "forwards", search from the top of the buffer. If "backwards", search from the bottom.
--- @param current_row number
---     The current window's cursor row. A 1-or-more value. The row is used to
---     stop looking for matches (so we don't accidentally search the whole
---     buffer twice in a row).
--- @param query vim.treesitter.Query
---     A tree-sitter query to check for spell data.
--- @param buffer number
---     A 1-or-more value indicating the buffer of text that `query` is meant for.
--- @param tree TSTree
---     The `buffer` but as a tree-sitter tree.
--- @return ColumnRange?
---     The found row and column, if any.
---
local function _get_wrap_captures(direction, current_row, query, buffer, tree)
  if
    direction == constant.Direction.forwards
    and configuration.is_wrap_next_recommendation_enabled()
  then
    local root = tree:root()
    local captures = query:iter_captures(root, buffer, root:start(), current_row)

    return _get_first_match(captures, query, buffer, 1, 1, direction)
  elseif
    direction == constant.Direction.backwards
    and configuration.is_wrap_previous_recommendation_enabled()
  then
    local captures =
      _get_reverse_array(query:iter_captures(tree:root(), buffer, current_row - 1, -1))

    local value = 1000000000 -- Just a really big number so the next run will pass
    return _get_first_match(captures, query, buffer, value, value, direction)
  end

  return nil
end

--- Find the next spelling recommendation in `window`, in some `direction`.
---
--- @param window number
---     A 1-or-more value for the window that has some cursor for us to query.
--- @param direction "forwards" | "backwards"
---     If "forwards", search from the top of the buffer. If "backwards", search from the bottom.
--- @return ColumnRange?
---     The found row and column, if any.
---
local function _get_spell_from_direction(window, direction)
  local buffer = vim.api.nvim_win_get_buf(window)
  local success, parser = pcall(vim.treesitter.get_parser, buffer)

  if not success then
    _LOGGER.error('Treesitter failed to parse "%s" buffer.', buffer)

    return
  end

  local current_row, current_column = unpack(vim.api.nvim_win_get_cursor(window))
  local query = vim.treesitter.query.get(parser:lang(), "highlights")

  if not query then
    _LOGGER.error('Buffer "%s" could not get a tree-sitter query.', buffer)

    return
  end

  for _, tree in ipairs(parser:parse()) do
    local captures

    if direction == constant.Direction.forwards then
      -- NOTE: We need to `current_row - 1` because the Neovim tree-sitter API
      -- is 0-indexed but the vim cursor API is 1-indexed
      --
      captures = query:iter_captures(tree:root(), buffer, current_row - 1)
    elseif direction == constant.Direction.backwards then
      local root = tree:root()
      captures =
        _get_reverse_array(query:iter_captures(root, buffer, root:start(), current_row))
    end

    local cursor =
      _get_first_match(captures, query, buffer, current_row, current_column, direction)

    if cursor then
      return cursor
    end

    _warn_wrap(direction)

    cursor = _get_wrap_captures(direction, current_row, query, buffer, tree)

    if cursor then
      return cursor
    end
  end

  _LOGGER.error("Finished searching but no recommendation was found.")

  return nil
end

--- Run tree-sitter on the `window` so that later queries will succeed.
---
--- @param window number
---     A 1-or-more value for the window that has some cursor for us to query.
local function _parse_window_with_treesitter(window)
  local buffer = vim.api.nvim_win_get_buf(window)
  local success, parser = pcall(vim.treesitter.get_parser, buffer)

  if not success then
    _LOGGER.error('Treesitter failed to parse "%s" buffer.', buffer)

    return
  end

  local query = vim.treesitter.query.get(parser:lang(), "highlights")

  if not query then
    _LOGGER.error('Buffer "%s" could not get a tree-sitter query.', buffer)

    return
  end

  parser:parse()
end

--- @return boolean # Make sure spelling is enabled on the current window.
local function _validate_spell_enabled()
  local window = vim.fn.win_getid()

  if not vim.wo[window].spell then
    error("E756: Spell checking is not possible")

    return false
  end

  return true
end

--- Find the next `spellbound` recommendation and go to it.
function M.go_to_next_recommendation()
  if not _validate_spell_enabled() then
    return
  end

  if constant.is_builtin_mapping_supported() then
    local window = vim.fn.win_getid()
    _parse_window_with_treesitter(window)
    vim.cmd([[normal ]r]])

    return
  end

  local window = vim.fn.win_getid()
  local cursor = _get_spell_from_direction(window, constant.Direction.forwards)

  if not cursor then
    _LOGGER.fmt_warn('Window "%s" could not find a next recommendation.', window)

    return
  end

  vim.api.nvim_win_set_cursor(window, cursor)
end

--- Find the previous `spellbound` recommendation and go to it.
function M.go_to_previous_recommendation()
  if not _validate_spell_enabled() then
    return
  end

  if constant.is_builtin_mapping_supported() then
    local window = vim.fn.win_getid()
    _parse_window_with_treesitter(window)
    vim.cmd([[normal [r]])

    return
  end

  local window = vim.fn.win_getid()
  local cursor = _get_spell_from_direction(window, constant.Direction.backwards)

  if not cursor then
    _LOGGER.fmt_warn('Window "%s" could not find a previous recommendation.', window)

    return
  end

  vim.api.nvim_win_set_cursor(window, cursor)
end

return M
