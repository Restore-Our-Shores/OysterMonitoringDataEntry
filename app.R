library(shiny)
library(bslib)

source("R/constants.R", local = TRUE)
source("R/validation.R", local = TRUE)
source("R/storage.R", local = TRUE)
source("R/mod_event.R", local = TRUE)
source("R/mod_visual.R", local = TRUE)
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
          span(class = "workflow-step", tags$b("2"), "Add observations"),
          span(class = "workflow-step", tags$b("3"), "Review & submit")
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
      div(class = "page-actions", actionButton("go_review", "Review staged observations", class = "btn-primary btn-lg"))
    )
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
          p("This prototype implements the visual survey from the BZ Oyster Monitoring workbook."),
          tags$ul(
            tags$li("Shared event information is entered once per monitoring visit."),
            tags$li("Any number of module/transect observations can be staged before submission."),
            tags$li("Local CSV storage is used for development; Google Sheets is supported through configuration."),
            tags$li("The detailed 50-oyster and structural protocols are planned as later modules.")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  event <- mod_event_server("event")
  visual <- mod_visual_server("visual")
  mod_review_server("review", event, visual$observations, visual$clear_all)

  observeEvent(input$go_visual, {
    bslib::nav_select("main_nav", selected = "visual_survey", session = session)
  })

  observeEvent(input$go_review, {
    bslib::nav_select("main_nav", selected = "review_submit", session = session)
  })
}

shinyApp(ui, server)
