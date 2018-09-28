library(moveVis)
library(move)
library(dplyr)

GTFS <- read.csv("data_GTFS/GTFS.csv")
GTFS <- read.csv("data_GTFS/GTFS_M05.csv")

GTFS$arrival_time <- as.POSIXct(strptime(GTFS$arrival_time, "%H:%M:%S", tz = "UTC"))
GTFS$route_color <- paste("#", GTFS$route_color, sep="")

conv_dir <- get_libraries()

out_dir <- paste0(getwd(),"/test")

GTFS_ani <- split(move(GTFS$stop_lon, GTFS$stop_lat, proj=CRS("+proj=longlat +ellps=WGS84"),
                       time = GTFS$arrival_time, animal=GTFS$trip_id, data=GTFS))

line_colors <- GTFS %>%
      group_by(trip_id) %>%
      slice(1) %>% pull(route_color) %>%
      as.vector


img_caption <- "Projection: Geographical, WGS84; Sources: GTFS CRTM Madrid 2018; Google Maps"
img_title <- "Metro, trams and suburban trains in Madrid (9-10am, weekday)"

animate_move(GTFS_ani, out_dir, out_name = "test5", conv_dir = conv_dir, 
             tail_elements = 6, tail_size = 2,
             paths_mode = "true_data", frames_nmax = 0,
             img_caption = img_caption, img_title = img_title,
             # img_sub = img_sub,
             log_level = 1, out_format = "mp4",
             map_type = "roadmap",
             paths_col = line_colors)
