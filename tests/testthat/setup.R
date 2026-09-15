# Tests never touch the network: skip the catalog version check on cache hits
# unless a test turns it back on explicitly
withr::local_options(
  list(tidyprf.check_updates = FALSE),
  .local_envir = testthat::teardown_env()
)
