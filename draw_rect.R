library(imager)
library(magick)


plot(draw_rect("/Users/yingda/Desktop/截屏2023-11-27 下午7.56.41.png",1,1,50,50,"darkgreen"))


require(jpeg)
require(png)
image_path <- "/Users/yingda/Desktop/截屏2023-11-27 下午7.56.41.png"
img <- readPNG(image_path)
plot(1:dim(img)[2], type='n')
rasterImage(img, 1, 1, dim(img)[2], dim(img)[2])

rect(1085, 581, 1127, 669, border = "red")

library(magick)
street_view1 <- image_read("/Users/yingda/Desktop/截屏2023-11-27 下午7.56.41.png")

street_view1 <- image_annotate(street_view1, "label", 
                               size = 15, color = "red", location ="+1085+581")

img <- image_draw(street_view1)
rect(1085, 581, 1127, 669, border = "red", lty = "dashed", lwd = 5)

image_write(img, path = "imge.jpg", format = 'jpg')
