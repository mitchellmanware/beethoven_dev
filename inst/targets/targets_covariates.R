target_covariates <-
  list(
    #########################             AQS             ######################
    targets::tar_target(
      download_aqs,
      command = {
        amadeus::download_aqs(
          directory_to_save = file.path(chr_input_dir, "aqs"),
          year = chr_years,
          unzip = list_download_args$unzip,
          remove_zip = list_download_args$remove_zip,
          remove_command = list_download_args$remove_command,
          acknowledgement = list_download_args$acknowledgement,
          download = list_download_args$download,
          hash = list_download_args$hash
        )
        TRUE
      },
      pattern = map(chr_years),
      description = "Download AQS data"
    )
    ,
    targets::tar_target(
      list_feat_proc_aqs_sites,
      command = {
        download_aqs
        sf_feat_proc_aqs_sites_date <- amadeus::process_aqs(
          path = file.path(chr_input_dir, "aqs", "data_files"),
          date = chr_daterange,
          mode = "location",
          data_field = "Arithmetic.Mean",
          return_format = "sf"
        )
        list_feat_split_aqs_sites <- lapply(
          split(
            sf_feat_proc_aqs_sites_date,
            sf_feat_proc_aqs_sites_date$site_id
          ),
          function(x) {
            rownames(x) <- NULL
            x
          }
        )
        list_feat_state_aqs_sites <- lapply(
          lapply(
            split(
              names(list_feat_split_aqs_sites),
              substr(names(list_feat_split_aqs_sites), 1, 2)
            ), function(x) list_feat_split_aqs_sites[x]
          ),
          function(x) dplyr::bind_rows(x)
        )
        list_feat_state_aqs_sites
      },
      description = "AQS locations"
    )
    ,
    #######################             NARR             #######################
    targets::tar_target(
      chr_iter_calc_narr,
      command = c("weasd", "air.sfc", "albedo", "apcp", "dswrf"),
      description = "NARR variables"
    )
    ,
    targets::tar_target(
      download_narr,
      command = amadeus::download_narr(
        variables = chr_iter_calc_narr,
        directory_to_save = file.path(chr_input_dir, "narr"),
        year = chr_years,
        remove_command = list_download_args$remove_command,
        acknowledgement = list_download_args$acknowledgement,
        download = list_download_args$download,
        hash = list_download_args$hash
      ),
      pattern = cross(chr_iter_calc_narr, chr_years),
      description = "Download NARR data"
    )
    ,
    targets::tar_target(
      download_narr_buffer,
      command = {
        download_narr
        TRUE
      },
      description = "Download NARR data | buffer"
    )
    ,
    targets::tar_target(
      list_feat_calc_narr,
      command = {
        download_narr_buffer
        dt_iter_calc_narr <- amadeus::calculate_narr(
          from = amadeus::process_narr(
            path = file.path(chr_input_dir, "narr", chr_iter_calc_narr),
            variable = chr_iter_calc_narr,
            date = beethoven::fl_dates(unlist(list_dates))
          ),
          locs = list_feat_proc_aqs_sites[[1]],
          locs_id = "site_id",
          radius = 0,
          fun = "mean",
          geom = "terra"
        )
        if (length(grep("level", names(dt_iter_calc_narr))) == 1) {
          dt_iter_calc_narr <-
            dt_iter_calc_narr[dt_iter_calc_narr$level == 1000, ]
          dt_iter_calc_narr <-
            dt_iter_calc_narr[, -grep("level", names(dt_iter_calc_narr))]
        }
        dt_iter_calc_narr
      },
      pattern = cross(list_feat_proc_aqs_sites, list_dates, chr_iter_calc_narr),
      iteration = "list",
      description = "Calculate NARR features | fit"
    )
    # ,
    # targets::tar_target(
    #   dt_feat_calc_narr,
    #   command = beethoven::reduce_merge(
    #     beethoven::reduce_list(list_feat_calc_narr),
    #     by = c("site_id", "time")
    #   ),
    #   description = "data.table of NARR features | fit"
    # )
  )
