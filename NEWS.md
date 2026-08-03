# tidyprf 0.1.1

* Use an absolute GitHub URL for the Portuguese README link in `README.md`
  (fixes invalid file URI reported by CRAN).

# tidyprf 0.1.0

* Initial release.
* `get_accidents()`, `get_crashes()`, and `get_violations()` download PRF
  open data as tidy tibbles, with filters by year, state (`uf`), federal
  highway (`br`), and severity.
* `info_accidents()`, `info_crashes()`, and `info_violations()` provide
  bilingual variable descriptions (English/Portuguese).
* `prf_years()` lists available years per dataset; `prf_cache()` and
  `prf_cache_clear()` manage the local Parquet cache.
