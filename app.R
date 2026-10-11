library(shiny)
library(bslib)

source("R/constants.R", local = TRUE)
source("R/validation.R", local = TRUE)
source("R/storage.R", local = TRUE)
source("R/mod_event.R", local = TRUE)
source("R/mod_visual.R", local = TRUE)
source("R/mod_measured.R", local = TRUE)
source("R/mod_structural.R", local = TRUE)
source("R/mod_review.R", local = TRUE)

app_theme <- bs_theme(
  version = 5,
  bg = "#f4f8fa",
  fg = "#173743",
  primary = "#035b7f",
  secondary = "#607d86",
  success = "#6f8f2f",
  warning = "#b27616",
  base_font = font_google("Source Sans 3"),
  heading_font = font_google("Merriweather")
)

ui <- page_navbar(
  title = div(
    class = "brand-lockup",
    tags$img(src = "restore-our-shores-logo.jpg", class = "brand-logo", alt = "Restore Our Shores"),
    div(class = "brand-title", span("Oyster Reef Monitoring"), tags$small("Field data collection"))
  ),
  id = "main_nav",
  theme = app_theme,
  header = tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", type = "text/css", href = "app.css"),
    tags$style(HTML("\n+      body { background: linear-gradient(180deg, #eef7f3 0, #f9fbfa 260px); }\n+      .navbar { border-bottom: 4px solid #d99b45; }\n+      .brand-lockup { display:flex; align-items:center; gap:.65rem; font-weight:700; }\n+      .brand-mark { display:inline-grid; place-items:center; width:2.4rem; height:2.4rem;\n+        border-radius:50%; background:#d99b45; color:#17352c; font-family:Georgia,serif; }\n+      .app-hero { padding:1.5rem 0 .75rem; }\n+      .app-hero h1 { color:#174e41; font-size:clamp(1.75rem,4vw,2.8rem); }\n+      .section-card { border:0; border-top:5px solid #2f8871; box-shadow:0 4px 18px rgba(23,53,44,.08); }\n+      .metric { background:#eef7f3; border-radius:.65rem; padding:.75rem; text-align:center; }\n+      .metric strong { display:block; color:#174e41; font-size:1.4rem; }\n+      .required-label::after { content:' *'; color:#b42318; }\n+      .sticky-actions { position:sticky; bottom:0; background:rgba(247,250,248,.96);\n+        border-top:1px solid #ccdcd6; padding:.85rem 0; z-index:10; }\n+      .table-wrap { overflow-x:auto; }\n+      .help-note { color:#58756d; font-size:.92rem; }\n+      @media (max-width: 768px) { .container-fluid { padding-left:.8rem; padding-right:.8rem; } }\n+    "))
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
          span(class = "workflow-step", tags$b("2"), "Visual survey"),
          span(class = "workflow-step", tags$b("3"), "Measure oysters"),
          span(class = "workflow-step", tags$b("4"), "Structure"),
          span(class = "workflow-step", tags$b("5"), "Review & submit")
        )
      ),
      card(
        class = "section-card",
        card_header("1. Event details"),
        card_body(
          mod_event_ui("event"),
          div(class = "page-actions", actionButton("go_visual", "Continue to visual survey", class = "btn-primary btn-lg"))
        )
      )
    )
  ),
  nav_panel(
    "Visual Survey",
    value = "visual_survey",
    div(
      class = "container-xl py-4",
      div(class = "page-heading", span("Step 2", class = "page-kicker"), h1("Visual survey observations"),
          p("Add one observation for each module and transect point. Event information remains attached automatically.")),
      card(
        class = "section-card",
        card_header("2. Add an observation"),
        card_body(mod_visual_ui("visual"))
      ),
      div(class = "page-actions", actionButton("go_measured", "Continue to 50 measured oysters", class = "btn-primary btn-lg"))
    )
  ),
  nav_panel(
    "50 Measured Oysters", value = "measured_oysters",
    div(class = "container-xl py-4",
      div(class = "page-heading", span("Step 3", class = "page-kicker"), h1("50 measured oysters"),
        p("Record one complete set of 50 shell heights and the associated species observations for each sample.")),
      card(class = "section-card", card_header("3. Add a measured-oyster sample"), card_body(mod_measured_ui("measured"))),
      div(class = "page-actions", actionButton("go_structural", "Continue to structural monitoring", class = "btn-primary btn-lg")))
  ),
  nav_panel(
    "Structural Monitoring", value = "structural_monitoring",
    div(class = "container-xl py-4",
      div(class = "page-heading", span("Step 4", class = "page-kicker"), h1("Structural monitoring"),
        p("Select the structure type to display the correct depth positions. Bag and Gabion use the same fields.")),
      card(class = "section-card", card_header("4. Add a structural observation"), card_body(mod_structural_ui("structural"))),
      div(class = "page-actions", actionButton("go_review", "Review staged data", class = "btn-primary btn-lg")))
  ),
  nav_panel("Review & Submit", value = "review_submit", mod_review_ui("review")),
  nav_panel(
    "About",
    value = "about",
    div(
      class = "container-lg py-4",
      card(
        class = "section-card",
        card_header("First-draft scope"),
        card_body(
          p("This prototype implements the linked oyster reef monitoring workflows from the BZ Oyster Monitoring workbook."),
          tags$ul(
            tags$li("Shared event information is entered once per monitoring visit."),
            tags$li("Any number of module/transect observations can be staged before submission."),
            tags$li("Local CSV storage is used for development; Google Sheets is supported through configuration."),
            tags$li("Every measured-oyster sample requires exactly 50 shell heights in millimeters."),
            tags$li("Corral depth fields differ from the shared Bag/Gabion form.")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  event <- mod_event_server("event")
  visual <- mod_visual_server("visual")
  measured <- mod_measured_server("measured")
  structural <- mod_structural_server("structural")
  mod_review_server("review", event, visual, measured, structural)

  observeEvent(input$go_visual, {
    bslib::nav_select("main_nav", selected = "visual_survey", session = session)
  })

  observeEvent(input$go_review, {
    bslib::nav_select("main_nav", selected = "review_submit", session = session)
  })

  observeEvent(input$go_measured, {
    bslib::nav_select("main_nav", selected = "measured_oysters", session = session)
  })

  observeEvent(input$go_structural, {
    bslib::nav_select("main_nav", selected = "structural_monitoring", session = session)
  })
}

shinyApp(ui, server)
