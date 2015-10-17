package Test::Map::Tube;

$Test::Map::Tube::VERSION   = '0.10';
$Test::Map::Tube::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Test::Map::Tube - Interface to test Map::Tube (map data).

=head1 VERSION

Version 0.10

=cut

use strict; use warnings;
use 5.006;
use Carp;
use XML::Twig;
use Test::Builder;

my $TEST      = Test::Builder->new;
my $TEST_BOOL = 1;
my $PLAN      = 0;

=head1 DESCRIPTION

It's main responsibilty is to  validate the map data (xml) as used by the package
that takes the role of L<Map::Tube>.You can also unit test map functions as well.

=head1 SYNOPSIS

=head2 Validate map data (xml) ONLY.

    use strict; use warnings;
    use Test::More;

    eval "use Test::Map::Tube";
    plan skip_all => "Test::Map::Tube required" if $@;

    use Map::Tube::London;
    ok_map(Map::Tube::London->new);

=head2 Validate map functions ONLY.

    use strict; use warnings;
    use Test::More;

    my $min_ver = 0.09;
    eval "use Test::Map::Tube $min_ver";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    ok_map_functions(Map::Tube::London->new);

=head2 Validate map data and functions BOTH.

    use strict; use warnings;
    use Test::More;

    my $min_ver = 0.09;
    eval "use Test::Map::Tube $min_ver tests => 2";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    my $map = Map::Tube::London->new;
    ok_map($map);
    ok_map_functions($map);

=cut

sub import {
    my ($self, %plan) = @_;
    my $caller = caller;

    foreach my $function (qw(ok_map ok_map_functions)) {
        no strict 'refs';
        *{$caller."::".$function} = \&$function;
    }

    $TEST->exported_to($caller);
    $TEST->plan(%plan);

    $PLAN = 1 if (exists $plan{tests});
}

=head1 METHODS

=head2 ok_map($map_object, $message)

Validates the map data (xml).It expects an object of a package that has taken the
role of L<Map::Tube>. You can optionally pass C<$message>.

=cut

sub ok_map ($;$) {
    my ($object, $message) = @_;

    $TEST->plan(tests => 1) unless $PLAN;
    $TEST->is_num(_ok_map($object), $TEST_BOOL, $message);
}

=head2 ok_map_functions($map_object, $message)

Validated the map functions. It expects an object of a package that has taken the
role of L<Map::Tube>. You can optionally pass C<$message>.

=cut

sub ok_map_functions ($;$) {
    my ($object, $message) = @_;

    $TEST->plan(tests => 1) unless $PLAN;
    $TEST->is_num(_ok_map_functions($object), $TEST_BOOL, $message);
}

#
#
# PRIVATE METHODS

sub _ok_map {
    my ($object) = @_;

    return 0 unless (defined $object && $object->does('Map::Tube'));

    eval { $object->_validate_map_data; };
    return 1 unless ($@);

    carp($@) and return 0;
}

sub _ok_map_functions {
    my ($object) = @_;

    return 0 unless (defined $object && $object->does('Map::Tube'));

    my $actual = $object->_xml_data;

    # get_shortest_route()
    eval { $object->get_shortest_route };
    ($@) or (carp($@) and return 0);
    eval { $object->get_shortest_route('Foo') };
    ($@) or (carp($@) and return 0);
    eval { $object->get_shortest_route('Foo', 'Bar') };
    ($@) or (carp($@) and return 0);
    my $from_station = $actual->{stations}->{station}->[0]->{name};
    my $to_station   = $actual->{stations}->{station}->[1]->{name};
    eval { $object->get_shortest_route($from_station, 'Bar') };
    ($@) or (carp($@) and return 0);
    eval { $object->get_shortest_route('Foo', $to_station) };
    ($@) or (carp($@) and return 0);
    eval { $object->get_shortest_route($from_station, $to_station) };
    ($@) and carp($@) and return 0;

    # get_name()
    ($object->name eq $actual->{name}) or (carp($@) and return 0);

    # get_lines()
    my $lines_count = scalar(@{$actual->{lines}->{line}});
    (scalar(@{$object->get_lines}) == $lines_count) or (carp($@) and return 0);

    # get_stations()
    eval { $object->get_stations };
    ($@) or (carp($@) and return 0);
    eval { $object->get_stations('X') };
    ($@) or (carp($@) and return 0);
    my $line_name = $actual->{lines}->{line}->[0]->{name};
    (scalar(@{$object->get_stations($line_name)}) > 0) or (carp($@) and return 0);

    # get_line_by_id()
    eval { $object->get_line_by_id };
    ($@) or (carp($@) and return 0);
    eval { $object->get_line_by_id('L') };
    ($@) or (carp($@) and return 0);
    my $line_id = $actual->{lines}->{line}->[0]->{id};
    eval { $object->get_line_by_id($line_id) };
    ($@) and (carp($@) and return 0);

    # get_line_by_name() - handle in case when Map::Tube::Plugin::FuzzyNames is installed.
    eval { $object->get_line_by_name($line_name) };
    ($@) and (carp($@) and return 0);
    eval { my $l = $object->get_line_by_name('L'); croak() unless defined $l };
    ($@) or (carp($@) and return 0);
    eval { my $l = $object->get_line_by_name; croak() unless defined $l; };
    ($@) or (carp($@) and return 0);

    # get_node_by_id()
    eval { $object->get_node_by_id };
    ($@) or (carp($@) and return 0);
    eval { $object->get_node_by_id('X') };
    ($@) or (carp($@) and return 0);
    my $station_id = $actual->{stations}->{station}->[0]->{id};
    eval { $object->get_node_by_id($station_id) };
    ($@) and (carp($@) and return 0);

    # get_node_by_nane()
    eval { $object->get_node_by_name };
    ($@) or (carp($@) and return 0);
    eval { $object->get_node_by_name('X') };
    ($@) or (carp($@) and return 0);
    my $station_name = $actual->{stations}->{station}->[0]->{name};
    eval { $object->get_node_by_name($station_name) };
    ($@) and (carp($@) and return 0);

    return 1;
}

=head1 BUGS

None that I am aware of.Of course, if you find a bug, let me know, and I would do
my best  to fix it.  This is still a very early version, so it is always possible
that I have just "gotten it wrong" in some places.

=head1 SEE ALSO

=over 4

=item L<Map::Tube>

=back

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Test-Map-Tube>

=head1 BUGS

Please report any bugs / feature requests to C<bug-test-map-tube at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Map-Tube>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Map::Tube

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Map-Tube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Map-Tube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Map-Tube>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Map-Tube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it  and/or modify it under
the  terms  of the the Artistic License (2.0). You may  obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Test::Map::Tube
