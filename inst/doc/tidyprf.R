## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(tidyprf)

## ----eval = FALSE-------------------------------------------------------------
# crashes_2023 <- get_crashes(2023)
# crashes_2023

## ----eval = FALSE-------------------------------------------------------------
# # Fatal accidents in São Paulo and Rio de Janeiro, 2020-2023
# fatal <- get_crashes(2020:2023, uf = c("SP", "RJ"), severity = "fatal")
# 
# # People involved in accidents on the BR-101
# people_101 <- get_accidents(2023, br = 101)
# 
# # Traffic violations in Minas Gerais
# violations_mg <- get_violations(2024, uf = "MG")

## ----eval = FALSE-------------------------------------------------------------
# prf_years()

## -----------------------------------------------------------------------------
info_crashes()

## -----------------------------------------------------------------------------
head(info_violations(lang = "pt"))

## -----------------------------------------------------------------------------
str(codebook)

## -----------------------------------------------------------------------------
prf_cache()

## ----eval = FALSE-------------------------------------------------------------
# prf_cache_clear("violations", year = 2024)
# prf_cache_clear()  # everything

