# $Id$
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::DBI::Plugin::DateTime::Base;
use strict;
use DateTime;

sub import
{
    my $class = shift;
    $class->SUPER::import(@_);

    my ($caller) = caller();
    my @methods = $class->_export_methods();
    foreach my $method (@methods) {
        no strict 'refs';
        *{"${caller}::${method}"} = *{"${class}::${method}"};
    }
}

sub _export_methods { return () }

sub _setup_column
{
    my $class   = shift;
    my $target  = shift;
    my $column  = shift;
    my $inflate = shift;
    my $deflate = shift;

    if (! $target->can('has_lazy')) {
        eval <<"        EOM";
            package $target;
            use Class::DBI::LazyInflate;
        EOM
        die if $@;
    }

    $target->has_lazy(
        $column => 'DateTime',
        inflate => $inflate,
        deflate => $deflate,
    );
}

1;

__END__

=head1 NAME 

Class::DBI::Plugin::DateTime::Base - Base Class For DateTime Plugin

=head1 SYNOPSIS

   package MyPlugin;
   use base qw(Class::DBI::Plugin::DateTime::Base);

=head1 DESCRIPTION

Base class for Class::DBI::Plugin::DateTime classes.

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>. All rights reserved.

Development funded by Brazil Ltd E<lt>http://b.razil.jpE<gt>

=cut

