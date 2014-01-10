package Pagesmith::Object::OA2::Url;

## Class for Url objects in namespace OA2.

## Author         : James Smith <js5>
## Maintainer     : James Smith <js5>
## Created        : Tue, 07 Jan 2014
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use base qw(Pagesmith::Object::OA2);

use Const::Fast qw(const);

## Definitions of lookup constants and methods exposing them to forms.
## ===================================================================

const my $ORDERED_URL_TYPE => [
  'redirect',
  'source',
  'user',
];
const my $LOOKUP_URL_TYPE => {
  'redirect' => 'redirect',
  'source' => 'source',
  'user' => 'user',
};
sub dropdown_values_url_type {
  return $ORDERED_URL_TYPE;
}

## uid property....
## ----------------

sub uid {
  my $self = shift;
  return $self->{'obj'}{'url_id'};
}

## Property get/setters
## ====================

## Property: url_id
## ----------------

sub get_url_id {
  my $self = shift;
  return $self->{'obj'}{'url_id'};
}

sub set_url_id {
  my ( $self, $value ) = @_;
  if( $value <= 0 ) {
    warn "Trying to set non positive value for 'url_id'\n";
    return $self;
  }
  $self->{'obj'}{'url_id'} = $value;
  return $self;
}

## Property: url_type
## ------------------

sub get_url_type {
  my $self = shift;
  return $self->{'obj'}{'url_type'};
}

sub set_url_type {
  my ( $self, $value ) = @_;
  unless( exists $LOOKUP_URL_TYPE->{$value} ) {
    warn "Trying to set invalid value for 'url_type'\n";
    return $self;
  }
  $self->{'obj'}{'url_type'} = $value;
  return $self;
}

## Property: uri
## -------------

sub get_uri {
  my $self = shift;
  return $self->{'obj'}{'uri'};
}

sub set_uri {
  my ( $self, $value ) = @_;
  $self->{'obj'}{'uri'} = $value;
  return $self;
}

sub set_client {
  my( $self, $client ) = @_;
  $client = $client->uid if ref $client;
  $self->{'obj'}{'client_id'} = $client;
  return $self;
}

sub get_client_id {
  my $self = shift;
  return $self->{'obj'}{'client_id'};
}
## Has "1" get/setters
## ===================

sub get_client {
  my $self = shift;
  return $self->get_other_adaptor( 'Client' )->fetch_client_by_url( $self );
}

## Has "many" getters
## ==================

## Relationship getters!
## =====================

## Store method
## =====================

sub store {
  my $self = shift;
  return $self->adaptor->store( $self );
}

sub remove {
  my $self = shift;
  return $self->adaptor->remove( $self );
}
## Other fetch functions!
## ======================
## Can add additional fetch functions here! probably hand crafted to get
## the full details...!

1;

__END__

Purpose
-------

Object classes are the basis of the Pagesmith OO abstraction layer
