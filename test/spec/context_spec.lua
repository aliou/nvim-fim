describe("fim.context", function()
  local context
  local config

  before_each(function()
    -- Clear loaded modules to get fresh state
    package.loaded["fim.config"] = nil
    package.loaded["fim.providers"] = nil
    package.loaded["fim.providers.codestral"] = nil
    package.loaded["fim.context"] = nil
    
    config = require("fim.config")
    config.setup({
      provider = "codestral",
      codestral = { api_key_provider = function() return "test" end },
    })
    
    context = require("fim.context")
  end)

  describe("get_current_context", function()
    it("should extract prefix and suffix around cursor", function()
      -- Create buffer with content
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "line 1",
        "line 2",
        "line 3",
        "line 4",
        "line 5",
      })
      
      -- Set current buffer and window
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      
      -- Move cursor to middle of line 3 (0-based: line 2, col 4)
      vim.api.nvim_win_set_cursor(win, {3, 4})
      
      local ctx = context.get_current_context()
      
      assert.is_not_nil(ctx)
      assert.is_string(ctx.prefix)
      assert.is_string(ctx.suffix)
      assert.truthy(ctx.prefix:match("line 1"))
      assert.truthy(ctx.prefix:match("line 2"))
      assert.truthy(ctx.prefix:match("line"))  -- Part of line 3
      assert.truthy(ctx.suffix:match(" 3"))  -- Rest of line 3
      assert.truthy(ctx.suffix:match("line 4"))
      
      -- Clean up
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should include cursor position in result", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"test line"})
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_win_set_cursor(win, {1, 5})
      
      local ctx = context.get_current_context()
      
      assert.is_not_nil(ctx)
      assert.is_not_nil(ctx.cursor)
      assert.equals(0, ctx.cursor.line)  -- 0-based
      assert.equals(5, ctx.cursor.col)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should truncate prefix to max_prefix_chars", function()
      config.setup({
        provider = "codestral",
        codestral = { api_key_provider = function() return "test" end },
        context = { max_prefix_chars = 10 }
      })
      
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "this is a very long line that should be truncated",
      })
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_win_set_cursor(win, {1, 50})
      
      local ctx = context.get_current_context()
      
      assert.is_not_nil(ctx)
      assert.is_true(#ctx.prefix <= 10)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should truncate suffix to max_suffix_chars", function()
      config.setup({
        provider = "codestral",
        codestral = { api_key_provider = function() return "test" end },
        context = { max_suffix_chars = 10 }
      })
      
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "this is a very long line that should be truncated",
      })
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_win_set_cursor(win, {1, 0})
      
      local ctx = context.get_current_context()
      
      assert.is_not_nil(ctx)
      assert.is_true(#ctx.suffix <= 10)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should return nil for disabled filetypes", function()
      config.setup({
        provider = "codestral",
        codestral = { api_key_provider = function() return "test" end },
        disabled_filetypes = { "markdown" }
      })
      
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"test"})
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      
      local ctx = context.get_current_context()
      
      assert.is_nil(ctx)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should respect prefix_lines setting", function()
      config.setup({
        provider = "codestral",
        codestral = { api_key_provider = function() return "test" end },
        context = { prefix_lines = 2 }
      })
      
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "line 1",
        "line 2",
        "line 3",
        "line 4",
        "line 5",
      })
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_win_set_cursor(win, {5, 0})  -- Last line
      
      local ctx = context.get_current_context()
      
      assert.is_not_nil(ctx)
      -- Should not include line 1 or line 2
      assert.is_false(ctx.prefix:match("line 1") ~= nil)
      assert.is_false(ctx.prefix:match("line 2") ~= nil)
      -- Should include line 4
      assert.truthy(ctx.prefix:match("line 4"))
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("should respect suffix_lines setting", function()
      config.setup({
        provider = "codestral",
        codestral = { api_key_provider = function() return "test" end },
        context = { suffix_lines = 1 }
      })
      
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "line 1",
        "line 2",
        "line 3",
        "line 4",
      })
      vim.api.nvim_set_current_buf(bufnr)
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_win_set_cursor(win, {1, 0})  -- First line
      
      local ctx = context.get_current_context()
      
      assert.is_not_nil(ctx)
      -- Should include line 2
      assert.truthy(ctx.suffix:match("line 2"))
      -- Should not include line 3 or 4
      assert.is_false(ctx.suffix:match("line 3") ~= nil)
      assert.is_false(ctx.suffix:match("line 4") ~= nil)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)
end)
