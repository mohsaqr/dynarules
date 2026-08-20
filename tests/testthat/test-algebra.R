tx <- list(c("a", "b", "c"), c("a", "b"), c("a", "c"), c("b", "c"),
           c("a", "b", "c"), c("a"), c("b"), c("a", "b"))
fit <- dynarules(tx, min_support = 0.2, min_confidence = 0.2, min_lift = 0)

test_that("predicates return one logical per rule", {
  n <- nrow(fit$rules)
  expect_length(is_redundant(fit), n)
  expect_length(is_significant(fit), n)
  expect_length(is_maximal(fit), n)
  expect_type(is_redundant(fit), "logical")
  expect_type(is_significant(fit), "logical")
  expect_type(is_maximal(fit), "logical")
  expect_false(anyNA(is_maximal(fit)))
})

test_that("a redundant rule really is beaten by a more general one", {
  red <- is_redundant(fit)
  r <- fit$rules
  if (any(red)) {
    i <- which(red)[1]
    ante_i <- strsplit(r$antecedent[i], ", ", fixed = TRUE)[[1]]
    beaten <- vapply(seq_len(nrow(r)), function(j) {
      aj <- strsplit(r$antecedent[j], ", ", fixed = TRUE)[[1]]
      r$consequent[j] == r$consequent[i] && length(aj) < length(ante_i) &&
        all(aj %in% ante_i) && r$confidence[j] >= r$confidence[i]
    }, logical(1))
    expect_true(any(beaten))
  }
  expect_equal(nrow(rules(fit, redundant = FALSE)), sum(!red))
})

test_that("significance tightens as the correction gets stricter", {
  n_none <- sum(is_significant(fit, adjust = "none"))
  n_bh <- sum(is_significant(fit, adjust = "BH"))
  n_bonf <- sum(is_significant(fit, adjust = "bonferroni"))
  expect_gte(n_none, n_bh)
  expect_gte(n_bh, n_bonf)
  expect_gte(sum(is_significant(fit, alpha = 0.5)),
             sum(is_significant(fit, alpha = 0.01)))
})

test_that("significance agrees with the Fisher measure it is built on", {
  p <- measures(fit, measure = "fishersExactTest")$fishersExactTest
  expect_equal(is_significant(fit, adjust = "none", alpha = 0.05), p < 0.05)
})

test_that("maximal rules have no larger mined pattern containing them", {
  mx <- is_maximal(fit)
  r <- fit$rules
  full <- lapply(seq_len(nrow(r)), function(i) {
    c(strsplit(r$antecedent[i], ", ", fixed = TRUE)[[1]],
      strsplit(r$consequent[i], ", ", fixed = TRUE)[[1]])
  })
  for (i in which(mx)) {
    bigger <- vapply(full, function(f) {
      length(f) > length(full[[i]]) && all(full[[i]] %in% f)
    }, logical(1))
    expect_false(any(bigger))
  }
})

test_that("rules() applies the predicates so callers never subset by hand", {
  expect_equal(nrow(rules(fit, significant = TRUE)),
               sum(is_significant(fit)))
  expect_equal(nrow(rules(fit, maximal = TRUE)), sum(is_maximal(fit)))
  expect_lte(nrow(rules(fit, significant = TRUE, maximal = TRUE)),
             nrow(rules(fit, significant = TRUE)))
  expect_equal(nrow(rules(fit, significant = TRUE, adjust = "none")),
               sum(is_significant(fit, adjust = "none")))
})

test_that("predicates handle an empty rule set", {
  empty <- dynarules(tx, min_support = 0.99, min_confidence = 0.99)
  expect_length(is_redundant(empty), 0L)
  expect_length(is_significant(empty), 0L)
  expect_length(is_maximal(empty), 0L)
  expect_equal(nrow(rules(empty, significant = TRUE)), 0L)
})

test_that("predicates reject non-dynarules input", {
  expect_error(is_redundant(list()), "dynarules")
  expect_error(is_significant(fit, alpha = 2), "alpha")
})
