test_that("cache_dir returns R_user_dir by default", {
  withr::with_options(list(tidyprf.cache_dir = NULL), {
    expect_equal(cache_dir(), tools::R_user_dir("tidyprf", "cache"))
  })
})

test_that("cache_dir respects option override", {
  withr::with_options(list(tidyprf.cache_dir = "/tmp/test_tidyprf"), {
    expect_equal(cache_dir(), "/tmp/test_tidyprf")
  })
})

test_that("cache_path builds correct file path using Portuguese filename", {
  # Catalog uses Portuguese names; cache filenames mirror those
  withr::with_options(list(tidyprf.cache_dir = "/tmp/test_tidyprf"), {
    expect_equal(cache_path("accidents",  2023), fs::path("/tmp/test_tidyprf", "acidentes_2023.parquet"))
    expect_equal(cache_path("crashes",    2023), fs::path("/tmp/test_tidyprf", "datatran_2023.parquet"))
    expect_equal(cache_path("violations", 2024), fs::path("/tmp/test_tidyprf", "infracoes_2024.parquet"))
  })
})

test_that("dataset_to_pt maps English dataset names to Portuguese", {
  expect_equal(dataset_to_pt("accidents"),  "acidentes")
  expect_equal(dataset_to_pt("crashes"),    "datatran")
  expect_equal(dataset_to_pt("violations"), "infracoes")
})

test_that("dataset_to_pt aborts on invalid name", {
  expect_error(dataset_to_pt("bad"), class = "rlang_error")
})

test_that("dataset_from_pt reverses the mapping", {
  expect_equal(dataset_from_pt("acidentes"), "accidents")
  expect_equal(dataset_from_pt("datatran"),  "crashes")
  expect_equal(dataset_from_pt("infracoes"), "violations")
})

test_that("validate_year deduplicates and sorts", {
  expect_equal(validate_year(c(2023, 2020, 2023)), c(2020L, 2023L))
})

test_that("validate_year coerces numeric to integer", {
  expect_type(validate_year(2023), "integer")
})

test_that("validate_year aborts on non-numeric input", {
  expect_error(validate_year("2023"), class = "rlang_error")
})

test_that("validate_year aborts on NA", {
  expect_error(validate_year(NA_real_), class = "rlang_error")
  expect_error(validate_year(c(2023, NA)), class = "rlang_error")
})

test_that("validate_year aborts on Inf and NaN", {
  expect_error(validate_year(Inf), class = "rlang_error")
  expect_error(validate_year(NaN), class = "rlang_error")
})

test_that("validate_year aborts on empty input", {
  expect_error(validate_year(integer(0)), class = "rlang_error")
  expect_error(validate_year(numeric(0)), class = "rlang_error")
})

test_that("dataset_from_pt returns NA for unknown PT names (intentional)", {
  expect_true(is.na(dataset_from_pt("foo")))
  expect_equal(
    dataset_from_pt(c("acidentes", "foo", "datatran")),
    c("accidents", NA, "crashes")
  )
})

test_that("severity_to_pt maps all three values correctly", {
  expect_equal(severity_to_pt("fatal"),      "Com Vítimas Fatais")
  expect_equal(severity_to_pt("injured"),    "Com Vítimas Feridas")
  expect_equal(severity_to_pt("no_victims"), "Sem Vítimas")
})

test_that("severity_to_pt returns NULL for NULL input", {
  expect_null(severity_to_pt(NULL))
})

test_that("severity_to_pt aborts with helpful message on invalid value", {
  expect_error(severity_to_pt("dead"), class = "rlang_error")
})

test_that("severity_to_pt accepts a vector", {
  result <- severity_to_pt(c("fatal", "injured"))
  expect_equal(result, c("Com Vítimas Fatais", "Com Vítimas Feridas"))
})
