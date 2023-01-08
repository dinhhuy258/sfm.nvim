# sfm.nvim

The simple directory tree viewer for Neovim written in Lua.

I created the `sfm` plugin because I wanted to write my own simple and lightweight file management options for NeoVim. I wanted a plugin that would allow me to easily browse and open files in my project without being weighed down by unnecessary features or complexity.

The `sfm` plugin is designed to be minimalistic and easy to use, with a clean and intuitive interface. It provides all the essential file management functionality that I need, without any unnecessary bells and whistles. I hope you find it as useful as I do!

The `sfm` plugin is also designed to be easily extensible. You can customize the plugin to suit your needs, or even create extensions for sfm to achieve specific tasks.

Please note that the `sfm` plugin is still in development and may not be fully stable. Use at your own risk.

## Demonstration

Here is a short demonstration of the `sfm` plugin in action:

https://user-images.githubusercontent.com/17776979/209444095-12be39db-9b6d-4773-b42f-aa93652154cc.mp4

## Installation

Install `sfm` on Neovim using your favorite plugin manager. For example, the below example shows how to install `sfm` using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'dinhhuy258/sfm.nvim',
  config = function()
    require("sfm").setup()
  end
}
```

## Configuration

`sfm` provides the following configuration options:

```lua
local default_config = {
  sort_by = nil,
  view = {
    side = "left", -- side of the tree, can be `left`, `right`
    width = 30,
    mappings = {
      custom_only = false,
      list = {
        -- user mappings go here
      },
    },
  },
  renderer = {
    icons = {
      file = {
        default = "",
        symlink = "",
      },
      folder = {
        default = "",
        open = "",
        symlink = "",
        symlink_open = "",
      },
      indicator = {
        folder_closed = "",
        folder_open = "",
        file = " ",
      },
      selection = "",
    },
  },
}
```

You can override the default configuration by calling the setup method and passing in your customizations:

```lua
require("sfm").setup {
--- your customization configuration
}
```

## Commands

`:SFMToggle` Open or close the explorer.

## Mappings

The default mapping is configurated [here](https://github.com/dinhhuy258/sfm.nvim/blob/main/lua/sfm/config.lua). You can override the default mapping by setting it via the `view.mappings` configuration. It's similar to the way [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) handles mapping overrides.

## Events

`sfm` dispatches events whenever an action is made in the explorer. These events can be subscribed to through handler functions, allowing for even further customization of `sfm`.

To subscribe to an event, use the `subscribe` function provided by `sfm` and specify the event name and the handler function:

```lua
M.sfm_explorer:subscribe(event.ExplorerOpened, function(payload)
  local bufnr = payload["bufnr"]
  local options = {
    noremap = true,
    expr = false,
  }

  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "m",
    "<CMD>lua require('sfm.extensions.sfm-bookmark').set_mark()<CR>",
    options
  )
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "`",
    "<CMD>lua require('sfm.extensions.sfm-bookmark').load_mark()<CR>",
    options
  )
end)
```

**Available events:**

- `ExplorerOpened`: Triggered when the explorer window is opened. The payload of the event is a table with the following keys:
  `winnr`: The number of the window where the explorer is opened.
  `bufnr`: The number of the buffer associated with the explorer window.
- `FileOpened`: Triggered when a file is opened in the explorer. The payload of the event is a table with the following key:
  `path`: The path of the file that was opened.
- `FolderOpened`: Triggered when a folder is opened in the explorer. The payload of the event is a table with the following key:
  `path`: The path of the folder that was opened.
- `FolderClosed`: Triggered when a folder is closed in the explorer. The payload of the event is a table with the following key:
  `path`: The path of the folder that was closed.

## Customizations

The sfm plugin allows users to customize the appearance of the explorer tree by providing two customization mechanisms: `remove_renderer` and `register_renderer`.

### remove_renderer

The `remove_renderer` function allows users to remove a renderer components from the list of renderers used to render the entry of the explorer tree. This can be useful if a user wants to disable a specific renderer provided by the sfm plugin or by an extension.

### register_renderer

The `register_renderer` function allows users to register their own renderers for the explorer tree. This can be useful if a user wants to customize the appearance of the tree or add new features to it.

### Example

Here is an example of how to use the `remove_renderer` and `register_renderer` functions to customize the sfm plugin:

```lua
local sfm_explorer = require("sfm").setup {}
sfm_explorer:remove_renderer "name"
sfm_explorer:register_renderer("name", 50, function(entry)
  local name = entry.name
  if entry.is_dir then
    name = name .. " [dir]"
  else
    name = name .. " [file]"
  end
  local name_hl_group = entry.is_dir and "SFMFolderName" or "SFMFileName"

  return {
    text = name,
    highlight = name_hl_group,
  }
end)
```

Here is an example of an extension for the `sfm` plugin that adds a custom renderer to display the entry size:

```lua
-- define a custom renderer that displays the entry size
local function size_renderer(entry)
  local stat = vim.loop.fs_stat(entry.path)
  local size = stat.size
  local size_text = string.format("[%d bytes]", size)

  return {
    text = size_text,
    highlight = "SFMSize",
  }
end

-- register the custom renderer
sfm_explorer:register_renderer("custom", 100, size_renderer)
```

The default entry renderers, in order of rendering priority, are:

- indent (priority 10)
- indicator (priority 20)
- icon (priority 30)
- selection (priority 40)
- name (priority 50)

## Extensions

The `sfm` plugin allows users to extend its functionality by installing extensions. Extensions are independent plugins that can add new features or customize the behavior of the `sfm` plugin.

The extensions must be written under `lua/sfm/extensions/` folder.

### Available Extensions

Here is a list of available extensions for the `sfm` plugin:

- [sfm-bookmark](https://github.com/dinhhuy258/sfm-bookmark.nvim): Adds bookmarking functionality to the `sfm` plugin
- [sfm-filter](https://github.com/dinhhuy258/sfm-filter.nvim): Allows users to filter entries in the `sfm` explorer tree

## Credits

- This plugin was developed using [NeoVim](https://neovim.io/).
- The file explorer functionality is based on the [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) plugin. I also copied some code from there.
- The icons used in the file explorer are from the [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).
