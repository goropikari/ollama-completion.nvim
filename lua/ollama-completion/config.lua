---@class OllamaConfig
local M = {}

---@class OllamaLLMOptions
---@field temperature? number LLM temperature (0.0 to 1.0)
---@field top_p? number LLM top_p sampling
---@field stop? string[] Stop tokens
---@field num_predict? integer Maximum number of tokens to predict. Default: 128.
---@field prompt_template? string | fun(prefix: string, suffix: string): string Template for constructing the prompt. If string, uses Lua string.format syntax (%s for prefix, %s for suffix). If function, it's called with prefix and suffix.
---@field filetype_context? boolean Whether to include filetype in prompt (deprecated if using FIM)

---@class OllamaCompletionOptions
---@field model? string Ollama model to use
---@field url? string Ollama API URL
---@field accept_key? string Key to accept completion
---@field debounce_ms? number Delay before triggering completion (ms)
---@field context_lines_before? number Lines of context before cursor
---@field context_lines_after? number Lines of context after cursor
---@field highlight_color? string Color for virtual text
---@field show_spinner? boolean Whether to show spinner in ghost text while waiting for completion
---@field options? OllamaLLMOptions LLM specific options like temperature, top_p, stop, num_predict
---@field prompt_template? string | fun(prefix: string, suffix: string): string Template for constructing the prompt.

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
  show_spinner = true, -- Whether to show spinner in ghost text
  options = {
    temperature = 0.0, -- LLM temperature
    top_p = 0.9, -- LLM top_p
    stop = {
      '<|fim_prefix|>',
      '<|fim_suffix|>',
      '<|fim_middle|>',
      '<|file_sep|>',
      '<|endoftext|>',
      '```',
    },
    num_predict = 64, -- Maximum number of tokens to predict. Default: 128.
  },
  -- prompt template
  prompt_template = function(prefix, suffix)
    return string.format('<|fim_prefix|>%s<|fim_suffix|>%s<|fim_middle|>', prefix, suffix)
  end,
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
