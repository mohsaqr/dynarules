tx <- list(c("a", "b", "c"), c("a", "b"), c("a", "c"), c("b", "c"),
           c("a", "b", "c"), c("a"), c("b"), c("a", "b"))
fit <- dynarules(tx, min_support = 0.2, min_confidence = 0.2, min_lift = 0)
types <- c("scatter", "two-key", "matrix", "grouped", "paracoord")
# `graph` delegates to cograph and returns a network, not a ggplot, so it is
# exercised separately.
all_types <- c(types, "graph")

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

test_that("the graph type hands the network to cograph", {
  skip_if_not_installed("cograph")
  net <- draw(fit, type = "graph")
  expect_s3_class(net, "cograph_network")
  expect_s3_class(net, "dynarules_net")
  expect_gt(nrow(net$edges), 0L)
})

test_that("the graph type says what to do when cograph is absent", {
  # The guard must name cograph and point at as_network() as the way out.
  src <- deparse(dynarules:::.dr_plot_graph)
  expect_true(any(grepl("cograph", src)))
  expect_true(any(grepl("as_network", src)))
})

test_that("as_network accepts any catalogued measure as the edge weight", {
  for (w in c("lift", "confidence", "support", "kappa", "jaccard")) {
    net <- as_network(fit, weight = w)
    expect_s3_class(net, "cograph_network")
    expect_gt(nrow(net$edges), 0L)
  }
  expect_error(as_network(fit, weight = "nope"), "Unknown weight measure")
})

test_that("plots work for sequential rules", {
  seqs <- list(c("a", "b", "c"), c("a", "b"), c("a", "b", "c"), c("b", "c"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.25,
                    min_confidence = 0.2, min_lift = 0)
  for (ty in types) expect_s3_class(draw(sfit, type = ty), "ggplot")
})

test_that("a repeated sequential item does not break any plot", {
  # Sequential mining legitimately yields rules like a -> a. geom_curve()
  # rejects identical end points, so these must be drawn as loops.
  seqs <- list(c("a", "a", "b"), c("a", "a", "b"), c("a", "a"),
               c("b", "a", "a"), c("a", "a", "b"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.3,
                    min_confidence = 0.3, min_lift = 0)
  r <- rules(sfit)
  expect_true(any(r$antecedent == r$consequent))   # the fixture really loops

  render <- function(ty) {
    pdf(NULL)
    on.exit(dev.off(), add = TRUE)
    print(plot(sfit, type = ty))
  }
  for (ty in types) expect_silent(render(ty))
})

test_that("every plot type renders for sequential rules, not just builds", {
  seqs <- list(c("a", "b", "c"), c("a", "b"), c("a", "b", "c"), c("b", "c"),
               c("c", "a", "b"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.2,
                    min_confidence = 0.2, min_lift = 0)
  render <- function(ty) {
    pdf(NULL)
    on.exit(dev.off(), add = TRUE)
    print(plot(sfit, type = ty))
  }
  for (ty in types) expect_silent(render(ty))
})

test_that("an empty rule set messages instead of failing", {
  empty <- dynarules(tx, min_support = 0.99, min_confidence = 0.99)
  expect_message(draw(empty), "No rules to plot")
  expect_null(suppressMessages(draw(empty)))
})

test_that("directedness follows the weight, not an assumption", {
  set.seed(8)
  items <- letters[1:5]
  tx2 <- lapply(1:200, function(i) unique(sample(items, sample(2:4, 1),
                prob = c(.35, .25, .18, .12, .1))))
  co <- dynarules(tx2, min_support = 0.05, min_confidence = 0.05,
                  min_lift = 0)

  # Symmetric measures carry no direction: drawing arrows would overclaim.
  for (w in c("lift", "support", "kappa", "jaccard", "cosine", "phi")) {
    net <- as_network(co, weight = w)
    expect_false(net$directed)
    expect_equal(net$weights, t(net$weights), ignore_attr = TRUE)
  }
  # Asymmetric ones do.
  for (w in c("confidence", "conviction", "laplace")) {
    net <- as_network(co, weight = w)
    expect_true(net$directed)
    expect_false(isTRUE(all.equal(net$weights, t(net$weights),
                                  check.attributes = FALSE)))
  }
})

test_that("sequential networks are directed whatever the weight", {
  sq <- list(c("a", "b"), c("a", "b"), c("a", "b"), c("b", "a"),
             c("a", "b"), c("a", "b"))
  sf <- dynarules(sq, type = "sequential", min_support = 0.2,
                  min_confidence = 0.1, min_lift = 0)
  for (w in c("lift", "support", "confidence")) {
    expect_true(as_network(sf, weight = w)$directed)
  }
  # Order really is destroyed in one direction.
  W <- as_network(sf, weight = "support")$weights
  expect_gt(W["a", "b"], 0)
  expect_equal(W["b", "a"], 0)
})

test_that("directed can be overridden explicitly", {
  fitn <- dynarules(tx, min_support = 0.2, min_confidence = 0.2,
                    min_lift = 0)
  expect_true(as_network(fitn, weight = "lift", directed = TRUE)$directed)
  expect_false(as_network(fitn, weight = "confidence",
                          directed = FALSE)$directed)
  expect_error(as_network(fitn, directed = "yes"), "is.logical")
})
