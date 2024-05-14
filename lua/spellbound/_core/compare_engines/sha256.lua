--- Compare a file on-disk with its last computed SHA value.
---
--- @module 'spellbound._core.compare_engines.sha256'
---

--- @class CompareEngine
---     An interface that answers two questions
---
---     1. Does the dictionary need to rebuild
---     2. (If needed) How do we remember that the dictionary does not need to rebuild.
--- @field compare fun(data: CompareData): boolean
---     Compare-related arguments (input files, the output dictionary, etc).
--- @field remember fun(path: string): nil
---     Pre-compute a SHA for `path` and write it to a known cache path on-disk.

--- @class CompareData
---     Compare-related arguments (input files, the output dictionary, etc).
--- @field parts string[]
---     The parts / pieces of a dictionary that need to be rebuilt.
--- @field dictionary string
---     An absolute path to a dictionary that may or may not exist on-disk.
---

local filer = require("spellbound._core.filer")
local sha2 = require("_spellbound_vendors.sha2")

local M = {}

local _ROOT = vim.fn.stdpath("data")
--- @cast _ROOT string
local _SAVE_DIRECTORY = vim.fs.joinpath(_ROOT, "spellbound.nvim", "sha256")

--- Convert `path` into a file name.
---
--- @param path string An absolute path on-disk to some file. e.g. `"/foo/bar.txt"`.
--- @return string # A converted path. e.g. `"%foo/bar.txt"`.
---
local function _escape(path)
  local match = string.gsub(path, "/", "%%")
  return match
end

--- Get the path on-disk where this module looks for a pre-computed SHA.
---
--- @param path string
---     An absolute path to a file on-disk. e.g. `"/tmp/foo.txt"`.
--- @return string
---     A pre-computed SHA location. e.g. `"~/.local/share/nvim/spellbound.nvim/sha2"`.
---
local function _get_source(path)
  return vim.fs.joinpath(_SAVE_DIRECTORY, _escape(vim.fs.normalize(path)))
end

--- Check if `path` has any changes. Check the pre-computed SHA for differences.
---
--- @param data CompareData
---     Compare-related arguments (input files, the output dictionary, etc).
--- @return boolean
---     If there's no difference between `data` and its computed SHA, return `false`.
---     If `data` could use a re-build, return `true`.
---
function M.compare(data)
  for _, path in ipairs(data.parts) do
    local source = _get_source(path)

    if vim.fn.filereadable(source) ~= 1 then
      return true
    end

    local old = filer.read(source)
    local new = sha2.sha256(filer.read(path))

    if old ~= new then
      return true
    end
  end

  return false
end

--- Pre-compute a SHA for `path` and write it to a known cache path on-disk.
---
--- @param path string
---     An absolute path to a file on-disk. e.g. `"/tmp/foo.txt"`.
--- @return boolean
---     If `path` writes to disk successfully, return `true`. Otherwise, `false`.
---
function M.remember(path)
  local source = _get_source(path)
  filer.make_parent_directory(source)
  local blob = filer.read(path)

  if not blob then
    return false
  end

  local cache = sha2.sha256(blob)
  --- @cast cache string
  filer.write(cache, source)

  return true
end

return M
