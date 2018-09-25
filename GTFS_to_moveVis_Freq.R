

GTFS_to_moveVis_Freq <- function(dir_GTFS, startHH = 6, endHH = 8, file_output = "GTFS.csv"){
      
    # required libraries:
    require(dplyr)
    require(chron)
    
    # fase 1: select trips using calendar and add min of frequency
    Freq <- read.delim(paste(dir_GTFS, "trips.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>%
          subset(select = c("trip_id", "service_id", "route_id")) %>%
          
          # open & select service_id (from calendar)
          inner_join(read.delim(paste(dir_GTFS, "calendar.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>%
                           subset(tuesday == "1", select = "service_id"), by = "service_id") %>%
          
          # open and select frequency
          inner_join(read.delim(paste(dir_GTFS, "frequencies.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>%
                           dplyr::select(-exact_times, -start_time, -end_time) %>%
                           group_by(trip_id) %>% 
                           filter(headway_secs == min(headway_secs)) %>% 
                           filter(1:n() == 1), by = "trip_id") %>%
          
          # add number of trips to be generated:
          mutate(no_trips = ceiling((endHH - startHH + 1)*60*60 / headway_secs))
    
    # fase 2: recalculate travel time of the first trip starting from start time
    # read stop_times file
    GTFS <- read.delim(paste(dir_GTFS, "stop_times.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>%
          dplyr::select(trip_id, arrival_time, stop_id, stop_sequence) %>%
          
          # select only trips included in Freq      
          inner_join(Freq %>%
                           dplyr::select(trip_id), by = "trip_id" )
    
    # exclude trips that start later than 00:00:00
    GTFS <- GTFS %>%
          inner_join(GTFS %>%
                           subset(stop_sequence == 0 & arrival_time == "00:00:00", select = c(trip_id)),
                     by = "trip_id")
    
    GTFS <- GTFS %>%
          mutate(arrival_time = chron(time = GTFS$arrival_time) + (startHH - 1)/24) %>%
          mutate(trip_id2 = paste(trip_id, "0", sep="_"))
    
    
    # mutliply trips using frequency and time range
    for(trip in unlist(Freq$trip_id)){
          i = 1
          Temp <- subset(GTFS, trip_id == trip)
                
          while(i <= as.numeric(subset(Freq, trip_id == trip, select = no_trips))){
                TempTrip <- Temp %>%
                      mutate(arrival_time = 
                            chron(times = chron(times = Temp$arrival_time) + 
                                  i*(as.integer(subset(Freq, trip_id == trip, select = headway_secs))/24/60/60)) ) %>%
                      mutate(trip_id2 = paste(trip_id, i, sep = "_"))
                      
                GTFS <- rbind(GTFS, TempTrip)
                rm(TempTrip)
                i = i + 1
          }
          rm(Temp, i)      
    }
    rm(trip)
    
    GTFS <- GTFS %>%
          # add service_id
          inner_join(Freq %>%
                           dplyr::select(trip_id, route_id), by = "trip_id") %>%
          
          # join selected cols from routes
          inner_join(read.delim(paste(dir_GTFS, "routes.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>% 
                           subset(select = c("route_id",  "route_short_name", "route_color")), by = "route_id") %>%
          
          # join coordinates of stops from stops.txt
          # unused stops produce warning (to be ignored)
          inner_join(read.delim(paste(dir_GTFS, "stops.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>% 
                           subset(select = c("stop_id", "stop_lat", "stop_lon")), by = "stop_id") %>%
          
          # replace trip_id by trip_id2 - with added consequent number of trip
          mutate(trip_id = trip_id2) %>%
          
          # limit stop-times to defined time frame
          filter(as.numeric(substr(arrival_time, 1, 2)) >= startHH, 
                 as.numeric(substr(arrival_time, 1, 2)) < endHH) %>%
          # select(-stop_id, -route_id, - stop_sequence, -trip_id2)
          dplyr::select(trip_id, arrival_time, stop_lat, stop_lon, route_short_name, route_color, stop_id)
    
    rm(Freq)
    
    # exclude trips with only one stop and order rows
    GTFS <- GTFS %>%
          inner_join(GTFS %>% 
                           group_by(trip_id) %>%
                           summarise(total = n()) %>%
                           filter(total != 1) %>%
                           dplyr::select(trip_id), by = "trip_id" ) %>%
          
          # order rows by arrival time within trips
          arrange(trip_id, arrival_time) 
    
    # save output
    write.csv(GTFS, file_output, row.names = F, quote = F)

}


