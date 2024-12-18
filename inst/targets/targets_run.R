target_run <-
  list(
    ############################################################################
    ############################################################################
    ###########################      STABLE TARGETS       ######################
    targets::tar_target(
      chr_daterange,
      command = c("2022-01-01", "2022-01-31"),
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
        list_feat_state_aqs_sites[1]
      },
      description = "AQS locations"
    )
    ,
    ############################################################################
    ############################################################################
    #########################            MODIS            ######################
    targets::tar_target(
      chr_args_calc_mcd19_files,
      command = list.files(
        file.path(chr_input_dir, "modis", "raw", "61", "MCD19A2"),
        full.names = TRUE,
        recursive = TRUE
      ),
      description = "MODIS - MCD19_*km files"
    )
    ,
    targets::tar_target(
      list_args_calc_mcd19_1km,
      command = list(
        from = grep(
          x = chr_args_calc_mcd19_files,
          pattern = paste0(
            "MCD19A2.A", unlist(list_dates_julian), collapse = "|"
          ),
          value = TRUE
        ),
        name_covariates = c("MOD_AD4TA_0_", "MOD_AD5TA_0_"),
        subdataset = "^Optical_Depth",
        radius = chr_iter_radii
      ),
      pattern = map(list_dates_julian),
      iteration = "list",
      description = "MODIS - MCD19_1km arguments"
    )
    ,
    targets::tar_target(
      list_feat_calc_mcd19_1km,
      command = beethoven::inject_modis(
        locs = list_feat_proc_aqs_sites[[1]],
        injection = list_args_calc_mcd19_1km
      ),
      pattern = cross(list_feat_proc_aqs_sites, list_args_calc_mcd19_1km),
      iteration = "list",
      resources = targets::tar_resources(
        crew = targets::tar_resources_crew(controller = "beethoven_controller")
      ),
      description = "Calculate MODIS - MCD19_1km features | fit"
    )
    ,
    targets::tar_target(
      list_args_calc_mcd19_5km,
      command = list(
        from = grep(
          x = chr_args_calc_mcd19_files,
          pattern = paste0(
            "MCD19A2.A", unlist(list_dates_julian), collapse = "|"
          ),
          value = TRUE
        ),
        name_covariates = c(
          "MOD_CSZAN_0_", "MOD_CVZAN_0_", "MOD_RAZAN_0_",
          "MOD_SCTAN_0_", "MOD_GLNAN_0_"
        ),
        subdataset = "cos|RelAZ|Angle",
        radius = chr_iter_radii
      ),
      pattern = map(list_dates_julian),
      iteration = "list",
      description = "MODIS - MCD19_5km arguments"
    )
    ,
    targets::tar_target(
      list_feat_calc_mcd19_5km,
      command = beethoven::inject_modis(
        locs = list_feat_proc_aqs_sites[[1]],
        injection = list_args_calc_mcd19_5km
      ),
      pattern = cross(list_feat_proc_aqs_sites, list_args_calc_mcd19_5km),
      iteration = "list",
      resources = targets::tar_resources(
        crew = targets::tar_resources_crew(controller = "beethoven_controller")
      ),
      description = "Calculate MODIS - MCD19_5km features | fit"
    )
    ############################################################################
    ############################################################################
  )
