describe("fim.providers.codestral", function()
  local codestral

  before_each(function()
    -- Clear loaded modules to get fresh state
    package.loaded["fim.providers.codestral"] = nil
    codestral = require("fim.providers.codestral")
  end)

  describe("validate_config", function()
    it("should error if provider config is nil", function()
      local ok, err = codestral.validate_config(nil)
      assert.is_false(ok)
      assert.truthy(err:match("codestral provider config is required"))
    end)

    it("should error if api_key_provider is not a function", function()
      local ok, err = codestral.validate_config({
        api_key_provider = "not-a-function",
        endpoint = "https://test.com",
      })
      assert.is_false(ok)
      assert.truthy(err:match("api_key_provider must be a function"))
    end)

    it("should error if endpoint is empty", function()
      local ok, err = codestral.validate_config({
        api_key_provider = function() return "test" end,
        endpoint = "",
      })
      assert.is_false(ok)
      assert.truthy(err:match("endpoint must be configured"))
    end)

    it("should error if endpoint is nil", function()
      local ok, err = codestral.validate_config({
        api_key_provider = function() return "test" end,
      })
      assert.is_false(ok)
      assert.truthy(err:match("endpoint must be configured"))
    end)

    it("should pass with valid config", function()
      local ok, err = codestral.validate_config({
        api_key_provider = function() return "test" end,
        endpoint = "https://codestral.mistral.ai/v1/fim/completions",
      })
      assert.is_true(ok)
      assert.is_nil(err)
    end)
  end)

  -- Note: Async request_completion tests are difficult to test reliably
  -- in Busted due to timing. Key validation logic is tested above.

  describe("provider interface", function()
    it("should have name field", function()
      assert.equals("codestral", codestral.name)
    end)

    it("should have request_completion function", function()
      assert.is_function(codestral.request_completion)
    end)

    it("should have validate_config function", function()
      assert.is_function(codestral.validate_config)
    end)
  end)
end)
