(
  (comment) @_html_comment
  (#eq? @_html_comment "/* html */")
  (template_string) @injection.content
  (#set! injection.language "html")
)
(
  (comment) @_css_comment
  (#eq? @_css_comment "/* css */")
  (template_string) @injection.content
  (#set! injection.language "css")
)
(
  (comment) @_html_comment
  (#eq? @_html_comment "/* sql */")
  (template_string) @injection.content
  (#set! injection.language "sql")
)
