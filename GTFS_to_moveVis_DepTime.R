
GTFS_to_moveVis_DepTime <- function(dir_GTFS, startHH = 6, endHH = 8, file_output = "GTFS.csv"){
        require(dplyr)

        GTFS <- read.delim(paste(dir_GTFS, "stop_times.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>% 
                subset(select = c("stop_id", "trip_id", "arrival_time")) %>%
                
                # unused stops produce warning (to be ignored)
                inner_join(read.delim(paste(dir_GTFS, "stops.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>% 
                        subset(select = c("stop_id", "stop_lat", "stop_lon")), by = "stop_id") %>%
                
                # read trips and select columns
                inner_join(read.delim(paste(dir_GTFS, "trips.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>%
                        subset(select = c("trip_id", "service_id", "route_id")), by = "trip_id") %>%
                
                # select service id based on weekday
                inner_join(read.delim(paste(dir_GTFS, "calendar.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>%
                        subset(tuesday == "1", select = "service_id"), by = "service_id") %>%
                
                # join selected cols from routes
                inner_join(read.delim(paste(dir_GTFS, "routes.txt", sep = "/"), sep=",", fileEncoding="UTF-8-BOM") %>% 
                        subset(select = c("route_id",  "route_short_name", "route_color")), by = "route_id") %>%

                # limit stop-times to defined time frame
                filter(as.numeric(substr(arrival_time, 1, 2)) >= startHH, 
                        as.numeric(substr(arrival_time, 1, 2)) < endHH) %>%
                select(-service_id, -stop_id, -route_id)
        
        # exclude trips with only one stop and order rows
        GTFS <- GTFS %>%
                inner_join(GTFS %>% 
                                group_by(trip_id) %>%
                                summarise(total = n()) %>%
                                filter(total != 1) %>%
                                select(trip_id), by = "trip_id" ) %>%
                
                # order rows by arrival time within trips
                arrange(trip_id, arrival_time) 
        
        # save output
        write.csv(GTFS, file_output, row.names = F, quote = F)
}
