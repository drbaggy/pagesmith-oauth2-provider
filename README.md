# Challenge 1

Today's is an interesting challenge ... to check to see if a value is in the matrix....

Initially this looks like we need to define some efficient sorting algorithm that flattens
the array and then searches it {e.g. binary search}.

We implement this... but we compare it against some alternative simple methods. We don't
get the result we expect...

## Binary search

We first flatten the array. Then we loop until the array is empty or it has a solitary value

  If we get a match with the "middle" value we return 1;
  Otherwise we remove the half of the list using `splice` which
  the number isn't in.
  
We return 0 if the array has length 0. If the length is 1 we return
1 or 0 depending on whether the array is search value or not.

```perl
sub find_val_search {
  my( $val, $m, @list ) = ( $_[0], 0, map { @{$_} } @{$_[1]} );

    $list[ $m = @list >> 1 ] == $val ? ( return 1              )
  : $list[ $m              ] >  $val ? ( splice @list, $m      )
  :                                    ( splice @list, 0, $m+1 )
    while @list>1;

  return @list && $list[0] == $val ? 1 : 0;
}
```

## The other (better) methods:

### grep on the flattened array

```perl
sub find_val_grep_map {
  my($v,$m)=@_;
  return 0 + grep { $_ == $v } map { @{$_} } @{$m};
}
```

### reducing array with grep and then combining with map

Uses `grep` on each sub array to return either an
empty array or an array containing the match.
We then use `map` to combine the arrays.

The resultant array will have length `0` or `1`.

```perl
sub find_val_map_grep {
  my($v,$m)=@_;
  return 0 + map { grep { $_ == $v } @{$_} } @{$m};
}
```
## Efficiency

We use `cmpthese` to compare the performance...

Our methods are:
  * `find_val_search`
  * `find_val_grep_map`
  * `find_val_map_grep`

Timings using `Benchmark::cmpthese`

|           |   Rate   | Search | Grep-Map | Map-Grep | *Flatten* |
| --------- | -------: | -----: | -------: | -------: | --------: |
| Search    |  4,859/s |     -- |     -10% |     -33% |    *-42%* |
| Grep-Map  |  5,394/s |    11% |       -- |     -25% |    *-36%* |
| Map-Grep  |  7,210/s |    48% |      34% |       -- |    *-14%* |
| *Flatten* |  8,418/s |  *73%* |    *56%* |    *17%* |       --* |

Notes:

  * *Flatten* is for comparison only - it actually does nothing other than flatten
    the array - this highlights how efficient each algorithm is (and can be)
  
  * So we see that the map_grep solution is 50% more efficient than the search
    algorith (this is true for all search method algorithms which flatten
    the array first);

## Not flattening array

As we have a limit on performance with the flattening operation. To
improve efficiency we will need to consider a different approach: **To
not flatten!**

### Do not flatten - find the row containing the number

```perl
sub find_val_dnf {
  my($v,$m) = @_;
  return $v < $m->[0][0] || $v > $m->[4][4]
       ? 0
       : 0 + grep { $v == $_ } @{$m->[ $v < $m->[3][0]
           ? ( $v < $m->[1][0] ? 0 : $v < $m->[2][0] ? 1 : 2 )
           : ( $v < $m->[4][0] ? 3 : 4                       )
         ]};
}
```

### Do not flatten - optimal solution

 * As well as not using `map` or `grep` on the outside array we
   do so on the inner array.

 * Once we have chosen the correct row then we split it into
   two halves and check for a match in each half depending on
   whether it matches the middle value or is above/below.

```perl
sub find_val_dnf_optimal {
  my($v,$m,$t) = @_;

  return $v < $m->[0][0] || $v > $m->[4][4]
       ? 0
       : ( $t = $m->[ $v < $m->[3][0]
           ? ( $v < $m->[1][0] ? 0 : $v < $m->[2][0] ? 1 : 2 )
           : ( $v < $m->[4][0] ? 3 : 4                       )
         ] ) &&
         ( return $v == $t->[2] ? 1 :
                  $v < $t->[2] ?
                  (( $v == $t->[0] || $v == $t->[1] ) ? 1 : 0) :
                  (( $v == $t->[4] || $v == $t->[3] ) ? 1 : 0) );
}
```

Timings using `Benchmark::cmpthese`

|           |   Rate   | Search | Grep-Map | Map-Grep | *Flatten* | DNF    | DNF Opt |
| --------- | -------: | -----: | -------: | -------: | --------: | -----: | ------: |
| Search    |  4,859/s |     -- |     -10% |     -33% |    *-42%* |   -76% |    -79% |
| Grep-Map  |  5,394/s |    11% |       -- |     -25% |    *-36%* |   -73% |    -77% |
| Map-Grep  |  7,210/s |    48% |      34% |       -- |    *-14%* |   -64% |    -69% |
| *Flatten* |  8,418/s |  *73%* |    *56%* |    *17%* |       --* | *-59%* |  *-63%* |
| DNF       | 20,284/s |   317% |     276% |     181% |    *141%* |    --  |    -12% |
| DNF_opt   | 22,989/s |   373% |     326% |     219% |    *173%* |    13% |      -- |

We can see that this "optimal method" is somwhere betwen 4.5 and 5 times more efficient
that the "search" function.

## Test script

For completeness - this is the test and benchmarking script

```perl
#!/usr/local/bin/perl

use strict;

use warnings;
use feature qw(say);
use Test::More;
use Benchmark qw(cmpthese);

my $matrix = [
  [  1,  2,  3,  5,  7 ],
  [  9, 11, 15, 19, 20 ],
  [ 23, 24, 25, 29, 31 ],
  [ 32, 33, 39, 40, 42 ],
  [ 45, 47, 48, 49, 50 ],
];

## Create a test set - numbers from -10 to 60...
my %TEST_SET = map { $_ => 0 } (my @KEYS = -10..60);
 
## Set all to 0, and then iterate through the elements of the matrix
## and set the numbers in the list to 1....

$TEST_SET{$_} = 1 foreach map { @{$_} } @{$matrix};

## Run the original PWC test examples...
is( find_val_search(      35, $matrix ), 0 );
is( find_val_search(      39, $matrix ), 1 );
is( find_val_map_grep(    35, $matrix ), 0 );
is( find_val_map_grep(    39, $matrix ), 1 );
is( find_val_grep_map(    35, $matrix ), 0 );
is( find_val_grep_map(    39, $matrix ), 1 );
is( find_val_dnf(         35, $matrix ), 0 );
is( find_val_dnf(         39, $matrix ), 1 );
is( find_val_dnf_optimal( 35, $matrix ), 0 );
is( find_val_dnf_optimal( 39, $matrix ), 1 );

## Now run our full test set - from -10 to 60. This covers
## all cases within the list and a few either side...

is( find_val_dnf_optimal( $_, $matrix ), $TEST_SET{$_} ) foreach @KEYS;
is( find_val_dnf(         $_, $matrix ), $TEST_SET{$_} ) foreach @KEYS;
is( find_val_search(      $_, $matrix ), $TEST_SET{$_} ) foreach @KEYS;
is( find_val_map_grep(    $_, $matrix ), $TEST_SET{$_} ) foreach @KEYS;
is( find_val_grep_map(    $_, $matrix ), $TEST_SET{$_} ) foreach @KEYS;

done_testing();

cmpthese(100_000, {
  q(DNF_opt)  => sub { find_val_dnf_optimal( $_, $matrix ) foreach @KEYS; },
  q(DNF)      => sub { find_val_dnf(         $_, $matrix ) foreach @KEYS; },
  'Flatten'   => sub { flatten(              $_, $matrix ) foreach @KEYS; },
  'Search'    => sub { find_val_search(      $_, $matrix ) foreach @KEYS; },
  'Grep-Map'  => sub { find_val_grep_map(    $_, $matrix ) foreach @KEYS; },
  'Map-Grep'  => sub { find_val_map_grep(    $_, $matrix ) foreach @KEYS; },
});
```
