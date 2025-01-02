target_initiate <-
  list(
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
  )