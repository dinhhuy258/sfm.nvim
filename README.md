# sfm.nvim

The simple directory tree viewer for Neovim written in Lua.

I created the `sfm` plugin because I wanted to write my own simple and lightweight file management options for NeoVim. I wanted a plugin that would allow me to easily browse and open files in my project without being weighed down by unnecessary features or complexity.

The `sfm` plugin is designed to be minimalistic and easy to use, with a clean and intuitive interface. It provides all the essential file management functionality that I need, without any unnecessary bells and whistles. I hope you find it as useful as I do!

The `sfm` plugin is also designed to be easily extensible. You can customize the plugin to suit your needs, or even create extensions for sfm to achieve specific tasks. 

Please note that the `sfm` plugin is still in development and may not be fully stable. Use at your own risk.

## Installation

Install `sfm` on Neovim using your favorite plugin manager. For example, the below example shows how to install `sfm` using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'dinhhuy258/sfm.nvim',
  config = function()
    require("sfm").setup()
  end,
}
```

## Configuration

`sfm` provides the following configuration options:

```lua
local default_config = {
  show_hidden_files = false,
  devicons_enable = true,
  sort_by = nil,
  view = {
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
      selected = "",
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

The default mapping is configurated [here](https://github.com/dinhhuy258/sfm.nvim/blob/main/lua/sfm/config.lua). You can override the default mapping by setting it via the view.mappings configuration. It's similar to the way [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) handles mapping overrides.

## Credits

- This plugin was developed using [NeoVim](https://neovim.io/).
- The file explorer functionality is based on the [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) plugin. I also copied some code from there.
- The icons used in the file explorer are from the [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).
