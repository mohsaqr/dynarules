# `a` never occurs without `b`, so supp(a) == supp(a,b): {a} is not closed
# and {a,b} is not a generator. This makes the four targets genuinely differ.
tx <- list(c("a", "b"), c("a", "b"), c("a", "b", "c"), c("b", "c"),
           c("b", "c"), c("c", "d"), c("b", "d"), c("a", "b", "d"))
fit <- dynarules(tx, min_support = 0.1, min_confidence = 0.01, min_lift = 0)

test_that("itemsets() returns a tidy table", {
  it <- itemsets(fit)
  expect_s3_class(it, "data.frame")
  expect_named(it, c("pattern", "size", "support", "count"))
  expect_true(all(it$support > 0 & it$support <= 1))
  expect_equal(it$count, it$support * fit$n_transactions)
})

test_that("the condensed targets nest as theory requires", {
  frequent <- itemsets(fit, target = "frequent")$pattern
  closed <- itemsets(fit, target = "closed")$pattern
  maximal <- itemsets(fit, target = "maximal")$pattern
  generator <- itemsets(fit, target = "generator")$pattern
  expect_true(all(closed %in% frequent))
  expect_true(all(maximal %in% closed))
  expect_true(all(generator %in% frequent))
  # This fixture is built so the targets are strictly different.
  expect_lt(length(closed), length(frequent))
  expect_lt(length(maximal), length(closed))
})

test_that("maximal itemsets have no frequent superset", {
  maximal <- itemsets(fit, target = "maximal")
  frequent <- itemsets(fit, target = "frequent")
  fitems <- strsplit(frequent$pattern, ", ", fixed = TRUE)
  mitems <- strsplit(maximal$pattern, ", ", fixed = TRUE)
  has_superset <- vapply(mitems, function(m) {
    any(vapply(fitems, function(f) {
      length(f) > length(m) && all(m %in% f)
    }, logical(1)))
  }, logical(1))
  expect_false(any(has_superset))
})

test_that("closed itemsets have no equal-support superset", {
  closed <- itemsets(fit, target = "closed")
  frequent <- itemsets(fit, target = "frequent")
  fitems <- strsplit(frequent$pattern, ", ", fixed = TRUE)
  citems <- strsplit(closed$pattern, ", ", fixed = TRUE)
  violates <- vapply(seq_along(citems), function(i) {
    any(vapply(seq_along(fitems), function(j) {
      length(fitems[[j]]) > length(citems[[i]]) &&
        all(citems[[i]] %in% fitems[[j]]) &&
        isTRUE(all.equal(frequent$support[j], closed$support[i]))
    }, logical(1)))
  }, logical(1))
  expect_false(any(violates))
})

test_that("size and top arguments filter without brackets", {
  expect_true(all(itemsets(fit, min_size = 2)$size >= 2))
  expect_true(all(itemsets(fit, max_size = 1)$size <= 1))
  expect_equal(nrow(itemsets(fit, top = 3)), 3L)
  expect_true(!is.unsorted(rev(itemsets(fit)$support)))
})

test_that("targets work for sequential patterns", {
  seqs <- list(c("a", "b", "c"), c("a", "b"), c("a", "b", "c"), c("b", "c"))
  sfit <- dynarules(seqs, type = "sequential", min_support = 0.25,
                    min_confidence = 0.1, min_lift = 0)
  expect_true(all(itemsets(sfit, target = "maximal")$pattern %in%
                    itemsets(sfit, target = "frequent")$pattern))
  expect_gt(nrow(itemsets(sfit)), 0L)
})
