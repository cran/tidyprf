cache_dir <- function() {
  getOption("tidyprf.cache_dir", tools::R_user_dir("tidyprf", "cache"))
}

# Maps English public-API dataset names to the Portuguese keys used in
# catalogo.json and Parquet filenames on GitHub Releases.
.dataset_pt_map <- c(
  "accidents"  = "acidentes",
  "crashes"    = "datatran",
  "violations" = "infracoes"
)

dataset_to_pt <- function(dataset) {
  bad <- dataset[!dataset %in% names(.dataset_pt_map)]
  if (length(bad) > 0) {
    cli::cli_abort(c(
      "Invalid {.arg dataset}: {.val {bad}}",
      "i" = "Valid values: {.val {names(.dataset_pt_map)}}"
    ))
  }
  unname(.dataset_pt_map[dataset])
}

# Returns NA for unknown PT names; callers (e.g. prf_cache) rely on this
# to silently skip foreign parquet files in the cache dir.
dataset_from_pt <- function(pt_name) {
  rev_map <- setNames(names(.dataset_pt_map), unname(.dataset_pt_map))
  unname(rev_map[pt_name])
}

cache_path <- function(dataset, year) {
  pt_name <- dataset_to_pt(dataset)
  fs::path(cache_dir(), paste0(pt_name, "_", year, ".parquet"))
}

validate_year <- function(year) {
  if (!is.numeric(year)) {
    cli::cli_abort("{.arg year} must be numeric, not {.type {year}}.")
  }
  if (length(year) == 0L) {
    cli::cli_abort("{.arg year} must have length >= 1.")
  }
  if (any(!is.finite(year))) {
    cli::cli_abort("{.arg year} must contain only finite values (no NA, NaN, or Inf).")
  }
  as.integer(unique(sort(year)))
}

severity_to_pt <- function(severity) {
  if (is.null(severity)) return(NULL)
  map <- c(
    "fatal"      = "Com V\u00edtimas Fatais",
    "injured"    = "Com V\u00edtimas Feridas",
    "no_victims" = "Sem V\u00edtimas"
  )
  bad <- severity[!severity %in% names(map)]
  if (length(bad) > 0) {
    cli::cli_abort(c(
      "Invalid {.arg severity}: {.val {bad}}",
      "i" = "Valid values: {.val {names(map)}}"
    ))
  }
  unname(map[severity])
}
