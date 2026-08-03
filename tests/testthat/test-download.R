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
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      dest <- cache_path("accidents", 2023)
      fs::file_create(dest)

      result <- fetch_parquet("accidents", 2023)
      expect_equal(result, dest)
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
