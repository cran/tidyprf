test_that("info_accidents returns tibble with variable/type/description columns", {
  result <- info_accidents()
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("variable", "type", "description"))
})

test_that("info_accidents covers all 40 schema columns", {
  expected_cols <- c(
    "id", "pesid", "data_inversa", "dia_semana", "horario",
    "uf", "br", "km", "municipio", "causa_principal", "causa_acidente",
    "ordem_tipo_acidente", "tipo_acidente", "classificacao_acidente",
    "fase_dia", "sentido_via", "condicao_metereologica", "tipo_pista",
    "tracado_via", "uso_solo", "id_veiculo", "tipo_veiculo", "marca",
    "ano_fabricacao_veiculo", "tipo_envolvido", "estado_fisico", "idade",
    "sexo", "nacionalidade", "naturalidade", "ilesos", "feridos_leves",
    "feridos_graves", "mortos", "latitude", "longitude",
    "regional", "delegacia", "uop", "ano"
  )
  expect_true(all(expected_cols %in% info_accidents()$variable))
})

test_that("info_accidents lang = 'pt' returns Portuguese descriptions", {
  result <- info_accidents(lang = "pt")
  expect_false(any(is.na(result$description)))
  expect_true(any(grepl("ção|ário|ê|ú", result$description)))
})

test_that("info_accidents aborts on unknown lang", {
  expect_error(info_accidents(lang = "fr"), class = "rlang_error")
})

test_that("info_crashes returns tibble with correct columns", {
  result <- info_crashes()
  expect_named(result, c("variable", "type", "description"))
  expect_true("pessoas" %in% result$variable)
})

test_that("info_violations returns tibble with correct columns", {
  result <- info_violations()
  expect_named(result, c("variable", "type", "description"))
  expect_true("cod_infracao" %in% result$variable)
})
