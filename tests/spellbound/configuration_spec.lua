--- All unittests to make sure a user's configuration is correct.
---
--- @module 'tests.spellbound.configuration_spec'
---

local common = require("tests.common")
local spellbound = require("spellbound")

--- Make sure `data` fails to validate.
---
--- @param data SpellboundConfiguration The user data to check.
---
local function _assert_bad_configuration(data)
  local success, _ = pcall(spellbound.setup, data)

  if success then
    error(string.format('Data "%s" did not fail.', vim.inspect(data)))

    return
  end
end

--- Make sure `data` validates as expected.
---
--- @param data Configuration The user data to check.
---
local function _assert_good_configuration(data)
  local success, _ = pcall(spellbound.setup, data)

  if not success then
    error(string.format('Data "%s" did not succeed.', vim.inspect(data)))

    return
  end
end

describe("validate configuration - behavior", function()
  before_each(function()
    common.keep_configuration()
  end)

  after_each(function()
    common.restore_configuration()
    common.delete_all_temporary_files()
  end)

  it("find bad", function()
    _assert_bad_configuration({ behavior = false })
    _assert_bad_configuration({ behavior = { wrap_next_recommendation = "asdf" } })
    _assert_bad_configuration({ behavior = { wrap_previous_recommendation = "asdf" } })
  end)

  it("find a good value - empty", function()
    _assert_good_configuration({ behavior = {} })
  end)

  it("find a good wrap_next_recommendation value", function()
    _assert_good_configuration({ behavior = { wrap_next_recommendation = false } })
    _assert_good_configuration({ behavior = { wrap_next_recommendation = true } })
    _assert_good_configuration({
      behavior = {
        wrap_next_recommendation = function()
          return false
        end,
      },
    })
  end)

  it("find a good wrap_previous_recommendation value", function()
    _assert_good_configuration({ behavior = { wrap_previous_recommendation = false } })
    _assert_good_configuration({ behavior = { wrap_previous_recommendation = true } })
    _assert_good_configuration({
      behavior = {
        wrap_previous_recommendation = function()
          return false
        end,
      },
    })
  end)
end)

describe("validate configuration - logging", function()
  before_each(function()
    common.keep_configuration()
  end)

  after_each(function()
    common.restore_configuration()
    common.delete_all_temporary_files()
  end)

  it("find bad", function()
    _assert_bad_configuration({ logging = false })
    _assert_bad_configuration({ logging = { level = 1 } })
    _assert_bad_configuration({ logging = { level = "does_not_exist" } })
    _assert_bad_configuration({ logging = { use_console = "asdf" } })
    _assert_bad_configuration({ logging = { use_file = "asdf" } })
  end)

  it("find a good value - empty", function()
    _assert_good_configuration({ logging = {} })
  end)

  it("find a good level value", function()
    _assert_good_configuration({ logging = { level = "trace" } })
    _assert_good_configuration({ logging = { level = "debug" } })
    _assert_good_configuration({ logging = { level = "info" } })
    _assert_good_configuration({ logging = { level = "warn" } })
    _assert_good_configuration({ logging = { level = "error" } })
  end)

  it("find a good use_console value", function()
    _assert_good_configuration({ logging = { use_console = false } })
    _assert_good_configuration({ logging = { use_console = true } })
  end)

  it("find a good use_file value", function()
    _assert_good_configuration({ logging = { use_file = false } })
    _assert_good_configuration({ logging = { use_file = true } })
  end)
end)

describe("validate configuration - profiles", function()
  it("find bad", function()
    _assert_bad_configuration({ profiles = false })
    _assert_bad_configuration({ profiles = { some_profile = 1 } })
    _assert_bad_configuration({ profiles = { some_profile = { runtimepath = 123 } } })
    _assert_bad_configuration({ profiles = { some_profile = { runtimepath = {} } } })
    _assert_bad_configuration({
      profiles = {
        some_profile = { runtimepath = { operation = "not_supported", text = "asdf" } },
      },
    })
    _assert_bad_configuration({
      profiles = {
        some_profile = { runtimepath = { operation = "append", text = 123 } },
      },
    })
    _assert_bad_configuration({ profiles = { some_profile = { spelllang = 123 } } })
    _assert_bad_configuration({ profiles = { some_profile = { spelllang = {} } } })
    _assert_bad_configuration({
      profiles = {
        some_profile = { spelllang = { operation = "not_supported", text = "asdf" } },
      },
    })
    _assert_bad_configuration({
      profiles = { some_profile = { spelllang = { operation = "append", text = 123 } } },
    })
    _assert_bad_configuration({ profiles = { some_profile = { spellsuggest = 123 } } })
    _assert_bad_configuration({ profiles = { some_profile = { spellsuggest = {} } } })
    _assert_bad_configuration({
      profiles = {
        some_profile = { spellsuggest = { operation = "not_supported", text = "asdf" } },
      },
    })
    _assert_bad_configuration({
      profiles = {
        some_profile = { spellsuggest = { operation = "append", text = 123 } },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {},
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = { { name = 123 } },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              watcher = { calculation_method = 123 },
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              watcher = { calculation_method = "asdfasdf" },
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              input_paths = "asdfasdf",
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              input_paths = { 123 },
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              output_path = { 123 },
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              output_path = {},
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              output_path = 123,
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              watcher = true,
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              name = "foo",
              input_paths = { "asdfasfd", "asdfasfasfd" },
              output_path = "asdfasfd",
              -- NOTE: `run_on` needs to be a `string[]`, not `string`
              watcher = { run_on = "start" },
            },
          },
        },
      },
    })

    _assert_bad_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              name = "foo",
              input_paths = { "asdfasfd", "asdfasfasfd" },
              output_path = "asdfasfd",
              -- NOTE: `run_on` needs to be a `string[]`, not `string`
              watcher = { run_on = { "start" }, calculation_method = "not_supported" },
            },
          },
        },
      },
    })

    _assert_good_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              name = "foo",
              watcher = false,
              input_paths = { "asdfasfd", "asdfasfasfd" },
              output_path = "asdfasfd",
            },
          },
        },
      },
    })

    _assert_good_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              name = "foo",
              watcher = { run_on = { "start" }, calculation_method = "sha256" },
              input_paths = { "asdfasfd", "asdfasfasfd" },
              output_path = "asdfasfd",
            },
          },
          runtimepath = { operation = "append", text = "something" },
          spelllang = { operation = "append", text = "something" },
          spellsuggest = { operation = "append", text = "something" },
        },
      },
    })
    _assert_good_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            {
              name = "foo",
              watcher = {
                run_on = { "start" },
                calculation_method = "last_modified_time",
              },
              input_paths = { "asdfasfd", "asdfasfasfd" },
              output_path = "asdfasfd",
            },
          },
          runtimepath = { operation = "append", text = "something" },
          spelllang = { operation = "append", text = "something" },
          spellsuggest = { operation = "append", text = "something" },
        },
      },
    })
    _assert_good_configuration({
      profiles = {
        some_profile = {
          dictionaries = {
            name = "foo",
            input_paths = function()
              return { "asdfasfd", "asdfasfasfd" }
            end,
            output_path = function()
              return "asdfasfd"
            end,
            watcher = { calculation_method = "sha256" },
          },
          runtimepath = {
            operation = "append",
            text = function()
              return "asdf"
            end,
          },
          spelllang = { operation = "append", text = "something" },
          spellsuggest = {
            operation = "append",
            text = function()
              return "asdf"
            end,
          },
        },
      },
    })
    _assert_good_configuration({
      profiles = {
        some_profile = {
          runtimepath = { operation = "append", text = "something" },
          spelllang = { operation = "replace", text = "something" },
          spellsuggest = { operation = "replace", text = "something" },
        },
      },
    })
  end)
end)
