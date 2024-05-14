--- Simple functions that make writing unittests easier.
---
--- @module 'tests.common'
---

local configuration = require("spellbound._core.configuration")

local M = {}

local _TEMPORARY_DIRECTORIES = {}
local _TEMPORARY_FILES = {}
local _CONFIGURATION = {}
local _OPTIONS = {}

--- Track `path` on-disk so it can be deleted later.
---
--- @param path string An absolute directory on-disk to delete later.
---
function M.add_temporary_directory(path)
  table.insert(_TEMPORARY_DIRECTORIES, path)
end

--- Track `path` on-disk so it can be deleted later.
---
--- @param path string An absolute file on-disk to delete later.
---
function M.add_temporary_file(path)
  table.insert(_TEMPORARY_FILES, path)
end

--- Delete all temporary directories that have not been deleted yet.
function M.delete_all_temporary_directories()
  for _, path in ipairs(_TEMPORARY_DIRECTORIES) do
    if vim.fn.isdirectory(path) ~= 1 then
      vim.fn.delete(path)
    end
  end

  _TEMPORARY_DIRECTORIES = {}
end

--- Delete all temporary files that have not been deleted yet.
function M.delete_all_temporary_files()
  for _, path in ipairs(_TEMPORARY_FILES) do
    if vim.fn.filereadable(path) ~= 1 then
      vim.fn.delete(path)
    end
  end

  _TEMPORARY_FILES = {}
end

--- Keep track of the current configuration so it can be restored later.
---
--- @see restore_configuration
---
function M.keep_configuration()
  _CONFIGURATION = vim.tbl_deep_extend("force", configuration.DATA, {})
end

--- Keep track of Vim settings so it can be reverted later.
function M.keep_vim_options()
  _OPTIONS = {
    runtimepath = vim.o.runtimepath,
    spelllang = vim.o.spelllang,
    spellsuggest = vim.o.spellsuggest,
  }
end

--- Re-apply the configuration that was previously stored.
---
--- @see keep_configuration
---
function M.restore_configuration()
  configuration.DATA = _CONFIGURATION
end

--- Re-apply the Vim options that was previously stored.
---
--- @see keep_vim_options
---
function M.restore_vim_options()
  vim.o.runtimepath = _OPTIONS.runtimepath
  vim.o.spelllang = _OPTIONS.spelllang
  vim.o.spellsuggest = _OPTIONS.spellsuggest
end

return M
