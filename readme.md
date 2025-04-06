# angular-file-switcher.nvim

A Neovim plugin written in Lua to quickly switch between related Angular component files: template (.html), spec (.spec.ts), TypeScript (.ts), and CSS (.css).

![Angular File Switcher demo](https://github.com/vijhhh2/angular-switch.nvim/blob/main/assets/angular-switch.gif)

## Features

* **Effortless Navigation:** Quickly jump between your Angular component's:
    * HTML template (`.html`)
    * Unit test file (`.spec.ts`)
    * Main TypeScript file (`.ts`)
    * Associated CSS files (`.css`, `.scss`, `.sass`, `.less`, etc.)
* **Intuitive Command:** A simple command to trigger the file switching.
* **Written in Lua:** Lightweight and fast.

## Prerequisites

* Neovim v0.5.0 or higher (for Lua plugin support)
* An Angular project

## Installation

You can install this plugin using your lazy.nvim package manager. Here are a few common examples:

**lazy.nvim:**

```lua
  {
    "vijhhh2/angular-switch.nvim",
    config = function()
      require("angular-switch").setup()
    end,
    keys = {
      { "<S-A-h>", "<cmd>AsSwitchToHtml<cr>", desc = "Angular Switch to  html" },
      { "<S-A-t>", "<cmd>AsSwitchToTs<cr>", desc = "Angular Switch to  typescript" },
      { "<S-A-c>", "<cmd>AsSwitchToStyles<cr>", desc = "Angular Switch to  styles" },
      { "<S-A-s>", "<cmd>AsSwitchToSpec<cr>", desc = "Angular Switch to  html" },
    },
  }
```
