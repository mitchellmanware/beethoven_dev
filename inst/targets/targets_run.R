target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
    targets::tar_target(
      chr_dates,
      command = c("2018-01-01", "2018-01-12")
    )
    ,

    targets::tar_target(
      chr_years,
      command = unique(lubridate::year(chr_daterange)),
      iteration = "list"
    )
    ,

    targets::tar_target(
      chr_daterange,
      command = amadeus::generate_date_sequence(
        chr_dates[1], chr_dates[2], sub_hyphen = FALSE
      )
    )
    ,

     targets::tar_target(
      chr_iter_calc_gridmet,
      command = c("Precipitation", "Maximum Near-Surface Air Temperature"),
      iteration = "vector",
    )
    ,
  
      targets::tar_target(
      chr_iter_calc_narr,
      command = c(
        "air.sfc", "weasd"
      ),
      iteration = "vector",
      description = "NARR features"
    )
    ,

  #############  DOWNLOAD #############

  targets::tar_target(
    name = download_aqs,
    command = {
      download_aqs(
        parameter_code = "88101",
        resolution_temporal = "daily",
        year = chr_years,
        directory_to_save = "input/aqs/",
        acknowledgement = TRUE,
        download = TRUE,
        remove_command = TRUE,
        unzip = TRUE,
        remove_zip = TRUE,
        hash = TRUE
      )
    },
    pattern = map(chr_years),
    iteration = "list"
  )
  ,

  # targets::tar_target(
  #   name = download_gridmet,
  #   command = {
    #   download_gridmet(
    #   variables = "pr",
    #   year = 2018,
    #   directory_to_save = "input/gridmet/",
    #   acknowledgement = TRUE,
    #   download = TRUE,
    #   remove_command = FALSE,
    #   hash = TRUE
    # )
  #   },
  #   pattern = map(chr_iter_calc_gridmet),
  #   iteration = "list"
  # )
  # ,

      targets::tar_target(
      download_narr,
      command = amadeus::download_narr(
        variables = chr_iter_calc_narr,
        directory_to_save =  "/input/narr/",
        year = chr_years,
        remove_command = FALSE,
        acknowledgement = TRUE,
        download = TRUE,
        hash = TRUE
      ),
      pattern = cross(chr_iter_calc_narr, chr_years),
      iteration = "list",
      description = "Download NARR data"
    )
    ,

  # ############### PROCESS ##################

  targets::tar_target(
    name = process_aqs,
    command = {
      download_aqs
      process_aqs(
      path = "/input/aqs/data_files/",
      date = chr_daterange,
      mode = "date-location",
      data_field = "Arithmetic.Mean",
      return_format = "sf"
      )
    },
      pattern = map(chr_daterange),
      iteration = "list"    

  ),


  #   targets::tar_target(
  #   name = process_gridmet,
  #   command = {
  #     process_gridmet(
  #     path = paste0("/input/aqs/", "pr"),
  #     variable = "pr",
  #     date = c(chr_daterange[1], chr_daterange[1]),
  #     return_format = "sf"
  #     )
  #   },
  #     pattern = cross(chr_daterange, chr_iter_calc_gridmet),
  #     iteration = "list"    
  
  # )
  # # ,
  #   geotargets::tar_terra_rast(
  #   name = process_narr,
  #   command = {
  #     download_narr
  #     process_narr(
  #     path = paste0("/input/narr/", chr_iter_calc_narr),
  #     variable = chr_iter_calc_narr,
  #     date = chr_daterange
  #     )
  #   },
  #     pattern = cross(chr_iter_calc_narr, chr_daterange)
  
  # )
  # ,

 
  ###########################       CALCULATE      ###########################

    targets::tar_target(
      calc_narr,
      command = {
        process_aqs
          narr <-   process_narr(
          path = paste0("/input/narr/", chr_iter_calc_narr),
            variable = chr_iter_calc_narr,
            date = chr_daterange
          )        
        calculate_narr(
          from = narr,
          locs = process_aqs,
          locs_id = "site_id",
          radius = 0,
          fun = "mean",
          geom = "sf"
        )
      },
      pattern = cross(process_aqs, cross(chr_iter_calc_narr, chr_daterange)),
      iteration = "list"
    )

  )
