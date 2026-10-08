# Package index

## Transactions

Deciding what counts as one transaction, and preparing the items.

- [`transactions()`](https://pak.dynasite.org/dynarules/reference/transactions.md)
  : Construct Transactions from Event Data
- [`read_transactions()`](https://pak.dynasite.org/dynarules/reference/read_transactions.md)
  : Read Transactions From a File
- [`discretize_items()`](https://pak.dynasite.org/dynarules/reference/discretize_items.md)
  : Discretize a Numeric Variable Into Mining Items
- [`item_frequency()`](https://pak.dynasite.org/dynarules/reference/item_frequency.md)
  : Item Frequencies
- [`cross_table()`](https://pak.dynasite.org/dynarules/reference/cross_table.md)
  : Pairwise Item Co-Occurrence
- [`affinity()`](https://pak.dynasite.org/dynarules/reference/affinity.md)
  : Item Affinity
- [`support_of()`](https://pak.dynasite.org/dynarules/reference/support_of.md)
  : Support of Arbitrary Itemsets
- [`sample_transactions()`](https://pak.dynasite.org/dynarules/reference/sample_transactions.md)
  : Sample Transactions
- [`random_transactions()`](https://pak.dynasite.org/dynarules/reference/random_transactions.md)
  : Generate Random Transactions
- [`add_complement()`](https://pak.dynasite.org/dynarules/reference/add_complement.md)
  : Add Complement Items
- [`aggregate_items()`](https://pak.dynasite.org/dynarules/reference/aggregate_items.md)
  : Roll Items Up a Hierarchy

## Mining

Finding the rules.

- [`dynarules()`](https://pak.dynasite.org/dynarules/reference/dynarules.md)
  : Mine Association or Sequential Rules
- [`rules()`](https://pak.dynasite.org/dynarules/reference/rules.md) :
  Extract, Filter, and Rank Mined Rules
- [`itemsets()`](https://pak.dynasite.org/dynarules/reference/itemsets.md)
  : Frequent Itemsets and Their Closed, Maximal and Generator Subsets
- [`rule_induction()`](https://pak.dynasite.org/dynarules/reference/rule_induction.md)
  : Induce Rules From Already-Mined Patterns

## Interest measures

The fifty ways to ask whether a rule is interesting.

- [`measures()`](https://pak.dynasite.org/dynarules/reference/measures.md)
  : Interest Measures for Mined Rules
- [`list_measures()`](https://pak.dynasite.org/dynarules/reference/list_measures.md)
  : Catalogue of Available Interest Measures

## Which rules to keep

- [`is_redundant()`](https://pak.dynasite.org/dynarules/reference/is_redundant.md)
  : Which Rules Are Redundant?
- [`is_significant()`](https://pak.dynasite.org/dynarules/reference/is_significant.md)
  : Which Rules Beat Independence?
- [`is_maximal()`](https://pak.dynasite.org/dynarules/reference/is_maximal.md)
  : Which Rules Rest on a Maximal Itemset?

## Inference

Rules are estimates; these say how much to trust them.

- [`bootstrap_rules()`](https://pak.dynasite.org/dynarules/reference/bootstrap_rules.md)
  : Bootstrap Stability of Mined Rules
- [`permute_rules()`](https://pak.dynasite.org/dynarules/reference/permute_rules.md)
  : Permutation Significance of Mined Rules

## Classification

- [`cba()`](https://pak.dynasite.org/dynarules/reference/cba.md) : Build
  a Classifier From Association Rules
- [`predict(`*`<dynarules_cba>`*`)`](https://pak.dynasite.org/dynarules/reference/predict.dynarules_cba.md)
  : Classify New Transactions

## Networks and plots

- [`as_network()`](https://pak.dynasite.org/dynarules/reference/as_network.md)
  : Convert Mined Rules to a Plottable Network
- [`rule_key()`](https://pak.dynasite.org/dynarules/reference/rule_key.md)
  : Draw the Size and Colour Key for a Rule Network

## Methods

Print, summary, plot and coercion methods for the result classes.

- [`print(`*`<dyna_transactions>`*`)`](https://pak.dynasite.org/dynarules/reference/print.dyna_transactions.md)
  : Print Method for dyna_transactions
- [`print(`*`<dynarules>`*`)`](https://pak.dynasite.org/dynarules/reference/print.dynarules.md)
  : Print Method for dynarules
- [`print(`*`<dynarules_boot>`*`)`](https://pak.dynasite.org/dynarules/reference/print.dynarules_boot.md)
  : Print Method for Bootstrapped Rules
- [`print(`*`<dynarules_cba>`*`)`](https://pak.dynasite.org/dynarules/reference/print.dynarules_cba.md)
  : Print Method for a CBA Classifier
- [`print(`*`<dynarules_net>`*`)`](https://pak.dynasite.org/dynarules/reference/print.dynarules_net.md)
  : Print Method for dynarules_net
- [`print(`*`<dynarules_perm>`*`)`](https://pak.dynasite.org/dynarules/reference/print.dynarules_perm.md)
  : Print Method for dynarules_perm
- [`summary(`*`<dyna_transactions>`*`)`](https://pak.dynasite.org/dynarules/reference/summary.dyna_transactions.md)
  : Summary Method for dyna_transactions
- [`summary(`*`<dynarules>`*`)`](https://pak.dynasite.org/dynarules/reference/summary.dynarules.md)
  : Summary Method for dynarules
- [`summary(`*`<dynarules_boot>`*`)`](https://pak.dynasite.org/dynarules/reference/summary.dynarules_boot.md)
  : Summary Method for dynarules_boot
- [`summary(`*`<dynarules_cba>`*`)`](https://pak.dynasite.org/dynarules/reference/summary.dynarules_cba.md)
  : Summary Method for a CBA Classifier
- [`summary(`*`<dynarules_perm>`*`)`](https://pak.dynasite.org/dynarules/reference/summary.dynarules_perm.md)
  : Summary Method for dynarules_perm
- [`plot(`*`<dynarules>`*`)`](https://pak.dynasite.org/dynarules/reference/plot.dynarules.md)
  : Plot Mined Rules
- [`plot(`*`<dynarules_boot>`*`)`](https://pak.dynasite.org/dynarules/reference/plot.dynarules_boot.md)
  : Plot Method for dynarules_boot
- [`plot(`*`<dynarules_perm>`*`)`](https://pak.dynasite.org/dynarules/reference/plot.dynarules_perm.md)
  : Plot Method for dynarules_perm
- [`as.data.frame(`*`<dynarules>`*`)`](https://pak.dynasite.org/dynarules/reference/as.data.frame.dynarules.md)
  : Coerce Mined Rules to a Data Frame
