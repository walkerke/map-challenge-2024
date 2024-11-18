library(shiny)
library(bslib)
library(mapgl)
library(sf)
library(colourpicker)
library(dplyr)

pipelines <- st_read("ppl_arcs/ppl_arcs.shp")

status_dict <- tibble::tribble(
  ~status, ~STATUS_COD,
  "ABANDONED AND COMBINED", "A/C",
  "OUT AND COMBINED", "O/C",
  "ABANDONED", "ABN",
  "ACTIVE", "ACT",
  "RELINQUISHED", "RELQ",
  "REMOVED", "REM",
  "PROPOSED", "PROP",
  "RELINQUISHED AND COMBINED", "R/C",
  "PROPOSE REMOVAL", "PREM",
  "PROPOSE ABANDONMENT", "PABN",
  "RELINQUISHED AND ABANDONED", "R/A",
  "COMBINED", "COMB",
  "RELINQUISHED AND REMOVED", "R/R",
  "OUT OF SERVICE", "OUT",
  "CANCELLED", "CNCL"
)

 # Product dictionary
prod_dict <- tibble::tribble(
  ~product, ~PROD_CODE,
  "UMBILICAL LINE. USUALLY INCLUDES PNEUMATIC OR HYDRAULIC CONT", "UMB",
  "GAS AND CONDENSATE (H2S)", "G/CH",
  "METHANOL / GLYCOL", "METH",
  "PIPELINE USED AS A PROTECTIVE CASING (CSNG) FOR ANOTHER PIPELINE", "CSNG",
  "NATURAL GAS ENHANCED RECOVERY", "NGER",
  "TEST", "TEST",
  "WATER", "H2O",
  "PROCESSED GAS WITH TRACE LEVELS OF HYDROGEN SULFIDE", "GASH",
  "CONDENSATE OR DISTILLATE TRANSPORTED DOWNSTREAM OF FIRST PRO", "COND",
  "GAS INJECTION", "INJ",
  "CORROSION INHIBITOR OR OTHER CHEMICALS", "CHEM",
  "SPARE", "SPRE",
  "LIQUID GAS ENHANCED RECOVERY", "LGER",
  "RENEWABLE ENERGY POWER CABLE", "CBLR",
  "GAS LIFT", "LIFT",
  "CARBON DIOXIDE (SUPPORT ACTIVITY LEASE)", "CO2",
  "PRESSURIZED WATER (RENEWABLE ENERGY)", "PWTR",
  "OIL AND WATER TRANSPORTED AFTER FIRST PROCESSING", "O/W",
  "SERVICE OR UTILITY LINE USED FOR PIGGING AND PIPELINE MAINTE", "SERV",
  "SUPPLY GAS", "SPLY",
  "POWER CABLE", "CBLP",
  "OIL TRANSPORTED AFTER FIRST PROCESSING", "OIL",
  "PNEUMATIC", "AIR",
  "PROCESSED OIL WITH TRACE LEVELS OF HYDROGEN SULFIDE", "OILH",
  "BULK OIL - FULL WELL STREAM PRODUCTION FROM OIL WELL(S) PRIO", "BLKO",
  "BULK GAS - FULL WELL STREAM PRODUCTION FROM GAS WELL(S) PRIO", "BLKG",
  "A NON-UMBILICAL CABLE SUCH AS FIBER OPTIC/COMMUNICATIONS", "CBLC",
  "ELECTRICAL UMBILICAL", "UMBE",
  "GAS AND CONDENSATE SERVICE AFTER FIRST PROCESSING", "G/C",
  "GAS AND OIL (H2S)", "G/OH",
  "HYDRAULIC UMBILICAL", "UMBH",
  "GAS AND OIL SERVICE AFTER FIRST PROCESSING", "G/O",
  "CHEMICAL UMBILICAL", "UMBC",
  "GAS TRANSPORTED AFTER FIRST PROCESSING", "GAS",
  "TOW ROUTE ONLY - NOT A PIPELINE", "TOW",
  "ACID", "ACID",
  "LIQUID PROPANE", "LPRO",
  "BULK GAS WITH TRACE LEVELS OF HYDROGEN SULFIDE", "BLGH"
)

pipelines <- pipelines |>
  left_join(prod_dict, by = "PROD_CODE") |>
  left_join(status_dict, by = "STATUS_COD")


 pipelines$popup_text <- paste0(
  "<b>Pipeline Details</b><br>",
  "Size: ", ifelse(!is.na(pipelines$PPL_SIZE_C),
    pipelines$PPL_SIZE_C, "Unknown"), " inches<br>",
  "Product: ", pipelines$product, "<br>",
  "Status: ", pipelines$status, "<br>",
  "Company: ", pipelines$SDE_COMPAN, "<br>",
  "Length: ", round(pipelines$SEG_LENGTH, 0), " feet<br>"
 )

ui <- page_navbar(
  theme = bs_theme(bootswatch = "cerulean"),
  title = "Pipelines in the Gulf of Mexico",
  sidebar = sidebar(
    colourInput("color", "Select a pipeline color", value = "#0077be"),
    sliderInput("opacity", "Pipeline opacity", min = 0, max = 1, value = 0.7, step = 0.1),
    sliderInput("size", "Minimum pipeline diameter (inches)",
              min = 0,
              max = 54,
              value = 0,
              step = 0.5)
  ),
  card(
    full_screen = TRUE,
    mapboxglOutput("map")
  )
)

server <- function(input, output, session) {
  output$map <- renderMapboxgl({
    mapboxgl(style = maptiler_style("ocean", api_key = "YOUR_MAPTILER_KEY"), bounds = pipelines,
             customAttribution = '<a href="https://www.data.boem.gov/Main/Mapping.aspx">Data source: BOEM</a>',
             access_token = "YOUR_MAPBOX_TOKEN") |>
      add_line_layer(id = "pipelines",
                     source = pipelines,
                     line_color = "#0077be",
                     line_opacity = 0.7,
                     line_width = 3,
                     hover_options = list(
                       line_color = "yellow",
                       line_width = 7
                     ),
                     popup = "popup_text")
  })

  observeEvent(input$color, {
    mapboxgl_proxy("map") |>
      set_paint_property("pipelines", "line-color", input$color)
  })

  observeEvent(input$opacity, {
    mapboxgl_proxy("map") |>
      set_paint_property("pipelines", "line-opacity", input$opacity)
  })


observeEvent(input$size, {
  size_filter <- list(">=", list("to-number", list("get", "PPL_SIZE_C")), input$size)

  mapboxgl_proxy("map") |>
    set_filter("pipelines", size_filter)
})
}

shinyApp(ui, server)
