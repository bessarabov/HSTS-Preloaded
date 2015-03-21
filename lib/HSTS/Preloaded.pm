package HSTS::Preloaded;

# ABSTRACT: Inspect Chrome's HSTS preloaded list

=encoding UTF-8

=cut

=head1 DESCRIPTION

This is a library to work with Chrome's HSTS preloaded list.

One can submit hosts for inclusion to the list with the form L<https://hstspreload.appspot.com/>.

And in the source code of Chromium one can see the list of hosts that are
currently in the list: L<https://code.google.com/p/chromium/codesearch#chromium/src/net/http/transport_security_state_static.json>

This library simplifies the work with the preloaded list.

=cut

use strict;
use warnings FATAL => 'all';
use utf8;
use open qw(:std :utf8);

use Carp;
use HTTP::Tiny;
use JSON::PP;

=head1 METHODS

=cut

=head2 new

    my $h = HSTS::Preloaded->new();

The constructor. It creates new object. It downloads all the info from
Chrome's HSTS preloaded list and stores it in the object. This is the only
method that interacts with intenet. All other methods uses data that object
already have.

=cut

sub new {
    my ($class, @params) = @_;

    croak "You should use new() without params" if @params;

    my $self = {};

    bless $self, $class;

    $self->{_data} = $self->_get_data_with_hsts_preloaded_list();

    # to speed up method host_is_in_hsts_preloaded_list()
    $self->{_hosts} = { map { $_->{name} => 1 } @{$self->{_data}->{entries}} };

    return $self;
}

=head2 host_is_in_hsts_preloaded_list

    my $result = $h->host_is_in_hsts_preloaded_list( $host );

Method returns true value if the specified host is in HSTS preloaded list.
Otherwise method returns false value.

For example:

    $h->host_is_in_hsts_preloaded_list('google.com'); # true
    $h->host_is_in_hsts_preloaded_list('microsoft.com'); # false

=cut

sub host_is_in_hsts_preloaded_list {
    my ($self, $host) = @_;

    croak "Host is not defined" if not defined $host;

    return !!$self->{_hosts}->{$host};
}

=head2 get_all_hsts_preloaded_list_data

    my $data = $h->get_all_hsts_preloaded_list_data();

Returns all the data. You can read the descrioption of the data structure
L<https://code.google.com/p/chromium/codesearch#chromium/src/net/http/transport_security_state_static.json>

This remoted returns perl hashref. For the boolean values that were in JSON
file the JSON::PP::Boolean objects are used.

Here is an example of some part of the data.

    my $partial_data = $h->get_all_hsts_preloaded_list_data()->{entries}->[619];

The $partial_data will be:

    {
        include_subdomains => JSON::PP::Boolean  {
            public methods (0)
            private methods (1) : __ANON__
            internals: 1
        },
        mode               => "force-https",
        name               => "www.dropbox.com",
        pins               => "dropbox",
    }

=cut

sub get_all_hsts_preloaded_list_data {
    my ($self) = @_;

    return $self->{_data};
}

=begin comment _get_data_with_hsts_preloaded_list

This is an internal method that downloads HSTS preloaded list from chromium
sources.

This method just downloads data from hardcoded url and parses it.

There is a question if the url is correct. I'm not sure that is the
primary version control system of chromium project. Is it svn or git.

I'm downloading data from git (because I love git much more than svn), but
I'm not sure if it is a preffered way of finding this data.

=end comment

=cut

sub _get_data_with_hsts_preloaded_list {
    my ($self) = @_;

    my $url = 'https://git.chromium.org/gitweb/?p=chromium/src/net.git;a=blob_plain;f=http/transport_security_state_static.json;hb=HEAD';

    my $content = $self->_get_content_from_url( $url );
    my $json = $self->_get_data_without_comments( $content );
    my $data = decode_json $json;

    return $data;
}

sub _get_data_without_comments {
    my ($self, $data) = @_;

    my $output;
    foreach my $line (split /\n/, $data) {
        if ($line !~ m{^\s*//}) {
            $output .= "$line\n";
        }
    }

    return $output;
}

sub _get_content_from_url {
    my ($self, $url) = @_;

    my $response = HTTP::Tiny->new->get($url);

    if ($response->{status} eq '200') {
        return $response->{content};
    } else {
        croak "Error. Can't get url '$url'. Got http status $response->{status}";
    }
}

1;
