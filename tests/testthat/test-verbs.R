# rules() accessor, as.data.frame, as_network

toy <- list(c("a", "b", "c"), c("a", "b"), c("b", "c"), c("a", "c"),
            c("a", "b", "c"))

test_that("rules() filters, ranks, and caps", {
  fit <- dynarules(toy, min_support = 0.2, min_confidence = 0, min_lift = 0)
  all_r <- rules(fit)
  expect_true(nrow(all_r) > 0L)
  expect_true(all(diff(all_r$lift) <= 0))

  hi <- rules(fit, min_confidence = 0.6)
  expect_true(all(hi$confidence >= 0.6))

  top2 <- rules(fit, top = 2, by = "support")
  expect_equal(nrow(top2), 2L)
  expect_true(all(diff(top2$support) <= 0))
})

test_that("rules(items=, side=) restricts by item position", {
  fit <- dynarules(toy, min_support = 0.2, min_confidence = 0, min_lift = 0)
  onto_c <- rules(fit, items = "c", side = "consequent")
  expect_true(all(grepl("c", onto_c$consequent, fixed = TRUE)))
  expect_false(any(vapply(strsplit(onto_c$antecedent, ", ", fixed = TRUE),
                          function(v) !"c" %in% v, logical(1)) == FALSE &
                     !grepl("c", onto_c$consequent, fixed = TRUE)))
})

test_that("redundant = FALSE drops dominated specializations", {
  fit <- dynarules(toy, min_support = 0.2, min_confidence = 0, min_lift = 0)
  full <- rules(fit)
  pruned <- rules(fit, redundant = FALSE)
  expect_true(nrow(pruned) <= nrow(full))
  # a dominated rule: {a, b} => {c} has conf 1/2; check the general
  # {a} => {c} (conf sup(ac)/sup(a) = (3/5)/(4/5) = 0.75 >= 0.5)
  expect_false(any(pruned$antecedent == "a, b" & pruned$consequent == "c"))
})

test_that("as.data.frame returns the tidy rules table", {
  fit <- dynarules(toy, min_support = 0.2, min_confidence = 0, min_lift = 0)
  df <- as.data.frame(fit)
  expect_s3_class(df, "data.frame")
  # support_antecedent / support_consequent are the two supports every
  # interest measure is derived from; measures() reads them from here.
  expect_equal(names(df),
               c("antecedent", "consequent", "support", "confidence",
                 "lift", "conviction", "support_antecedent",
                 "support_consequent", "count", "n_transactions"))
})

test_that("as_network builds a directed cograph-compatible object", {
  fit <- dynarules(toy, min_support = 0.2, min_confidence = 0, min_lift = 0)
  net <- as_network(fit)
  expect_true(inherits(net, "cograph_network"))
  expect_true(net$directed)
  expect_equal(dim(net$weights), c(3L, 3L))
  expect_equal(net$nodes$label, c("a", "b", "c"))
  expect_true(is.integer(net$edges$from))
  expect_equal(sum(diag(net$weights)), 0)
  # edge a -> b weight = max lift over rules with a in antecedent, b in
  # consequent; all lifts here computable, just check positivity + match
  r <- rules(fit)
  expect_equal(net$weights["a", "b"],
               max(r$lift[grepl("a", r$antecedent, fixed = TRUE) &
                            grepl("b", r$consequent, fixed = TRUE)]))
})

test_that("as_network aggregate and weight arguments work", {
  fit <- dynarules(toy, min_support = 0.2, min_confidence = 0, min_lift = 0)
  net_mean <- as_network(fit, weight = "confidence", aggregate = "mean")
  r <- rules(fit)
  expect_equal(net_mean$weights["a", "b"],
               mean(r$confidence[grepl("a", r$antecedent, fixed = TRUE) &
                                   grepl("b", r$consequent, fixed = TRUE)]))
})
