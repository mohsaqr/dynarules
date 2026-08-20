# bootstrap_rules() and permute_rules()

toy <- list(c("plan", "discuss", "reflect"),
            c("plan", "discuss", "execute"),
            c("plan", "discuss", "reflect"),
            c("discuss", "reflect"),
            c("plan", "discuss", "reflect"),
            c("plan", "execute"))

test_that("bootstrap_rules returns tidy stability with valid ranges", {
  fit <- dynarules(toy, min_support = 0.3, min_confidence = 0, min_lift = 0)
  bs <- bootstrap_rules(fit, iter = 30, seed = 42)
  st <- bs$stability
  expect_s3_class(st, "data.frame")
  expect_equal(nrow(st), nrow(fit$rules))
  expect_true(all(st$recovery >= 0 & st$recovery <= 1))
  ok <- !is.na(st$lift_lower)
  expect_true(all(st$lift_lower[ok] <= st$lift_upper[ok]))
})

test_that("bootstrap_rules is reproducible with a seed", {
  fit <- dynarules(toy, min_support = 0.3, min_confidence = 0, min_lift = 0)
  b1 <- bootstrap_rules(fit, iter = 20, seed = 7)
  b2 <- bootstrap_rules(fit, iter = 20, seed = 7)
  expect_equal(b1$stability, b2$stability)
})

test_that("permutation p-values are valid and reproducible", {
  fit <- dynarules(toy, min_support = 0.3, min_confidence = 0, min_lift = 0)
  p1 <- permute_rules(fit, iter = 99, seed = 3)
  p2 <- permute_rules(fit, iter = 99, seed = 3)
  expect_equal(p1$tests, p2$tests)
  expect_true(all(p1$tests$p > 0 & p1$tests$p <= 1))
  expect_true(all(p1$tests$p_adj >= p1$tests$p - 1e-12))
})

test_that("sequential permutation detects a genuinely ordered rule", {
  # order is perfectly consistent: a always precedes b, within rich noise
  set.seed(11)
  seqs <- lapply(1:40, function(i) {
    noise <- sample(c("x", "y", "z"), 3, replace = TRUE)
    c(noise[1], "a", noise[2], "b", noise[3])
  })
  fit <- dynarules(seqs, type = "sequential", min_support = 0.5,
                   min_confidence = 0, min_lift = 0, max_length = 2)
  pt <- permute_rules(fit, iter = 99, seed = 5)
  ab <- pt$tests[pt$tests$antecedent == "a" & pt$tests$consequent == "b", ]
  expect_equal(nrow(ab), 1L)
  expect_lt(ab$p, 0.05)
  expect_match(pt$null, "order")
})

test_that("co-occurrence permutation keeps item margins", {
  fit <- dynarules(toy, min_support = 0.3, min_confidence = 0, min_lift = 0)
  pt <- permute_rules(fit, iter = 50, seed = 9)
  expect_match(pt$null, "column")
  expect_equal(nrow(pt$tests), nrow(fit$rules))
})

test_that("inference verbs error cleanly with no rules", {
  fit <- dynarules(toy, min_support = 0.99)
  expect_error(bootstrap_rules(fit, iter = 10), "No rules")
  expect_error(permute_rules(fit, iter = 10), "No rules")
})
