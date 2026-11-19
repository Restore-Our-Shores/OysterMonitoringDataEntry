test_that("the packaged golem config supports standard development lookup", {
  config <- system.file("golem-config.yml", package = "rosoyster")
  expect_true(file.exists(config))
  project <- tempfile("golem-config-")
  dir.create(file.path(project, "inst"), recursive = TRUE)
  file.copy(config, file.path(project, "inst", "golem-config.yml"))
  expect_identical(golem::get_golem_name(golem_wd = project), "rosoyster")
  expect_identical(golem::get_golem_version(golem_wd = project), as.character(utils::packageVersion("rosoyster")))
})
