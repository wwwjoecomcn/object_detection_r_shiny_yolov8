library(shiny)
library(magick)

# Install custermized googleway 
# devtools::install_github("yingda-guo-capgemini/googleway")
library(googleway)

# Load Google api key
source("~/private/googlemap_api_key.R")
googleway::set_key(google_map_api_key)


# Set up python environment
library(reticulate)
use_python("/opt/homebrew/Caskroom/miniforge/base/envs/yolov8/bin/python")
# Load Object Detection script
source_python("object_detector.py")

# Set up maximal upload file size
options(shiny.maxRequestSize = 10 * 1024^2)

ui <- fluidPage(
  # Use imageOutput to place the image on the page
  fluidRow(width = 12,
           google_mapOutput(outputId = "map")),
  fluidRow(width = 12,
           google_mapOutput(outputId = "pano")),
  fluidRow(actionButton("ab_detect", "Run Object Detection")),
  fluidRow(imageOutput("input_image", width = 12))

)

server <- function(input, output, session) {
  
  # Render a google map view
  output$map <- renderGoogle_map({
    google_map(data = df, location = c(44.564296, -80.939121), split_view = "pano")
  })
  
  # Get pano view info
  pano_view_info <- reactiveVal()
  
  # When click run object detection code
  observeEvent(input$ab_detect,{
    
    pano_view_info(list(pano_lat = input$map_pano_position_changed$lat, 
                        pano_lng = input$map_pano_position_changed$lon,
                        pano_heading = input$map_pano_view_changed$heading,
                        pano_pitch = input$map_pano_view_changed$pitch))

  })
  
  
  output$input_image <- renderImage({
    
    shiny::req(pano_view_info())
    # A temp file to save the output.
    pano_info <- pano_view_info()
    # This file will be removed later by renderImage
    pano_street_view_url <- google_streetview(location = c(pano_info$pano_lat, pano_info$pano_lng), 
                                              heading = pano_info$pano_heading, 
                                              pitch = pano_info$pano_pitch,
                                              output = "html", size = c(640, 640))
    
    # Load in streetview
    street_view <- image_read(pano_street_view_url)
    
    # Write image to a tmp file
    tmpfile <- image_write(street_view, tempfile(fileext='.jpg'), format = 'jpg')
    
    # Run object detection code
    object_detection <- detect_objects_on_image(tmpfile)
    
    
    # Start to add annotations
    for(i in 1:length(object_detection)){
      object <- object_detection[[i]]
      street_view <- image_annotate(street_view, object[[5]], 
                                    size = 15, color = "red", 
                                    location = paste0("+", object[[1]], "+", object[[2]] - 20))
    }
    
    # Draw rectangles
    street_view <- image_draw(street_view)
    for(i in 1:length(object_detection)){
      object <- object_detection[[i]]
      rect(object[[1]], object[[2]], object[[3]], object[[4]], border = "red", lwd = 2)
    }
    
    # Write image to a tmp file
    tmpfile <- image_write(street_view, tempfile(fileext='.jpg'), format = 'jpg')
    
    # Return a list
    list(src = tmpfile, contentType = "image/jpeg")
  }, deleteFile = TRUE)
  

  
  

}

shinyApp(ui, server)