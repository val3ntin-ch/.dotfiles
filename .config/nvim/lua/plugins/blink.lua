return {
  -- LazyVim's default blink.cmp keymap is "enter" — <Tab> only jumps snippet
  -- placeholders (via snippet_forward), it never accepts/selects a menu item,
  -- so typing "rafce" and pressing Tab did nothing. "super-tab" makes <Tab>
  -- accept the highlighted item (expanding the snippet) when nothing's
  -- active, and jump snippet placeholders once one's expanded.
  "saghen/blink.cmp",
  opts = {
    keymap = { preset = "super-tab" },
  },
}
