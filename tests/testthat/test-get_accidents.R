# Helper: write a minimal accidents-schema parquet to a temp cache dir
make_accidents_parquet <- function(dir, year, n = 5) {
  df <- tibble::tibble(
    id = seq_len(n), pesid = seq_len(n),
    data_inversa = as.Date(paste0(year, "-06-15")),
    dia_semana = "sexta-feira", horario = "14:30:00",
    uf = rep(c("SP", "SP", "RJ", "MG", "SP"), length.out = n),
    br = rep(c(101L, 101L, 116L, 40L, 101L), length.out = n),
    km = 10.5, municipio = "São Paulo",
    causa_principal = NA_character_,
    causa_acidente = "Falta de atenção",
    ordem_tipo_acidente = NA_integer_,
    tipo_acidente = "Colisão traseira",
    classificacao_acidente = rep(
      c("Com Vítimas Fatais", "Sem Vítimas", "Com Vítimas Feridas",
        "Com Vítimas Fatais", "Sem Vítimas"), length.out = n
    ),
    fase_dia = "Pleno dia", sentido_via = "Crescente",
    condicao_metereologica = "Céu claro", tipo_pista = "Simples",
    tracado_via = "Reta", uso_solo = "Rural",
    id_veiculo = seq_len(n), tipo_veiculo = "Automóvel", marca = "FIAT",
    ano_fabricacao_veiculo = 2020L,
    tipo_envolvido = "Condutor", estado_fisico = "Ileso",
    idade = 35L, sexo = "Masculino",
    nacionalidade = NA_character_, naturalidade = NA_character_,
    ilesos = 1L, feridos_leves = 0L, feridos_graves = 0L, mortos = 0L,
    latitude = -23.5, longitude = -46.6,
    regional = NA_character_, delegacia = NA_character_, uop = NA_character_,
    ano = as.integer(year)
  )
  arrow::write_parquet(df, fs::path(dir, paste0("acidentes_", year, ".parquet")))
}

test_that("get_accidents returns a tibble", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2023)
      result <- get_accidents(2023)
      expect_s3_class(result, "tbl_df")
    })
  })
})

test_that("get_accidents returns all rows when no filters", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2023, n = 5)
      expect_equal(nrow(get_accidents(2023)), 5L)
    })
  })
})

test_that("get_accidents filters by uf", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2023)
      result <- get_accidents(2023, uf = "SP")
      expect_true(all(result$uf == "SP"))
      expect_gt(nrow(result), 0L)
    })
  })
})

test_that("get_accidents filters by br", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2023)
      result <- get_accidents(2023, br = 101)
      expect_true(all(result$br == 101L))
    })
  })
})

test_that("get_accidents filters by severity = 'fatal'", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2023)
      result <- get_accidents(2023, severity = "fatal")
      expect_true(all(result$classificacao_acidente == "Com Vítimas Fatais"))
    })
  })
})

test_that("get_accidents binds multiple years", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2022, n = 5)
      make_accidents_parquet(getwd(), 2023, n = 5)
      result <- get_accidents(c(2022, 2023))
      expect_equal(nrow(result), 10L)
    })
  })
})

test_that("get_accidents aborts on invalid severity", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_accidents_parquet(getwd(), 2023)
      expect_error(get_accidents(2023, severity = "bad"), class = "rlang_error")
    })
  })
})

test_that("get_crashes returns a tibble with crashes schema", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      df <- tibble::tibble(
        id = 1L, data_inversa = as.Date("2023-06-15"),
        dia_semana = "sexta-feira", horario = "14:30:00",
        uf = "SP", br = 101L, km = 10.5, municipio = "São Paulo",
        causa_acidente = "Falta de atenção",
        tipo_acidente = "Colisão traseira",
        classificacao_acidente = "Sem Vítimas",
        fase_dia = "Pleno dia", sentido_via = "Crescente",
        condicao_metereologica = "Céu claro", tipo_pista = "Simples",
        tracado_via = "Reta", uso_solo = "Rural",
        pessoas = 2L, mortos = 0L, feridos_leves = 0L, feridos_graves = 0L,
        ilesos = 2L, ignorados = 0L, feridos = 0L, veiculos = 1L,
        latitude = -23.5, longitude = -46.6,
        regional = NA_character_, delegacia = NA_character_,
        uop = NA_character_, ano = 2023L
      )
      arrow::write_parquet(df, "datatran_2023.parquet")
      expect_s3_class(get_crashes(2023), "tbl_df")
    })
  })
})
