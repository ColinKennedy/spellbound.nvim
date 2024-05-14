--- Responsible for recompiling dictionaries when files on-disk change.
---
--- @module 'spellbound._core.watchman'
---

local constant = require("spellbound._core.constant")
local filer = require("spellbound._core.filer")

local _COMMENT_PREFIX = "#"
local _LOGGER = require("_spellbound_vendors.vlog")

local M = {}

--- Check if `text` starts with `prefix`.
---
--- @param text string A full bit of text. e.g. `"foot"`.
--- @param prefix string Some starting text. e.g. `"foo"`.
--- @return boolean # If `prefix` is a prefix, return `true`.
---
local function _startswith(text, prefix)
  return string.sub(text, 1, string.len(prefix)) == prefix
end

--- Check if `text` is a (pseudo) comment.
---
--- @param text string Some text. e.g. `"# some comment"`.
--- @return boolean
---
local function _is_comment(text)
  return _startswith(text, _COMMENT_PREFIX)
end

--- Find the tool that will be used to answer "does `dictionary` need to rebuild"?
---
--- @param dictionary SpellboundDictionary All parts of a dictionary to (maybe) rebuild.
--- @return CompareEngine? # Determine if `dictionary` should rebuild.
---
local function _get_comparison_caller(dictionary)
  local method

  if not dictionary.watcher then
    method = constant.Watcher.calculation_method.sha256
  else
    method = dictionary.watcher.calculation_method
  end

  if method == constant.Watcher.calculation_method.sha256 then
    return require("spellbound._core.compare_engines.sha256")
  end

  if method == constant.Watcher.calculation_method.last_modified_time then
    return require("spellbound._core.compare_engines.last_modified_time")
  end
end

--- Get the "start" of a dictionary word.
---
--- @param line string Some raw dictionary line of text. e.g. `"egg/S"`.
--- @return string? # The found base name, if any. e.g. `"egg"`.
---
local function _get_dictionary_word(line)
  if _is_comment(line) then
    return nil
  end

  if line == "" then
    return nil
  end

  return string.match(line, "([^/]+)/?.*")
end

--- Combine `inputs` files and write it to `output`.
---
--- @param inputs string[]
---     Every absolute file on-disk that will be read and re-combined into `output`.
--- @param output string
---     The absolute path to write to-disk.
--- @return boolean
---     If `output` is written to disk, return `true`. Otherwise return `false`.
---
local function _combine(inputs, output)
  local blobs = {}

  for _, path in ipairs(inputs) do
    local handler = io.open(path, "r")

    if not handler then
      _LOGGER.fmt_error('Path "%s" could not be read.', path)

      return false
    end

    local lines = {}

    for line in handler:lines() do
      table.insert(lines, line)
    end

    table.insert(blobs, { path = path, lines = lines })

    handler:close()
  end

  local lines = {}
  local seen = {}

  for _, blob in ipairs(blobs) do
    table.insert(lines, string.format("# START - Generated %s file", blob.path))

    for _, line in ipairs(blob.lines) do
      local base = _get_dictionary_word(line)

      if base then
        if not vim.tbl_contains(seen, base) then
          table.insert(seen, base)
          table.insert(lines, line)
        end
      else
        table.insert(lines, line)
      end
    end

    table.insert(lines, string.format("# END - Generated %s file", blob.path))
  end

  filer.make_parent_directory(output)

  local handler = io.open(output, "w")

  if not handler then
    _LOGGER.fmt_error('Path "%s" could not be written to.', output)

    return false
  end

  handler:write(table.concat(lines, "\n"))
  handler:close()

  return true
end

--- Return `path` if it's a path or call the function if it's a function.
---
--- @param value (... |fun(): ...)
---     Some value or a function to return.
--- @return ...
---     The path(s) returned.
---
local function _evaluate_values(value)
  if type(value) == "function" then
    return value()
  end

  return value
end

--- Re-build `dictionary` if its `dictionary.watcher` requires it.
---
--- @param dictionary SpellboundDictionary All parts of a dictionary to (maybe) rebuild.
---
function M.build_if_needed(dictionary)
  local paths = _evaluate_values(dictionary.input_paths)
  --- @cast paths string[]

  if vim.tbl_isempty(paths) then
    return
  end

  local comparator = _get_comparison_caller(dictionary)

  if not comparator then
    error(string.format('Dictionary "%s" is invalid.', vim.inspect(dictionary)))

    return
  end

  local output_path = _evaluate_values(dictionary.output_path)
  --- @cast output_path string

  --- @type CompareData
  local data = { parts = paths, dictionary = output_path }
  local needs_compile = comparator.compare(data)

  if needs_compile then
    if not _combine(paths, output_path) then
      return
    end

    vim.cmd("mkspell! " .. output_path)

    if comparator.remember then
      for _, path in ipairs(paths) do
        comparator.remember(path)
      end
    end
  end
end

return M
