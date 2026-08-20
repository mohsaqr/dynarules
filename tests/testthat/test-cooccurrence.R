# Co-occurrence miner: hand-computed metrics on a fixed toy set

# 4 transactions:
#   T1 {a, b, c}   T2 {a, b}   T3 {b, c}   T4 {a, c}
# sup(a)=3/4  sup(b)=3/4  sup(c)=3/4
# sup(ab)=2/4 sup(ac)=2/4 sup(bc)=2/4  sup(abc)=1/4
toy <- list(c("a", "b", "c"), c("a", "b"), c("b", "c"), c("a", "c"))

test_that("pair rule metrics match hand computation", {
  fit <- dynarules(toy, min_support = 0.25, min_confidence = 0,
                   min_lift = 0, max_length = 3)
  r <- fit$rules
  ab <- r[r$antecedent == "a" & r$consequent == "b", ]
  expect_equal(nrow(ab), 1L)
  expect_equal(ab$support, 0.5)
  expect_equal(ab$confidence, 0.5 / 0.75)
  expect_equal(ab$lift, 0.5 / (0.75 * 0.75))
  expect_equal(ab$count, 2L)
  # conviction = (1 - sup(b)) / (1 - conf) = 0.25 / (1 - 2/3)
  expect_equal(ab$conviction, 0.25 / (1 - 0.5 / 0.75))
})

test_that("three-item itemset is found and split into all proper subsets", {
  fit <- dynarules(toy, min_support = 0.25, min_confidence = 0,
                   min_lift = 0, max_length = 3)
  f3 <- fit$frequent[fit$frequent$size == 3, ]
  expect_equal(f3$pattern, "a, b, c")
  expect_equal(f3$support, 0.25)
  # rules from {a,b,c}: 6 splits (3 singleton antecedents + 3 pairs)
  from_abc <- fit$rules[fit$rules$count == 1L, ]
  expect_equal(nrow(from_abc), 6L)
  # {a, b} => {c}: conf = sup(abc)/sup(ab) = 0.5
  abc <- from_abc[from_abc$antecedent == "a, b", ]
  expect_equal(abc$confidence, 0.5)
})

test_that("thresholds prune as documented", {
  fit <- dynarules(toy, min_support = 0.6, min_confidence = 0, min_lift = 0)
  # only singletons reach 60% support -> no rules
  expect_equal(nrow(fit$rules), 0L)
  expect_equal(max(fit$frequent$size), 1)

  fit2 <- dynarules(toy, min_support = 0.25, min_confidence = 0.7,
                    min_lift = 0)
  expect_true(all(fit2$rules$confidence >= 0.7))
})

test_that("max_length caps itemset size", {
  fit <- dynarules(toy, min_support = 0.25, min_confidence = 0,
                   min_lift = 0, max_length = 2)
  expect_equal(max(fit$frequent$size), 2)
})

test_that("order within a transaction does not matter for co-occurrence", {
  fit1 <- dynarules(list(c("a", "b"), c("a", "b"), c("b", "a")),
                    min_support = 0.5, min_confidence = 0, min_lift = 0)
  fit2 <- dynarules(list(c("b", "a"), c("b", "a"), c("a", "b")),
                    min_support = 0.5, min_confidence = 0, min_lift = 0)
  expect_equal(fit1$rules[order(fit1$rules$antecedent), ],
               fit2$rules[order(fit2$rules$antecedent), ])
})
