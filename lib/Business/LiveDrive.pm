package Business::LiveDrive;
our $VERSION = '0.01';
use Carp qw/croak/;
use strict;
use warnings;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/apiKey/);

use Business::LiveDriveAPI; # Autogenerated SOAP::Lite bits

=head1 NAME

Business::LiveDrive - use the livedrive.com reseller API

=head1 SYNOPSIS

  use Business::LiveDrive;

  my $ld = Business::LiveDrive->new( apiKey => 'My-Reseller-Key');

  my $users = $ld->getusers();

  my $u = $ld->adduser( email => 'bob@example.com',
                        password => 'abc123',
                        ... );


=head1 DESCRIPTION

Perl interface to the livedrive.com reseller API.

You can use this interface to create, retrieve and update your users on 
your livedrive.com reseller account.

To use this you need to have registered a reseller account with 
livedrive.com from which you need the API Key from the reseller management
system. 

See the documentation on the livedrive.com website for more information.

=cut

sub new { shift->SUPER::new({ @_ }) }

sub _call {
    my ($self, $method, @args) = @_;
    my ($result, $status, $error) = 
        LiveDriveAPI->$method($self->apiKey, @args);
    if ( $error ) { croak($error); }
    if ( ! $result ) {
        croak("Unable to connect to LiveDrive API");
    }
    return $result;
}

=head2 addbackup

    $livedrive->addbackup('123456');

Upgrades a user account to include Backup. The account is specified by 
passing the account user ID.

Returns details for the upgraded account.

=cut

sub addbackup {
    my ($self, $id) = @_;
    croak('You must pass the cutomer ID') unless $id;
    my $res = $self->_call("AddBackup", $id);
    if ( $res->{Header}->{Code} ne 'UserUpgraded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 addbackupwithlimit

    $livedrive->addbackupwithlimit( userID => '123456', 
        capacity => 'OneTeraByte');

Upgrades a user account to include Backup with a limit as specified

Parameters:
    UserID      : the user account ID
    capacity    : one of HalfTeraByte, OneTeraByte, OneAndAHalfTeraBytes or TwoTeraBytes

Returns a hashref with the new details for the account

=cut

sub addbackupwithlimit {
    my ($self, %args) = @_;
    my @params = ();
    foreach (qw/userID capacity/) {
        croak("You must pass the $_ parameter") unless $args{$_};
        push @params, $args{$_};
    }
    my $res = $self->_call("AddBackupWithLimit", @params);
    if ( $res->{Header}->{Code} ne 'UserUpgraded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 adduser

Creates a new user

Parameters:
    email
    password
    confirmPassword
    subDomain
    capacity            :   Unlimited or HalfTeraByte or OneTeraByte or OneAndAHalfTeraBytes or TwoTeraBytes
    isSharing           :   true (1) or false (0)
    hasWebApps          :   true (1) or false (0)
    firstName
    lastName
    cardVerificationValue
    productType         :   Backup or Briefcase or BackupAndBriefCase

Note that capacity can only be set to Unlimited for Backup accounts. 
Briefcase and BackupAndBriefCase accounts cannot be unlimited.

Returns a hashref with details for the new account.

=cut

sub adduser {
    my ($self, %args) = @_;
    my @params = ();
    foreach (qw/email password confirmPassword subDomain
        capacity isSharing hasWebApps
        firstName lastName cardVerificationValue productType/) {
        croak("You must pass the $_ parameter") unless $args{$_};
        push @params, $args{$_};
    }
    my $res = $self->_call("AddUser", @params);
    if ( $res->{Header}->{Code} ne 'UserAdded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

sub adduserwithlimit {
    my ($self, %args) = @_;
    my @params = ();
    foreach (qw/email password confirmPassword subDomain
        BriefcaseCapacity BackupCapacity isSharing hasWebApps
        firstName lastName cardVerificationValue productType/) {
        croak("You must pass the $_ parameter") unless $args{$_};
        push @params, $args{$_};
    }
    my $res = $self->_call("AddUserWithLimit", @params);
    if ( $res->{Header}->{Code} ne 'UserAdded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 getuser

    $livedrive->getuser('123456');

Returns a hashref with details of the specified user account. 

=cut

sub getuser {
    my ($self, $id) = @_;
    croak("Your must supply the customer id") unless $id;
    my $res = $self->_call("GetUser", qq/$id/);
    if ( $res->{Header}->{Code} ne 'UserFound' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 getusers

    $livedrive->getusers($page_number);

Returns a paged list of user records. Returns first page unless 
$page_number (int) is specified in which case that page is returned.

=cut

sub getusers {
    my ($self, $page) = @_;
    $page = 1 unless $page;
    my $res = $self->_call("GetUsers", qq/$page/);
    return unless $res->{Header}->{Code} eq 'UsersFound';
    delete $res->{Header};
    return $res;
}

=head2 updateuser

Updates user details.

=cut

sub updateuser {
    my ($self, %args) = @_;
    my @params = ();
    foreach (qw/userID firstName lastName email password confirmPassword
        subDomain isSharing hasWebApps/) {
        croak("You must pass the $_ parameter") unless $args{$_} ||
            $_ =~ /assword/; # Password is not compulsory
        push @params, $args{$_};
    }
    my $res = $self->_call("UpdateUser", @params);
    if ( $res->{Header}->{Code} ne 'UserUpdated' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 upgradeuser

Adds briefcase to the user or upgrades a user to a briefcase of a given size.

Parameters:
    userID : The ID of the customer account
    capacity : HalfTeraByte or OneTeraByte or OneAndAHalfTeraBytes or TwoTeraBytes
    cardVerificationValue : the CV2 of the card used to register the reseller account

=cut

sub upgradeuser {
    my ($self, %args) = @_;
    my @params = ();
    foreach (qw/userID capacity cardVerificationValue/) {
        croak("You must pass the $_ parameter") unless $args{$_};
        push @params, $args{$_};
    }
    my $res = $self->_call("UpgradeUser", @params);
    if ( $res->{Header}->{Code} ne 'UserUpgraded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 closeuser

    $livedrive->closeuser('123456');

Closes a user account and deletes all backup and briefcase storage under 
that user account.

=cut

sub closeuser {
    my ($self, $id) = @_;
    croak("You must pass the user id") unless $id;
    my $res = $self->_call("CloseUser", qq/$id/);
    if ( $res->{Header}->{Code} ne 'UserClosed' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=cut addbusinessuser

    $livedrive->addbusinessuser( %parameters );

Add a Business User account. You must pass all of the parameters below.

Parameters:
    email
    password
    confirmPassword
    subDomain
    firstName
    lastName
    cardVerificationValue
    productType
    companyName
    userCapacity
    capacity                Unlimited or HalfTeraByte or OneTeraByte or OneAndAHalfTeraBytes or TwoTeraBytes

=cut

sub addbusinessuser {
    my ($self, %args) = @_;
    my @params = ();
    for my $p (qw/email password confirmPassword subDomain firstName 
                  lastName cardVerificationValue productType 
                  companyName userCapacity capacity/) {
        croak("You must pass the $p parameter") unless $args{$p};
        push @params, $args{$p};
    }
    my $res = $self->_call("AddBusinessUser", @params);
    if ( $res->{Header}->{Code} ne 'UserAdded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head2 adduserstobusiness

    $livedrive->adduserstobusiness( %parameters );

Parameters:
    userID                  The ID of the customer account
    cardVerificationValue   
    productType             
    userCapacity            

=cut

sub adduserstobusiness {
    my ($self, %args) = @_;
    my @params = ();
    for my $p (qw/userID cardVerificationValue productType userCapacity /) {
        croak("You must pass the $p parameter") unless $args{$p};
        push @params, $args{$p};
    }
    my $res = $self->_call("AddUsersToBusiness", @params);
    if ( $res->{Header}->{Code} ne 'UserAdded' ) {
        croak($res->{Header}->{Description});
    }
    delete $res->{Header};
    return $res;
}

=head1 SEE ALSO

http://www.livedrive.com/ for the API documentation

=head1 AUTHOR

Jason Clifford, E<lt>jason@ukfsn.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Jason Clifford

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 or later.

=cut
1;
