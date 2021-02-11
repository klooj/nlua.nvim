local cache_location = vim.fn.stdpath('cache')
local hizz = os.getenv("HOME")
local build_foo
local bin_folder

if vim.loop.os_uname().sysname == "Darwin" then
  bin_folder = 'macOS'
else
  bin_folder = 'Linux'
end

-- if g.is_mac then
  -- build_foo = '/usr/local/share/nvim/runtime'
-- else
build_foo = hizz .. '/.local/share/nvim/runtime'
-- end

local nlua_nvim_lsp = {
  base_directory = hizz .. "/gits/lua-language-server/",
  bin_location = hizz .. "/gits/lua-language-server/bin/" .. bin_folder .. "lua-language-server"
}

local sumneko_command = function()
  return {
    nlua_nvim_lsp.bin_location,
    "-E",
    string.format(
      "%s/main.lua",
      nlua_nvim_lsp.base_directory
    ),
  }
end

local function get_lua_runtime()
    local result = {};
    for _, path in pairs(vim.api.nvim_list_runtime_paths()) do
        local lua_path = path .. "/lua/";
        if vim.fn.isdirectory(lua_path) then
            result[lua_path] = true
        end
    end

    -- This loads the `lua` files from nvim into the runtime.
    result[vim.fn.expand("$VIMRUNTIME/lua")] = true

    -- TODO: Figure out how to get these to work...
    --  Maybe we need to ship these instead of putting them in `src`?...
    -- result[vim.fn.expand("~/build/neovim/src/nvim/lua")] = true
    -- result[build_foo .. "/lua"] = true

    return result;
end

nlua_nvim_lsp.setup = function(nvim_lsp, config)
  local cmd = config.cmd or sumneko_command()
  local executable = cmd[1]

  if vim.fn.executable(executable) == 0 then
    print("Could not find sumneko executable:", executable)
    return
  end

  if vim.fn.filereadable(cmd[3]) == 0 then
    print("Could not find resulting build files", cmd[3])
    return
  end

  nvim_lsp.sumneko_lua.setup({
    cmd = cmd,

    -- Lua LSP configuration
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",

          -- TODO: Figure out how to get plugins here.
          path = vim.split(package.path, ';'),
          -- path = {package.path},
        },

        completion = {
          -- You should use real snippets
          keywordSnippet = "Disable",
        },

        diagnostics = {
          enable = true,
          disable = config.disabled_diagnostics or {
            "trailing-space",
          },
          globals = vim.list_extend({
              -- Neovim
              "vim",
              -- Busted
              "describe", "it", "before_each", "after_each", "teardown", "pending"
            }, config.globals or {}
          ),
        },
        telemetry = {
          enable = false
        },

        workspace = {
          library = vim.list_extend(get_lua_runtime(), config.library or {}),
          maxPreload = 2000,
          preloadFileSize = 1000,
        },
      }
    },

    -- Runtime configurations
    filetypes = {"lua"},

    on_attach = config.on_attach,
    handlers = config.handlers,
  })
end

nlua_nvim_lsp.hover = function()
  vim.lsp.buf.hover()
end

return nlua_nvim_lsp
