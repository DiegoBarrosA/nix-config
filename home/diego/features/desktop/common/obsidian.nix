{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.colorscheme) colors;

  # Generate Obsidian CSS that matches Stylix colors
  obsidianStylix = pkgs.writeText "obsidian-stylix.css" ''
    /* Obsidian Stylix Theme - Generated from colorscheme */

    :root {
      /* Primary colors from Stylix */
      --color-primary: #${colors.base0D};
      --color-accent: #${colors.base0D};
      --color-background: #${colors.base00};
      --color-text: #${colors.base05};
      --color-text-secondary: #${colors.base04};
      --color-text-tertiary: #${colors.base03};
      
      /* UI colors */
      --color-success: #${colors.base0B};
      --color-warning: #${colors.base0A};
      --color-error: #${colors.base08};
      --color-info: #${colors.base0C};
      
      /* Neutral colors */
      --color-dark: #${colors.base01};
      --color-light: #${colors.base06};
      --color-border: #${colors.base02};
      
      /* Syntax highlighting */
      --color-keyword: #${colors.base0E};
      --color-string: #${colors.base0B};
      --color-number: #${colors.base09};
      --color-comment: #${colors.base03};
      --color-function: #${colors.base0D};
    }

    /* Editor background */
    .markdown-preview-view,
    .markdown-source-view,
    .cm-editor {
      background-color: #${colors.base00} !important;
      color: #${colors.base05} !important;
    }

    /* Sidebar */
    .sidebar {
      background-color: #${colors.base01} !important;
      border-color: #${colors.base02} !important;
    }

    /* File tree */
    .nav-file-title,
    .nav-folder-title {
      color: #${colors.base04} !important;
    }

    .nav-file-title:hover,
    .nav-folder-title:hover {
      background-color: rgba(130, 170, 255, 0.1) !important;
    }

    .nav-file-title.is-active {
      background-color: rgba(130, 170, 255, 0.2) !important;
      color: #${colors.base0D} !important;
    }

    /* Ribbon */
    .side-dock-ribbon {
      background-color: #${colors.base01} !important;
      border-color: #${colors.base02} !important;
    }

    .side-dock-ribbon-action {
      color: #${colors.base04} !important;
    }

    .side-dock-ribbon-action:hover,
    .side-dock-ribbon-action.is-active {
      background-color: rgba(130, 170, 255, 0.15) !important;
      color: #${colors.base0D} !important;
    }

    /* Tabs */
    .workspace-tab-header {
      background-color: #${colors.base01} !important;
      border-color: #${colors.base02} !important;
      color: #${colors.base04} !important;
    }

    .workspace-tab-header.is-active {
      background-color: #${colors.base00} !important;
      border-bottom-color: #${colors.base0D} !important;
      color: #${colors.base05} !important;
    }

    /* Buttons */
    button,
    .button {
      background-color: #${colors.base02} !important;
      color: #${colors.base05} !important;
      border: 1px solid #${colors.base03} !important;
    }

    button:hover,
    .button:hover {
      background-color: #${colors.base03} !important;
      border-color: #${colors.base0D} !important;
    }

    button.mod-cta,
    .button.mod-cta {
      background-color: #${colors.base0D} !important;
      color: #${colors.base00} !important;
    }

    /* Input fields */
    input,
    textarea,
    select {
      background-color: #${colors.base01} !important;
      color: #${colors.base05} !important;
      border: 1px solid #${colors.base02} !important;
    }

    input:focus,
    textarea:focus,
    select:focus {
      border-color: #${colors.base0D} !important;
      box-shadow: 0 0 0 2px rgba(130, 170, 255, 0.2) !important;
    }

    /* Code blocks */
    code,
    pre {
      background-color: #${colors.base01} !important;
      color: #${colors.base0D} !important;
    }

    .cm-s-obsidian {
      background-color: #${colors.base00} !important;
      color: #${colors.base05} !important;
    }

    .cm-s-obsidian .cm-string {
      color: #${colors.base0B} !important;
    }

    .cm-s-obsidian .cm-number {
      color: #${colors.base09} !important;
    }

    .cm-s-obsidian .cm-atom {
      color: #${colors.base0E} !important;
    }

    .cm-s-obsidian .cm-variable {
      color: #${colors.base0D} !important;
    }

    .cm-s-obsidian .cm-comment {
      color: #${colors.base03} !important;
    }

    /* Headers */
    h1, h2, h3, h4, h5, h6 {
      color: #${colors.base0D} !important;
    }

    /* Links */
    a,
    .internal-link {
      color: #${colors.base0D} !important;
    }

    a:hover,
    .internal-link:hover {
      text-decoration: underline;
      color: #${colors.base0C} !important;
    }

    /* Blockquotes */
    blockquote {
      border-left: 3px solid #${colors.base0D} !important;
      color: #${colors.base04} !important;
    }

    /* Tables */
    table {
      border-color: #${colors.base02} !important;
    }

    th {
      background-color: #${colors.base02} !important;
      color: #${colors.base05} !important;
    }

    td {
      border-color: #${colors.base02} !important;
    }

    /* Popups and modals */
    .modal,
    .prompt {
      background-color: #${colors.base01} !important;
      color: #${colors.base05} !important;
      border: 1px solid #${colors.base02} !important;
    }

    /* Checkboxes */
    input[type="checkbox"] {
      accent-color: #${colors.base0D} !important;
    }

    /* Scrollbars */
    ::-webkit-scrollbar {
      width: 10px;
      height: 10px;
    }

    ::-webkit-scrollbar-track {
      background: #${colors.base01} !important;
    }

    ::-webkit-scrollbar-thumb {
      background: #${colors.base03} !important;
      border-radius: 5px;
    }

    ::-webkit-scrollbar-thumb:hover {
      background: #${colors.base0D} !important;
    }

    /* Obsidian tag pills */
    .tag {
      background-color: rgba(130, 170, 255, 0.15) !important;
      color: #${colors.base0D} !important;
      border-radius: 12px;
      padding: 2px 8px;
    }

    .tag:hover {
      background-color: rgba(130, 170, 255, 0.25) !important;
    }

    /* Graph view */
    .graph-controls {
      background-color: #${colors.base01} !important;
      color: #${colors.base05} !important;
    }

    /* Canvas nodes */
    .canvas-node {
      background-color: #${colors.base01} !important;
      border-color: #${colors.base02} !important;
    }

    .canvas-node.is-selected {
      border-color: #${colors.base0D} !important;
    }

    /* Status bar */
    .status-bar {
      background-color: #${colors.base01} !important;
      border-top: 1px solid #${colors.base02} !important;
      color: #${colors.base04} !important;
    }

    /* Vault switcher */
    .vault-switcher {
      background-color: #${colors.base01} !important;
    }

    /* Search and replace */
    .search-result {
      background-color: rgba(130, 170, 255, 0.1) !important;
    }

    .search-result.is-highlighted {
      background-color: rgba(130, 170, 255, 0.25) !important;
    }

    /* Highlights and marks */
    mark {
      background-color: rgba(255, 235, 59, 0.3) !important;
      color: #${colors.base05} !important;
    }

    /* Transparent base color for RGBA */
    .transparent-bg {
      background-color: rgba(130, 170, 255, 0.1) !important;
    }

    .transparent-bg-light {
      background-color: rgba(130, 170, 255, 0.05) !important;
    }

    .transparent-bg-medium {
      background-color: rgba(130, 170, 255, 0.2) !important;
    }
  '';
in
{
  # Add Obsidian to packages
  home.packages = with pkgs; [
    obsidian
  ];

  # Copy Stylix CSS to Obsidian snippets folder
  xdg.configFile."obsidian/snippets/stylix.css".source = obsidianStylix;

  # Note: To enable this snippet in Obsidian:
  # 1. Open Obsidian settings
  # 2. Go to Appearance > CSS snippets
  # 3. Enable the "stylix" snippet
  # Or uncomment the line below if you want to try to symlink it directly
  # home.file.".obsidian/snippets/stylix.css".source = obsidianStylix;
}
