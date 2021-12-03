#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny leaflet
#' @noRd
app_server <- function( input, output, session ) {
  hide_buttons <- function() {
    lapply(c("yes", "no"), shinyjs::hide)
  }
  show_buttons <- function() {
    lapply(c("yes", "no"), shinyjs::show)
  }

  hide_buttons()

  googlesheets4::gs4_auth(cache=".secrets", email="johan.ejstrud@gmail.com")
  googlesheet <- googlesheets4::gs4_get("1FfmjuUcedOGODkuetrpLXIYYSdKRVQG4oc5EKEEBno0")

  points <- reactiveVal(googlesheets4::read_sheet(ss))

  output$map <- renderLeaflet({
    leaflet() %>%
      fitBounds(lat1=64.20, lng1=-51.75, lat2=64.15, lng2=-51.65) %>%
      addProviderTiles(providers$Stamen.Toner)
  })

  observe({
    leafletProxy("map") %>%
      clearMarkers() %>%
      addCircleMarkers(data=subset(points(), hasPower),
                       fillColor="green",
                       stroke=FALSE) %>%
      addCircleMarkers(data=subset(points(), !hasPower),
                       fillColor="red",
                       stroke=FALSE)
  })

  click <- reactive(input$map_click)

  observe({
    if (is.null(click())) {
      message("null click!")
      return()
    }

    message("click!")

    show_buttons()

    leafletProxy("map") %>%
      clearGroup(group="click") %>%
      addMarkers(data = cbind(click()$lng, click()$lat), group="click")
  })

  save_click_data <- function(clickedHasPower) {
    googlesheets4::sheet_append(ss,
                                data.frame(lat=click()$lat,
                                           lng=click()$lng,
                                           hasPower=clickedHasPower,
                                           time=Sys.time()))

    hide_buttons()

    # Refresh data
    points(googlesheets4::read_sheet(ss))
  }

  observeEvent(input$no,  save_click_data(clickedHasPower=FALSE))
  observeEvent(input$yes, save_click_data(clickedHasPower=TRUE))
}
