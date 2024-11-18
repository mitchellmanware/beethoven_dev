target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
    targets::tar_target(
      chr_daterange,
      command = amadeus::generate_date_sequence(
        "2018-01-01", "2018-01-08", sub_hyphen = FALSE
      )
    )
    ,
    targets::tar_target(
      chr_input_dir,
      command = "/input",
      description = "Input directory"
    )
    ,
    ############################################################################
    ############################################################################
    ###########################         AQS          ###########################
    targets::tar_target(
      list_feat_proc_aqs_sites,
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
      ) %>%
        distinct(site_id, .keep_all = TRUE) %>%
        split(.$site_id) %>%
        lapply(function(sublist) {
          sublist <- sublist %>%
            sf::st_as_sf() %>% 
            mutate(row_id = NULL)
          rownames(sublist) <- NULL
          sublist
        }),
      description = "AQS sites"
    )
    ,
    targets::tar_target(
      num_proc_aqs_sites,
      command = seq(1, length(list_feat_proc_aqs_sites)),
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
        locs = list_feat_proc_aqs_sites[[num_proc_aqs_sites]],
        nthreads = 1
      ),
      pattern = cross(chr_daterange, num_proc_aqs_sites),
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