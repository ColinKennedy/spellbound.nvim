--- Anything to make dealing with files and directories easier in Lua.
---
--- @module 'spellbound._core.filer'
---

local M = {}

-- os specific path separator
M.PATH_SEPARATOR = package.config:sub(1, 1)

--- Make sure the parent directory `path` exists, if it doesn't already.
---
--- @param path string Some file path that may or may not exist on-disk.
---
function M.make_parent_directory(path)
  local directory = vim.fn.fnamemodify(path, ":h")

  if vim.fn.isdirectory(directory) ~= 1 then
    vim.fn.mkdir(directory, "p")
  end
end

--- Read the text from `path`.
---
--- @param path string An absolute path to a file on-disk.
--- @return string? # The found text, if any.
---
function M.read(path)
  local handler = io.open(path, "r")

  if not handler then
    error(string.format('Path "%s" could not be read.', path))

    return nil
  end

  local result = handler:read("*a")
  handler:close()

  return result
end

--- Write `text` to `path`.
---
--- @param text string A blob of text to replace `path` with.
--- @param path string A path on-disk that will be written to.
---
function M.write(text, path)
  local handler = io.open(path, "w")

  if not handler then
    error(string.format('Path "%s" is not writeable.', path))
  end

  handler:write(text)
  handler:close()
end

return M
