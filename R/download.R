catalog_env <- new.env(parent = emptyenv())

# Separated so tests can mock it without mocking httr2 directly
.catalog_fetch <- function() {
  url <- paste0(
    "https://raw.githubusercontent.com/bonijoao/tidyprf-dados/main/",
    "catalogo.json"
  )
  resp <- httr2::request(url) |>
    httr2::req_error(is_error = \(r) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_is_error(resp)) {
    cli::cli_abort(c(
      "Could not fetch tidyprf catalog.",
      "i" = "Check your internet connection.",
      "x" = "HTTP {httr2::resp_status(resp)} from {url}"
    ))
  }
  httr2::resp_body_json(resp, check_type = FALSE)
}

catalog_get <- function() {
  if (!is.null(catalog_env$catalog)) return(catalog_env$catalog)
  catalog_env$catalog <- .catalog_fetch()
  catalog_env$catalog
}

# Separated so tests can mock it without mocking httr2 directly
.download_file <- function(url, path) {
  httr2::request(url) |>
    httr2::req_progress() |>
    httr2::req_perform(path = path)
  invisible(path)
}

# TRUE when the catalog lists a version of `filename` published after the
# cached copy was downloaded. Any failure (offline, catalog unavailable,
# missing date) keeps the cached copy.
.cache_outdated <- function(pt_name, filename, dest) {
  if (!isTRUE(getOption("tidyprf.check_updates", TRUE))) return(FALSE)

  catalog <- tryCatch(catalog_get(), error = function(e) NULL)
  updated <- catalog$datasets[[pt_name]]$arquivos[[filename]]$atualizado_em
  if (is.null(updated)) return(FALSE)

  updated <- tryCatch(as.Date(updated), error = function(e) NA)
  cached  <- as.Date(fs::file_info(dest)$modification_time)
  isTRUE(updated > cached)
}

fetch_parquet <- function(dataset, year) {
  pt_name  <- dataset_to_pt(dataset)
  filename <- paste0(pt_name, "_", year, ".parquet")
  dest     <- cache_path(dataset, year)
  cached   <- fs::file_exists(dest)

  if (cached) {
    if (!.cache_outdated(pt_name, filename, dest)) {
      size_mb <- round(as.numeric(fs::file_size(dest)) / 1e6, 1)
      cli::cli_inform(c("v" = "Using cached {filename} ({size_mb} MB)"))
      return(dest)
    }
    cli::cli_inform(c("i" = "A newer version of {filename} is available."))
  }

  catalog <- catalog_get()
  info    <- catalog$datasets[[pt_name]]$arquivos[[filename]]

  if (is.null(info)) {
    available <- catalog$datasets[[pt_name]]$anos
    cli::cli_abort(c(
      "No {dataset} data available for year {year}.",
      "i" = "Available years: {available}"
    ))
  }

  cli::cli_inform(c("i" = "Downloading {filename} ({info$tamanho_mb} MB)..."))
  fs::dir_create(fs::path_dir(dest))

  tmp <- paste0(dest, ".part")
  on.exit(if (fs::file_exists(tmp)) fs::file_delete(tmp), add = TRUE)

  ok <- tryCatch(
    {
      .download_file(info$url, tmp)
      TRUE
    },
    error = function(e) {
      # Keep serving the old cached copy if the refresh fails
      if (!cached) stop(e)
      cli::cli_warn(c(
        "Could not download the newer {filename}; using the cached copy.",
        "x" = conditionMessage(e)
      ))
      FALSE
    }
  )

  if (ok) fs::file_move(tmp, dest)
  dest
}
