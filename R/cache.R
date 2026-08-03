#' Show locally cached PRF data files
#'
#' @param dataset Character or NULL. One of `"accidents"`, `"crashes"`,
#'   `"violations"`. NULL (default) shows all.
#' @return A tibble with columns `dataset`, `year`, `size_mb`, `cached_at`.
#' @export
#' @examples
#' prf_cache()
prf_cache <- function(dataset = NULL) {
  dir <- cache_dir()

  if (!fs::dir_exists(dir)) return(.empty_cache_tibble())

  files <- fs::dir_ls(dir, glob = "*.parquet")
  if (length(files) == 0L) return(.empty_cache_tibble())

  nms     <- fs::path_file(files)
  pt_name <- sub("_\\d{4}\\.parquet$", "", nms)
  result <- tibble::tibble(
    dataset   = dataset_from_pt(pt_name),
    year      = as.integer(regmatches(nms, regexpr("\\d{4}", nms))),
    size_mb   = round(as.numeric(fs::file_size(files)) / 1e6, 2),
    cached_at = as.Date(fs::file_info(files)$modification_time)
  ) |>
    dplyr::filter(!is.na(.data$dataset))   # drop unknown parquet files

  if (!is.null(dataset)) result <- dplyr::filter(result, .data$dataset == !!dataset)
  result
}

#' Delete locally cached PRF data files
#'
#' @param dataset Character or NULL. Dataset to clear. NULL = all.
#' @param year Integer or NULL. Year(s) to clear. NULL = all years.
#' @return Invisible NULL.
#' @export
#' @examples
#' \dontrun{
#' prf_cache_clear("violations", year = 2024)
#' prf_cache_clear()
#' }
prf_cache_clear <- function(dataset = NULL, year = NULL) {
  cached <- prf_cache(dataset = dataset)
  if (!is.null(year)) cached <- dplyr::filter(cached, .data$year %in% !!as.integer(year))

  if (nrow(cached) == 0L) {
    cli::cli_inform("No cached files matched.")
    return(invisible(NULL))
  }

  paths <- cache_path(cached$dataset, cached$year)
  fs::file_delete(paths)
  cli::cli_inform("Deleted {nrow(cached)} file{?s}.")
  invisible(NULL)
}

#' Show years available in the PRF catalog
#'
#' @param dataset Character or NULL. One of `"accidents"`, `"crashes"`,
#'   `"violations"`. NULL (default) returns all three.
#' @return A tibble with columns `dataset`, `year`, `rows`, `size_mb`.
#' @export
#' @examples
#' \dontrun{
#' prf_years()
#' prf_years("accidents")
#' }
prf_years <- function(dataset = NULL) {
  catalog  <- catalog_get()
  datasets <- if (is.null(dataset)) c("accidents", "crashes", "violations") else dataset

  purrr::map_dfr(datasets, function(ds) {
    pt_name  <- dataset_to_pt(ds)
    arquivos <- catalog$datasets[[pt_name]]$arquivos
    if (is.null(arquivos) || length(arquivos) == 0L) return(tibble::tibble())

    purrr::map_dfr(names(arquivos), function(filename) {
      info <- arquivos[[filename]]
      year <- as.integer(regmatches(filename, regexpr("\\d{4}", filename)))
      tibble::tibble(
        dataset = ds,
        year    = year,
        rows    = as.integer(info$linhas),
        size_mb = info$tamanho_mb
      )
    })
  })
}

.empty_cache_tibble <- function() {
  tibble::tibble(
    dataset   = character(),
    year      = integer(),
    size_mb   = double(),
    cached_at = as.Date(character())
  )
}
