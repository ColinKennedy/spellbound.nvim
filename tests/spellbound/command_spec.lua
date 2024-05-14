--- All unittests that handle cursor movements.
---
--- @module 'tests.spellbound.command_spec'
---

describe("edit all-recommendations", function()
  before_each(function()
    vim.cmd([[%bwipeout!]])
  end)

  it("works with 0 paths", function()
    vim.o.spellsuggest = ""
    local buffers = vim.api.nvim_list_bufs()

    vim.cmd([[Spellbound edit all-recommendations]])

    assert.are.same(buffers, vim.api.nvim_list_bufs())
  end)

  it("works with 1 path", function()
    local path = vim.fn.tempname() .. ".txt"
    vim.o.spellsuggest = "file:" .. path
    local buffers = #vim.api.nvim_list_bufs()

    vim.cmd("edit " .. vim.fn.tempname())
    vim.cmd([[Spellbound edit all-recommendations]])

    assert.are.same(buffers + 1, #vim.api.nvim_list_bufs())
  end)

  it("works with 2 paths", function()
    local path_1 = vim.fn.tempname() .. ".txt"
    local path_2 = vim.fn.tempname() .. ".txt"
    vim.o.spellsuggest = "file:" .. path_1 .. ",file:" .. path_2
    local buffers = #vim.api.nvim_list_bufs()

    vim.cmd("edit " .. vim.fn.tempname())
    vim.cmd([[Spellbound edit all-recommendations]])

    assert.are.same(buffers + 2, #vim.api.nvim_list_bufs())
  end)
end)
