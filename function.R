generate_cv_index_spt_dev <- function(
  data,
  id = "site_id",
  coords = c("lon", "lat"),
  s_fold = 5L,
  time = "time",
  t_fold = 10L,
  year = FALSE,
  ...
) {

  #########################       SPATIAL FOLDS       ##########################
  stopifnot(c(id, coords, time) %in% names(data))

  # new `data.frame`and `sf` with onle `id` and lat/lon coordinates
  data_trim <- unique(data.frame(data)[, c(id, coords)])
  data_sf <- sf::st_as_sf(data_trim, coords = coords, remove = FALSE)

  # generate spatial splits with `spatialsample::spatial_block_cv`
  sp_index <-
    rlang::inject(
      spatialsample::spatial_block_cv(
        data_sf,
        v = s_fold,
        !!!list(...)
      )
    )

  # retrieve in_id
  data_rowid <- seq_len(nrow(data_trim))
  spatial_cv <- data_rowid

  if (
    !all(
      !is.na(Reduce(c, Map(function(x) is.na(x$out_id), sp_index$splits)))
    )
  ) {
    cat("Warning: some splits have missing values in `out_id`...\n")
    spatial_cv <-
      lapply(
        sp_index$splits,
        function(x) list(analysis = x$in_id, assessment = x$out_id)
      )
  } else {
    cat("No missing values in `out_id`...\n")
    sp_index <- lapply(sp_index$splits, function(x) x$in_id)
    for (i in seq_along(sp_index)) {
      spatial_cv[setdiff(data_rowid, sp_index[[i]])] <- i
    }
  }

  # merge spatial cross validation index with full data
  data_trim$cv <- spatial_cv
  data_sp <- data %>%
    dplyr::left_join(
      dplyr::select(data_trim, id, coords[1], coords[2], cv),
      by = c(id, coords[1], coords[2])
    )

  # check spatial cross validation index is in the data
  stopifnot("cv" %in% names(data_sp))
  # check data with spatial cv has same rows as raw data
  stopifnot(nrow(data_sp) == nrow(data))
  # check data with spatial cv has one more column than raw data
  stopifnot(ncol(data_sp) == ncol(data) + 1)

  #########################       TEMPORAL FOLDS       #########################
  # coerce class of time and cv index
  data_sp[[time]] <- as.Date(data_sp[[time]])
  data_sp$cv <- as.integer(data_sp$cv)

  # unique time points
  time_vec <- sort(unique(data_sp[[time]]))
  # unique spatial indices
  sp_indices <- sort(unique(data_sp$cv))

  # split time range into `t_fold` folds
  if (year) {
    year_vec_split <- sort(unique(substr(data_sp[[time]], 1, 4)))
    stopifnot(length(year_vec_split) == t_fold)
    time_vec_split <- as.Date(paste0(year_vec_split, "-01-01"))
    time_vec_split <- c(
      time_vec_split,
      as.Date(paste0(as.numeric(max(year_vec_split)) + 1, "-01-01"))
    )
  } else {
    time_vec_split <- quantile(time_vec, probs = seq(0, 1, 1 / t_fold))
    time_vec_split <- as.Date(time_vec_split)
  }

  stopifnot(length(time_vec_split) == t_fold + 1)
  stopifnot(class(time_vec_split) == class(data_sp$time))

  # list to store temporal cv index
  spt_index_list <- list()

  for (i in seq_along(sp_indices)) {
    for (j in seq(t_fold)) {
      # test data are within spatial fold `i` and time fold `j`
      out_id <- which(
        data_sp$time >= time_vec_split[j] &
          data_sp$time < time_vec_split[j + 1] &
          data_sp$cv == sp_indices[i]
      )
      # training data are all other data
      in_id <- setdiff(seq_len(nrow(data_sp)), out_id)
      spt_index_list <- c(
        spt_index_list,
        list(list(analysis = in_id, assessment = out_id))
      )
    }
  }

  return(spt_index_list)

}
