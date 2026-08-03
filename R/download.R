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

fetch_parquet <- function(dataset, year) {
  pt_name  <- dataset_to_pt(dataset)
  filename <- paste0(pt_name, "_", year, ".parquet")
  dest     <- cache_path(dataset, year)

  if (fs::file_exists(dest)) {
    size_mb <- round(as.numeric(fs::file_size(dest)) / 1e6, 1)
    cli::cli_inform(c("v" = "Using cached {filename} ({size_mb} MB)"))
    return(dest)
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

  httr2::request(info$url) |>
    httr2::req_progress() |>
    httr2::req_perform(path = tmp)

  fs::file_move(tmp, dest)
  dest
}
