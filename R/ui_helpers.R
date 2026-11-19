notes_label <- function(label) {
  tagList(label, " ", bslib::tooltip(
    tags$span("i", class = "notes-info", tabindex = "0", role = "button",
      `aria-label` = "Notes formatting help"),
    "Separate individual notes with a semicolon (;)."
  ))
}
