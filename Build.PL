# $Id$
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

print <<EOM;

We want to know which of the bundled modules you intend to use.
All modules will be installed anyway, but if you answer "no" to any of the
questions below, that particular database type will not be tested, nor
will the dependencies be required.

Do you intend to use ...
EOM

my @exclude_tests;
my %requires = (
    'Class::DBI' => 0,
    'Class::DBI::LazyInflate' => 0,
);
my %depends = (
    pg    => {
        module   => 'Class::DBI::Plugin::DateTime::Pg',
        requires => { 'DBD::Pg' => 0, 'DateTime::Format::Pg' => 0 },
        env      => [
            POSTGRES_DSN      => 'PostgreSQL DSN to use for testing (empty to skip test)?',
            POSTGRES_USER     => 'PostgreSQL username to use for testing?',
            POSTGRES_PASSWORD => 'PostgreSQL password to use for testing?',
        ],
    },
    mysql => {
        module   => 'Class::DBI::Plugin::DateTime::MySQL',
        requires => { 'DBD::mysql' => 0, 'DateTime::Format::MySQL' => 0 },
        env      => [
            MYSQL_DSN      => 'MySQL DSN to use for testing (empty to skip test)?',
            MYSQL_USER     => 'MySQL username to use for testing?',
            MYSQL_PASSWORD => 'MySQL password to use for testing?',
        ],
    },
);

my %dsn;
while (my($type, $data) = each %depends) {
    my $skip = 1;

    if (Module::Build->y_n($data->{module} . '?', "y")) {
        $skip = 0;
        my $deps = $data->{requires};
        while (my($module, $version) = each %$deps) {
            $requires{$module} = $version;
        }

        my $env = $data->{env};
        for my $idx (0 .. (scalar(@{$env}) / 2) - 1) {
            my $key = $env->[2 * $idx];
            my $q   = $env->[2 * $idx + 1];

            my $value = Module::Build->prompt($q);
            if (!$value && $key =~ /_DSN$/) {
                $skip = 1;
                goto DONE;
            }

            $dsn{$key} = $value if $value;
        }
    }

DONE:
    if ($skip) {
        push @exclude_tests, '\b' . $type . '.*\\.t\z';
    }
}

my $code = <<'EOM';
sub ACTION_disttest
{
    my $self = shift;
    local $ENV{PERL_TESTPOD} = 1;
    $self->SUPER::ACTION_disttest(@_);
}

sub ACTION_test
{
    my $self = shift;
EOM
while (my($key, $value) = each %dsn) {
    $code .= sprintf(qq|    local \$ENV{%s} = '%s';\n|, $key, $value);
}
$code .= <<'EOM';
    $self->SUPER::ACTION_test(@_);
}

sub find_test_files
{
    my $self  = shift;
    my $tests = $self->SUPER::find_test_files(@_);
EOM

if (scalar @exclude_tests) {
    $code .= sprintf(<<'EOM', join('|', @exclude_tests));
    $tests = [ grep { !/%s/ } @$tests ];
EOM
}

$code .= <<'EOM';
    return $tests if $ENV{PERL_TESTPOD};
    return [ grep { $_ !~ /\bpod.*\.t\z/ } @$tests ];
}
EOM

my $class = Module::Build->subclass(code => $code);

my $build = $class->new(
    dist_name => 'Class-DBI-Plugin-DateTime',
    dist_version => '0.01',
    dist_author  => 'Daisuke Maki <dmaki@cpan.org>',
    license => 'perl',
    requires => \%requires,
    create_makefile_pl => 'traditional',
);

$build->create_build_script();