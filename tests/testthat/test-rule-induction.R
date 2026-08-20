tx <- list(c("a", "b", "c"), c("a", "b"), c("a", "c"), c("b", "c"),
           c("a", "b", "c"))

test_that("induction reproduces re-mining exactly", {
  strict <- dynarules(tx, min_support = 0.2, min_confidence = 0.9,
                      min_lift = 0)
  induced <- rule_induction(strict, min_confidence = 0.3, min_lift = 0)
  remined <- dynarules(tx, min_support = 0.2, min_confidence = 0.3,
                       min_lift = 0)
  ord <- function(r) r[order(r$antecedent, r$consequent), , drop = FALSE]
  expect_equal(ord(induced$rules), ord(remined$rules),
               ignore_attr = TRUE)
})

test_that("induction reproduces re-mining for sequential rules too", {
  sq <- list(c("a", "b", "c"), c("a", "b"), c("a", "b", "c"))
  strict <- dynarules(sq, type = "sequential", min_support = 0.3,
                      min_confidence = 0.9, min_lift = 0)
  induced <- rule_induction(strict, min_confidence = 0.2, min_lift = 0)
  remined <- dynarules(sq, type = "sequential", min_support = 0.3,
                       min_confidence = 0.2, min_lift = 0)
  ord <- function(r) r[order(r$antecedent, r$consequent), , drop = FALSE]
  expect_equal(ord(induced$rules), ord(remined$rules), ignore_attr = TRUE)
})

test_that("the induced object is a full dynarules object", {
  fit <- dynarules(tx, min_support = 0.2, min_confidence = 0.9, min_lift = 0)
  ind <- rule_induction(fit, min_confidence = 0.3, min_lift = 0)
  expect_s3_class(ind, "dynarules")
  expect_gt(nrow(measures(ind, measure = "all")), 0L)
  expect_gt(nrow(rules(ind)), 0L)
  expect_s3_class(as_network(ind), "cograph_network")
  expect_equal(ind$n_transactions, fit$n_transactions)
})

test_that("tightening thresholds through induction shrinks the rule set", {
  fit <- dynarules(tx, min_support = 0.2, min_confidence = 0, min_lift = 0)
  n <- vapply(c(0, 0.3, 0.6, 0.9), function(cf) {
    nrow(rule_induction(fit, min_confidence = cf, min_lift = 0)$rules)
  }, numeric(1))
  expect_false(is.unsorted(rev(n)))
})

test_that("induction honours appearance and length limits", {
  fit <- dynarules(tx, min_support = 0.2, min_confidence = 0, min_lift = 0)
  only_c <- rule_induction(fit, min_confidence = 0, min_lift = 0,
                           appearance = list(rhs = "c"))
  expect_true(all(only_c$rules$consequent == "c"))
  long <- rule_induction(fit, min_confidence = 0, min_lift = 0,
                         min_length = 3)
  sizes <- lengths(strsplit(long$rules$antecedent, ", ", fixed = TRUE)) +
    lengths(strsplit(long$rules$consequent, ", ", fixed = TRUE))
  expect_true(all(sizes >= 3))
})

test_that("induction validates its input", {
  fit <- dynarules(tx, min_support = 0.2, min_confidence = 0.5)
  expect_error(rule_induction(list()), "dynarules")
  expect_error(rule_induction(fit, min_confidence = 2), "min_confidence")
})
