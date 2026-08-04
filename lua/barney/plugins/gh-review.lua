local gh_review = require("gh_review")
gh_review.setup({
  keymaps = {
    diff = { preview = false },
    files = { toggle_viewed = "v" },
  },
})
