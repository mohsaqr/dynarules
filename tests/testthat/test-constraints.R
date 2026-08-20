sq <- list(c("a", "x", "b"), c("a", "b"), c("a", "x", "x", "b"),
           c("a", "b", "c"), c("a", "b"))
cn <- dynarules:::.dr_contains

# Every embedding of `p` in `s`, tested against the documented constraints
# directly. The matcher must agree with this.
brute <- function(s, p, gap = NULL, min_gap = NULL, window = NULL) {
  n <- length(s); k <- length(p)
  if (k > n) return(FALSE)
  any(vapply(utils::combn(n, k, simplify = FALSE), function(idx) {
    if (!identical(s[idx], p)) return(FALSE)
    d <- diff(idx)
    (is.null(gap) || all(d <= gap)) &&
      (is.null(min_gap) || all(d >= min_gap)) &&
      (is.null(window) || (idx[k] - idx[1L]) <= window)
  }, logical(1)))
}

test_that("the matcher backtracks instead of committing to the first hit", {
  # Greedy first-match takes a@1, strands b@5, and wrongly reports FALSE.
  s <- c("a", "x", "x", "a", "b")
  expect_true(cn(s, c("a", "b")))
  expect_true(cn(s, c("a", "b"), gap = 1))
  expect_false(cn(s, c("a", "b"), min_gap = 5))
  expect_true(cn(s, c("a", "a", "b"), gap = 3))
  expect_false(cn(s, c("a", "a", "b"), gap = 1))
})

test_that("the matcher agrees with brute force over random inputs", {
  set.seed(101)
  alpha <- c("a", "b", "c")
  grid <- expand.grid(gap = c(NA, 1, 2, 3), min_gap = c(NA, 1, 2),
                      window = c(NA, 1, 2, 3, 5))
  disagree <- sum(vapply(seq_len(600), function(t) {
    s <- sample(alpha, sample(2:7, 1), replace = TRUE)
    p <- sample(alpha, sample(1:3, 1), replace = TRUE)
    cc <- grid[sample(nrow(grid), 1), ]
    g <- if (is.na(cc$gap)) NULL else cc$gap
    mg <- if (is.na(cc$min_gap)) NULL else cc$min_gap
    w <- if (is.na(cc$window)) NULL else cc$window
    if (!is.null(g) && !is.null(mg) && mg > g) return(FALSE)
    !identical(cn(s, p, gap = g, min_gap = mg, window = w),
               brute(s, p, gap = g, min_gap = mg, window = w))
  }, logical(1)))
  expect_equal(disagree, 0L)
})

test_that("the unconstrained path is unchanged", {
  base <- dynarules(sq, type = "sequential", min_support = 0.2,
                    min_confidence = 0.1, min_lift = 0)
  none <- dynarules(sq, type = "sequential", min_support = 0.2,
                    min_confidence = 0.1, min_lift = 0,
                    gap = NULL, min_gap = NULL, window_size = NULL)
  expect_equal(base$rules, none$rules)
})

test_that("constraints can only shrink support, never grow it", {
  supp <- function(fit, pat) {
    it <- itemsets(fit)
    v <- it$support[it$pattern == pat]
    if (length(v) == 0L) 0 else v
  }
  base <- dynarules(sq, type = "sequential", min_support = 0.1,
                    min_confidence = 0.1, min_lift = 0)
  g1 <- dynarules(sq, type = "sequential", min_support = 0.1,
                  min_confidence = 0.1, min_lift = 0, gap = 1)
  w1 <- dynarules(sq, type = "sequential", min_support = 0.1,
                  min_confidence = 0.1, min_lift = 0, window_size = 1)
  expect_equal(supp(base, "a -> b"), 1)
  expect_equal(supp(g1, "a -> b"), 0.6)     # only the 3 adjacent ones
  expect_lte(supp(w1, "a -> b"), supp(base, "a -> b"))
  expect_lte(nrow(itemsets(g1)), nrow(itemsets(base)))
})

test_that("a tighter gap never finds more than a looser one", {
  n <- vapply(1:4, function(g) {
    nrow(itemsets(dynarules(sq, type = "sequential", min_support = 0.1,
                            min_confidence = 0.1, min_lift = 0, gap = g)))
  }, numeric(1))
  expect_false(is.unsorted(n))
})

test_that("constraints are rejected for co-occurrence mining", {
  expect_error(dynarules(sq, gap = 1), "sequential")
  expect_error(dynarules(sq, window_size = 2), "sequential")
})

test_that("constraint arguments are validated", {
  expect_error(dynarules(sq, type = "sequential", gap = 0), "gap")
  expect_error(dynarules(sq, type = "sequential", gap = c(1, 2)), "gap")
  expect_error(dynarules(sq, type = "sequential", gap = 1, min_gap = 3),
               "cannot exceed")
})

test_that("a max gap disables the drop-one prune, which it must", {
  # Dropping a MIDDLE item widens its neighbours' gap, so a frequent
  # pattern can have an infrequent drop-one subsequence. Mining with a gap
  # must therefore still find long patterns.
  s2 <- rep(list(c("a", "b", "c", "d")), 10)
  fit <- dynarules(s2, type = "sequential", min_support = 0.5,
                   min_confidence = 0.1, min_lift = 0, gap = 1,
                   max_length = 4)
  it <- itemsets(fit)
  expect_true("a -> b -> c -> d" %in% it$pattern)
  expect_equal(max(it$size), 4L)
})
