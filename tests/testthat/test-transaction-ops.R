tx <- list(c("a", "b", "c"), c("a", "b"), c("a", "c"), c("b", "c"),
           c("a", "b", "c"), c("a"), c("b"))
tr <- transactions(tx)

test_that("item_frequency is tidy, sorted and internally consistent", {
  f <- item_frequency(tr)
  expect_named(f, c("item", "count", "support"))
  expect_equal(f$support, f$count / tr$n_transactions)
  expect_false(is.unsorted(rev(f$support)))
  expect_equal(nrow(item_frequency(tr, top = 2)), 2L)
  expect_equal(f$count[f$item == "a"], 5L)
})

test_that("cross_table counts pairs and leaves the diagonal out", {
  ct <- cross_table(tr)
  expect_named(ct, c("item1", "item2", "value"))
  expect_false(any(ct$item1 == ct$item2))
  expect_equal(nrow(ct), 6L)                       # 3 items, ordered pairs
  ab <- ct$value[ct$item1 == "a" & ct$item2 == "b"]
  expect_equal(ab, 3)                              # a and b share 3 rows
  expect_equal(ab, ct$value[ct$item1 == "b" & ct$item2 == "a"])
  expect_equal(nrow(cross_table(tr, diagonal = TRUE)), 9L)
  expect_true(all(cross_table(tr, measure = "support")$value <= 1))
})

test_that("an item's lift against itself is NA, not a number", {
  ct <- cross_table(tr, measure = "lift", diagonal = TRUE)
  expect_true(all(is.na(ct$value[ct$item1 == ct$item2])))
  expect_false(anyNA(cross_table(tr, measure = "lift")$value))
})

test_that("affinity is a symmetric Jaccard in [0, 1]", {
  af <- affinity(tr)
  expect_named(af, c("item1", "item2", "affinity"))
  expect_true(all(af$affinity >= 0 & af$affinity <= 1))
  ab <- af$affinity[af$item1 == "a" & af$item2 == "b"]
  ba <- af$affinity[af$item1 == "b" & af$item2 == "a"]
  expect_equal(ab, ba)
  expect_equal(ab, 3 / 7)                          # |a & b| = 3, |a | b| = 7
})

test_that("support_of measures itemsets you name yourself", {
  sp <- support_of(tr, list(c("a", "b"), "a", c("a", "b", "c")))
  expect_named(sp, c("pattern", "size", "support", "count"))
  expect_equal(sp$count, c(3, 5, 2))
  expect_equal(sp$support, c(3, 5, 2) / 7)
  expect_equal(sp$size, c(2L, 1L, 1L * 3L))
  expect_equal(support_of(tr, "zzz")$count, 0)     # unknown item, not an error
  expect_equal(support_of(tr, c("a", "b"))$pattern, "a, b")
})

test_that("support_of respects order when asked to", {
  seq_tr <- transactions(list(c("a", "b"), c("b", "a"), c("a", "b")))
  expect_equal(support_of(seq_tr, c("a", "b"), type = "sequential")$count, 2)
  expect_equal(support_of(seq_tr, c("a", "b"))$count, 3)
  mat_tr <- transactions(matrix(c(TRUE, TRUE), 1, 2,
                                dimnames = list(NULL, c("a", "b"))))
  expect_error(support_of(mat_tr, c("a", "b"), type = "sequential"),
               "ordered sequences")
})

test_that("sampling returns a smaller transaction set", {
  set.seed(1)
  s <- sample_transactions(tr, size = 3)
  expect_s3_class(s, "dyna_transactions")
  expect_equal(s$n_transactions, 3L)
  expect_length(s$sequences, 3L)
  expect_equal(nrow(s$matrix), 3L)
  expect_error(sample_transactions(tr, size = 100), "replace = TRUE")
  expect_equal(sample_transactions(tr, size = 100,
                                   replace = TRUE)$n_transactions, 100L)
})

test_that("random_transactions honours its shape arguments", {
  set.seed(2)
  rt <- random_transactions(50, 6, density = 0.5)
  expect_s3_class(rt, "dyna_transactions")
  expect_equal(rt$n_transactions, 50L)
  expect_lte(length(rt$items), 6L)
  expect_true(all(grepl("^item", rt$items)))
  expect_error(random_transactions(10, 3, density = 2), "density")
})

test_that("add_complement adds one negated item per named item", {
  cp <- add_complement(tr, items = "a")
  expect_true("!a" %in% cp$items)
  expect_equal(length(cp$items), length(tr$items) + 1L)
  expect_equal(sum(cp$matrix[, "!a"]), sum(!tr$matrix[, "a"]))
  expect_null(cp$sequences)                        # absence has no position
  expect_error(add_complement(tr, items = "zzz"), "Unknown item")
  expect_equal(length(add_complement(tr)$items), 2L * length(tr$items))
})

test_that("aggregate_items rolls items up and collapses repeat runs", {
  ag <- aggregate_items(tr, c(a = "vowel", b = "cons", c = "cons"))
  expect_setequal(ag$items, c("cons", "vowel"))
  # c("a","b","c") -> vowel, cons, cons -> collapses to vowel, cons
  expect_equal(ag$sequences[[1]], c("vowel", "cons"))
  expect_equal(ag$n_transactions, tr$n_transactions)
  df_map <- data.frame(item = c("a", "b", "c"),
                       group = c("vowel", "cons", "cons"))
  expect_equal(aggregate_items(tr, df_map)$items, ag$items)
  # unmapped items keep their own label
  expect_true("c" %in% aggregate_items(tr, c(a = "vowel"))$items)
})

test_that("read_transactions reads both file layouts", {
  f <- tempfile(); on.exit(unlink(f), add = TRUE)
  writeLines(c("a,b,c", "a,b", "b,c"), f)
  b <- read_transactions(f)
  expect_equal(b$n_transactions, 3L)
  expect_setequal(b$items, c("a", "b", "c"))

  g <- tempfile(); on.exit(unlink(g), add = TRUE)
  writeLines(c("t1,a", "t1,b", "t2,b", "t2,c"), g)
  s <- read_transactions(g, format = "single")
  expect_equal(s$n_transactions, 2L)
  expect_equal(s$sequences[[1]], c("a", "b"))
})

test_that("weights turn support into weighted support", {
  w <- c(10, 1, 1, 1, 1, 1, 1)
  wt <- transactions(tx, weights = w)
  expect_equal(wt$weights, w)
  # First transaction {a,b,c} now carries 10 of the 16 total weight.
  expect_equal(support_of(wt, c("a", "b", "c"))$support, 11 / 16)
  expect_equal(support_of(tr, c("a", "b", "c"))$support, 2 / 7)

  fit_w <- dynarules(wt, min_support = 0.1, min_confidence = 0.1,
                     min_lift = 0)
  expect_equal(fit_w$total_weight, sum(w))
  expect_equal(fit_w$n_transactions, 7L)
  expect_true(all(fit_w$rules$support <= 1))
})

test_that("weights are validated", {
  expect_error(transactions(tx, weights = c(1, 2)), "weights")
  expect_error(transactions(tx, weights = rep(-1, 7)), "weights")
  expect_error(transactions(tx, weights = rep(0, 7)), "sum to zero")
})

test_that("unweighted mining is unchanged by the weighted code path", {
  a <- dynarules(tx, min_support = 0.2, min_confidence = 0.2, min_lift = 0)
  b <- dynarules(transactions(tx, weights = rep(1, length(tx))),
                 min_support = 0.2, min_confidence = 0.2, min_lift = 0)
  expect_equal(a$rules$support, b$rules$support)
  expect_equal(a$rules$confidence, b$rules$confidence)
  expect_equal(a$rules$lift, b$rules$lift)
  expect_type(a$rules$count, "integer")
})

test_that("verbs accept raw input, not just transaction objects", {
  expect_equal(nrow(item_frequency(tx)), 3L)
  expect_equal(nrow(cross_table(tx)), 6L)
  expect_equal(support_of(tx, "a")$count, 5)
})
