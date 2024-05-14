--- Make sure `spellbound` profile logic and commands work as expected.
---
--- @module 'tests.spellbound.profile_spec'
---

local build_profile = require("spellbound._core.commands.build_profile")
local configuration = require("spellbound._core.configuration")
local filer = require("spellbound._core.filer")
local last_modified_time =
  require("spellbound._core.compare_engines.last_modified_time")
local profile_manager = require("spellbound._core.commands.profile_manager")
local sha256 = require("spellbound._core.compare_engines.sha256")

local common = require("tests.common")

local _BUILD_ALL_DICTIONARIES
local _BUILD_PROFILE_DICTIONARIES
local _LAST_MODIFED_TIME_REMEMBER
local _SHA256_REMEMBER

--- Replace `path` with `lines`.
---
--- @param lines string[] Some text to set `path` with.
--- @param path string An absolute path that may exist on-disk. It will be replaced.
---
local function _write(lines, path)
  local handler = io.open(path, "w")

  if not handler then
    error(string.format('Path "%s" could not be written.', path))
  end

  handler:write(table.concat(lines, "\n"))
  handler:close()
end

--- Create some example "parts" of a dictionary.
---
--- @return string[] # All absolute paths on-disk to the created files.
---
local function _make_dictionary_parts()
  local lines = { "egg/S", "milk/D" }
  local path_1 = vim.fn.tempname() .. "_food.txt"
  _write(lines, path_1)

  lines = { "boat/S", "bus/S" }
  local path_2 = vim.fn.tempname() .. "_transportation.txt"
  _write(lines, path_2)

  return { path_1, path_2 }
end

describe("profile auto-build dictionary", function()
  before_each(function()
    _SHA256_REMEMBER = sha256.remember
    _LAST_MODIFED_TIME_REMEMBER = last_modified_time.remember
    _BUILD_ALL_DICTIONARIES = build_profile.build_profile_dictionaries
    _BUILD_PROFILE_DICTIONARIES = build_profile.build_dictionaries
    common.keep_configuration()
  end)

  after_each(function()
    sha256.remember = _SHA256_REMEMBER
    last_modified_time.remember = _LAST_MODIFED_TIME_REMEMBER
    build_profile.build_profile_dictionaries = _BUILD_ALL_DICTIONARIES
    build_profile.build_dictionaries = _BUILD_PROFILE_DICTIONARIES
    common.restore_configuration()
  end)

  it("builds the dictionary on-demand", function()
    local files = _make_dictionary_parts()
    local root = vim.fn.tempname()
    local dictionary_name = "example123"
    local output_path = vim.fs.joinpath(root, "spell", dictionary_name)

    for _, path in ipairs(files) do
      common.add_temporary_file(path)
    end

    common.add_temporary_file(output_path)

    configuration.DATA.profiles = {
      some_profile = {
        dictionaries = {
          {
            name = dictionary_name,
            input_paths = files,
            output_path = output_path,
            watcher = { run_on = { "start" }, calculation_method = "sha256" },
          },
        },
        runtimepath = {
          operation = "append",
          text = root,
        },
        spelllang = {
          operation = "append",
          text = dictionary_name,
        },
      },
    }

    local dictionary = output_path .. ".utf-8.spl"

    assert.is_falsy(vim.fn.filereadable(output_path) == 1)
    assert.is_falsy(vim.fn.filereadable(dictionary) == 1)

    vim.cmd([[Spellbound build-profile]])

    assert.is_truthy(vim.fn.filereadable(output_path) == 1)
    assert.is_truthy(vim.fn.filereadable(dictionary) == 1)
  end)

  it("builds all dictionaries if not profile is given", function()
    local dictionary_name = "something"

    configuration.DATA.profiles = {
      some_profile = {
        dictionaries = {
          {
            name = dictionary_name,
            input_paths = { "blah.txt" },
            output_path = "asdfasfd",
            watcher = { run_on = { "start" }, calculation_method = "sha256" },
          },
        },
      },
    }

    local count_build_all = 0
    local count_build_profile = 0

    local _count_build_profile_dictionaries = function()
      count_build_all = count_build_all + 1
    end

    local _count_build_dictionaries = function()
      count_build_profile = count_build_profile + 1
    end

    build_profile.build_profile_dictionaries = _count_build_profile_dictionaries
    build_profile.build_dictionaries = _count_build_dictionaries

    assert.equal(0, count_build_all)
    assert.equal(0, count_build_profile)
    vim.cmd([[Spellbound build-profile]])
    assert.equal(1, count_build_all)
    assert.equal(0, count_build_profile)

    assert.equal(0, count_build_profile)
    vim.cmd([[Spellbound build-profile some_profile]])
    assert.equal(1, count_build_profile)
    assert.equal(1, count_build_all)
  end)

  it("ignores duplicates", function()
    local lines = { "egg/S", "milk/D" }
    local path_1 = vim.fn.tempname() .. "_food_1.txt"
    _write(lines, path_1)

    lines = { "egg/Y", "onion/S" }
    local path_2 = vim.fn.tempname() .. "_food_2.txt"
    _write(lines, path_2)

    local files = { path_1, path_2 }

    local root = vim.fn.tempname()
    local dictionary_name = "duplicates123"
    local output_path = vim.fs.joinpath(root, "spell", dictionary_name)

    for _, path in ipairs(files) do
      common.add_temporary_file(path)
    end

    common.add_temporary_file(output_path)

    configuration.DATA.profiles = {
      some_profile = {
        dictionaries = {
          {
            name = dictionary_name,
            input_paths = files,
            output_path = output_path,
            watcher = { run_on = { "start" }, calculation_method = "sha256" },
          },
        },
        runtimepath = {
          operation = "append",
          text = root,
        },
        spelllang = {
          operation = "append",
          text = dictionary_name,
        },
      },
    }

    assert.is_falsy(vim.fn.filereadable(output_path) == 1)
    vim.cmd([[Spellbound build-profile]])
    local text = filer.read(output_path)
    local template = [[
# START - Generated %s file
egg/S
milk/D
# END - Generated %s file
# START - Generated %s file
onion/S
# END - Generated %s file]]
    assert.equal(string.format(template, path_1, path_1, path_2, path_2), text)
  end)

  it("re-builds only if a file has been changed - last_modified_time", function()
    local files = _make_dictionary_parts()
    local root = vim.fn.tempname()
    local dictionary_name = "example123"
    local output_path = vim.fs.joinpath(root, "spell", dictionary_name)

    for _, path in ipairs(files) do
      common.add_temporary_file(path)
    end

    common.add_temporary_file(output_path)

    configuration.DATA.profiles = {
      some_profile = {
        dictionaries = {
          {
            name = dictionary_name,
            input_paths = files,
            output_path = output_path,
            watcher = {
              run_on = { "start" },
              calculation_method = "last_modified_time",
            },
          },
        },
        runtimepath = {
          operation = "append",
          text = root,
        },
        spelllang = {
          operation = "append",
          text = dictionary_name,
        },
      },
    }

    local dictionary = output_path .. ".utf-8.spl"

    assert.is_falsy(vim.fn.filereadable(output_path) == 1)
    assert.is_falsy(vim.fn.filereadable(dictionary) == 1)

    vim.cmd([[Spellbound build-profile]])

    local count = 0

    local function _count_remember(_)
      count = count + 1
    end

    last_modified_time.remember = _count_remember
    vim.cmd([[Spellbound build-profile]])
    assert.equal(0, count)
  end)

  it("re-builds only if a file has been changed - sha256", function()
    local files = _make_dictionary_parts()
    local root = vim.fn.tempname()
    local dictionary_name = "example123"
    local output_path = vim.fs.joinpath(root, "spell", dictionary_name)

    for _, path in ipairs(files) do
      common.add_temporary_file(path)
    end

    common.add_temporary_file(output_path)

    configuration.DATA.profiles = {
      some_profile = {
        dictionaries = {
          {
            name = dictionary_name,
            input_paths = files,
            output_path = output_path,
            watcher = { run_on = { "start" }, calculation_method = "sha256" },
          },
        },
        runtimepath = {
          operation = "append",
          text = root,
        },
        spelllang = {
          operation = "append",
          text = dictionary_name,
        },
      },
    }

    local dictionary = output_path .. ".utf-8.spl"

    assert.is_falsy(vim.fn.filereadable(output_path) == 1)
    assert.is_falsy(vim.fn.filereadable(dictionary) == 1)

    vim.cmd([[Spellbound build-profile]])

    local count = 0

    local function _count_remember(_)
      count = count + 1
    end

    sha256.remember = _count_remember
    vim.cmd([[Spellbound build-profile]])
    assert.equal(0, count)
  end)
end)

describe("profile switch", function()
  before_each(function()
    vim.g.spellbound_active_profile = nil
    profile_manager.PROFILE_STACK = {}
    common.keep_configuration()
    common.keep_vim_options()
  end)

  after_each(function()
    common.restore_configuration()
    common.restore_vim_options()
  end)

  it("can replace from one profile to another and back as expected", function()
    configuration.DATA.profiles = {
      test_profile_a = {
        runtimepath = {
          operation = "append",
          text = "/test/profile_a",
        },
        spelllang = {
          operation = "append",
          text = "test_profile_a",
        },
        spellsuggest = {
          operation = "append",
          text = "file:/tmp/test_profile_a_thesaurus.txt",
        },
      },
      test_profile_b = {
        runtimepath = {
          operation = "replace",
          text = "/test/profile_b",
        },
        spelllang = {
          operation = "replace",
          text = "test_profile_b",
        },
        spellsuggest = {
          operation = "replace",
          text = "file:/tmp/test_profile_b_thesaurus.txt",
        },
      },
    }

    vim.o.runtimepath = "foo"
    vim.o.spelllang = "en_us"
    vim.o.spellsuggest = "best"

    profile_manager.toggle_profile("test_profile_a")

    vim.o.runtimepath = vim.o.runtimepath .. ",bar"
    vim.o.spelllang = vim.o.spelllang .. ",cjk"
    vim.o.spellsuggest = vim.o.spellsuggest .. ",file:/foo/another.txt"

    assert.equal("foo,/test/profile_a,bar", vim.o.runtimepath)
    assert.equal("en_us,test_profile_a,cjk", vim.o.spelllang)
    assert.equal(
      "best,file:/tmp/test_profile_a_thesaurus.txt,file:/foo/another.txt",
      vim.o.spellsuggest
    )

    profile_manager.toggle_profile("test_profile_b")

    assert.equal("/test/profile_b", vim.o.runtimepath)
    assert.equal("test_profile_b", vim.o.spelllang)
    assert.equal("file:/tmp/test_profile_b_thesaurus.txt", vim.o.spellsuggest)

    profile_manager.toggle_profile("test_profile_b")

    assert.equal("foo,/test/profile_a,bar", vim.o.runtimepath)
    assert.equal("en_us,test_profile_a,cjk", vim.o.spelllang)
    assert.equal(
      "best,file:/tmp/test_profile_a_thesaurus.txt,file:/foo/another.txt",
      vim.o.spellsuggest
    )
  end)

  it("can switch from one profile to another and back as expected", function()
    configuration.DATA.profiles = {
      test_profile_a = {
        runtimepath = {
          operation = "append",
          text = "/test/profile_a",
        },
        spelllang = {
          operation = "append",
          text = "test_profile_a",
        },
        spellsuggest = {
          operation = "append",
          text = "file:/tmp/test_profile_a_thesaurus.txt",
        },
      },
      test_profile_b = {
        runtimepath = {
          operation = "append",
          text = "/test/profile_b",
        },
        spelllang = {
          operation = "append",
          text = "test_profile_b",
        },
        spellsuggest = {
          operation = "append",
          text = "file:/tmp/test_profile_b_thesaurus.txt",
        },
      },
    }

    vim.o.runtimepath = "foo"
    vim.o.spelllang = "en_us"
    vim.o.spellsuggest = "best"

    profile_manager.toggle_profile("test_profile_a")

    vim.o.runtimepath = vim.o.runtimepath .. ",bar"
    vim.o.spelllang = vim.o.spelllang .. ",cjk"
    vim.o.spellsuggest = vim.o.spellsuggest .. ",file:/foo/another.txt"

    assert.equal("foo,/test/profile_a,bar", vim.o.runtimepath)
    assert.equal("en_us,test_profile_a,cjk", vim.o.spelllang)
    assert.equal(
      "best,file:/tmp/test_profile_a_thesaurus.txt,file:/foo/another.txt",
      vim.o.spellsuggest
    )

    profile_manager.toggle_profile("test_profile_b")

    assert.equal("foo,/test/profile_a,bar,/test/profile_b", vim.o.runtimepath)
    assert.equal("en_us,test_profile_a,cjk,test_profile_b", vim.o.spelllang)
    assert.equal(
      "best,file:/tmp/test_profile_a_thesaurus.txt,file:/foo/another.txt,file:/tmp/test_profile_b_thesaurus.txt",
      vim.o.spellsuggest
    )

    profile_manager.toggle_profile("test_profile_b")

    assert.equal("foo,/test/profile_a,bar", vim.o.runtimepath)
    assert.equal("en_us,test_profile_a,cjk", vim.o.spelllang)
    assert.equal(
      "best,file:/tmp/test_profile_a_thesaurus.txt,file:/foo/another.txt",
      vim.o.spellsuggest
    )
  end)
end)

describe("profile toggle", function()
  before_each(function()
    common.keep_configuration()
    common.keep_vim_options()
  end)

  after_each(function()
    common.restore_configuration()
    common.restore_vim_options()
  end)

  it("errors with no defined profiles", function()
    configuration.DATA.profiles = {}

    assert.has_error(function()
      profile_manager.toggle_profile("some_profile")
    end)
  end)

  it("errors with an incorrect profile", function()
    configuration.DATA.profiles = { a_profile_name = {} }

    assert.has_error(function()
      profile_manager.toggle_profile("does_not_exist")
    end)
  end)

  it("works with the default profile", function()
    configuration.DATA.profiles = {
      test_profile = {
        runtimepath = {
          operation = "append",
          text = "/test/path",
        },
        spelllang = {
          operation = "append",
          text = "test_dictionary",
        },
        spellsuggest = {
          operation = "append",
          text = "file:/tmp/test_profile_thesaurus.txt",
        },
      },
    }

    vim.o.runtimepath = "foo"
    vim.o.spelllang = "en_us"
    vim.o.spellsuggest = "best"

    profile_manager.toggle_profile("test_profile")

    vim.o.runtimepath = vim.o.runtimepath .. ",bar"
    vim.o.spelllang = vim.o.spelllang .. ",cjk"
    vim.o.spellsuggest = vim.o.spellsuggest .. ",file:/foo/another.txt"

    assert.equal("foo,/test/path,bar", vim.o.runtimepath)
    assert.equal("en_us,test_dictionary,cjk", vim.o.spelllang)
    assert.equal(
      "best,file:/tmp/test_profile_thesaurus.txt,file:/foo/another.txt",
      vim.o.spellsuggest
    )

    profile_manager.toggle_profile("test_profile")

    assert.equal("foo", vim.o.runtimepath)
    assert.equal("en_us", vim.o.spelllang)
    assert.equal("best", vim.o.spellsuggest)
  end)
end)
