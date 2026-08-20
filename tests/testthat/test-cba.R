# "cool" always implies yes; "hot" + "humid" always implies no; the rest is
# a coin flip. A classifier should recover the two deterministic rules.
set.seed(3)
mk <- function(n) lapply(seq_len(n), function(i) {
  t1 <- sample(c("hot", "mild", "cool"), 1)
  t2 <- sample(c("humid", "windy"), 1)
  cls <- if (t1 == "cool") "yes" else
    if (t1 == "hot" && t2 == "humid") "no" else sample(c("yes", "no"), 1)
  c(t1, t2, cls)
})
train <- mk(200)
truth <- vapply(train, function(z) z[3], character(1))
fit <- cba(train, class = c("yes", "no"), min_support = 0.03,
           min_confidence = 0.5)

test_that("cba returns a decision list", {
  expect_s3_class(fit, "dynarules_cba")
  expect_gt(nrow(fit$rules), 0L)
  expect_true(fit$default %in% c("yes", "no"))
  expect_setequal(fit$classes, c("yes", "no"))
  expect_true(all(fit$rules$consequent %in% c("yes", "no")))
})

test_that("consequents are single class items only", {
  expect_false(any(grepl(",", fit$rules$consequent, fixed = TRUE)))
  antes <- unlist(strsplit(fit$rules$antecedent, ", ", fixed = TRUE))
  expect_false(any(antes %in% c("yes", "no")))
})

test_that("the decision list is sorted by precedence", {
  r <- fit$rules
  if (nrow(r) > 1L) {
    # confidence non-increasing; ties broken by support non-increasing
    for (i in seq_len(nrow(r) - 1L)) {
      expect_true(r$confidence[i] > r$confidence[i + 1L] ||
        isTRUE(all.equal(r$confidence[i], r$confidence[i + 1L])))
    }
  }
})

test_that("it recovers the deterministic structure of the generator", {
  lst <- paste(fit$rules$antecedent, "=>", fit$rules$consequent)
  expect_true(any(grepl("^cool =>\\s*yes$", lst)))
  expect_true(any(grepl("humid", lst) & grepl("no$", lst)))
})

test_that("it beats the majority-class baseline", {
  acc <- mean(predict(fit, train) == truth)
  baseline <- max(table(truth)) / length(truth)
  expect_gt(acc, baseline)
  expect_equal(acc, fit$accuracy)
})

test_that("predict returns one label per transaction, always a known class", {
  p <- predict(fit, train)
  expect_length(p, length(train))
  expect_true(all(p %in% c("yes", "no")))
  expect_false(anyNA(p))
  expect_equal(predict(fit), p)          # defaults to the training data
})

test_that("predict generalises to unseen transactions", {
  test <- mk(80)
  p <- predict(fit, test)
  expect_length(p, 80L)
  expect_true(all(p %in% c("yes", "no")))
  acc <- mean(p == vapply(test, function(z) z[3], character(1)))
  expect_gt(acc, 0.5)
})

test_that("type = 'rule' reports which rule fired", {
  idx <- predict(fit, train, type = "rule")
  expect_length(idx, length(train))
  fired <- idx[!is.na(idx)]
  expect_true(all(fired >= 1 & fired <= nrow(fit$rules)))
  # every case with no firing rule must take the default
  p <- predict(fit, train)
  expect_true(all(p[is.na(idx)] == fit$default))
  expect_equal(p[!is.na(idx)], fit$rules$consequent[fired])
})

test_that("a case matched by no rule falls through to the default", {
  unseen <- list(c("mild", "windy", "yes"))
  p <- predict(fit, unseen)
  expect_length(p, 1L)
  expect_true(p %in% c("yes", "no"))
})

test_that("print and summary describe the decision list", {
  expect_output(print(fit), "dynarules_cba")
  expect_output(print(fit), "otherwise")
  s <- summary(fit)
  expect_s3_class(s, "data.frame")
  expect_equal(nrow(s), nrow(fit$rules) + 1L)
  expect_equal(s$antecedent[nrow(s)], "(default)")
  expect_equal(s$consequent[nrow(s)], fit$default)
})

test_that("bad class specifications are refused", {
  expect_error(cba(train, class = c("yes", "nope")), "not present")
  # a transaction with two class items is ambiguous
  bad <- c(train, list(c("hot", "yes", "no")))
  expect_error(cba(bad, class = c("yes", "no")), "exactly one class")
  # and one with none
  bad2 <- c(train, list(c("hot", "humid")))
  expect_error(cba(bad2, class = c("yes", "no")), "exactly one class")
})

test_that("an unlearnable problem degrades to the default, not an error", {
  set.seed(9)
  noise <- lapply(1:60, function(i) c(sample(c("p", "q"), 1),
                                      sample(c("yes", "no"), 1)))
  f <- cba(noise, class = c("yes", "no"), min_support = 0.1,
           min_confidence = 0.95)
  expect_s3_class(f, "dynarules_cba")
  expect_true(f$default %in% c("yes", "no"))
  expect_true(all(predict(f, noise) %in% c("yes", "no")))
})
