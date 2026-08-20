x <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

test_that("each method returns a factor of the requested width", {
  for (m in c("frequency", "interval")) {
    f <- discretize(x, method = m, breaks = 4)
    expect_s3_class(f, "factor")
    expect_length(f, length(x))
    expect_equal(nlevels(f), 4L)
    expect_false(anyNA(f))
  }
})

test_that("equal-frequency bins hold roughly equal counts", {
  f <- discretize(x, method = "frequency", breaks = 5)
  expect_true(all(table(f) == 2))
})

test_that("equal-width bins split the range evenly", {
  f <- discretize(c(0, 10, 20, 30, 40), method = "interval", breaks = 2)
  expect_equal(nlevels(f), 2L)
  expect_equal(as.integer(table(f)), c(2L, 3L))     # right = FALSE: [0,20) [20,40]
})

test_that("clustering follows where the data clumps", {
  set.seed(4)
  y <- c(rnorm(30, 0, 0.2), rnorm(30, 10, 0.2))
  f <- discretize(y, method = "cluster", breaks = 2)
  expect_equal(nlevels(f), 2L)
  expect_equal(as.integer(table(f)), c(30L, 30L))
})

test_that("fixed breaks are used verbatim", {
  f <- discretize(x, method = "fixed", breaks = c(0, 5, 10))
  expect_equal(nlevels(f), 2L)
  expect_equal(as.integer(table(f)), c(4L, 6L))     # [0,5) and [5,10]
})

test_that("labels and ordering are respected", {
  f <- discretize(x, breaks = 3, labels = c("lo", "mid", "hi"))
  expect_equal(levels(f), c("lo", "mid", "hi"))
  expect_true(is.ordered(discretize(x, breaks = 3, ordered = TRUE)))
  expect_false(is.ordered(discretize(x, breaks = 3)))
})

test_that("infinity extends the outer bins beyond the training range", {
  f <- discretize(x, method = "interval", breaks = 2, infinity = TRUE)
  cuts <- levels(f)
  expect_true(grepl("-Inf", cuts[1]))
  expect_true(grepl("Inf", cuts[length(cuts)]))
})

test_that("a data.frame discretizes its numeric columns only", {
  df <- data.frame(num = x, chr = letters[1:10], stringsAsFactors = FALSE)
  out <- discretize(df, breaks = 2)
  expect_s3_class(out$num, "factor")
  expect_type(out$chr, "character")
  expect_warning(discretize(data.frame(a = letters[1:3])), "No numeric")
})

test_that("degenerate input warns rather than failing silently", {
  expect_error(discretize(rep(1, 10), method = "frequency", breaks = 3),
               "only one distinct value")
  # A near-constant vector loses bins but is still discretizable.
  expect_warning(discretize(c(rep(1, 9), 2), method = "frequency", breaks = 3),
                 "Duplicated cut points")
  expect_error(discretize("a"), "is.numeric")
})

test_that("discretized values feed straight into mining", {
  set.seed(6)
  df <- data.frame(score = runif(60, 0, 100), time = runif(60, 0, 60))
  binned <- discretize(df, breaks = 3, labels = c("low", "mid", "high"))
  wide <- data.frame(score = paste0("score=", binned$score),
                     time = paste0("time=", binned$time),
                     stringsAsFactors = FALSE)
  fit <- dynarules(wide, min_support = 0.05, min_confidence = 0.2,
                   min_lift = 0)
  expect_s3_class(fit, "dynarules")
  expect_gt(nrow(fit$rules), 0L)
})
