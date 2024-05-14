--- All unittests that handle cursor movements.
---
--- @module 'tests.spellbound.go_to_spec'
---

local actions = require("spellbound._core.actions")
local configuration = require("spellbound._core.configuration")
local constant = require("spellbound._core.constant")

local common = require("tests.common")
local dictionary = require("tests.dictionary")
local testmate = require("tests.testmate")
local textmate = require("tests.textmate")

describe("go to - backwards", function()
  before_each(function()
    vim.o.wrapscan = true
    vim.wo.spell = false
    common.keep_configuration()
    common.keep_vim_options()
  end)

  after_each(function()
    vim.o.wrapscan = true
    common.restore_configuration()
    common.restore_vim_options()
    common.delete_all_temporary_files()
  end)

  it("does not run if spell is disabled on the buffer", function()
    vim.wo.spell = false
    local success, _ = pcall(actions.go_to_previous_recommendation)

    assert.falsy(success)
  end)

  it("does not move when on the only suggestion", function()
    configuration.DATA.behavior.wrap_previous_recommendation = true

    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some |end||start|suggestion.
    ---
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("wraps to the end if the configuration is set", function()
    configuration.DATA.behavior.wrap_previous_recommendation = true

    local template = [[
    --- |start|
    --- @param text Something with a |end|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("does not wrap to the end if the configuration is not set", function()
    vim.wo.spell = true

    if constant.is_builtin_mapping_supported() then
      vim.o.wrapscan = false
    end

    configuration.DATA.behavior.wrap_previous_recommendation = false

    local source = [[
    --- Some lines here.
    --- more lines
    ---
    --- @param text Some suggestion with another text.
    local function foo(text)
    end
    ]]

    local start_cursor = { 4, 5 }

    local window = textmate.switch_to_temporary_lua_buffer(source)
    vim.api.nvim_win_set_cursor(window, start_cursor)
    actions.go_to_previous_recommendation()
    assert.are.same(start_cursor, vim.api.nvim_win_get_cursor(window))
  end)

  it("wraps to the end even if the match is on the same line", function()
    vim.o.wrapscan = true
    configuration.DATA.behavior.wrap_previous_recommendation = true

    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- @param text Some |start|suggestion |end|suggestion with another text.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works from 1 characters away", function()
    local template = [[
    --- @param text Something with a |end|s|start|uggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works from 2 characters away", function()
    local template = [[
    --- @param text Something with a |end|su|start|ggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works from multiple lines away", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some |end|suggestion
    ---
    --- @param text Something with a |start| text.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works while currently on another recommendation - 001", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some suggestion.
    ---
    --- @param text Something with a |end|sug|start|gestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works with consecutive recommendations", function()
    local template = [[
    --- @param text |end|suggestion |start|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works with multiple recommendations on the same line - 001", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some suggestion.
    ---
    --- @param text suggestion Some suggestion with another |end|sug|start|gestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)

  it("works with multiple recommendations on the same line - 002", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some suggestion.
    ---
    --- @param text Some |end|suggestion with another |start|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.backwards
    )
  end)
end)

describe("go to - forwards", function()
  before_each(function()
    vim.o.wrapscan = true
    vim.wo.spell = false
    common.keep_configuration()
  end)

  after_each(function()
    vim.o.wrapscan = true
    common.restore_configuration()
    common.delete_all_temporary_files()
  end)

  it("does not run if spell is disabled on the buffer", function()
    local success, _ = pcall(actions.go_to_next_recommendation)

    assert.falsy(success)
  end)

  it("does not move when on the only suggestion", function()
    configuration.DATA.behavior.wrap_next_recommendation = true

    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some |end||start|suggestion.
    ---
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("wraps to the start if the configuration is set", function()
    configuration.DATA.behavior.wrap_next_recommendation = true

    local template = [[
    --- @param text Something with a |end|suggestion.
    local function foo(text)
      |start|
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("does not wrap to the start if the configuration is not set", function()
    vim.wo.spell = true

    if constant.is_builtin_mapping_supported() then
      vim.o.wrapscan = false
    end

    configuration.DATA.behavior.wrap_next_recommendation = false

    local source = [[
    --- Some lines here.
    --- more lines
    ---
    --- @param text Some suggestion with another text.
    local function foo(text)
    end
    ]]

    local start_cursor = { 4, 37 }

    local window = textmate.switch_to_temporary_lua_buffer(source)
    vim.api.nvim_win_set_cursor(window, start_cursor)
    actions.go_to_next_recommendation()
    assert.are.same(start_cursor, vim.api.nvim_win_get_cursor(window))
  end)

  it("wraps to the start even if the match is on the same line", function()
    configuration.DATA.behavior.wrap_next_recommendation = true

    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- @param text Some |end|suggestion |start|with another text.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works from one character away", function()
    local template = [[
    --- @param text Something with a|start| |end|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works from multiple lines away", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some |start|more.
    ---
    --- @param text Something with a |end|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works with consecutive recommendations", function()
    local template = [[
    --- @param text |start|suggestion |end|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works while currently on another recommendation - 001", function()
    configuration.DATA.behavior.wrap_next_recommendation = true

    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some |end|sug|start|gestion.
    ---
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works while currently on another recommendation - 002", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some sug|start|gestion |end|suggestion.
    ---
    --- @param text Something with a suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works while currently on another recommendation - 003", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some sug|start|gestion |end|suggestion.
    ---
    --- @param text Something with a suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works with multiple recommendations on the same line - 001", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some suggestion.
    ---
    --- @param text suggestion Some sug|start|gestion with another |end|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)

  it("works with multiple recommendations on the same line - 002", function()
    local template = [[
    --- Some lines here.
    --- more lines
    ---
    --- and some suggestion.
    ---
    --- @param text Some suggestion |start|with another |end|suggestion.
    local function foo(text)
    end
    ]]

    testmate.assert_go_to_lua(
      template,
      dictionary.TemporaryTestData:new("suggestion/?", "suggestion/other"),
      constant.Direction.forwards
    )
  end)
end)
