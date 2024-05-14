--- Extra functions for unittesting + parsing strings.
---
--- @module 'tests.textmate'
---

--- @class CursorRange
---     A fake position in-space where a user's cursor is meant to be.
--- @field start_cursor table<number, number>
---     The place where a cursor should go before unittests are run.
--- @field end_cursor table<number, number>
---     The place where a cursor should be after unittests are run.

local _MARKER_START = "|start|"
local _MARKER_END = "|end|"

local M = {}

--- Find all lines marked with `"|cursor|"` and return their row / column positions.
---
---@param source string Pseudo-Python source-code to call. It contains `"|cursor|"` which is the expected user position.
---@return CursorRange[] # The row and column cursor position in `source`.
---@return string # The same source code but with `"|cursor|"` stripped out.
---
function M.parse_source(source)
  local index = 1
  local count = #source
  local cursors = {}
  local marker_start_offset = #_MARKER_START - 1
  local marker_end_offset = #_MARKER_END - 1
  local start_cursor = nil
  local end_cursor = nil

  local code = ""

  local current_row = 1
  local current_column = 1

  while index <= count do
    local character = source:sub(index, index)

    if character == "\n" then
      current_row = current_row + 1
      current_column = 1
    else
      current_column = current_column + 1
    end

    if character == "|" then
      if source:sub(index, index + marker_start_offset) == _MARKER_START then
        index = index + marker_start_offset
        -- NOTE: Don't count the current column - We need to `current_column - 1`
        start_cursor = { current_row, current_column - 2 }
        current_column = current_column - 1
      elseif source:sub(index, index + marker_end_offset) == _MARKER_END then
        index = index + marker_end_offset
        -- NOTE: Don't count the current column - We need to `current_column - 1`
        end_cursor = { current_row, current_column - 2 }
        current_column = current_column - 1
      else
        code = code .. character
      end
    else
      code = code .. character
    end

    index = index + 1

    if start_cursor and end_cursor then
      table.insert(cursors, { start_cursor = start_cursor, end_cursor = end_cursor })
      start_cursor = nil
      end_cursor = nil
    end
  end

  if index <= count then
    -- If this happens, is because the while loop called `break` early
    -- This is very likely so we add the last character(s) to the output
    local remainder = source:sub(index, #source)
    code = code .. remainder
  end

  return { cursors, code }
end

--- Make a temporary Lua buffer with `text` and get the created window.
---
--- @param text string The blob of Lua text to add to the new buffer.
--- @return number # The window ID showing the buffer with ``text``.
---
function M.switch_to_temporary_lua_buffer(text)
  local buffer = vim.api.nvim_create_buf(false, false)
  local window = vim.fn.win_getid()
  vim.api.nvim_win_set_buf(window, buffer)
  vim.bo[buffer].filetype = "lua"

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.fn.split(text, "\n"))

  return window
end

return M
