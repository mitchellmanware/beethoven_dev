target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################      STABLE TARGETS       ######################
    targets::tar_target(
      chr_daterange,
      command = c("2018-01-01", "2018-02-28"),
      description = "Date range"
    )
    ,
    targets::tar_target(
      chr_nasa_token,
      command = readLines("/inst/extdata/nasa_token.txt"),
      description = "NASA Earthdata token"
    )
    ,
    targets::tar_target(
      chr_mod06_links,
      command = "/inst/extdata/mod06_links_2018_2022.csv",
      description = "File of MOD06 links"
    )
    ,
    targets::tar_target(
      num_dates_split,
      command = 10
    )
    ,
    targets::tar_target(
      chr_input_dir,
      command = "/input"
    )
    ,
    targets::tar_target(
      chr_dates,
      command = amadeus::generate_date_sequence(
        chr_daterange[1], chr_daterange[2], sub_hyphen = FALSE
      )
    )
    ,
    targets::tar_target(
      chr_years,
      command = unique(lubridate::year(chr_dates)),
      iteration = "list"
    )
    ,
    targets::tar_target(
      list_dates,
      command = beethoven::split_dates(
        dates = chr_daterange,
        n = num_dates_split,
        year = TRUE
      )
    )
    ,
    targets::tar_target(
      list_dates_julian,
      command = lapply(list_dates, function(x) format(as.Date(x), "%Y%j")),
      description = "Dates as list (YYYYDDD)"
    )
    ,
    targets::tar_target(
      chr_iter_radii,
      command = c(100, 1000),
      description = "Buffer radii"
    )
    ,
    targets::tar_target(
      list_download_args,
      command = list(
        unzip = TRUE,
        remove_zip = FALSE,
        remove_command = TRUE,
        acknowledgement = TRUE,
        download = TRUE,
        hash = FALSE
      ),
      description = "Common download arguments"
    )
    ,
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
        list_feat_state_aqs_sites[1:2]
      },
      description = "AQS locations"
    )
    ,
    ############################################################################
    ############################################################################
    #########################             NARR            ######################
    targets::tar_target(
      chr_iter_calc_narr,
      # command = c("weasd", "air.sfc")
      command = c("weasd", "air.sfc", "shum")
    )
    ,
    targets::tar_target(
      list_feat_calc_narr,
      command = amadeus::calculate_narr(
        from = amadeus::process_narr(
          path = file.path(chr_input_dir, "narr", chr_iter_calc_narr),
          variable = chr_iter_calc_narr,
          date = beethoven::fl_dates(unlist(list_dates))
        ),
        locs = list_feat_proc_aqs_sites[[1]],
        locs_id = "site_id",
        radius = 0,
        fun = "mean",
        geom = FALSE
      ),
      pattern = cross(list_feat_proc_aqs_sites, list_dates, chr_iter_calc_narr),
      iteration = "list",
      description = "Calculate NARR features | fit"
    )
    ,
    targets::tar_target(
      list_feat_calc_narr_2,
      command = lapply(
        list_feat_calc_narr,
        function(x) {
          if (length(grep("level", names(x))) == 1) {
            y <- x[x$level == 1000, ]
            y <- y[, -grep("level", names(y))]
          } else {
            y <- x
          }
          return(y)
        }
      ),
      description = "Calculate NARR features | 1000 hPa | fit"
    )
    ,
    targets::tar_target(
      dt_feat_calc_narr,
      command = beethoven::reduce_merge(
        beethoven::reduce_list(list_feat_calc_narr_2),
        by = c("site_id", "time")
      ),
      description = "data.table of NARR features | fit"
    )
    ############################################################################
    ############################################################################
  )
