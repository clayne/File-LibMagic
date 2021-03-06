# This Makefile.PL for File-LibMagic was generated by
# inc::MyMakeMaker <self>
# and Dist::Zilla::Plugin::MakeMaker::Awesome 0.48.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Determine MIME types of data or files using libmagic",
  "AUTHOR" => "Andreas Fitzner, Michael Hendricks <michael\@ndrix.org>, Dave Rolsky <autarch\@urth.org>",
  "CONFIGURE_REQUIRES" => {
    "Config::AutoConf" => 0,
    "ExtUtils::CBuilder" => 0,
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "File-LibMagic",
  "LIBS" => "-lmagic",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "File::LibMagic",
  "PM" => {
    "lib/File/LibMagic.pm" => "\$(INST_LIB)/File/LibMagic.pm",
    "lib/File/LibMagic/Constants.pm" => "\$(INST_LIB)/File/LibMagic/Constants.pm"
  },
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "List::Util" => 0,
    "Scalar::Util" => 0,
    "XSLoader" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Cwd" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.96",
    "base" => 0,
    "lib" => 0
  },
  "VERSION_FROM" => "lib/File/LibMagic.pm",
  "test" => {
    "TESTS" => "t/*.t t/old-apis/*.t"
  }
);
my $gcc_warnings = $ENV{AUTHOR_TESTING} && $] >= 5.008008 ? q{ -Wall -Werror} : q{};
$WriteMakefileArgs{DEFINE}
    = ( $WriteMakefileArgs{DEFINE} || q{} ) . $gcc_warnings;

$WriteMakefileArgs{DEFINE} = ( $WriteMakefileArgs{DEFINE} || q{} ) . _defines();
$WriteMakefileArgs{INC}    = join q{ }, _includes();
$WriteMakefileArgs{LIBS}   = join q{ }, _libs(), $WriteMakefileArgs{LIBS};

my %FallbackPrereqs = (
  "Carp" => 0,
  "Cwd" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "List::Util" => 0,
  "Scalar::Util" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.96",
  "XSLoader" => 0,
  "base" => 0,
  "lib" => 0,
  "strict" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

use Config::AutoConf;
use Getopt::Long;

my @libs;
my @includes;

sub _libs     { return map { '-L' . $_ } @libs }
sub _includes { return map { '-I' . $_ } @includes }

sub _defines {
    GetOptions(
        'lib:s@'     => \@libs,
        'include:s@' => \@includes,
    );

    my $ac = Config::AutoConf->new(
        extra_link_flags   => [ _libs() ],
        extra_include_dirs => \@includes,
    );

    _check_libmagic($ac);

    my @defs;
    push @defs, '-DHAVE_MAGIC_VERSION'
            if $ac->check_lib( 'magic', 'magic_version' );
    push @defs, '-DHAVE_MAGIC_SETPARAM'
            if $ac->check_lib( 'magic', 'magic_setparam' );
    push @defs, '-DHAVE_MAGIC_GETPARAM'
            if $ac->check_lib( 'magic', 'magic_getparam' );

    return q{} unless @defs;
    return q{ } . join q{ }, @defs;
}

sub _check_libmagic {
    my $ac = shift;

    return
        if $ac->check_header('magic.h')
        && $ac->check_lib( 'magic', 'magic_open' );

    warn <<'EOF';

  This module requires the libmagic.so library and magic.h header. See
  INSTALL.md for more details on installing these.

EOF

    exit 1;
}
