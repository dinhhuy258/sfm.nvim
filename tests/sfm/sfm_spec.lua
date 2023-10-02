local file_nesting_trie = require "sfm.utils.file_nesting_trie"

describe("test SufTrie", function()
  it("exact matches", function()
    local t = file_nesting_trie.SufTrie.new()
    t:add(".npmrc", "MyKey")

    assert.are.same({ "MyKey" }, t:get ".npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({}, t:get "a.npmrc")
  end)

  it("star matches", function()
    local t = file_nesting_trie.SufTrie.new()
    t:add("*.npmrc", "MyKey")

    assert.are.same({ "MyKey" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "MyKey" }, t:get "a.npmrc")
    assert.are.same({ "MyKey" }, t:get "a.b.c.d.npmrc")
  end)

  it("star substitutes", function()
    local t = file_nesting_trie.SufTrie.new()
    t:add("*.npmrc", "${capture}.json")

    assert.are.same({ ".json" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "a.json" }, t:get "a.npmrc")
    assert.are.same({ "a.b.c.d.json" }, t:get "a.b.c.d.npmrc")
  end)

  it("multi matches", function()
    local t = file_nesting_trie.SufTrie.new()
    t:add("*.npmrc", "Key1")
    t:add("*.json", "Key2")
    t:add("*d.npmrc", "Key3")

    assert.are.same({ "Key1" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "Key2" }, t:get ".json")
    assert.are.same({ "Key2" }, t:get "a.json")
    assert.are.same({ "Key1" }, t:get "a.npmrc")
    assert.are.same({ "Key1", "Key3" }, t:get "a.b.c.d.npmrc")
  end)

  it("multi substitutes", function()
    local t = file_nesting_trie.SufTrie.new()
    t:add("*.npmrc", "Key1.${capture}.js")
    t:add("*.json", "Key2.${capture}.js")
    t:add("*d.npmrc", "Key3.${capture}.js")

    assert.are.same({ "Key1..js" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "Key2..js" }, t:get ".json")
    assert.are.same({ "Key2.a.js" }, t:get "a.json")
    assert.are.same({ "Key1.a.js" }, t:get "a.npmrc")
    assert.are.same({ "Key1.a.b.cd.js", "Key3.a.b.c.js" }, t:get "a.b.cd.npmrc")
    assert.are.same({ "Key1.a.b.c.d.js", "Key3.a.b.c..js" }, t:get "a.b.c.d.npmrc")
  end)
end)

describe("test PreTrie", function()
  it("exact matches", function()
    local t = file_nesting_trie.PreTrie.new()
    t:add(".npmrc", "MyKey")

    assert.are.same({ "MyKey" }, t:get ".npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({}, t:get "a.npmrc")
  end)

  it("star matches", function()
    local t = file_nesting_trie.PreTrie.new()
    t:add("*.npmrc", "MyKey")

    assert.are.same({ "MyKey" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "MyKey" }, t:get "a.npmrc")
    assert.are.same({ "MyKey" }, t:get "a.b.c.d.npmrc")
  end)

  it("star substitutes", function()
    local t = file_nesting_trie.PreTrie.new()
    t:add("*.npmrc", "${capture}.json")

    assert.are.same({ ".json" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "a.json" }, t:get "a.npmrc")
    assert.are.same({ "a.b.c.d.json" }, t:get "a.b.c.d.npmrc")
  end)

  it("multi matches", function()
    local t = file_nesting_trie.PreTrie.new()
    t:add("*.npmrc", "Key1")
    t:add("*.json", "Key2")
    t:add("*d.npmrc", "Key3")

    assert.are.same({ "Key1" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "Key2" }, t:get ".json")
    assert.are.same({ "Key2" }, t:get "a.json")
    assert.are.same({ "Key1" }, t:get "a.npmrc")
    assert.are.same({ "Key1", "Key3" }, t:get "a.b.c.d.npmrc")
  end)

  it("multi substitutes", function()
    local t = file_nesting_trie.PreTrie.new()
    t:add("*.npmrc", "Key1.${capture}.js")
    t:add("*.json", "Key2.${capture}.js")
    t:add("*d.npmrc", "Key3.${capture}.js")

    assert.are.same({ "Key1..js" }, t:get ".npmrc")
    assert.are.same({}, t:get "npmrc")
    assert.are.same({}, t:get ".npmrcs")
    assert.are.same({ "Key2..js" }, t:get ".json")
    assert.are.same({ "Key2.a.js" }, t:get "a.json")
    assert.are.same({ "Key1.a.js" }, t:get "a.npmrc")
    assert.are.same({ "Key1.a.b.cd.js", "Key3.a.b.c.js" }, t:get "a.b.cd.npmrc")
    assert.are.same({ "Key1.a.b.c.d.js", "Key3.a.b.c..js" }, t:get "a.b.c.d.npmrc")
  end)

  it("empty matches", function()
    local t = file_nesting_trie.PreTrie.new()
    t:add("package*json", "package")

    assert.are.same({ "package" }, t:get "package.json")
    assert.are.same({ "package" }, t:get "packagejson")
    assert.are.same({ "package" }, t:get "package-lock.json")
  end)
end)

describe("test FileNestingTrie", function()
  it("does added extension nesting", function()
    local trie = file_nesting_trie.FileNestingTrie.new {
      {
        "*",
        {
          "${capture}.*",
        },
      },
    }

    local nested_files = trie:nest {
      "file",
      "file.json",
      "boop.test",
      "boop.test1",
      "boop.test.1",
      "beep",
      "beep.test1",
      "beep.boop.test1",
      "beep.boop.test2",
      "beep.boop.a",
    }

    assert.equal(4, vim.tbl_count(nested_files))
    assert.are.same({ "file.json" }, nested_files["file"])
    assert.are.same({ "boop.test.1" }, nested_files["boop.test"])
    assert.are.same({}, nested_files["boop.test1"])
    assert.are.same({ "beep.test1", "beep.boop.test1", "beep.boop.test2", "beep.boop.a" }, nested_files["beep"])
  end)

  it("does ext specific nesting", function()
    local trie = file_nesting_trie.FileNestingTrie.new {
      {
        "*.ts",
        {
          "${capture}.js",
        },
      },
      {
        "*.js",
        {
          "${capture}.map",
        },
      },
    }

    local nested_files = trie:nest {
      "a.ts",
      "a.js",
      "a.jss",
      "ab.js",
      "b.js",
      "b.map",
      "c.ts",
      "c.js",
      "c.map",
      "d.ts",
      "d.map",
    }

    assert.equal(7, vim.tbl_count(nested_files))

    assert.are.same({ "a.js" }, nested_files["a.ts"])
    assert.are.same({}, nested_files["ab.js"])
    assert.are.same({}, nested_files["a.jss"])
    assert.are.same({ "b.map" }, nested_files["b.js"])
    assert.are.same({ "c.js", "c.map" }, nested_files["c.ts"])
    assert.are.same({}, nested_files["d.ts"])
    assert.are.same({}, nested_files["d.map"])
  end)

  it("handles loops", function()
    local trie = file_nesting_trie.FileNestingTrie.new {
      { "*.a", { "${capture}.b", "${capture}.c" } },
      { "*.b", { "${capture}.a" } },
      { "*.c", { "${capture}.d" } },

      { "*.aa", { "${capture}.bb" } },
      { "*.bb", { "${capture}.cc", "${capture}.dd" } },
      { "*.cc", { "${capture}.aa" } },
      { "*.dd", { "${capture}.ee" } },
    }

    local nested_files = trie:nest {
      ".a",
      ".b",
      ".c",
      ".d",
      "a.a",
      "a.b",
      "a.d",
      "a.aa",
      "a.bb",
      "a.cc",
      "b.aa",
      "b.bb",
      "c.bb",
      "c.cc",
      "d.aa",
      "d.cc",
      "e.aa",
      "e.bb",
      "e.dd",
      "e.ee",
      "f.aa",
      "f.bb",
      "f.cc",
      "f.dd",
      "f.ee",
    }

    assert.equal(19, vim.tbl_count(nested_files))

    assert.are.same({}, nested_files[".a"])
    assert.are.same({}, nested_files[".b"])
    assert.are.same({}, nested_files[".c"])
    assert.are.same({}, nested_files[".d"])

    assert.are.same({}, nested_files["a.a"])
    assert.are.same({}, nested_files["a.b"])
    assert.are.same({}, nested_files["a.d"])

    assert.are.same({}, nested_files["a.aa"])
    assert.are.same({}, nested_files["a.bb"])
    assert.are.same({}, nested_files["a.cc"])

    assert.are.same({ "b.bb" }, nested_files["b.aa"])
    assert.are.same({ "c.cc" }, nested_files["c.bb"])
    assert.are.same({ "d.aa" }, nested_files["d.cc"])
    assert.are.same({ "e.bb", "e.dd", "e.ee" }, nested_files["e.aa"])

    assert.are.same({}, nested_files["f.aa"])
    assert.are.same({}, nested_files["f.bb"])
    assert.are.same({}, nested_files["f.cc"])
    assert.are.same({}, nested_files["f.dd"])
    assert.are.same({}, nested_files["f.ee"])
  end)

  it("does general bidirectional suffix matching", function()
    local trie = file_nesting_trie.FileNestingTrie.new {
      { "*-vsdoc.js", { "${capture}.js" } },
      { "*.js", { "${capture}-vscdoc.js" } },
    }

    local nested_files = trie:nest {
      "a-vsdoc.js",
      "a.js",
      "b.js",
      "b-vscdoc.js",
    }

    assert.equal(2, vim.tbl_count(nested_files))
    assert.are.same({ "a.js" }, nested_files["a-vsdoc.js"])
    assert.are.same({ "b-vscdoc.js" }, nested_files["b.js"])
  end)

  it("does general bidirectional prefix matching", function()
    local trie = file_nesting_trie.FileNestingTrie.new {
      { "vsdoc-*.js", { "${capture}.js" } },
      { "*.js", { "vscdoc-${capture}.js" } },
    }

    local nested_files = trie:nest {
      "vsdoc-a.js",
      "a.js",
      "b.js",
      "vscdoc-b.js",
    }

    assert.equal(2, vim.tbl_count(nested_files))
    assert.are.same({ "a.js" }, nested_files["vsdoc-a.js"])
    assert.are.same({ "vscdoc-b.js" }, nested_files["b.js"])
  end)
end)
