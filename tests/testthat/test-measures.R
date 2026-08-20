tx <- list(c("a", "b", "c"), c("a", "b"), c("a", "c"), c("b", "c"),
           c("a", "b", "c"), c("a"), c("b"), c("a", "b"))
fit <- dynarules(tx, min_support = 0.2, min_confidence = 0.2, min_lift = 0)

test_that("the catalogue is a tidy table of 50 measures", {
  cat_df <- list_measures()
  expect_s3_class(cat_df, "data.frame")
  expect_equal(nrow(cat_df), 50L)
  expect_named(cat_df, c("measure", "range", "uses_subrules", "description"))
  expect_false(any(duplicated(cat_df$measure)))
  expect_true(all(nzchar(cat_df$description)))
})

test_that("measures() defaults to the four headline measures", {
  m <- measures(fit)
  expect_named(m, c("antecedent", "consequent", "support", "confidence",
                    "lift", "count"))
  expect_equal(nrow(m), nrow(fit$rules))
  expect_equal(m$support, fit$rules$support)
  expect_equal(m$lift, fit$rules$lift)
})

test_that("every catalogued measure computes for every rule", {
  m <- measures(fit, measure = "all")
  expect_equal(nrow(m), nrow(fit$rules))
  expect_true(all(list_measures()$measure %in% names(m)))
  numeric_ok <- vapply(m[list_measures()$measure], is.numeric, logical(1))
  expect_true(all(numeric_ok))
})

test_that("bounded measures stay inside their documented range", {
  m <- measures(fit, measure = c("confidence", "jaccard", "cosine", "kappa",
                                 "phi", "yuleQ", "laplace"))
  expect_true(all(m$confidence >= 0 & m$confidence <= 1))
  expect_true(all(m$jaccard >= 0 & m$jaccard <= 1))
  expect_true(all(m$cosine >= 0 & m$cosine <= 1))
  expect_true(all(m$laplace >= 0 & m$laplace <= 1))
  expect_true(all(m$kappa >= -1 & m$kappa <= 1))
  expect_true(all(m$phi >= -1 & m$phi <= 1))
  expect_true(all(m$yuleQ >= -1 & m$yuleQ <= 1))
})

test_that("identities that must hold by definition do hold", {
  m <- measures(fit, measure = c("support", "confidence", "lift", "coverage",
                                 "rhsSupport", "leverage", "addedValue",
                                 "centeredConfidence", "varyingLiaison"))
  expect_equal(m$confidence, m$support / m$coverage)
  expect_equal(m$lift, m$confidence / m$rhsSupport)
  expect_equal(m$leverage, m$support - m$coverage * m$rhsSupport)
  expect_equal(m$addedValue, m$centeredConfidence)
  expect_equal(m$varyingLiaison, m$lift - 1)
})

test_that("counts = TRUE returns a contingency table that adds to n", {
  m <- measures(fit, counts = TRUE)
  expect_true(all(c("n11", "n10", "n01", "n00") %in% names(m)))
  expect_equal(m$n11 + m$n10 + m$n01 + m$n00,
               rep(fit$n_transactions, nrow(m)))
  expect_equal(m$n11, fit$rules$count)
})

test_that("sub-rule measures fall back to zero, not NA", {
  m <- measures(fit, measure = c("improvement", "boost", "LIC"))
  expect_false(anyNA(m$improvement))
  single <- !grepl(", ", fit$rules$antecedent, fixed = TRUE)
  expect_equal(m$improvement[single],
               (fit$rules$support / fit$rules$support_antecedent)[single])
  expect_true(all(is.infinite(m$boost[single])))
})

test_that("unknown measures are refused by name", {
  expect_error(measures(fit, measure = "nope"), "Unknown measure")
  expect_error(measures(fit, measure = c("lift", "alsonope")), "alsonope")
  expect_error(measures(list()), "dynarules")
})

test_that("an empty rule set yields an empty tidy frame, not an error", {
  empty <- dynarules(tx, min_support = 0.99, min_confidence = 0.99)
  m <- measures(empty, measure = "all")
  expect_equal(nrow(m), 0L)
  expect_true(all(list_measures()$measure %in% names(m)))
})

test_that("rules carry the supports every measure is built from", {
  expect_true(all(c("support_antecedent", "support_consequent") %in%
                    names(fit$rules)))
  expect_equal(fit$rules$confidence,
               fit$rules$support / fit$rules$support_antecedent)
})

test_that("measures work for sequential rules too", {
  seqs <- list(c("a", "b", "c"), c("a", "b"), c("a", "c", "b"),
               c("b", "c"), c("a", "b", "c"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.2,
                    min_confidence = 0.2, min_lift = 0)
  m <- suppressWarnings(measures(sfit, measure = "all"))
  expect_equal(nrow(m), nrow(sfit$rules))
  expect_false(anyNA(m$support))
  expect_false(anyNA(m$confidence))
  expect_false(anyNA(m$lift))
})

test_that("sequential rules warn when the contingency table is inconsistent", {
  seqs <- list(c("a", "b", "c"), c("a", "b"), c("a", "c", "b"),
               c("b", "c"), c("a", "b", "c"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.2,
                    min_confidence = 0.2, min_lift = 0)
  expect_warning(measures(sfit, measure = "yuleY"),
                 "inconsistent contingency table")
  # The order-based measures stay clean and must not warn.
  expect_silent(measures(sfit, measure = c("support", "confidence", "lift")))
})
