describe("fim.providers", function()
  local providers

  before_each(function()
    package.loaded["fim.providers"] = nil
    package.loaded["fim.providers.codestral"] = nil
    providers = require("fim.providers")
    providers.providers = {}
  end)

  it("registers and returns provider", function()
    local p = { request_completion = function() end }
    providers.register("x", p)
    assert.equals(p, providers.get("x"))
  end)

  it("lazy loads provider modules", function()
    local p = providers.get("codestral")
    assert.is_not_nil(p)
    assert.equals("codestral", p.name)
    assert.equals(p, providers.providers.codestral)
  end)

  it("returns nil for missing provider", function()
    assert.is_nil(providers.get("does_not_exist"))
  end)

  it("validate fails when provider missing", function()
    local ok, err = providers.validate("does_not_exist")
    assert.is_false(ok)
    assert.truthy(err:match("not found"))
  end)

  it("validate fails when request_completion missing", function()
    providers.register("broken", {})
    local ok, err = providers.validate("broken")
    assert.is_false(ok)
    assert.truthy(err:match("missing request_completion"))
  end)

  it("validate passes for valid provider", function()
    providers.register("ok", { request_completion = function() end })
    local ok, err = providers.validate("ok")
    assert.is_true(ok)
    assert.is_nil(err)
  end)
end)
