# Today's map is different!
# I'm recording a video geocoding where I lived during study abroad 
# in college in Angers, France 21 years ago, and trying to remember
# my walking commute to the Universite Catholique de l'Ouest campus.
#
# I'm using the geocoder control to locate the house where I stayed, 
# and the draw control to draw the walking route.  

library(mapgl)

mapboxgl() |> 
  add_geocoder_control() |> 
  add_draw_control()