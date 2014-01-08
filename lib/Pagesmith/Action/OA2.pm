package Pagesmith::Action::OA2;

## Put functions here that are shared between all Actions

## Author         : js5 (James Smith)
## Maintainer     : js5 (James Smith)
## Created        : 2014-01-08
## Last commit by : $Author $
## Last modified  : $Date $
## Revision       : $Revision $
## Repository URL : $HeadURL $

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use base qw(Pagesmith::Action Pagesmith::Support::OA2);

sub run {
  my $self = shift;
  return $self->no_content;
}

1;

