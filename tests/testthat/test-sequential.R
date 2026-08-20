# Sequential miner: order-aware rules with hand-computed values

# 4 ordered sequences:
#   S1: a b c     S2: a b     S3: a c b     S4: b a c
# containment supports:
#   <a>=4/4  <b>=4/4  <c>=3/4
#   <a,b> in S1,S2,S3 = 3/4      <b,a> in S4 = 1/4
#   <a,c> in S1,S3,S4 = 3/4      <c,a> = 0
#   <b,c> in S1,S4 = 2/4         <c,b> in S3 = 1/4
#   <a,b,c> in S1 = 1/4          <a,c,b> in S3 = 1/4
seq_toy <- list(c("a", "b", "c"), c("a", "b"), c("a", "c", "b"),
                c("b", "a", "c"))

test_that("directional supports are asymmetric and hand-verified", {
  fit <- dynarules(seq_toy, type = "sequential", min_support = 0.2,
                   min_confidence = 0, min_lift = 0, max_length = 3)
  f <- fit$frequent
  expect_equal(f$support[f$pattern == "a -> b"], 0.75)
  expect_equal(f$support[f$pattern == "b -> a"], 0.25)
  expect_equal(f$support[f$pattern == "a -> c"], 0.75)
  expect_false("c -> a" %in% f$pattern)
})

test_that("sequential rules split only at cut points and use pattern sups", {
  fit <- dynarules(seq_toy, type = "sequential", min_support = 0.2,
                   min_confidence = 0, min_lift = 0, max_length = 3)
  r <- fit$rules
  # rule a => b : conf = sup(<a,b>)/sup(<a>) = 0.75
  ab <- r[r$antecedent == "a" & r$consequent == "b", ]
  expect_equal(ab$confidence, 0.75)
  expect_equal(ab$lift, 0.75 / (1 * 1))
  # from <a,b,c>: exactly 2 splits (a => b->c and a->b => c)
  abc <- r[r$count == 1L & (r$antecedent == "a" | r$antecedent == "a -> b") &
             grepl("c", r$consequent, fixed = TRUE), ]
  expect_true("a -> b" %in% abc$antecedent)
  # a->b => c : conf = sup(<a,b,c>)/sup(<a,b>) = (1/4)/(3/4)
  abc2 <- r[r$antecedent == "a -> b" & r$consequent == "c", ]
  expect_equal(abc2$confidence, 1 / 3)
})

test_that("containment is non-contiguous", {
  # b then d with a gap
  tr <- list(c("b", "x", "x", "d"), c("d", "b"))
  fit <- dynarules(tr, type = "sequential", min_support = 0.5,
                   min_confidence = 0, min_lift = 0)
  expect_equal(fit$frequent$support[fit$frequent$pattern == "b -> d"], 0.5)
})

test_that("repeated items form valid patterns (a -> a)", {
  tr <- list(c("a", "b", "a"), c("a", "a"), c("a", "b"))
  fit <- dynarules(tr, type = "sequential", min_support = 0.5,
                   min_confidence = 0, min_lift = 0)
  expect_equal(fit$frequent$support[fit$frequent$pattern == "a -> a"],
               2 / 3)
})

test_that("sequential mining refuses set-only (matrix) input", {
  m <- matrix(c(1, 0, 1, 1), 2, 2, dimnames = list(NULL, c("a", "b")))
  expect_error(dynarules(m, type = "sequential"), "ordered sequences")
})

test_that("event-log grammar flows through the front door", {
  log <- data.frame(
    student = rep(c("s1", "s2"), each = 3L),
    code = c("plan", "discuss", "reflect", "plan", "discuss", "reflect"),
    stringsAsFactors = FALSE
  )
  fit <- dynarules(log, actor = "student", action = "code",
                   type = "sequential", min_support = 0.5,
                   min_confidence = 0, min_lift = 0, max_length = 3)
  expect_equal(fit$n_transactions, 2L)
  expect_equal(
    fit$frequent$support[fit$frequent$pattern == "plan -> discuss -> reflect"],
    1)
})
