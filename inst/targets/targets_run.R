target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
    targets::tar_target(
      chr_dates,
      # command = c("2018-12-25", "2018-12-31")
      command = c("2018-12-25", "2019-01-05")
    ),
    targets::tar_target(
      chr_years,
      command = unique(lubridate::year(chr_daterange)),
      iteration = "list"
    ),
    targets::tar_target(
      chr_daterange,
      command = amadeus::generate_date_sequence(
        chr_dates[1], chr_dates[2],
        sub_hyphen = FALSE
      )
    ),
    targets::tar_target(
      chr_iter_calc_narr,
      command = c(
        "air.sfc", "weasd"
      ),
      iteration = "vector"
    ),
    ###########################       DOWNLOAD       ###########################
    # targets::tar_target(
    #   name = download_aqs,
    #   command = {
    #     amadeus::download_aqs(
    #       parameter_code = "88101",
    #       resolution_temporal = "daily",
    #       year = chr_years,
    #       directory_to_save = "/input/aqs/",
    #       acknowledgement = TRUE,
    #       download = TRUE,
    #       remove_command = TRUE,
    #       unzip = TRUE,
    #       remove_zip = TRUE,
    #       hash = FALSE
    #     )
    #   },
    #   pattern = map(chr_years),
    #   iteration = "list"
    # ),
    # targets::tar_target(
    #   download_narr,
    #   command = amadeus::download_narr(
    #     variables = chr_iter_calc_narr,
    #     directory_to_save = "/input/narr/",
    #     year = chr_years,
    #     remove_command = TRUE,
    #     acknowledgement = TRUE,
    #     download = TRUE,
    #     hash = FALSE
    #   ),
    #   pattern = cross(chr_iter_calc_narr, chr_years),
    #   iteration = "list"
    # ),
    ###########################        PROCESS      ###########################
    targets::tar_target(
      name = process_aqs,
      command = amadeus::process_aqs(
        path = "/input/aqs/data_files/",
        date = chr_daterange,
        mode = "date-location",
        data_field = "Arithmetic.Mean",
        return_format = "sf"
      ),
      pattern = map(chr_daterange),
      iteration = "list"
    ),
    ###########################       CALCULATE      ###########################
    targets::tar_target(
      calc_narr,
      command = {
        process_narr <- amadeus::process_narr(
          path = paste0("/input/narr/", chr_iter_calc_narr),
          variable = chr_iter_calc_narr,
          date = chr_daterange
        )
        amadeus::calculate_narr(
          from = process_narr,
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
