# Catalogue of Available Interest Measures

Catalogue of Available Interest Measures

## Usage

``` r
list_measures()
```

## Value

A tidy `data.frame` with one row per measure: its `measure` name, the
theoretical `range`, whether it compares against more general rules
(`uses_subrules`), and a one-line `description`.

## See also

[`measures()`](https://mohsaqr.github.io/dynarules/reference/measures.md)

## Examples

``` r
list_measures()
#>                measure       range uses_subrules
#> 1              support      [0, 1]         FALSE
#> 2           confidence      [0, 1]         FALSE
#> 3                 lift    [0, Inf)         FALSE
#> 4                count      [0, n]         FALSE
#> 5             coverage      [0, 1]         FALSE
#> 6           rhsSupport      [0, 1]         FALSE
#> 7           addedValue     [-1, 1]         FALSE
#> 8   centeredConfidence     [-1, 1]         FALSE
#> 9     casualConfidence      [0, 1]         FALSE
#> 10       casualSupport      [0, 2]         FALSE
#> 11           certainty     [-1, 1]         FALSE
#> 12          chiSquared    [0, Inf)         FALSE
#> 13  collectiveStrength    [0, Inf)         FALSE
#> 14 confirmedConfidence     [-1, 1]         FALSE
#> 15          conviction    [0, Inf)         FALSE
#> 16              cosine      [0, 1]         FALSE
#> 17      counterexample   (-Inf, 1]         FALSE
#> 18                 doc     [-1, 1]         FALSE
#> 19    fishersExactTest      [0, 1]         FALSE
#> 20                gini      [0, 1]         FALSE
#> 21     hyperConfidence      [0, 1]         FALSE
#> 22           hyperLift    [0, Inf)         FALSE
#> 23           imbalance      [0, 1]         FALSE
#> 24    implicationIndex (-Inf, Inf)         FALSE
#> 25         improvement   (-Inf, 1]          TRUE
#> 26          importance (-Inf, Inf)         FALSE
#> 27             jaccard      [0, 1]         FALSE
#> 28            jMeasure      [0, 1]         FALSE
#> 29               kappa     [-1, 1]         FALSE
#> 30          kulczynski      [0, 1]         FALSE
#> 31              lambda      [0, 1]         FALSE
#> 32             laplace      [0, 1]         FALSE
#> 33  leastContradiction   (-Inf, 1]         FALSE
#> 34              lerman (-Inf, Inf)         FALSE
#> 35            leverage     [-1, 1]         FALSE
#> 36                 LIC (-Inf, Inf)          TRUE
#> 37       maxconfidence      [0, 1]         FALSE
#> 38   mutualInformation      [0, 1]         FALSE
#> 39           oddsRatio    [0, Inf)         FALSE
#> 40                 phi     [-1, 1]         FALSE
#> 41      ralambondrainy      [0, 1]         FALSE
#> 42        relativeRisk    [0, Inf)         FALSE
#> 43                 RLD      [0, 1]         FALSE
#> 44     rulePowerFactor      [0, 1]         FALSE
#> 45               sebag    [0, Inf)         FALSE
#> 46             stdLift      [0, 1]         FALSE
#> 47      varyingLiaison   [-1, Inf)         FALSE
#> 48               yuleQ     [-1, 1]         FALSE
#> 49               yuleY     [-1, 1]         FALSE
#> 50               boost    [0, Inf)          TRUE
#>                                                                           description
#> 1                        P(A and B): fraction of transactions holding the whole rule.
#> 2                          P(B | A): how often the consequent follows the antecedent.
#> 3                     Confidence over the consequent's own support; 1 = independence.
#> 4                                             Transactions containing the whole rule.
#> 5                                 P(A): antecedent support, the rule's applicability.
#> 6                                                           P(B): consequent support.
#> 7          Confidence minus consequent support (Piatetsky-Shapiro change of support).
#> 8                       Confidence centred on independence; identical to added value.
#> 9                          Mean of the rule's confidence and its negated counterpart.
#> 10                       Support of the rule plus support of its negated counterpart.
#> 11      Certainty factor (Loevinger): confidence gain relative to the room available.
#> 12                    Chi-squared statistic for independence on the 2x2 table (1 df).
#> 13                        Ratio of observed to expected co-occurrence and co-absence.
#> 14              Confidence minus the confidence of the same antecedent against not-B.
#> 15      Expected-to-observed ratio of the rule being wrong; Inf when confidence is 1.
#> 16                      Geometric-mean-normalised co-occurrence (Ochiai coefficient).
#> 17                              Rate of supporting versus contradicting transactions.
#> 18                                 Difference of confidence: P(B|A) minus P(B|not A).
#> 19            One-sided Fisher p-value for the rule occurring more often than chance.
#> 20                             Gini index: impurity of B explained by splitting on A.
#> 21           1 minus the Fisher p-value: confidence that the rule beats independence.
#> 22          Count over the 99th percentile of its hypergeometric null; a robust lift.
#> 23                          Imbalance ratio: how unequal the two sides' supports are.
#> 24             Standardised deficit of counter-examples (Lerman's implication index).
#> 25            Confidence gain over the best more general rule in the set (0 if none).
#> 26          Log-odds weight of evidence that the antecedent brings to the consequent.
#> 27                                      Intersection over union of the two item sets.
#> 28            Cross-entropy: information the antecedent carries about the consequent.
#> 29          Cohen's kappa: agreement beyond chance between antecedent and consequent.
#> 30                      Mean of the two conditional probabilities, P(B|A) and P(A|B).
#> 31                Goodman-Kruskal lambda: proportional reduction in prediction error.
#> 32           Laplace-corrected confidence; shrinks rules resting on few transactions.
#> 33         Supporting minus contradicting transactions, scaled by consequent support.
#> 34                              Lerman similarity: standardised excess co-occurrence.
#> 35                                Piatetsky-Shapiro: observed minus expected support.
#> 36                                     Lift increase over the best more general rule.
#> 37                                     The larger of the two directions' confidences.
#> 38            Mutual information of the 2x2 table, normalised by the smaller entropy.
#> 39                      Odds of the consequent with the antecedent versus without it.
#> 40                 Phi coefficient: Pearson correlation of the two binary indicators.
#> 41                  Support of the counter-examples, P(A and not B); lower is better.
#> 42              Risk of the consequent given the antecedent versus given its absence.
#> 43              Relative linkage disequilibrium: deviation from independence, scaled.
#> 44 Support weighted by confidence; favours rules that are both frequent and reliable.
#> 45                      Sebag-Schoenauer: supporting over contradicting transactions.
#> 46                         Lift rescaled onto the range attainable at these supports.
#> 47                                       Lift minus one; deviation from independence.
#> 48                                          Yule's Q: odds ratio mapped onto [-1, 1].
#> 49                              Yule's Y: square-root odds ratio mapped onto [-1, 1].
#> 50               Confidence boost: confidence relative to the best more general rule.
```
