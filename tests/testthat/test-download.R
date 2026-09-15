# catalog_get() tests use testthat::local_mocked_bindings to avoid real HTTP
# fetch_parquet() tests use a real temp dir to test the cache-hit path

test_that("catalog_get caches result in session env after first call", {
  catalog_env$catalog <- NULL
  withr::defer(catalog_env$catalog <- NULL)

  testthat::local_mocked_bindings(
    .catalog_fetch = function() {
      list(datasets = list(
        acidentes = list(anos = 2023L, arquivos = list()),
        datatran  = list(anos = 2023L, arquivos = list()),
        infracoes = list(anos = 2024L, arquivos = list())
      ))
    },
    .package = "tidyprf"
  )

  result <- catalog_get()
  expect_type(result, "list")
  expect_true("datasets" %in% names(result))
  expect_false(is.null(catalog_env$catalog))
})

test_that("catalog_get returns cached value on second call without HTTP", {
  catalog_env$catalog <- list(datasets = list(test = TRUE))
  withr::defer(catalog_env$catalog <- NULL)
  result <- catalog_get()
  expect_true(result$datasets$test)
})

test_that("fetch_parquet returns existing cached file without HTTP", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd(), tidyprf.check_updates = FALSE), {
      dest <- cache_path("accidents", 2023)
      fs::file_create(dest)

      testthat::local_mocked_bindings(
        catalog_get = function() stop("catalog should not be queried"),
        .download_file = function(url, path) stop("should not download"),
        .package = "tidyprf"
      )

      result <- fetch_parquet("accidents", 2023)
      expect_equal(result, dest)
    })
  })
})

# Catalog with a single accidents_2023 entry published on `date`
fake_catalog <- function(date) {
  list(datasets = list(acidentes = list(
    anos = list(2023L),
    arquivos = list(acidentes_2023.parquet = list(
      url = "https://example.com/acidentes_2023.parquet",
      tamanho_mb = 1,
      linhas = 10,
      atualizado_em = date
    ))
  )))
}

# Creates a cached accidents_2023 file with modification date `date`
fake_cached_file <- function(date) {
  dest <- cache_path("accidents", 2023)
  fs::dir_create(fs::path_dir(dest))
  writeLines("old", dest)
  Sys.setFileTime(dest, as.POSIXct(paste(date, "12:00:00")))
  dest
}

test_that("fetch_parquet keeps cache when catalog version is not newer", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd(), tidyprf.check_updates = TRUE), {
      dest <- fake_cached_file("2026-06-01")
      downloaded <- FALSE
      testthat::local_mocked_bindings(
        catalog_get = function() fake_catalog("2026-05-03"),
        .download_file = function(url, path) downloaded <<- TRUE,
        .package = "tidyprf"
      )

      expect_equal(fetch_parquet("accidents", 2023), dest)
      expect_false(downloaded)
      expect_equal(readLines(dest), "old")
    })
  })
})

test_that("fetch_parquet re-downloads when catalog version is newer", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd(), tidyprf.check_updates = TRUE), {
      dest <- fake_cached_file("2026-05-01")
      testthat::local_mocked_bindings(
        catalog_get = function() fake_catalog("2026-09-14"),
        .download_file = function(url, path) writeLines("new", path),
        .package = "tidyprf"
      )

      expect_message(fetch_parquet("accidents", 2023), "newer version")
      expect_equal(readLines(dest), "new")
      expect_false(fs::file_exists(paste0(dest, ".part")))
    })
  })
})

test_that("fetch_parquet uses cache when catalog is unavailable", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd(), tidyprf.check_updates = TRUE), {
      dest <- fake_cached_file("2026-05-01")
      testthat::local_mocked_bindings(
        catalog_get = function() stop("offline"),
        .download_file = function(url, path) stop("should not download"),
        .package = "tidyprf"
      )

      expect_equal(fetch_parquet("accidents", 2023), dest)
      expect_equal(readLines(dest), "old")
    })
  })
})

test_that("fetch_parquet keeps old cache when refresh download fails", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd(), tidyprf.check_updates = TRUE), {
      dest <- fake_cached_file("2026-05-01")
      testthat::local_mocked_bindings(
        catalog_get = function() fake_catalog("2026-09-14"),
        .download_file = function(url, path) stop("network error"),
        .package = "tidyprf"
      )

      expect_warning(
        expect_equal(fetch_parquet("accidents", 2023), dest),
        "cached copy"
      )
      expect_equal(readLines(dest), "old")
    })
  })
})

test_that("tidyprf.check_updates = FALSE skips the catalog check", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd(), tidyprf.check_updates = FALSE), {
      dest <- fake_cached_file("2026-05-01")
      testthat::local_mocked_bindings(
        catalog_get = function() stop("catalog should not be queried"),
        .package = "tidyprf"
      )

      expect_equal(fetch_parquet("accidents", 2023), dest)
    })
  })
})

test_that("fetch_parquet aborts when year not in catalog", {
  catalog_env$catalog <- list(
    datasets = list(
      acidentes = list(
        anos = 2023L,
        arquivos = list()
      )
    )
  )
  withr::defer(catalog_env$catalog <- NULL)

  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      expect_error(fetch_parquet("accidents", 2021), class = "rlang_error")
    })
  })
})
