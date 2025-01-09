target_critical <-
  list(
    ########################      CRITICAL TARGETS       #######################
    targets::tar_target(
      chr_daterange,
      command = c("2018-01-01", "2018-12-31"),
      description = "Date range"
    )
    ,
    # targets::tar_target(
    #   chr_nasa_token,
    #   command = readLines("/inst/extdata/nasa_token.txt"),
    #   description = "NASA Earthdata token"
    # )
    # ,
    # targets::tar_target(
    #   chr_mod06_links,
    #   command = "/inst/extdata/mod06_links_2018_2022.csv",
    #   description = "File of MOD06 links"
    # )
    # ,
    targets::tar_target(
      num_dates_split,
      command = 122
    )
    ,
    targets::tar_target(
      chr_input_dir,
      command = "/input"
    )
  )