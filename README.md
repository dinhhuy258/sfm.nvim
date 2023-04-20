# sfm.nvim

The simple directory tree viewer for Neovim written in Lua.

I created the `sfm` plugin because I wanted to write my own simple and lightweight file management options for NeoVim. I wanted a plugin that would allow me to easily browse and open files in my project without being weighed down by unnecessary features or complexity.

The `sfm` plugin is designed to be minimalistic and easy to use, with a clean and intuitive interface. It provides all the essential file management functionality that I need, without any unnecessary bells and whistles. I hope you find it as useful as I do!

The `sfm` plugin is also designed to be easily extensible. You can customize the plugin to suit your needs, or even create extensions for sfm to achieve specific tasks.

Please note that the `sfm` plugin is still in development and may not be fully stable. Use at your own risk.

## Demonstration

Here is a short demonstration of the `sfm` plugin in action:

https://user-images.githubusercontent.com/17776979/213235911-f2cfc886-5485-413d-8959-bf404ecc8451.mp4

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
  view = {
    side = "left", -- side of the tree, can be `left`, `right`. this setting will be ignored if view.float.enable is set to true,
    width = 30 -- this setting will be ignored if view.float.enable is set to true,
    float = {
      enable = false,
      config = {
        relative = "editor",
        border = "rounded",
        width = 30, -- int or function
        height = 30, -- int or function
        row = 1, -- int or function
        col = 1 -- int or function
      }
    }
  },
  mappings = {
    custom_only = false,
    list = {
      -- user mappings go here
    }
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
      }
    }
  }
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

To use the functionalities provided by the `sfm` plugin, you can use the following key bindings:

| Key   | Action        | Description                                                |
| ----- | ------------- | ---------------------------------------------------------- |
| cr    | edit          | Open a file or directory                                   |
| ctr-v | vsplit        | Open a file in a vertical split window                     |
| ctr-h | split         | Open a file in a horizontal split window                   |
| ctr-t | tabnew        | Open a file in a new tab                                   |
| s-tab | close_entry   | Close current opened directory or parent                   |
| K     | first_sibling | Navigate to the first sibling of current file or directory |
| J     | last_sibling  | Navigate to the last sibling of current file or directory  |
| P     | parent_entry  | Move cursor to the parent directory                        |
| R     | reload        | Reload the explorer                                        |
| q     | close         | Close the explorer window                                  |

You can customize these key bindings by defining custom functions or action names in the `mappings` configuration option. For example, you can assign a custom function to the `t` key:

```lua
local sfm_explorer = require("sfm").setup {
  mappings = {
    list = {
      {
        key = "c",
        action = function()
          print("Custom function executed")
        end,
      },
      {
        key = "x",
        action = "close",
      },
    },
  },
}
```

In this example, when the user presses the `c` key in the explorer, the custom function `function() print("Custom function executed") end` will be executed. Pressing the `x` key will perform the default action `close`.
Please note that if the action for a key is set to `nil` or an empty string, the default key binding for that key will be disabled. Also, ensure that the action provided is a valid function or action name, as listed in the above table.

## Highlighting

The `sfm` plugin uses the following highlight values:

- `SFMRootFolder`: This highlight value is used to highlight the root folder in the file explorer. The default color scheme for this highlight value is `purple`.
- `SFMSymlink`: This highlight value is used to highlight symbolic links in the file explorer. The default color scheme for this highlight value is `cyan`.
- `SFMFileIndicator` and `SFMFolderIndicator` : These highlight values are used to highlight file and folder indicators in the file explorer. The default color scheme for this highlight value is `fg=#3b4261`.
- `SFMFolderName` and `SFMFolderIcon` : These highlight values are used to highlight folder names and icons in the file explorer. The default color scheme for this highlight value is `Directory`.
- `SFMFileName` and `SFMDefaultFileIcon` : These highlight values are used to highlight file names and icons in the file explorer. The default color scheme for this highlight value is `Normal`.

In addition to the above highlight values, the `sfm` plugin also uses the following highlight values:

- `SFMNormal`, `SFMNormalNC`, `SFMEndOfBuffer`, `SFMCursorLine`, `SFMCursorLineNr`, `SFMLineNr`, `SFMWinSeparator`, `SFMStatusLine`, `SFMStatuslineNC`, `SFMSignColumn` these highlight values are used to link to the default Neovim highlight groups.

## Extensions

The `sfm` plugin allows users to extend its functionality by installing extensions. Extensions are independent plugins that can add new features or customize the behavior of the `sfm` plugin.

The extensions must be written under `lua/sfm/extensions/` folder.

### Available Extensions

Here is a list of available extensions for the `sfm` plugin:

- [sfm-fs](https://github.com/dinhhuy258/sfm-fs.nvim): Adds file system functionality (create, move, delete...) to the `sfm` plugin.
- [sfm-bookmark](https://github.com/dinhhuy258/sfm-bookmark.nvim): Adds bookmarking functionality to the `sfm` plugin
- [sfm-filter](https://github.com/dinhhuy258/sfm-filter.nvim): Allows users to filter entries in the `sfm` explorer tree
- [sfm-git](https://github.com/dinhhuy258/sfm-git.nvim): Adds git icon support to the `sfm` plugin's file and folder explorer view, indicating the git status of the file or folder.
- [sfm-telescope](https://github.com/dinhhuy258/sfm-telescope.nvim): Allows users to search for entries in the `sfm` explorer tree

## Customizations

The `sfm` plugin provides several customization mechanisms, including `remove_renderer`, `register_renderer`, `remove_entry_filter`, `register_entry_filter`, and `set_entry_sort_method`, that allow users to alter the appearance and behavior of the explorer tree.

### remove_renderer

The `remove_renderer` function allows users to remove a renderer components from the list of renderers used to render the entry of the explorer tree. This can be useful if a user wants to disable a specific renderer provided by the sfm plugin or by an extension.

### register_renderer

The `register_renderer` function allows users to register their own renderers for the explorer tree. This can be useful if a user wants to customize the appearance of the tree or add new features to it.

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

local sfm_explorer = require("sfm").setup {}
-- register the custom renderer
sfm_explorer:register_renderer("custom", 100, size_renderer)
```

The default entry renderers, in order of rendering priority, are:

- indent (priority 10)
- indicator (priority 20)
- icon (priority 30)
- name (priority 40)

### register_entry_filter

The `register_entry_filter` function allows users to register their own filters for the explorer tree. This can be useful if a user wants to filter out certain entries based on certain criteria. For example, a user can filter out files that are larger than a certain size, or files that have a certain file extension.

### remove_entry_filter

The `remove_entry_filter` function allows users to remove a filter component from the list of filters used to filter the entries of the explorer tree. This can be useful if a user wants to disable a specific filter provided by the sfm plugin or by an extension.

Here is an example of an extension for the `sfm` plugin that adds a custom entry filter to hide the big entry size:

```lua
local sfm_explorer = require("sfm").setup {}
sfm_explorer:register_entry_filter("big_files", function(entry)
  local stat = vim.loop.fs_stat(entry.path)
  local size = stat.size
  if size > 1000000 then
    return false
  else
    return true
  end
end)
```

### set_entry_sort_method

This method allows you to customize the sorting of entries in the explorer tree. The function passed as a parameter should take in two entries and return a boolean value indicating whether the first entry should be sorted before the second. For example, you can use the following function to sort entries alphabetically by name:

```lua
local sfm_explorer = require("sfm").setup {}
sfm_explorer:set_entry_sort_method(function(entry1, entry2)
  return entry1.name < entry2.name
end)
```

## Events

`sfm` dispatches events whenever an action is made in the explorer. These events can be subscribed to through handler functions, allowing for even further customization of `sfm`.

To subscribe to an event, use the `subscribe` function provided by `sfm` and specify the event name and the handler function:

```lua
local sfm_explorer = require("sfm").setup {}
sfm_explorer:subscribe(event.ExplorerOpened, function(payload)
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
  - `winnr`: The number of the window where the explorer is opened.
  - `bufnr`: The number of the buffer associated with the explorer window.
- `ExplorerClosed`: Triggered when the explorer window is closed. It does not provide any payload.
- `ExplorerReloaded`: Triggered when a explorer is reloaded. This event is emitted after the explorer tree has finished reloading, and all the files and folders have been re-read. Listeners can use this event to update or refresh any state or information that is dependent on the explorer tree. It does not provide any payload.
- `ExplorerRendered`: Triggered when a explorer is rendered. This event can be used to perform additional customizations or updates after the explorer has been rendered. The payload of the event is a table with the following keys:
  - `winnr`: The number of the window explorer.
  - `bufnr`: The number of the buffer associated with the explorer window.
- `ExplorerRootChanged`: This event is fired when the root of the explorer changes. The payload of the event is a table with the following key:
  - `path`: The new root path
- `FileOpened`: Triggered when a file is opened in the explorer. The payload of the event is a table with the following key:
  - `path`: The path of the file that was opened.
- `FolderOpened`: Triggered when a folder is opened in the explorer. The payload of the event is a table with the following key:
  - `path`: The path of the folder that was opened.
- `FolderClosed`: Triggered when a folder is closed in the explorer. The payload of the event is a table with the following key:
  - `path`: The path of the folder that was closed.

## API

The `sfm` plugin exposes a number of APIs that can be used to customize the explorer tree and write extensions for the plugin. These functions are located in the `lua/sfm/api.lua` file and can be accessed by requiring it. Below are the available functions and their usage:

### Explorer

- `api.explorer.toggle()`: Toggles the visibility of the explorer window.
- `api.explorer.open()`: Opens the explorer window.
- `api.explorer.close()`: Closes the explorer window.
- `api.explorer.is_open()`: Returns `true` if the explorer window is currently open, `false` otherwise.
- `api.explorer.reload()`: Reloads the explorer tree.
- `api.explorer.refresh()`: Refreshes the current view of the explorer tree.
- `api.explorer.change_root(cwd: string)`: Changes the root directory of the explorer tree to the specified directory. If the directory is not valid, an error message will be displayed.

### Entry

- `api.entry.root()`: Returns the root entry of the explorer tree.
- `api.entry.current()`: Returns the current entry in the explorer tree.
- `api.entry.all()`: Returns a table containing all the entries in the explorer tree.

### Navigation

- `api.navigation.focus(p: string)`: Focuses on the specified file or directory in the explorer tree.

### Path

- `api.path.clean(p: string)`: Cleans up a file path to make it more standard.
- `api.path.split(p: string)`: Splits a file path into a table of its parts.
- `api.path.join(...)`: Joins a list of parts into a file path.
- `api.path.dirname(p: string)`: Returns the directory name of a file path.
- `api.path.basename(p: string)`: Returns the base name of a file path.
- `api.path.remove_trailing(p: string)`: Removes the trailing path separator from a file path.
- `api.path.has_trailing(p: string)`: Returns `true` if the file path has a trailing path separator, `false` otherwise.
- `api.path.add_trailing(p: string)`: Add trailing separator to the given path
- `api.path.exists(p: string)`: Check if the given path exists
- `api.path.isfile(p: string)`: Check if the given path is a file
- `api.path.isdir(p: string)`: Check if the given path is a directory
- `api.path.islink(p: string)`: Check if the given path is a symbolic link
- `api.path.unify(paths: table)`: Unify ancestor for the given paths
- `api.path.path_separator`: Get the system path separator

### Debouncing

- `api.debounce(name: string, delay: integer, fn: function)`: Create a debounced version of the given function

### Logging

- `api.log.info(message: string)`: Log an informational message
- `api.log.warn(message: string)`: Log a warning message
- `api.log.error(message: string)`: Log an error message

Here's an example of how you might use the API provided by the `sfm` plugin in your own extension or configuration file:

```lua
local api = require('sfm.api')
-- use the `path.remove_trailing` function to remove trailing slashes from a file path
local cleaned_path = api.path.remove_trailing('/path/to/file/')
-- use the `debounce` function to debounce a function call
api.debounce("debounce-context", 1000, function()
  -- your code
end)
```

## Credits

- This plugin was developed using [NeoVim](https://neovim.io/).
- The file explorer functionality is based on the [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) plugin. I also copied some code from there.
- The icons used in the file explorer are from the [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).
