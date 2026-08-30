# Read Transactions From a File

Read Transactions From a File

## Usage

``` r
read_transactions(
  file,
  format = c("basket", "single"),
  sep = ",",
  header = FALSE,
  cols = c(1, 2)
)
```

## Arguments

- file:

  Path to a text file.

- format:

  `"basket"` (default): one transaction per line, items separated by
  `sep`. `"single"`: one item per line, with columns identifying the
  transaction and the item.

- sep:

  Field separator. Default `","`.

- header:

  Does the file have a header line? Default `FALSE`.

- cols:

  For `format = "single"`, the transaction-id and item column positions
  or names. Default `c(1, 2)`.

## Value

A `dyna_transactions` object.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)

## Examples

``` r
f <- tempfile()
writeLines(c("a,b,c", "a,b", "b,c"), f)
read_transactions(f)
#> <dyna_transactions>  3 transactions | 3 items | unit: row
#>   mean events per transaction: 2.3 (ordered sequences kept)
unlink(f)
```
