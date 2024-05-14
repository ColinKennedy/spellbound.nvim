--- Make it easier to create dictionary and thesaurus files for Neovim unittests.
---
--- @module 'tests.dictionary'
---

local common = require("tests.common")

local _LOGGER = require("_spellbound_vendors.vlog")

local M = {}

--- @class TemporaryTestData
---     A collection dictionary and thesaurus data used for unittests.
--- @field runtimepath string
---     The directory on-disk where you can find a spell/ folder with some dictionary.
--- @field spelllang string
---     A temporary dictionary needed for unittests.
--- @field spellsuggest string
---     The URI that points to the temporary thesaurus file.

M.TemporaryTestData = {}

--- Make a dictionary on-disk and delete it later.
---
--- @param language string The name of the dictionary language to write.
--- @param text string The data to add into the dictionary.
--- @return string? # The created dictionary path on-disk.
---
local function _create_temporary_dictionary(language, text)
  local path = vim.fn.tempname() .. "_temporary_dictionary_" .. language
  vim.fn.delete(path) -- We don't want a path, we want a directory

  common.add_temporary_directory(path)
  local spell = vim.fs.joinpath(path, "spell")
  vim.fn.mkdir(spell, "p")
  local dictionary = vim.fs.joinpath(spell, language)

  local handler = io.open(dictionary, "w")

  if not handler then
    return nil
  end

  handler:write(text)
  handler:close()

  vim.cmd("silent! mkspell! " .. dictionary)

  return dictionary
end

--- Make a temporary path on-disk with `text` as its data.
---
--- @param text string A blob of ASCII to add into the new file.
--- @return string? # The created file path, if any.
---
local function _create_temporary_thesaurus(text)
  local path = vim.fn.tempname() .. "_thesaurus.txt"
  local handler = io.open(path, "w")

  if not handler then
    error(string.format('Path "%s" could not be created.', path))

    return nil
  end

  handler:write(text)
  handler:close()

  common.add_temporary_file(path)

  return path
end

--- Create temporary dictionary and thesaurus files in a single structure.
---
--- @param dictionary string The blob of text used to create a temporary dictionary file.
--- @param recommendations string The blob of text used to create a new thesaurus file.
---
function M.TemporaryTestData:new(dictionary, recommendations)
  local obj = {}

  obj.spelllang = "testdictionary"
  local path = _create_temporary_dictionary(obj.spelllang, dictionary)

  if not path then
    _LOGGER.fmt_error('Unable to create a temporary "%s" dictionary.', obj.spelllang)

    return nil
  end

  obj.runtimepath = vim.fn.fnamemodify(vim.fn.fnamemodify(path, ":h"), ":h")
  obj.spellsuggest = "file:" .. _create_temporary_thesaurus(recommendations)

  setmetatable(obj, self)
  self.__index = self

  return obj
end

return M
