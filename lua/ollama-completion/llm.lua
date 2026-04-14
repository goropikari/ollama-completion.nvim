local config = require('ollama-completion.config')

---@class OllamaLLM
local M = {}

--- Store current active process to cancel it if a new one starts
---@type vim.SystemObj|nil
local current_process = nil
--- Disable automatic requests after a connection failure until manually resumed
---@type boolean
local is_connection_suspended = false

--- Return whether automatic Ollama requests are currently suspended
---@return boolean
function M.is_suspended()
  return is_connection_suspended
end

--- Resume Ollama requests after a connection failure
function M.resume()
  is_connection_suspended = false
end

--- Call Ollama API to generate completion
---@param prefix string The text before the cursor
---@param suffix string The text after the cursor
---@param callback fun(response: string) The function to call with the generated code
function M.generate(prefix, suffix, callback)
  if is_connection_suspended then
    return
  end

  -- Cancel previous process if it exists
  if current_process then
    current_process:kill()
    current_process = nil
  end

  local url = config.options.url:gsub('/$', '') .. '/api/generate'

  -- Get the prompt template from configuration (can be string or function)
  local prompt_template_config = config.options.prompt_template

  local final_prompt
  if type(prompt_template_config) == 'function' then
    -- If it's a function, call it with prefix and suffix
    final_prompt = prompt_template_config(prefix, suffix)
  elseif type(prompt_template_config) == 'string' then
    -- If it's a string, use string.format
    final_prompt = string.format(prompt_template_config, prefix, suffix)
  else
    -- Fallback to a default FIM format if type is unexpected or not set
    vim.notify('Warning: Invalid prompt_template type in config, using default FIM format.', vim.log.levels.WARN)
    final_prompt = string.format('<|fim_prefix|>%s<|fim_suffix|>%s<|fim_middle|>', prefix, suffix)
  end

  local data = {
    model = config.options.model,
    prompt = final_prompt, -- Use the generated prompt
    stream = false,
    raw = true, -- Keep raw = true for FIM
    options = config.options.options,
  }

  local cmd = {
    'curl',
    '-s',
    '-X',
    'POST',
    url,
    '-d',
    vim.fn.json_encode(data),
    '-H',
    'Content-Type: application/json',
  }

  -- Start asynchronous process using vim.system
  current_process = vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      current_process = nil
      if obj.code ~= 0 then
        is_connection_suspended = true
        local error_msg = string.format('Ollama error (code %d)', obj.code)
        if obj.stderr and obj.stderr ~= '' then
          error_msg = error_msg .. ': ' .. obj.stderr
        end
        vim.notify(error_msg .. '. Automatic requests are paused. Run :OllamaCompletionReconnect to try again.', vim.log.levels.ERROR)
        return
      end
      if not obj.stdout or obj.stdout == '' then
        return
      end

      local decoded = vim.json.decode(obj.stdout)
      if not decoded.response then
        vim.notify('Ollama response missing: ' .. obj.stdout, vim.log.levels.ERROR)
        return
      end

      local resp = decoded.response
      -- Basic code block extraction from the LLM response
      local code = resp:match('```[%w]*\n?(.-)```') or resp
      callback(code)
    end)
  end)
end

return M
