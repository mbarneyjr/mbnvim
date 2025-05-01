local image = require("image")
image.setup({
  processor = "magick_cli",
  max_height_window_percentage = 95,
  window_overlap_clear_enabled = true,
})
