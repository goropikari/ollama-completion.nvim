local M = {}

---@class OllamaLLMOptions
---@field temperature? number LLM temperature (0.0 to 1.0)
---@field top_p? number LLM top_p sampling
---@field stop? string[] Stop tokens

---@class OllamaCompletionOptions
---@field model? string Ollama model to use
---@field url? string Ollama API URL
---@field accept_key? string Key to accept completion
---@field debounce_ms? number Delay before triggering completion (ms)
---@field context_lines_before? number Lines of context before cursor
---@field context_lines_after? number Lines of context after cursor
---@field highlight_color? string Color for virtual text
---@field options? OllamaLLMOptions LLM specific options like temperature, top_p, stop

--- Default configuration options
---@type OllamaCompletionOptions
M.defaults = {
  model = 'qwen2.5-coder:3b', -- Ollama model to use
  url = 'http://localhost:11434', -- Ollama API URL
  accept_key = '<Tab>', -- Key to accept completion
  debounce_ms = 500, -- Delay before triggering completion (ms)
  context_lines_before = 50, -- Lines of context before cursor
  context_lines_after = 50, -- Lines of context after cursor
  highlight_color = '#808080', -- Color for virtual text
  options = {
    temperature = 0.2, -- LLM temperature
    top_p = 0.9, -- LLM top_p
    stop = {
      '<|fim_prefix|>',
      '<|fim_suffix|>',
      '<|fim_middle|>',
      '<|file_sep|>',
      '<|endoftext|>',
      '```',
    },
  },
}

-- Merged options
---@type OllamaCompletionOptions
M.options = vim.deepcopy(M.defaults)

--- Setup plugin options
---@param user_options OllamaCompletionOptions|nil
function M.setup(user_options)
  M.options = vim.tbl_deep_extend('force', M.defaults, user_options or {})
end

return M
