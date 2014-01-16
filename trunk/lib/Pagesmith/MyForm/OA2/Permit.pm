package Pagesmith::MyForm::OA2::Permit;

## Allow client to use given permissions...
##
## Author         : js5
## Maintainer     : js5
## Created        : 2009-08-12
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use strict;
use warnings;
use utf8;

use version qw(qv); our $VERSION = qv('0.1.0');

use Const::Fast qw(const);
const my $MAX_FAILURES  => 3;
const my $SLEEP_FACTOR  => 10;

use base qw(Pagesmith::MyForm Pagesmith::Support::OA2);
use Pagesmith::Utils::Authenticate;
use Pagesmith::Core qw(safe_base64_encode);
use Pagesmith::Session::User;
use Pagesmith::Config;

## All MyForm objects are required to define a number of methods
##
## fetch_object    -> getting the attached object
##                    how to get an object out of the database to attach to the
##                    form - this is the object that we will be
##                    creating/editting
## initialize_form -> setting up the elements of the form
##                    this is done after the object is fetched so can depend
##                    on the current state of the underlying object
## submit_form     -> what to do when the user finally submits the form
##                    this will usually generate an object/update an existing
##                    object

sub cant_edit {
  my $self = shift;
  return 'unknown_user' unless $self->user->logged_in;
  return;
}

sub initialize_form {
  my $self = shift;
  ## Set up the form...
  ## no critic (LongChainsOfMethodCalls)
  my $ret = $self->attribute( 'ref' )||q();
  $ret =~ s{\Ahttps?://[^/]+/}{/}mxs;
  $self->set_title( 'OA' )
       ->set_secure
       ->add_class(          'form',     'check' )          # Javascript validation is enabled
       ->add_class(          'form',     'cancel_quietly' ) # Cancel doens't throw warning!
       ->add_class(          'section',  'panel' )          # Form sections are wrapped in panels
       ->add_class(          'layout',   'fifty50' )        # Centre the form object
       ->add_form_attribute( 'id',       'login' )
       ->add_form_attribute( 'method',   'post' )
       ->set_option(         'validate_before_next' )
       ->set_option(         'cancel_button' )
       ->set_option(         'no_reset', )
       ->set_navigation_path( $ret )
       ->set_no_progress
       ;
  ## use critic

  my $client_id  = $self->attribute( 'client_id' ) ||q();
  my %scope_list = map { ($_=>1) } split m{\s+}mxs, $self->attribute( 'scope_list' )||q();

  ## Talk to oauth adaptor and get:
  # * the client details,
  # * the scope list and

  $self->add_stage( 'OAuth2 permissions' );

  my $ca = $self->adaptor( 'Client' );
  if( $ca && $client_id ) {
    $self->{'oa_client'}      = $ca->fetch_client( $client_id );
  }
  if( $self->{'oa_client'} ) {
    $self->{'oa_project'}     = $self->{'oa_client'}->get_project;
    $self->{'oa_scopes'}      = $self->adaptor( 'Scope' )->fetch_scopes;
    $self->{'oa_user'}        = $self->adaptor( 'User'  )->fetch_user_by_username( $self->user->username );
    $self->{'oa_user_scopes'} = $self->{'oa_user'}->get_permissions( $self->{'oa_project'} ) if $self->{'oa_user'};
    if( $self->{'oa_project'}) {
      $self->add_section( 'OAuth2 login for '.$self->{'oa_project'}->get_name );
      my $img = $self->{'oa_project'}->get_image;
      $self->add( 'Information', 'desc' )->set_caption(
        sprintf '<img class="left" src="/oa2/Logo/%s" height="%d" width="%d" alt="*" style="margin-right: 1em" />%s<div class="clear">&nbsp;</div>',
          $self->{'oa_client'}->get_code, $img->{'logo_height'},
          $img->{'logo_width'}, $self->encode( $self->{'oa_project'}->get_description ) );
      $self->add( 'Information', 'This application is requesting to authenticate you with your account details' );
    }
    my @req = grep { exists $scope_list{ $_->uid } } @{$self->{'oa_scopes'}||[]};

    $self->add( 'Information', 'scopes' )->set_caption(
      sprintf '<ul>%s</ul>', join q(), map {
        sprintf '<li><strong>%s %s</strong><br />%s</li>',
          $_->get_name,
          0 ? ' [already granted]' : q(),
          $_->get_description;
      } @req,
    ) if @req;
  } else {
    $self->add( 'Heading', 'unknown_client' );
  }
  $self->add_redirect_stage( 'auth' );

  $self->add_redirect_stage( 'unknown_user' );
  return $self;
}

sub on_cancel {
  my $self = shift;
  my $href = $self->attribute( 'ref' );
  return $href ? "$href&error=access_denied" : $self->base_url( $self->r );
}

sub on_redirect {
  my ($self, $stage ) = @_;
  ## We now need to store the information...
  my %scope_list = map { ($_=>1) } split m{\s+}mxs, $self->attribute( 'scope_list' )||q();
  if( $stage->id ne 'unknown_user' ) {
    ## We need to store the information about the scopes allocated....
    foreach ( keys %scope_list ) {
      $self->{'oa_user'}->add_permission( $self->{'oa_project'}, $_, 'granted' );
    }
  }
  $self->add_attribute( 'redirect', 'stored' )->store;
  return $self->attribute( 'ref' );
}

1;