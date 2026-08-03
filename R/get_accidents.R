#' Get PRF accident data by person
#'
#' Downloads and returns accident records at the person level (one row per
#' person involved in each accident). Files are cached after first download.
#'
#' @param year Integer or vector of integers. Year(s) to fetch (2007-2026).
#' @param uf Character or NULL. State abbreviation(s), e.g. `"SP"`. NULL = all.
#' @param br Integer or NULL. Federal highway number(s), e.g. `101`. NULL = all.
#' @param severity Character or NULL. `"fatal"`, `"injured"`, or `"no_victims"`. NULL = all.
#' @return A tibble.
#' @export
#' @examples
#' \dontrun{
#' get_accidents(2023)
#' get_accidents(2020:2023, uf = "SP", severity = "fatal")
#' df <- get_accidents(c(2019:2021, 2023), br = 101)
#' }
get_accidents <- function(year, uf = NULL, br = NULL, severity = NULL) {
  .get_road_data("accidents", year, uf = uf, br = br, severity = severity)
}

#' Get PRF accident data by occurrence
#'
#' Downloads and returns accident records at the occurrence level (one row
#' per accident, with aggregated person and vehicle counts). Files are cached
#' after first download.
#'
#' @param year Integer or vector of integers. Year(s) to fetch (2007-2026).
#' @param uf Character or NULL. State abbreviation(s). NULL = all.
#' @param br Integer or NULL. Federal highway number(s). NULL = all.
#' @param severity Character or NULL. `"fatal"`, `"injured"`, or `"no_victims"`. NULL = all.
#' @return A tibble.
#' @export
#' @examples
#' \dontrun{
#' get_crashes(2023)
#' get_crashes(2020:2023, uf = c("SP", "RJ"))
#' }
get_crashes <- function(year, uf = NULL, br = NULL, severity = NULL) {
  .get_road_data("crashes", year, uf = uf, br = br, severity = severity)
}

.get_road_data <- function(dataset, year, uf, br, severity) {
  year   <- validate_year(year)
  sev_pt <- severity_to_pt(severity)

  paths <- vapply(year, function(y) fetch_parquet(dataset, y), character(1))
  ds    <- arrow::open_dataset(paths, format = "parquet")

  if (!is.null(uf))     ds <- dplyr::filter(ds, .data$uf %in% !!uf)
  if (!is.null(br))     ds <- dplyr::filter(ds, .data$br %in% !!as.integer(br))
  if (!is.null(sev_pt)) ds <- dplyr::filter(ds, .data$classificacao_acidente %in% !!sev_pt)

  dplyr::collect(ds)
}
