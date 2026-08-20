# transactions(): the event-log grammar and the other input paths

test_that("long event log builds actor-session transactions in time order", {
  log <- data.frame(
    student = c("s1", "s1", "s1", "s2", "s2", "s2"),
    lesson = c("L1", "L1", "L2", "L1", "L1", "L1"),
    code = c("plan", "discuss", "reflect", "discuss", "plan", "execute"),
    t = c(2, 1, 1, 1, 2, 3),
    stringsAsFactors = FALSE
  )
  tr <- transactions(log, actor = "student", action = "code",
                     time = "t", session = "lesson")
  expect_s3_class(tr, "dyna_transactions")
  expect_equal(tr$n_transactions, 3L)
  # s1/L1 ordered by time: discuss(t=1) then plan(t=2)
  expect_equal(tr$sequences[[1L]], c("discuss", "plan"))
  # s2/L1 ordered by time: discuss, plan, execute
  expect_equal(tr$sequences[[3L]], c("discuss", "plan", "execute"))
  expect_equal(tr$items, sort(unique(log$code)))
})

test_that("unit = 'actor' pools sessions into one stream", {
  log <- data.frame(
    student = c("s1", "s1", "s1", "s1"),
    lesson = c("L1", "L1", "L2", "L2"),
    code = c("a", "b", "c", "d"),
    stringsAsFactors = FALSE
  )
  tr <- transactions(log, actor = "student", action = "code",
                     session = "lesson", unit = "actor")
  expect_equal(tr$n_transactions, 1L)
  expect_equal(tr$sequences[[1L]], c("a", "b", "c", "d"))
})

test_that("unit = 'window' cuts tumbling windows and keeps >= 2 events", {
  log <- data.frame(
    id = rep("s1", 5L),
    code = c("a", "b", "c", "d", "e"),
    stringsAsFactors = FALSE
  )
  tr <- transactions(log, actor = "id", action = "code",
                     unit = "window", window = 2)
  # 5 events, tumbling width 2: (a,b), (c,d), (e) -> last dropped (< 2)
  expect_equal(tr$n_transactions, 2L)
  expect_equal(tr$sequences[[2L]], c("c", "d"))
  expect_equal(tr$ids$window, c(1L, 2L))
})

test_that("wide, list, and matrix inputs work; matrix loses order", {
  wide <- data.frame(V1 = c("a", "b"), V2 = c("b", NA),
                     stringsAsFactors = FALSE)
  tr_w <- transactions(wide)
  expect_equal(tr_w$n_transactions, 2L)
  expect_equal(tr_w$sequences[[1L]], c("a", "b"))
  expect_equal(tr_w$sequences[[2L]], "b")

  tr_l <- transactions(list(c("x", "y"), c("y", "z")))
  expect_equal(tr_l$items, c("x", "y", "z"))

  m <- matrix(c(1, 0, 1, 1), 2, 2, dimnames = list(NULL, c("a", "b")))
  tr_m <- transactions(m)
  expect_null(tr_m$sequences)
  expect_true(all(tr_m$matrix[1L, ]))
})

test_that("set matrix marks unique items per transaction", {
  tr <- transactions(list(c("a", "b", "a"), c("b", "c")))
  expect_equal(dim(tr$matrix), c(2L, 3L))
  expect_equal(as.vector(tr$matrix[1L, ]), c(TRUE, TRUE, FALSE))
  # repeats kept in the sequence form
  expect_equal(tr$sequences[[1L]], c("a", "b", "a"))
})

test_that("summary returns tidy per-item support", {
  tr <- transactions(list(c("a", "b"), c("a", "c")))
  s <- summary(tr)
  expect_equal(names(s), c("item", "count", "support"))
  expect_equal(s$support[s$item == "a"], 1)
  expect_equal(s$support[s$item == "b"], 0.5)
})
