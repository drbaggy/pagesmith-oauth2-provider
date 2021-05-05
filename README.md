# Challenge 1 - Search Matrix

You are given 5x5 matrix filled with integers such that each row is sorted from left to
right and the first integer of each row is greater than the last integer of the previous
row.

Write a script to find a given integer in the matrix using an efficient search algorithm.

## Solution to challenge 1

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

 * Rather than using `map`/`grep` on the outer array, we instead use
   a "hard coded" binary search.

 * First we return 0 if the number is outside the range of numbers in
   the list.

 * Then we look to see if the number is below the first value of the
   4th row. This means it is in rows 1, 2 or 3. So we test for that.
   Otherwise it is in rows 4 or 5, so we can test that as well.
 
 * This function expression returns which row the number *could be in*

```perl
   $v < $m->[3][0]
 ? ( $v < $m->[1][0] ? 0 : $v < $m->[2][0] ? 1 : 2 )
 : ( $v < $m->[4][0] ? 3 : 4                       )
```

This leads the whole function to be:

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
| *Flatten* |  8,418/s |  *73%* |    *56%* |    *17%* |      *--* | *-59%* |  *-63%* |
| DNF       | 20,284/s |   317% |     276% |     181% |    *141%* |    --  |    -12% |
| DNF_opt   | 22,989/s |   373% |     326% |     219% |    *173%* |    13% |      -- |

We can see that this "optimal method" is somwhere betwen 4.5 and 5 times more efficient
than the "search" function.

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

# Challenge 2 - Ordered Letters

Given a word, you can sort its letters alphabetically (case insensitive).
For example, “beekeeper” becomes “beeeeekpr” and “dictionary” becomes
“acdiinorty”.

Write a script to find the longest English words that don’t change when
their letters are sorted.

## Dictionaries available

In this example we will consider the dictionaries available in Ubuntu,
as I am in UK - I will use the British English dictionaries:

 * `/usr/share/dict/british-english-small`
 * `/usr/share/dict/british-english-large`
 * `/usr/share/dict/british-english-huge`
 * `/usr/share/dict/british-english-insane`

## Assumptions into what really is a word

These dictionaries contain a number of "Words" which we wouldn't
necessarily consider to be words. Words with hyphens/apostrophes,
words starting with capital letters.

So we will filter these words out...

A summary of the four dictionaries above give the following counts:

| Name:  | # words | # trimmed |
| ------ | ------: | --------: |
| small  |  50,790 |    39,781 |
| large  | 166,828 |   113,695 |
| huge   | 344,861 |   245,593 |
| insane | 654,299 |   427,891 |

## Solution to challenge 2

We will collect all of the words that meet this requirement.
We will collect them in an array `@max`. The first value will
be the length of the words in the list and the rest 

There are 4 parts to the loop...

 * The filters as above...

   `!/\W/ && !/^[A-Z]/`

* A filter that skips words shorter than the max length
   
   `$max[0] <= length $_`

 * The calculation to see if the word matches

   `lc $_ eq join q(), sort split //, lc $_`

 * The code to either replace the array `@max` with the
   newer longer word *or* to push the new word to the end
   of the list.
   
   `$max[0] == length $_ ? ( push @max, $_ ) : ( @max = (length $_, $_) )`

The full function is....

```perl
sub longest {
  open my $fh, q(<), $_[0];
  my @max = (0);
     (chomp)         ## Remove newline character
  && !/\W/           ## Remove words with non-alpha chars
  && !/^[A-Z]/       ## Remove words starting with a capital
  && ( $max[0] <= length $_ )
                     ## Remove words that are too short
  && ( lc $_ eq join q(), sort split //, lc $_ )
                     ## Check the word is unchanged when the
                     ## letters are sorted
  && ( $max[0] == length $_
       ? ( push @max, $_ )
       : ( @max = (length $_, $_) )
     )
    ## If the word is the same length as the maximal word
    ## push it onto @max - so we store all the longest words
    ## with maximum length.
    ## If the word is longer than the max length (1st entry
    ## in @max - reset max to include the new max length and
    ## the word.
    while <$fh>;
  return "$_[0] > @max";
  ## Return the name of the file used, the size of the words
  ## and a complete list of the words of that length.
}
```

If you like the code more compact - here it is without the comments...

```perl
sub longest_no_comments {
  open my $fh, q(<), $_[0];
  my @m = (0);
  (chomp)&&!/\W/&&!/^[A-Z]/&&($m[0]<=length$_)&&
    (lc$_ eq join q(),sort split//,lc$_)&&
    ($m[0]==length$_?(push@m,$_):(@m=(length$_,$_)))
    while <$fh>;
  return "$_[0] > @m";
}
```

## The results...

```
british-english-small - max length 6 - 21 words
  abhors accent accept access accost almost
  begins bellow billow cellos chills chilly
  chimps chintz choosy choppy effort floors
  floppy glossy knotty

british-english-large - max length 7 - 1 word
  billowy

british-english-huge - max length 7 - 4 words
  beefily billowy chikors dikkops

british-english-insane - max length 8 - 1 word
  aegilops
```

## Some definitions...

All the 6 letter words and billowy and beefily are quite common words, but there are three that people may not have heard of these are all species names.

 * **chikors** - An alternative spelling of chukars - A species of partridge native to central Asia (*Alectoris chukar*).
 * **dikkops** - A bird of the family Burhinidae. The stone curlew, thick-knee. (From afrikaans) *dik*-*kop* or thick head
 * **aegilops** - A genus of Eurasian and North American plants in the grass family, Poaceae. They are known generally as goat grasses. Some species are known as invasive weeds in parts of North America.
