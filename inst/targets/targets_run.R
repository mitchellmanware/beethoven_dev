target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
    targets::tar_target(
      chr_dates,
      command = c("2018-12-30", "2018-12-31")
      # command = c("2018-12-30", "2019-01-01")
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
      chr_iter_calc_narr,
      command = c("weasd"),
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
        aqs_sort
      },
      description = "AQS sites as sorted list"
    ),
    ###########################       CALCULATE      ###########################
    targets::tar_target(
      calc_narr,
      command = {
        download_narr_buffer
        process_narr <- amadeus::process_narr(
          path = paste0("/input/narr/", chr_iter_calc_narr),
          variable = chr_iter_calc_narr,
          date = chr_daterange
        )
        amadeus::calculate_narr(
          from = process_narr,
          locs = process_aqs[[1]],
          locs_id = "site_id",
          radius = 0,
          fun = "mean",
          geom = "sf"
        )
      },
      pattern = cross(process_aqs, cross(chr_daterange, chr_iter_calc_narr)),
      iteration = "list"
    )
  )
