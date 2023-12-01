library(shiny)
library(magick)

# Set up python environment
library(reticulate)
use_python("/opt/homebrew/Caskroom/miniforge/base/envs/yolov8/bin/python")
# Load Object Detection script
source_python("object_detector.py")

# Set up maximal upload file size
options(shiny.maxRequestSize = 10 * 1024^2)

ui <- pageWithSidebar(
  headerPanel("Object Detection using YOLO V8"),
  sidebarPanel(
    fileInput(inputId = "upload", label = "Upload an Image", accept = c(".jpg", ".png", ".jpeg"))
  ),
  mainPanel(
    # Use imageOutput to place the image on the page
    imageOutput("input_image")
  )
)

server <- function(input, output, session) {
  output$input_image <- renderImage({
    
    shiny::req(input$upload)
    # A temp file to save the output.
    # This file will be removed later by renderImage
    outfile_path <- input$upload$datapath
    
    # Run object detection code
    object_detection <- detect_objects_on_image(outfile_path)
    
    # Load in streetview
    street_view <- image_read(outfile_path)
    
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
    tmpfile <- image_write(street_view, tempfile(fileext='jpg'), format = 'jpg')
    
    # Return a list
    list(src = tmpfile, contentType = "image/jpeg")
  }, deleteFile = TRUE)
}

shinyApp(ui, server)