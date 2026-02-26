describe("fim.suggestion", function()
  local suggestion
  local config
  local mock_provider

  before_each(function()
    -- Clear loaded modules to get fresh state
    package.loaded["fim.config"] = nil
    package.loaded["fim.providers"] = nil
    package.loaded["fim.providers.codestral"] = nil
    package.loaded["fim.render"] = nil
    package.loaded["fim.suggestion"] = nil
    
    -- Mock the Codestral provider
    mock_provider = {
      name = "codestral",
      request_completion = function(prefix, suffix, callback)
        -- Store last call for assertions
        mock_provider.last_call = { prefix = prefix, suffix = suffix }
        -- Simulate async response
        vim.defer_fn(function()
          if mock_provider.should_error then
            callback(nil, "mock error")
          else
            callback({
              choices = {
                {
                  message = {
                    content = mock_provider.response_text or "_stub_completion"
                  }
                }
              }
            }, nil)
          end
        end, 0)
      end,
      validate_config = function() return true, nil end,
      last_call = nil,
      should_error = false,
      response_text = nil,
    }
    package.loaded["fim.providers.codestral"] = mock_provider
    
    -- Mock render module to avoid extmark errors in tests
    package.loaded["fim.render"] = {
      render_suggestion = function() end,
      clear_suggestion = function() end,
    }
    
    config = require("fim.config")
    config.setup({
      provider = "codestral",
      codestral = { api_key_provider = function() return "test" end },
    })
    
    suggestion = require("fim.suggestion")
    suggestion.setup()
  end)

  describe("request_completion", function()
    it("should call provider with correct prefix and suffix", function()
      local ctx = {
        prefix = "function test() {",
        suffix = "}",
        cursor = { line = 0, col = 17 }
      }
      
      suggestion.request_completion(ctx)
      
      assert.is_not_nil(mock_provider.last_call)
      assert.equals("function test() {", mock_provider.last_call.prefix)
      assert.equals("}", mock_provider.last_call.suffix)
    end)

    it("should call vim.notify_once on provider error", function()
      local notify_calls = {}
      vim.notify_once = function(msg, level)
        table.insert(notify_calls, { msg = msg, level = level })
      end
      
      -- Mock insert mode and cursor position
      local orig_mode = vim.fn.mode
      vim.fn.mode = function() return 'i' end
      local orig_get_cursor = vim.api.nvim_win_get_cursor
      vim.api.nvim_win_get_cursor = function() return { 1, 4 } end
      
      -- Use synchronous mock for this test
      mock_provider.request_completion = function(prefix, suffix, callback)
        callback(nil, "mock error")
      end
      
      suggestion.request_completion({
        prefix = "test",
        suffix = "",
        cursor = { line = 0, col = 4 }
      })
      
      -- Restore mocks
      vim.fn.mode = orig_mode
      vim.api.nvim_win_get_cursor = orig_get_cursor
      
      assert.equals(1, #notify_calls)
      assert.is_true(notify_calls[1].msg:find("mock error") ~= nil)
      assert.equals(vim.log.levels.WARN, notify_calls[1].level)
    end)

    it("should increment request_id on each call", function()
      local initial_id = suggestion.state.request_id
      
      suggestion.request_completion({
        prefix = "test",
        suffix = "",
        cursor = { line = 0, col = 4 }
      })
      
      local after_first = suggestion.state.request_id
      assert.is_true(after_first > initial_id)
      
      suggestion.request_completion({
        prefix = "test2",
        suffix = "",
        cursor = { line = 0, col = 5 }
      })
      
      assert.is_true(suggestion.state.request_id > after_first)
    end)

    it("should store cursor position", function()
      local ctx = {
        prefix = "test",
        suffix = "",
        cursor = { line = 5, col = 10 }
      }
      
      suggestion.request_completion(ctx)
      
      assert.is_not_nil(suggestion.state.cursor_pos)
      assert.equals(5, suggestion.state.cursor_pos.line)
      assert.equals(10, suggestion.state.cursor_pos.col)
    end)
  end)

  describe("clear_suggestion", function()
    it("should clear suggestion state", function()
      suggestion.state.suggestion = "test"
      suggestion.state.cursor_pos = { line = 0, col = 4 }
      suggestion.state.bufnr = 1
      
      suggestion.clear_suggestion()
      
      assert.is_nil(suggestion.state.suggestion)
      assert.is_nil(suggestion.state.cursor_pos)
      assert.is_nil(suggestion.state.bufnr)
    end)
  end)

  describe("accept_suggestion", function()
    it("should do nothing if no suggestion", function()
      suggestion.state.suggestion = nil
      assert.has_no.errors(function()
        suggestion.accept_suggestion()
      end)
    end)

    it("should clear suggestion after accepting", function()
      suggestion.state.suggestion = "test"
      suggestion.accept_suggestion()
      assert.is_nil(suggestion.state.suggestion)
    end)
  end)

  describe("accept_word", function()
    it("should accept up to first word boundary", function()
      suggestion.state.suggestion = "hello world"
      suggestion.accept_word()
      -- After accepting "hello ", remaining should be "world"
      assert.equals("world", suggestion.state.suggestion)
    end)

    it("should accept full suggestion if no word boundary", function()
      suggestion.state.suggestion = "helloworld"
      suggestion.accept_word()
      assert.is_nil(suggestion.state.suggestion)
    end)

    it("should clear if remaining is empty", function()
      suggestion.state.suggestion = "test "
      suggestion.accept_word()
      assert.is_nil(suggestion.state.suggestion)
    end)
  end)

  describe("accept_line", function()
    it("should accept up to first newline", function()
      suggestion.state.suggestion = "line1\nline2"
      suggestion.accept_line()
      assert.equals("line2", suggestion.state.suggestion)
    end)

    it("should accept full suggestion if no newline", function()
      suggestion.state.suggestion = "single line"
      suggestion.accept_line()
      assert.is_nil(suggestion.state.suggestion)
    end)

    it("should clear if remaining is empty", function()
      suggestion.state.suggestion = "test\n"
      suggestion.accept_line()
      assert.is_nil(suggestion.state.suggestion)
    end)
  end)
end)
