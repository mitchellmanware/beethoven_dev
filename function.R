generate_cv_index_sp_dev <-
  function(
    data,
    target_cols = c("lon", "lat"),
    ...
  ) {

    data_sf <- sf::st_as_sf(data, coords = target_cols, remove = FALSE)
    cv_index <-
      rlang::inject(
        spatialsample::spatial_block_cv(
          data_sf,
          !!!list(...)
        )
      )

    # retrieve in_id
    data_rowid <- seq_len(nrow(data))
    newcv <- data_rowid

    if (
      !all(
        !is.na(Reduce(c, Map(function(x) is.na(x$out_id), cv_index$splits)))
      )
    ) {
      newcv <-
        lapply(
          cv_index$splits,
          function(x) list(analysis = x$in_id, assessment = x$out_id)
        )
    } else {
      cv_index <- lapply(cv_index$splits, function(x) x$in_id)
      for (i in seq_along(cv_index)) {
        newcv[setdiff(data_rowid, cv_index[[i]])] <- i
      }
    }

    return(newcv)
  }

make_subdata_dev <- function(
  data,
  n = NULL,
  p = 0.3,
  ngroup_init = NULL
) {
  if (is.null(n) && is.null(p)) {
    stop("Please provide either n or p.")
  }
  if (!is.null(ngroup_init) && ngroup_init <= 0) {
    stop("ngroup_init must be a positive integer.")
  }

  nr <- seq_len(nrow(data))

  if (!is.null(n)) {
    if (!is.null(ngroup_init)) {
      n <- floor(n / ngroup_init) * ngroup_init
    }
    nsample <- sample(nr, n)
  } else {
    sample_size <- ceiling(nrow(data) * p)
    if (!is.null(ngroup_init)) {
      sample_size <- floor(sample_size / ngroup_init) * ngroup_init
    }
    nsample <- sample(nr, sample_size)
  }

  rowindex <- nsample
  data_name <- as.character(substitute(data))
  attr(rowindex, "object_origin") <- data_name[length(data_name)]

  return(rowindex)
}
