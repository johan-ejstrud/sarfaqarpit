#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function( input, output, session ) {
  map = createLeafletMap(session, "map")

  output$map <- renderLeaflet({
    leaflet() %>%
      fitBounds(lat1=64.20, lng1=-51.75, lat2=64.15, lng2=-51.65) %>%
      addProviderTiles(providers$Stamen.Toner) %>%
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
    leafletProxy("map") %>%
      clearGroup(group="click") %>%
      addMarkers(data = cbind(click()$lng, click()$lat), group="click")
  })

  points <- reactiveVal(data.frame(lat=as.double(),
                                   lng=as.double(),
                                   hasPower=as.logical()
                                   )
                        )

  add_click_to_points <- function(clickedHasPower) {
    points(
      points() %>%
        tibble::add_row(lng=click()$lng,
                        lat=click()$lat,
                        hasPower=clickedHasPower)
    )
  }

  observeEvent(input$no,  add_click_to_points(clickedHasPower=FALSE))
  observeEvent(input$yes, add_click_to_points(clickedHasPower=TRUE))
}
