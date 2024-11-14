target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################     CRITICAL TARGETS      ######################
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
    ###########################         AQS          ###########################
    targets::tar_target(
      list_feat_proc_aqs_sites,
      command = {
        if (!file.exists("/inst/extdata/list_feat_proc_aqs_sites.qs")) {
          list_feat_proc_aqs_sites <- list(
            amadeus::process_aqs(
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
            )
          )
          names(list_feat_proc_aqs_sites) <- seq(
            1, length(list_feat_proc_aqs_sites)
          )
          qs::qsave(
            list_feat_proc_aqs_sites,
            "/inst/extdata/list_feat_proc_aqs_sites.qs"
          )
          qs::qsave(
            chr_daterange[length(chr_daterange)],
            "/inst/extdata/chr_dateend.qs"
          )
          list_feat_proc_aqs_sites
        } else if (file.exists("/inst/extdata/list_feat_proc_aqs_sites.qs")) {
          list_feat_proc_aqs_sites_prev <-
            qs::qread("/inst/extdata/list_feat_proc_aqs_sites.qs")
          chr_dateend <- qs::qread("/inst/extdata/chr_dateend.qs")
          chr_datesnew <- chr_daterange[chr_daterange > chr_dateend]
          list_feat_proc_aqs_sites_new <- list(
            amadeus::process_aqs(
              path = list.files(
                path = file.path(
                  chr_input_dir,
                  "aqs",
                  "data_files"
                ),
                pattern = "daily_88101_[0-9]{4}.csv",
                full.names = TRUE
              ),
              date = c(chr_datesnew[1], chr_datesnew[length(chr_datesnew)]),
              mode = "location",
              return_format = "sf"
            )
          )
          list_feat_proc_aqs_sites <- c(
            list_feat_proc_aqs_sites_prev,
            list_feat_proc_aqs_sites_new
          )
          names(list_feat_proc_aqs_sites) <- seq(
            1, length(list_feat_proc_aqs_sites)
          )
          qs::qsave(
            list_feat_proc_aqs_sites,
            "/inst/extdata/list_feat_proc_aqs_sites.qs"
          )
          qs::qsave(
            chr_datesnew[length(chr_datesnew)],
            "/inst/extdata/chr_dateend.qs"
          )
          list_feat_proc_aqs_sites
        }
      },
      iteration = "list",
      description = "AQS sites"
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