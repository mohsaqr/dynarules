# ---- S3 methods: print / summary / plot ----

.okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                "#0072B2", "#D55E00", "#CC79A7", "#999999")

#' Print Method for dynarules
#'
#' @param x A `dynarules` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules <- function(x, ...) {
  arrow <- "=>"
  cat(sprintf("<dynarules> %s rules  [%d rules | %d items | %d transactions]\n",
              x$type, nrow(x$rules), length(x$items), x$n_transactions))
  cat(sprintf("  support >= %.2f | confidence >= %.2f | lift >= %.2f | max length %d\n",
              x$params$min_support, x$params$min_confidence,
              x$params$min_lift, x$params$max_length))
  if (nrow(x$rules) > 0L) {
    top <- utils::head(x$rules, 10L)
    cat("\n  Top rules (by lift):\n")
    invisible(lapply(seq_len(nrow(top)), function(i) {
      cat(sprintf("    %2d. {%s} %s {%s}  (sup=%.3f conf=%.3f lift=%.2f)\n",
                  i, top$antecedent[i], arrow, top$consequent[i],
                  top$support[i], top$confidence[i], top$lift[i]))
    }))
    if (nrow(x$rules) > 10L) {
      cat(sprintf("    ... and %d more rules (see rules(x))\n",
                  nrow(x$rules) - 10L))
    }
  }
  invisible(x)
}


#' Summary Method for dynarules
#'
#' @param object A `dynarules` object.
#' @param ... Ignored.
#' @return The tidy rules data.frame.
#' @export
summary.dynarules <- function(object, ...) {
  as.data.frame(object)
}


#' Plot Method for dynarules
#'
#' @description
#' Support x confidence scatter of the mined rules, colored by lift with
#' the diverging midpoint at lift = 1 (independence).
#'
#' @param x A `dynarules` object.
#' @param top Integer or NULL. Plot only the top N rules by lift.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @export
plot.dynarules <- function(x, top = NULL, ...) {
  df <- rules(x, top = top)
  if (nrow(df) == 0L) {
    message("No rules to plot.")
    return(invisible(NULL))
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(x = support, y = confidence,
                                        color = lift)) +
    ggplot2::geom_point(size = 3, alpha = 0.8) +
    ggplot2::scale_color_gradient2(low = "#D33F6A", mid = "grey85",
                                   high = "#4A6FE3", midpoint = 1) +
    ggplot2::labs(
      x = "Support", y = "Confidence", color = "Lift",
      title = sprintf("%s rules (%d)",
                      if (x$type == "sequential") "Sequential" else
                        "Co-occurrence",
                      nrow(df))
    ) +
    ggplot2::theme_minimal(base_size = 12)
  print(p)
  invisible(p)
}


#' Print Method for dynarules_boot
#'
#' @param x A `dynarules_boot` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules_boot <- function(x, ...) {
  cat(sprintf("<dynarules_boot> %d resamples | %d rules | %.0f%% CIs\n",
              x$iter, nrow(x$stability), 100 * x$conf))
  st <- utils::head(x$stability, 10L)
  cat("\n  Rule stability (by recovery):\n")
  invisible(lapply(seq_len(nrow(st)), function(i) {
    cat(sprintf("    %2d. {%s} => {%s}  recovery=%.2f  lift=%.2f [%.2f, %.2f]\n",
                i, st$antecedent[i], st$consequent[i], st$recovery[i],
                st$lift_mean[i], st$lift_lower[i], st$lift_upper[i]))
  }))
  if (nrow(x$stability) > 10L) {
    cat(sprintf("    ... and %d more rules\n", nrow(x$stability) - 10L))
  }
  invisible(x)
}


#' Summary Method for dynarules_boot
#'
#' @param object A `dynarules_boot` object.
#' @param ... Ignored.
#' @return The tidy stability data.frame.
#' @export
summary.dynarules_boot <- function(object, ...) {
  st <- .subset2(object, "stability")
  row.names(st) <- NULL
  st
}


#' Plot Method for dynarules_boot
#'
#' @description
#' Rules ordered by recovery, showing the bootstrap lift interval per rule
#' and each rule's recovery proportion.
#'
#' @param x A `dynarules_boot` object.
#' @param top Integer. Plot the top N rules by recovery. Default 20.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @export
plot.dynarules_boot <- function(x, top = 20L, ...) {
  st <- utils::head(x$stability, top)
  if (nrow(st) == 0L) {
    message("No rules to plot.")
    return(invisible(NULL))
  }
  st$rule <- factor(paste0("{", st$antecedent, "} => {", st$consequent, "}"),
                    levels = rev(paste0("{", st$antecedent, "} => {",
                                        st$consequent, "}")))
  p <- ggplot2::ggplot(st, ggplot2::aes(x = lift_mean, y = rule)) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed",
                        color = "grey60", linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = lift_lower,
                                         xmax = lift_upper),
                            height = 0.25, color = "#0072B2") +
    ggplot2::geom_point(ggplot2::aes(size = recovery), color = "#0072B2") +
    ggplot2::scale_size_continuous(range = c(1.5, 4), limits = c(0, 1)) +
    ggplot2::labs(x = "Lift (bootstrap mean and CI)", y = NULL,
                  size = "Recovery",
                  title = sprintf("Rule stability (%d resamples)", x$iter)) +
    ggplot2::theme_minimal(base_size = 12)
  print(p)
  invisible(p)
}


#' Print Method for dynarules_perm
#'
#' @param x A `dynarules_perm` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules_perm <- function(x, ...) {
  cat(sprintf("<dynarules_perm> %d permutations | null: %s | %s correction\n",
              x$iter, x$null, x$correction))
  cat(sprintf("  %d of %d rules significant at adjusted p < .05\n",
              sum(x$tests$significant), nrow(x$tests)))
  tst <- utils::head(x$tests, 10L)
  cat("\n  Rules (by adjusted p):\n")
  invisible(lapply(seq_len(nrow(tst)), function(i) {
    cat(sprintf("    %2d. {%s} => {%s}  lift=%.2f (null %.2f)  p_adj=%.4f%s\n",
                i, tst$antecedent[i], tst$consequent[i], tst$lift[i],
                tst$lift_null[i], tst$p_adj[i],
                if (tst$significant[i]) " *" else ""))
  }))
  if (nrow(x$tests) > 10L) {
    cat(sprintf("    ... and %d more rules\n", nrow(x$tests) - 10L))
  }
  invisible(x)
}


#' Summary Method for dynarules_perm
#'
#' @param object A `dynarules_perm` object.
#' @param ... Ignored.
#' @return The tidy tests data.frame.
#' @export
summary.dynarules_perm <- function(object, ...) {
  tst <- .subset2(object, "tests")
  row.names(tst) <- NULL
  tst
}


#' Plot Method for dynarules_perm
#'
#' @description
#' Observed lift against the permutation-null mean per rule; significant
#' rules (adjusted p < .05) are highlighted.
#'
#' @param x A `dynarules_perm` object.
#' @param top Integer. Plot the top N rules by adjusted p. Default 20.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @export
plot.dynarules_perm <- function(x, top = 20L, ...) {
  tst <- utils::head(x$tests, top)
  if (nrow(tst) == 0L) {
    message("No rules to plot.")
    return(invisible(NULL))
  }
  tst$rule <- factor(paste0("{", tst$antecedent, "} => {",
                            tst$consequent, "}"),
                     levels = rev(paste0("{", tst$antecedent, "} => {",
                                         tst$consequent, "}")))
  p <- ggplot2::ggplot(tst, ggplot2::aes(y = rule)) +
    ggplot2::geom_segment(ggplot2::aes(x = lift_null, xend = lift,
                                       yend = rule),
                          color = "grey70", linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(x = lift_null), color = "grey60",
                        size = 2) +
    ggplot2::geom_point(ggplot2::aes(x = lift, color = significant),
                        size = 3) +
    ggplot2::scale_color_manual(values = c(`TRUE` = "#009E73",
                                           `FALSE` = "#D55E00"),
                                labels = c(`TRUE` = "significant",
                                           `FALSE` = "not significant")) +
    ggplot2::labs(x = "Lift (grey = permutation-null mean)", y = NULL,
                  color = NULL,
                  title = sprintf("Permutation test (%d permutations, %s)",
                                  x$iter, x$correction)) +
    ggplot2::theme_minimal(base_size = 12)
  print(p)
  invisible(p)
}
