#' Variable codebook for tidyprf datasets
#'
#' Bilingual (English/Portuguese) variable descriptions for all three PRF
#' datasets. Used internally by [info_accidents()], [info_crashes()], and
#' [info_violations()].
#'
#' @format A tibble with 97 rows and 5 columns:
#' \describe{
#'   \item{dataset}{Dataset name: `"accidents"`, `"crashes"`, or `"violations"`}
#'   \item{variable}{Variable name as returned by the `get_*()` functions}
#'   \item{type}{R type abbreviation (chr, int, dbl, date)}
#'   \item{description_en}{Description in English}
#'   \item{description_pt}{Description in Portuguese}
#' }
#' @source Compiled from the official PRF variable dictionaries published at
#'   <https://www.gov.br/prf/pt-br/acesso-a-informacao/dados-abertos/dados-abertos-da-prf>.
"codebook"
