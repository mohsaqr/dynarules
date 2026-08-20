tx <- list(c("a", "b", "c"), c("a", "b"), c("a", "c"), c("b", "c"),
           c("a", "b", "c"), c("a"), c("b"), c("a", "b"))
fit <- dynarules(tx, min_support = 0.2, min_confidence = 0.2, min_lift = 0)
types <- c("scatter", "two-key", "matrix", "grouped", "graph", "paracoord")

# Plot methods print as a side effect; capture that so the suite stays quiet.
draw <- function(...) {
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  plot(...)
}

test_that("every plot type builds a ggplot object", {
  for (ty in types) {
    p <- draw(fit, type = ty)
    expect_s3_class(p, "ggplot")
  }
})

test_that("plots render without error or warning", {
  # print() must happen inside a null device too, or ggplot writes an
  # Rplots.pdf into the test directory.
  render <- function(ty) {
    pdf(NULL)
    on.exit(dev.off(), add = TRUE)
    print(plot(fit, type = ty))
  }
  for (ty in types) expect_silent(render(ty))
})

test_that("plots can be coloured by any catalogued measure", {
  for (m in c("lift", "confidence", "kappa", "jaccard", "conviction")) {
    expect_s3_class(draw(fit, type = "scatter", measure = m), "ggplot")
  }
  expect_error(draw(fit, type = "scatter", measure = "nope"),
               "Unknown measure")
})

test_that("an unknown plot type is refused", {
  expect_error(draw(fit, type = "sunburst"), "'arg' should be one of")
})

test_that("top limits how many rules are drawn", {
  p <- draw(fit, type = "scatter", top = 3)
  expect_equal(nrow(p$data), 3L)
})

test_that("the two-key plot encodes rule order", {
  p <- draw(fit, type = "two-key")
  expect_true("order" %in% names(p$data))
  expect_true(all(p$data$order >= 2))
})

test_that("the graph plot links every item it draws", {
  p <- draw(fit, type = "graph")
  expect_s3_class(p, "ggplot")
  expect_gt(length(p$layers), 2L)
})

test_that("plots work for sequential rules", {
  seqs <- list(c("a", "b", "c"), c("a", "b"), c("a", "b", "c"), c("b", "c"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.25,
                    min_confidence = 0.2, min_lift = 0)
  for (ty in types) expect_s3_class(draw(sfit, type = ty), "ggplot")
})

test_that("an empty rule set messages instead of failing", {
  empty <- dynarules(tx, min_support = 0.99, min_confidence = 0.99)
  expect_message(draw(empty), "No rules to plot")
  expect_null(suppressMessages(draw(empty)))
})
