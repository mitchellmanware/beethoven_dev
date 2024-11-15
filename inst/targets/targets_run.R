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
      chr_dateend,
      command = {
        if (file.exists("/inst/extdata/chr_dateend.qs")) {
          chr_dateend <- qs::qread("/inst/extdata/chr_dateend.qs")
          chr_dateend
        } else {
          chr_dateend <- chr_daterange[1] - 1
          chr_dateend
        }
      }
    )
    ,
    targets::tar_target(
      chr_daterun,
      command = chr_daterange[chr_daterange > chr_dateend]
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
      list_feat_proc_aqs_sites_prev,
      command = {
        if (file.exists("/inst/extdata/list_feat_proc_aqs_sites.qs")) {
          list_feat_proc_aqs_sites_prev <- qs::qread(
            "/inst/extdata/list_feat_proc_aqs_sites.qs"
          )
          list_feat_proc_aqs_sites_prev
        } else {
          list()
        }
      },
      cue = targets::tar_cue("always"),
      description = "AQS sites (previous)"
    )
    ,
    targets::tar_target(
      list_feat_proc_aqs_sites_new,
      command = {
        sf_feat_proc_aqs_sites_new <- amadeus::process_aqs(
          path = list.files(
            path = file.path(
              chr_input_dir,
              "aqs",
              "data_files"
            ),
            pattern = "daily_88101_[0-9]{4}.csv",
            full.names = TRUE
          ),
          date = c(chr_daterun[1], chr_daterun[length(chr_daterun)]),
          mode = "location",
          return_format = "sf"
        )
        chr_aqsprev <- as.vector(
          unlist(
            lapply(list_feat_proc_aqs_sites_prev, function(x) x$site_id)
          )
        )
        chr_aqsnew <- setdiff(
          sf_feat_proc_aqs_sites_new$site_id,
          chr_aqsprev
        )
        sf_feat_proc_aqs_sites_filter <- sf_feat_proc_aqs_sites_new[
          which(sf_feat_proc_aqs_sites_new$site_id %in% chr_aqsnew),
        ]
        list_feat_proc_aqs_sites_new <- list(sf_feat_proc_aqs_sites_filter)
        names(list_feat_proc_aqs_sites_new) <-
          length(list_feat_proc_aqs_sites_prev) + 1
        list_feat_proc_aqs_sites_new
      },
      iteration = "list",
      description = "AQS sites (new)"
    )
    ,
    targets::tar_target(
      list_feat_proc_aqs_sites,
      command = {
        list_feat_proc_aqs_sites <- c(
          list_feat_proc_aqs_sites_prev,
          list_feat_proc_aqs_sites_new
        )
        qs::qsave(
          list_feat_proc_aqs_sites,
          "/inst/extdata/list_feat_proc_aqs_sites.qs"
        )
        qs::qsave(
          chr_daterun[length(chr_daterun)],
          "/inst/extdata/chr_dateend.qs"
        )
        list_feat_proc_aqs_sites
      },
      description = "AQS sites"
    )
    ,
    targets::tar_target(
      chr_aqsnames,
      command = names(list_feat_proc_aqs_sites),
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
        date = c(chr_daterun, chr_daterun),
        locs = list_feat_proc_aqs_sites[[chr_aqsnames]],
        nthreads = 1
      ),
      pattern = cross(chr_iter_calc_narr, chr_daterun, chr_aqsnames),
      cue = targets::tar_cue("thorough"),
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