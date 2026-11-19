app_ui <- function(request) {
  golem::add_resource_path("www", system.file("app/www", package = "rosoyster"))
app_theme <- bs_theme(
  version = 5,
  bg = "#f4f8fa",
  fg = "#173743",
  primary = "#035b7f",
  secondary = "#607d86",
  success = "#6f8f2f",
  warning = "#b27616",
  base_font = "Source Sans 3, sans-serif",
  heading_font = "Merriweather, Georgia, serif"
)

page_navbar(
  title = div(
    class = "brand-lockup",
    tags$img(src = "www/restore-our-shores-logo.jpg", class = "brand-logo", alt = "Restore Our Shores"),
    div(class = "brand-title", span("Oyster Reef Monitoring"), tags$small("Field data collection"))
  ),
  id = "main_nav",
  theme = app_theme,
  header = tags$head(
    tags$script(src = "www/form-state.js"),
    tags$script(src = "www/workbook-downloads.js"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/app.css")
  ),
  nav_panel(
    "Event Information",
    value = "event_information",
    div(
      class = "container-xl",
      div(
        class = "app-hero",
        span("Restore Our Shores", class = "eyebrow"),
        h1("New monitoring event"),
        p("Start by recording information shared by every observation from this monitoring visit.", class = "lead"),
        div(
          class = "workflow",
          span(class = "workflow-step", tags$b("1"), "Event details"),
          span(class = "workflow-step", tags$b("2"), "Shell measurements"),
          span(class = "workflow-step", tags$b("3"), "Visual survey"),
          span(class = "workflow-step", tags$b("4"), "Structure"),
          span(class = "workflow-step", tags$b("5"), "Review & download")
        )
      ),
      card(
        class = "section-card",
        card_header("1. Event details"),
        card_body(
          mod_event_ui("event"),
          div(class = "page-actions", actionButton("go_measured", "Continue to shell measurements", class = "btn-primary btn-lg"))
        )
      )
    )
  ),
  nav_panel(
    "Shell Measurements", value = "measured_oysters",
    div(class = "container-xl py-4",
      div(class = "page-heading", span("Step 2", class = "page-kicker"), h1("Shell measurements"),
        p("Record 1 to 50 shell heights and the associated species observations for each sample.")),
      card(class = "section-card", card_header("2. Add a shell-measurement sample"), card_body(mod_measured_ui("measured"))),
      div(class = "page-actions", actionButton("go_visual", "Continue to visual survey", class = "btn-primary btn-lg")))
  ),
  nav_panel(
    "Visual Survey",
    value = "visual_survey",
    div(
      class = "container-xl py-4",
      div(class = "page-heading", span("Step 3", class = "page-kicker"), h1("Visual survey observations"),
          p("Add one observation for each module and transect point. Event information remains attached automatically.")),
      card(
        class = "section-card",
        card_header("3. Add an observation"),
        card_body(mod_visual_ui("visual"))
      ),
      div(class = "page-actions", actionButton("go_structural", "Continue to structural monitoring", class = "btn-primary btn-lg"))
    )
  ),
  nav_panel(
    "Structural Monitoring", value = "structural_monitoring",
    div(class = "container-xl py-4",
      div(class = "page-heading", span("Step 4", class = "page-kicker"), h1("Structural monitoring"),
        p("Select the structure type to display the correct depth positions. Bag and Gabion use the same fields.")),
      card(class = "section-card", card_header("4. Add a structural observation"), card_body(mod_structural_ui("structural"))),
      div(class = "page-actions", actionButton("go_review", "Review staged data", class = "btn-primary btn-lg")))
  ),
  nav_panel("Review & Download", value = "review_submit", mod_review_ui("review")),
  nav_panel(
    "About",
    value = "about",
    div(
      class = "container-lg py-4",
      card(
        class = "section-card",
        card_header("Monitoring workflow"),
        card_body(
          p("This application implements the linked oyster reef monitoring workflows from the BZ Oyster Monitoring workbook."),
          tags$ul(
            tags$li("Shared event information is entered once per monitoring visit."),
            tags$li("Any number of module/transect observations can be staged before finalizing."),
            tags$li("Finalize the event, review all data, and download one Excel workbook with six standard sheets."),
            tags$li("Shell samples accept 1 to 50 shell heights in millimeters."),
            tags$li("Corral depth fields differ from the shared Bag/Gabion form.")
          )
        )
      )
    )
  )
)

}
