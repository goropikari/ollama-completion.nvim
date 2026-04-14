local config = require('ollama-completion.config')
local completion = require('ollama-completion.completion')
local llm = require('ollama-completion.llm')

---@class OllamaCompletionPlugin
local M = {}

--- Initialize the plugin
---@param opts OllamaCompletionOptions|nil User configuration
function M.setup(opts)
  -- 1. Setup config
  config.setup(opts)
  -- 2. Setup autocommands to trigger completion on movement
  completion.setup_autocmds()

  -- 3. Define highlight group for completion virtual text
  vim.api.nvim_set_hl(0, 'OllamaCompletion', { fg = config.options.highlight_color })

  -- 4. Set keymap to accept completion (e.g., <Tab>) in insert and normal mode
  ---@type string
  local accept_key = config.options.accept_key
  local function accept_completion()
    -- Try to accept current completion
    if not completion.accept() then
      -- If no completion to accept, feed the original key (like <Tab>)
      local key = vim.api.nvim_replace_termcodes(accept_key, true, true, true)
      vim.api.nvim_feedkeys(key, 'n', true)
    end
  end

  vim.keymap.set('i', accept_key, accept_completion, { silent = true, desc = 'Accept Ollama completion' })

  vim.api.nvim_create_user_command('OllamaCompletionReconnect', function()
    llm.resume()
    completion.trigger(true)
  end, {
    desc = 'Resume Ollama completion requests and trigger a new connection attempt',
  })
end

return M
