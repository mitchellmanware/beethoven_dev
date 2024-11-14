target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
    # targets::tar_target(
    #   chr_daterange,
    #   command = c("2018-01-01", "2018-01-21"),
    #   description = "Date range"
    # )
    # ,
    targets::tar_target(
      chr_daterange,
      command = amadeus::generate_date_sequence(
        "2018-01-01", "2018-01-10", sub_hyphen = FALSE
      )
    )
    ,
    targets::tar_target(
      chr_input_dir,
      command = "/input",
      description = "Input directory"
    )
    ,
    # targets::tar_target(
    #   num_dates_split,
    #   command = 10,
    #   description = "Number of days to include in each temporal split"
    # )
    # ,
    ############################################################################
    ############################################################################
    ############################################################################
    targets::tar_target(
      chr_years,
      command = seq(
        as.numeric(substr(chr_daterange[1], 1, 4)),
        as.numeric(substr(chr_daterange[2], 1, 4))
      ),
      description = "Year range"
    )
    ,
    # targets::tar_target(
    #   list_dates,
    #   command = beethoven::split_dates(
    #     dates = chr_daterange,
    #     n = num_dates_split,
    #     year = TRUE,
    #     julian = FALSE,
    #     append = FALSE
    #   ),
    #   description = "Split date range into list"
    # )
    # ,
    # targets::tar_target(
    #   list_dates,
    #   command = split(
    #     chr_daterange,
    #     ceiling(length(chr_daterange) / num_dates_split)
    #   )
    # )
    # ,
    # targets::tar_target(
    #   chr_datenames,
    #   command = names(list_dates),
    #   description = "Names of date list"
    # )
    # ,
    ###########################         AQS          ###########################
    targets::tar_target(
      sf_feat_proc_aqs_sites,
      command = amadeus::process_aqs(
        path = list.files(
          path = file.path(
            chr_input_dir,
            "aqs",
            "data_files"
          ),
          pattern = "daily_88101_[0-9]{4}.csv",
          full.names = TRUE
        ),
        date = c(chr_daterange[1], chr_daterange[length(chr_daterange)]),
        mode = "location",
        return_format = "sf"
      )[1:10, ],
      iteration = "list",
      description = "AQS sites"
    )
    ,
    targets::tar_target(
      list_feat_proc_aqs_sites,
      command = split(
        sf_feat_proc_aqs_sites,
        sf_feat_proc_aqs_sites$site_id
      ),
      description = "Names of AQS sites list"
    )
    ,
    targets::tar_target(
      chr_aqsnames,
      command = names(list_feat_proc_aqs_sites)
    )
    ,
    ###########################       CALCULATE      ###########################
    targets::tar_target(
      chr_iter_calc_narr,
      command = c("weasd"),
      iteration = "vector",
      description = "NARR features"
    )
    ,
    targets::tar_target(
      list_feat_calc_narr,
      command = par_narr(
        domain = chr_iter_calc_narr,
        path = file.path(chr_input_dir, "/narr/"),
        date = c(chr_daterange, chr_daterange),
        locs = list_feat_proc_aqs_sites[[chr_aqsnames]],
        nthreads = 1
      ),
      pattern = cross(chr_iter_calc_narr, chr_daterange, chr_aqsnames),
      iteration = "list",
      description = "Calculate NARR features (fit)"
    )
    ,
    ###########################      DATA.TABLE      ###########################
    targets::tar_target(
      dt_feat_calc_narr,
      command = reduce_merge(
        lapply(
          list(list_feat_calc_narr),
          function(x) reduce_merge(reduce_list(lapply(x, "[[", 1)))
        ),
        by = c("site_id", "time")
      ),
      description = "data.table of NARR features (fit)"
    )
  )