#' Get PRF infraction data
#'
#' Downloads PRF infraction records and returns an Arrow query.
#' Files are 100-300 MB; use [dplyr::filter()] before [dplyr::collect()]
#' to avoid loading the full dataset into memory.
#'
#' @param year Integer or vector of integers. Available: 2019-2020, 2022-2026.
#' @param uf Character or NULL. State of infraction (`uf_infracao`). NULL = all.
#' @param br Integer or NULL. Federal highway number (`num_br_infracao`). NULL = all.
#' @return An Arrow query. Call [dplyr::collect()] to load into a tibble.
#' @export
#' @examples
#' \dontrun{
#' # Filter before collecting to avoid loading 243 MB into RAM
#' get_violations(2024, uf = "SP") |>
#'   dplyr::filter(cod_infracao == "55412") |>
#'   dplyr::collect()
#' }
get_violations <- function(year, uf = NULL, br = NULL) {
  year  <- validate_year(year)
  paths <- vapply(year, function(y) fetch_parquet("violations", y), character(1))
  ds    <- arrow::open_dataset(paths, format = "parquet")

  if (!is.null(uf)) ds <- dplyr::filter(ds, .data$uf_infracao    %in% !!uf)
  if (!is.null(br)) ds <- dplyr::filter(ds, .data$num_br_infracao %in% !!as.integer(br))

  ds
}
