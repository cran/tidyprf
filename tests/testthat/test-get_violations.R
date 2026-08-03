make_violations_parquet <- function(dir, year, n = 4) {
  df <- tibble::tibble(
    numero_auto = paste0("1234", seq_len(n)),
    dat_infracao = as.Date(paste0(year, "-03-15")),
    tip_abordagem = "Ativa",
    ind_assinou_auto = "Sim",
    ind_veiculo_estrangeiro = "Não",
    ind_sentido_trafego = "Crescente",
    uf_placa = "SP",
    uf_infracao = rep(c("SP", "SP", "RJ", "MG"), length.out = n),
    num_br_infracao = rep(c(101L, 101L, 116L, 40L), length.out = n),
    num_km_infracao = 50.0,
    nom_municipio = "São Paulo",
    cod_infracao = "55412",
    descricao_abreviada = "Excesso de velocidade",
    enquadramento = "CTB Art. 218 III",
    data_inicio_vigencia = as.Date("2020-01-01"),
    data_fim_vigencia = as.Date("2025-12-31"),
    med_realizada = 100.0, med_considerada = 95.0, exc_verificado = 15.0,
    especie = "Automóvel", nome_veiculo_marca = "FIAT",
    tipo_veiculo = "Automóvel", nom_modelo_veiculo = "Argo",
    hora = "14:30:00", qtd_infracoes = 1L,
    ano = as.integer(year)
  )
  arrow::write_parquet(df, fs::path(dir, paste0("infracoes_", year, ".parquet")))
}

test_that("get_violations does NOT return a tibble", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_violations_parquet(getwd(), 2024)
      result <- get_violations(2024)
      expect_false(inherits(result, "tbl_df"))
    })
  })
})

test_that("get_violations returns an Arrow object", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_violations_parquet(getwd(), 2024)
      result <- get_violations(2024)
      expect_true(
        inherits(result, "arrow_dplyr_query") || inherits(result, "Dataset")
      )
    })
  })
})

test_that("get_violations can be collected after filter", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_violations_parquet(getwd(), 2024, n = 4)
      result <- get_violations(2024, uf = "SP") |> dplyr::collect()
      expect_s3_class(result, "tbl_df")
      expect_true(all(result$uf_infracao == "SP"))
      expect_gt(nrow(result), 0L)
    })
  })
})

test_that("get_violations filters by br before returning", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_violations_parquet(getwd(), 2024, n = 4)
      result <- get_violations(2024, br = 101) |> dplyr::collect()
      expect_true(all(result$num_br_infracao == 101L))
    })
  })
})

test_that("get_violations supports multi-year vector", {
  withr::with_tempdir({
    withr::with_options(list(tidyprf.cache_dir = getwd()), {
      make_violations_parquet(getwd(), 2023, n = 4)
      make_violations_parquet(getwd(), 2024, n = 4)
      result <- get_violations(c(2023, 2024)) |> dplyr::collect()
      expect_equal(nrow(result), 8L)
    })
  })
})
