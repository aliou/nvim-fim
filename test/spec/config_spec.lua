describe("fim.config", function()
  local config

  before_each(function()
    -- Clear loaded modules to get fresh state
    package.loaded["fim.config"] = nil
    package.loaded["fim.providers"] = nil
    package.loaded["fim.providers.codestral"] = nil
    config = require("fim.config")
  end)

  describe("defaults", function()
    it("should have nil provider by default (must be set by user)", function()
      assert.is_nil(config.defaults.provider)
    end)

    it("should have codestral defaults", function()
      assert.equals("https://codestral.mistral.ai/v1/fim/completions", config.defaults.codestral.endpoint)
      assert.equals("codestral-latest", config.defaults.codestral.model)
      assert.equals(256, config.defaults.codestral.max_tokens)
      assert.is_nil(config.defaults.codestral.stop)
    end)

    it("should have valid default context settings", function()
      assert.equals(100, config.defaults.context.prefix_lines)
      assert.equals(30, config.defaults.context.suffix_lines)
      assert.equals(4000, config.defaults.context.max_prefix_chars)
      assert.equals(1000, config.defaults.context.max_suffix_chars)
    end)

    it("should have default debounce_ms", function()
      assert.equals(50, config.defaults.debounce_ms)
    end)

    it("should have default highlight group", function()
      assert.equals("Comment", config.defaults.highlight)
    end)

    it("should have default keymaps", function()
      assert.equals("<Tab>", config.defaults.keymaps.accept)
      assert.equals("<C-Right>", config.defaults.keymaps.accept_word)
      assert.equals("<C-e>", config.defaults.keymaps.accept_line)
      assert.equals("<C-]>", config.defaults.keymaps.dismiss)
      assert.equals("<C-Space>", config.defaults.keymaps.trigger)
    end)

    it("should have empty disabled_filetypes by default", function()
      assert.same({}, config.defaults.disabled_filetypes)
    end)
  end)

  describe("setup", function()
    it("should merge user config with defaults", function()
      config.setup({
        provider = "codestral",
        debounce_ms = 100,
        codestral = {
          api_key_provider = function() return "test" end,
          endpoint = "https://custom.endpoint.com",
        },
      })

      assert.equals("codestral", config.options.provider)
      assert.equals(100, config.options.debounce_ms)
      assert.equals("https://custom.endpoint.com", config.options.codestral.endpoint)
      -- Should still have other defaults
      assert.equals(30, config.options.context.suffix_lines)
    end)

    it("should deep merge nested config", function()
      config.setup({
        provider = "codestral",
        codestral = {
          api_key_provider = function() return "test" end,
          max_tokens = 512,
        },
        context = {
          prefix_lines = 50,
        },
      })

      assert.equals(50, config.options.context.prefix_lines)
      -- Should still have other context defaults
      assert.equals(30, config.options.context.suffix_lines)
      assert.equals(512, config.options.codestral.max_tokens)
    end)
  end)

  describe("validate", function()
    it("should error if provider is not set", function()
      assert.has_error(function()
        config.setup({})
      end)
    end)

    it("should error if provider doesn't exist", function()
      assert.has_error(function()
        config.setup({ provider = "nonexistent" })
      end, "nvim-fim: Provider 'nonexistent' not found")
    end)

    it("should error if provider config is invalid", function()
      assert.has_error(function()
        config.setup({
          provider = "codestral",
          codestral = {
            api_key_provider = "not-a-function",  -- Invalid
          },
        })
      end, "nvim-fim: codestral.api_key_provider must be a function")
    end)

    it("should error if prefix_lines is not positive", function()
      assert.has_error(function()
        config.setup({
          provider = "codestral",
          codestral = { api_key_provider = function() return "test" end },
          context = { prefix_lines = 0 },
        })
      end, "nvim-fim: context.prefix_lines must be positive")
    end)

    it("should error if suffix_lines is negative", function()
      assert.has_error(function()
        config.setup({
          provider = "codestral",
          codestral = { api_key_provider = function() return "test" end },
          context = { suffix_lines = -1 },
        })
      end, "nvim-fim: context.suffix_lines must be non-negative")
    end)

    it("should error if max_prefix_chars is not positive", function()
      assert.has_error(function()
        config.setup({
          provider = "codestral",
          codestral = { api_key_provider = function() return "test" end },
          context = { max_prefix_chars = 0 },
        })
      end, "nvim-fim: context.max_prefix_chars must be positive")
    end)

    it("should error if max_suffix_chars is negative", function()
      assert.has_error(function()
        config.setup({
          provider = "codestral",
          codestral = { api_key_provider = function() return "test" end },
          context = { max_suffix_chars = -1 },
        })
      end, "nvim-fim: context.max_suffix_chars must be non-negative")
    end)

    it("should not error with valid configuration", function()
      assert.has_no.errors(function()
        config.setup({
          provider = "codestral",
          codestral = {
            api_key_provider = function() return "test" end,
          },
        })
      end)
    end)
  end)
end)
