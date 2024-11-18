target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
    targets::tar_target(
      chr_dates,
      # command = c("2018-12-27", "2019-01-06")
      command = c("2018-12-27", "2019-01-09")
    ),
    targets::tar_target(
      chr_years,
      command = unique(lubridate::year(chr_daterange)),
      iteration = "list"
    ),
    targets::tar_target(
      chr_daterange,
      command = amadeus::generate_date_sequence(
        chr_dates[1], chr_dates[2], sub_hyphen = FALSE
      )
    ),
    targets::tar_target(
      list_dates,
      command = beethoven::split_dates(
        dates = chr_dates,
        n = 4,
        year = TRUE
      )
    ),
    ###########################       DOWNLOAD       ###########################
    targets::tar_target(
      chr_iter_calc_narr,
      command = c("weasd", "air.sfc"),
      iteration = "vector"
    ),
    targets::tar_target(
      download_narr,
      command = amadeus::download_narr(
        variables = chr_iter_calc_narr,
        directory_to_save = "/input/narr/",
        year = chr_years,
        remove_command = TRUE,
        acknowledgement = TRUE,
        download = TRUE,
        hash = FALSE
      ),
      pattern = cross(chr_iter_calc_narr, chr_years),
      iteration = "list",
      format = "file",
    ),
    targets::tar_target(
      download_narr_buffer,
      command = {
        download_narr
        TRUE
      }
    ),
    ###########################        PROCESS      ###########################
    targets::tar_target(
      name = process_aqs,
      command = {
        aqs_sf <- amadeus::process_aqs(
          path = "/input/aqs/data_files/",
          date = chr_dates,
          mode = "location",
          data_field = "Arithmetic.Mean",
          return_format = "sf"
        )
        aqs_list <- lapply(
          split(aqs_sf, aqs_sf$site_id),
          function(x) {
            rownames(x) <- NULL
            x
          }
        )
        aqs_sort <- aqs_list[sort(names(aqs_list))]
        aqs_sort[1:5]
      },
      description = "AQS sites as sorted list"
    ),
    geotargets::tar_terra_rast(
      process_narr,
      command = {
        download_narr_buffer
        amadeus::process_narr(
          path = paste0("/input/narr/", chr_iter_calc_narr),
          variable = chr_iter_calc_narr,
          date = beethoven::fl_dates(list_dates[[1]])
        )
      },
      pattern = cross(list_dates, chr_iter_calc_narr),
    ),
    ###########################       CALCULATE      ###########################
    targets::tar_target(
      calc_narr,
      command = amadeus::calculate_narr(
        from = process_narr[[1]],
        locs = process_aqs[[1]],
        locs_id = "site_id",
        radius = 0,
        fun = "mean",
        geom = FALSE
      ),
      pattern = cross(process_aqs, process_narr),
      iteration = "list"
    )
  )
