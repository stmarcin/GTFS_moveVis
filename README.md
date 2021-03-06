# GTFS_moveVis

Scripts for playing with moveVis and transport (GTFS) data. Created for data provided by [*Consorcio de Transportes de Madrid*](https://www.crtm.es) (data can be found [here](http://datos.crtm.es)).
The repo consist of two parts:

1) [Part I](##part_1) that convert set of required GTFS files into one, which is then used by `moveVis` package:

2) [Part II](#part_2) is an example how to create a video showing movement of public tranpsort vehicles using `moveVis´ package.

Both functions requires `dplyr` package, while the second one additionally requires `chron` package.

## Part I {#part_1}

Preparation of GTFS files: collect all required information from existing set of GTFS files and combine them into one `csv` file.
Depending on the character of GTFS data there are two separate funtions:

* [`GTFS_to_moveVis_DepTime`](#DepartureTimes) for GTFS which uses exact departure times;
* [`GTFS_to_moveVis_Freq`](#Frequency) for GTFS which are based on frequency data.

In both cases the output file contains the following variables:

* *trip_id*: individual id of the trip;
* *arrival_time*: in the format HH:MM:SS
* *stop_lat* and *stop_lon*: coordinates of stops
* *route_short_name*
* *route_color*

#### GTFS that uses exact departure times {#DepartureTimes}

Required functions: 

```
require(dplyr)

```

Script uses following files as an **input**

* `stop_times.txt`: departure times
* `stops.txt`: location of stops
* `trips.txt`: selected trips & connection between `calendar`, `routes` and `stop_times`
* `calendar.txt`: trips realized during specified date(s)
* `routes.txt`: (short) name of route and its default color

##### Function syntax:

```

GTFS_to_moveVis_DepTime <- function(dir_GTFS, startHH = 6, endHH = 8, file_output = "GTFS.csv")

```
with following parameters:

* *dir_GTFS*: directory where the original GTFS files are stored; **no default**.
* *startHH*: hour of the begining of the animation; numeric; **default** `startHH = 6` 
* *endHH*: hour of the end of the animation; numeric; **default** `endHH = 8` ^1^
* *file_output* name of the file with the final output. **default** `file_output = "GTFS.csv"`

^1^ for computational reasons the time coverage is limited, in the default settings to 2 hours;

Application of the funciton (example of suburban trains and trams in Madrid):

```
# cercanias (suburban trains):
GTFS_to_moveVis_DepTime(dir_GTFS = "data_GTFS/google_transit_M05", startHH=6, endHH=8, file_output = "data_GTFS/GTFS_M05.csv")

# metro ligero (trams):
GTFS_to_moveVis_DepTime(dir_GTFS = "data_GTFS/google_transit_M10", startHH=6, endHH=8, file_output = "data_GTFS/GTFS_M10.csv")

```

#### GTFS that uses frequency  {#Frequency}

Comparing to the previous, this function add (multiply) consequtive trips, using minimum frequency for a given route (line). 
Travel times between the stops are equal to the original one. 

Required functions: 

```
require(dplyr)
require(chron)

```
Script uses following files as an **input**

* `stop_times.txt`: departure (arrival) times
* `stops.txt`: location of stops
* `trips.txt`: selected trips & connection between `calendar`, `routes` and `stop_times`
* `calendar.txt`: trips realized during specified date(s)
* `routes.txt`: (short) name of route and its default color
* `frequencies.txt`: (minimum) frequency of a given route (line)

##### Function syntax:

```

GTFS_to_moveVis_Freq <- function(dir_GTFS, startHH = 6, endHH = 8, file_output = "GTFS.csv"){

```
with following parameters:

* *dir_GTFS*: directory where the original GTFS files are stored; **no default**.
* *startHH*: hour of the begining of the animation; numeric; **default** `startHH = 6` 
* *endHH*: hour of the end of the animation; numeric; **default** `endHH = 8` ^1^
* *file_output* name of the file with the final output. **default** `file_output = "GTFS.csv"`

^1^ for computational reasons the time coverage is limited, in the default settings to 2 hours;

Application of the function (example of metro lines in Madrid):

```
GTFS_to_moveVis_Freq(dir_GTFS = "data_GTFS/google_transit_M04", startHH = 6, endHH = 8, file_output = "data_GTFS/GTFS_M04.csv")

```

#### Step 1'

Once separate files for each of the included transport modes are ready, they have to be combined together:

```
# read file with metro
GTFS <- read.delim(paste("data_GTFS", "GTFS_M04.csv", sep = "/"), sep=",") %>%
      
      #read file with suburban trains
      bind_rows(read.delim(paste("data_GTFS", "GTFS_M05.csv", sep = "/"), sep=",")) %>%
      
      # read file with trams
      bind_rows(read.delim(paste("data_GTFS", "GTFS_M10.csv", sep = "/"), sep=","))

# save output:
write.csv(GTFS, paste("data_GTFS", "GTFS.csv", sep = "/"), row.names = F, quote = F)
```

## Part II {#part_2}

Scirpt used to generate an example: suburban trains, metros and trams in Madrid. It is strongly inspired by an example provided by the author of moveVis package ([16EAGLE](https://github.com/16EAGLE)). A reproductible example is available [here](https://github.com/16EAGLE/moveVis).


```
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
```


![alt text](https://github.com/stmarcin/GTFS_moveVis/blob/master/imgs/moveVis_eg1.jpeg)

Video is available [here](https://github.com/stmarcin/GTFS_moveVis/blob/master/imgs/Madrid_0608am.mp4)
