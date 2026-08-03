test_that("prf_cache returns empty tibble when cache dir is empty", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      result <- prf_cache()
      expect_s3_class(result, "tbl_df")
      expect_equal(nrow(result), 0L)
    })
  })
})

test_that("prf_cache detects cached files and returns English dataset names", {
  # Files on disk use Portuguese names; prf_cache converts back to English
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      fs::file_create("acidentes_2023.parquet")
      fs::file_create("datatran_2022.parquet")

      result <- prf_cache()
      expect_named(result, c("dataset", "year", "size_mb", "cached_at"))
      expect_equal(nrow(result), 2L)
      expect_setequal(result$dataset, c("accidents", "crashes"))
    })
  })
})

test_that("prf_cache filters by English dataset argument", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      fs::file_create("acidentes_2023.parquet")
      fs::file_create("datatran_2022.parquet")

      result <- prf_cache(dataset = "accidents")
      expect_equal(nrow(result), 1L)
      expect_equal(result$dataset, "accidents")
    })
  })
})

test_that("prf_cache_clear deletes only the specified file", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      fs::file_create("acidentes_2023.parquet")
      fs::file_create("acidentes_2022.parquet")

      prf_cache_clear(dataset = "accidents", year = 2023)

      expect_false(fs::file_exists("acidentes_2023.parquet"))
      expect_true(fs::file_exists("acidentes_2022.parquet"))
    })
  })
})

test_that("prf_cache_clear returns invisibly", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      fs::file_create("acidentes_2023.parquet")
      expect_invisible(prf_cache_clear(dataset = "accidents", year = 2023))
    })
  })
})

test_that("prf_years returns tibble with English dataset names", {
  testthat::local_mocked_bindings(
    catalog_get = function() list(datasets = list(
      acidentes = list(
        anos = 2023L,
        arquivos = list(
          `acidentes_2023.parquet` = list(linhas = 571052L, tamanho_mb = 11.04)
        )
      ),
      datatran  = list(anos = integer(0), arquivos = list()),
      infracoes = list(anos = integer(0), arquivos = list())
    )),
    .package = "tidyprf"
  )
  result <- prf_years()
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("dataset", "year", "rows", "size_mb"))
  expect_equal(result$dataset, "accidents")
  expect_equal(result$year, 2023L)
})

test_that("prf_years filters by English dataset argument", {
  testthat::local_mocked_bindings(
    catalog_get = function() list(datasets = list(
      acidentes = list(
        anos = 2023L,
        arquivos = list(
          `acidentes_2023.parquet` = list(linhas = 571052L, tamanho_mb = 11.04)
        )
      ),
      datatran = list(
        anos = 2023L,
        arquivos = list(
          `datatran_2023.parquet` = list(linhas = 67766L, tamanho_mb = 2.47)
        )
      ),
      infracoes = list(anos = integer(0), arquivos = list())
    )),
    .package = "tidyprf"
  )
  result <- prf_years(dataset = "accidents")
  expect_true(all(result$dataset == "accidents"))
})
