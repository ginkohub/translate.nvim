# translate.nvim

A lightweight, zero-dependency, modular translation plugin for Neovim written in Lua, leveraging system `curl` for asynchronous translation.

## Features

- **Asynchronous**: Uses `vim.fn.jobstart` to translate in the background without blocking Neovim.
- **Zero-Dependency**: No external plugin dependencies.
- **Modular Backends**: Easily add, customize, or swap translation backends. Built-in support for Google Translate, LibreTranslate, and MyMemory.
- **Multiple Actions**:
  - Display translation via `vim.notify`.
  - Replace selected text with its translation and receive success notifications indicating the backend and language.
  - Copy translation to registers and system clipboard.

## Installation

Using a plugin manager like `lazy.nvim`:

```lua
{
  "ginkohub/translate.nvim",
  opts = {
    default_backend = "google",
    default_target = "en",
    default_source = "auto"
  }
}
```

## Configuration

Default configuration parameters:

```lua
require("translate").setup({
  default_backend = "google",
  default_target = "en",
  default_source = "auto",
  backends = {
    libretranslate = {
      url = "https://libretranslate.com",
      api_key = ""
    },
    mymemory = {
      email = ""
    }
  }
})
```

### LibreTranslate URL Failover / Rotation

If you use LibreTranslate, you can specify multiple URLs (mirrors) in an array. If one mirror fails or rate-limits, the plugin automatically rotates and falls back to the next available mirror:

```lua
require("translate").setup({
  backends = {
    libretranslate = {
      url = {
        "https://translate.fedilab.app",
        "https://translate.mstdn.social",
        "https://translate.rinderha.cc"
      }
    }
  }
})
```

### Custom Backends

You can add a custom backend by placing a module in your runtimepath under `lua/translate/backends/<name>.lua` returning a table with `get_cmd` and `parse` functions, or by defining it directly:

```lua
require("translate").backends.my_service = {
  get_cmd = function(text, target, source, config)
    return {
      "curl", "-s", "https://api.my-service.com/translate?text=" .. text .. "&target=" .. target
    }
  end,
  parse = function(response)
    local data = vim.json.decode(response)
    return data.result
  end
}
```

## Usage

### Commands

Each command takes optional `[target]` and `[source]` language arguments. If not supplied, they fall back to the configured defaults.

#### Display Translation
Displays translation using `vim.notify`:
- `:Translate [target] [source]`
- `:Tr [target] [source]`
- `:TranslateTo [target] [source]`
- `:TrTo [target] [source]`

#### Replace Text
Replaces the selected text (or current line in normal mode) with the translation:
- `:TranslateR [target] [source]`
- `:TrR [target] [source]`
- `:TranslateToR [target] [source]`
- `:TrToR [target] [source]`

#### Copy Translation
Translates and copies the result to clipboard/registers:
- `:TranslateC [target] [source]`
- `:TrC [target] [source]`
- `:TranslateToC [target] [source]`
- `:TrToC [target] [source]`

### Keymaps Example

You can map these commands in your config:

```lua
vim.keymap.set("v", "<leader>t", ":TrToR<CR>", { silent = true })
vim.keymap.set("n", "<leader>t", ":TrTo<CR>", { silent = true })
```

## Troubleshooting

Run the built-in health check to check curl availability and test connectivity to configured translation backends and mirrors:

```vim
:checkhealth translate
```
