use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Test::AnyOf;
use Test::More 0.96;

use File::LibMagic;

# If this is populated then libmagic will use it to find the magic file.
delete $ENV{MAGIC};

{
    my %standard = (
        'foo.foo' => [
            'ASCII text',
            'text/plain',
            qr/us-ascii/,
        ],
        'foo.c' => [
            [
                'ASCII C program text',
                'C source, ASCII text',
                'c program, ASCII text',    # Apple default magic
            ],
            'text/x-c',
            qr/us-ascii/,
        ],
        'tiny.pdf' => [
            'PDF document, version 1.4',
            'application/pdf',
            qr/(?:binary|unknown|us-ascii)/,
        ],
    );

    my $flm = File::LibMagic->new();

    subtest(
        'standard magic file',
        sub {
            _test_flm( $flm, \%standard );
        }
    );
}

SKIP:
{
    my $standard_file = _scrape_file_version();

    note "Found magic file at $standard_file";

    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
    skip "The standard magic file must exist at $standard_file", 1
        unless -l $standard_file || -f _;

    my $info = File::LibMagic->new()->info_from_filename($standard_file);
    skip "The file at $standard_file is not a magic file", 1
        unless $info && $info->{description} =~ /magic binary file/;

    my %custom = (
        'foo.foo' => [
            'A foo file',
            'text/plain',
            'us-ascii',
        ],
        'foo.c' => [
            [
                'ASCII C program text',
                'C source, ASCII text',
                'c program, ASCII text',    # Apple default magic
            ],
            'text/x-c',
            'us-ascii',
        ],
    );

    my $flm = File::LibMagic->new(
        [
            "$Bin/samples/magic",
            $standard_file,
        ],
    );

    subtest(
        'custom magic file',
        sub {
            _test_flm( $flm, \%custom );
        }
    );
}

sub _scrape_file_version {
    for (`file -v`) {    ## no critic (ProhibitBacktickOperators)
        chomp;
        next unless m/\Amagic file from (.*)/;

        my $magic = $1;

        ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
        return "$magic.mgc"
            if $magic !~ m/ [.] mgc \z /smx && -f "$magic.mgc";
        return $magic
            if -f $magic;

        last;
    }

    return '/usr/share/file/magic.mgc';
}

sub _test_flm {
    my $flm   = shift;
    my $tests = shift;

    for my $file ( sort keys %{$tests} ) {
        my $path = "$Bin/samples/$file";

        subtest(
            "old API with $path",
            sub { _test_old_oo_api( $flm, $path, @{ $tests->{$file} } ); },
        );

        subtest(
            "new API with $path",
            sub { _test_new_oo_api( $flm, $path, @{ $tests->{$file} } ); },
        );
    }
}

sub _test_old_oo_api {
    my $flm      = shift;
    my $file     = shift;
    my $desc     = shift;
    my $mime     = shift;
    my $encoding = shift;

    like(
        $flm->checktype_filename($file),
        qr/$mime(?:; charset=$encoding)?/,
        "checktype_filename $file"
    );

    is_any_of(
        $flm->describe_filename($file),
        ref $desc ? $desc : [$desc],
        "describe_filename $file",
    );

    open my $fh, '<', $file or die $!;
    my $data = do { local $/ = undef; <$fh>; };
    close $fh or die $!;

    like(
        $flm->checktype_contents($data),
        qr/$mime(?:; charset=$encoding)?/,
        "checktype_contents $file"
    );

    like(
        $flm->checktype_contents( \$data ),
        qr/$mime(?:; charset=$encoding)?/,
        "checktype_contents $file as ref"
    );

    is_any_of(
        $flm->describe_contents($data),
        ref $desc ? $desc : [$desc],
        "describe_contents $file"
    );

    is_any_of(
        $flm->describe_contents( \$data ),
        ref $desc ? $desc : [$desc],
        "describe_contents $file as ref"
    );
}

sub _test_new_oo_api {
    my $flm  = shift;
    my $file = shift;
    my @args = @_;

    my @s;
    subtest(
        'info_from_filename',
        sub {
            _test_info( $flm->info_from_filename($file), @args );
        },
    );

    subtest(
        'info_from_string',
        sub {
            open my $fh, '<:raw', $file or die $!;
            my $string = do { local $/ = undef; <$fh> };
            close $fh or die $!;
            _test_info( $flm->info_from_string($string), @args );
        },
    );

    subtest(
        'info_from_string as ref',
        sub {
            open my $fh, '<:raw', $file or die $!;
            my $string = do { local $/ = undef; <$fh> };
            push @s, $string;
            close $fh or die $!;
            _test_info( $flm->info_from_string( \$string ), @args );
        },
    );

    subtest(
        'info_from_handle',
        sub {
            open my $fh, '<:raw', $file or die $!;
            _test_info( $flm->info_from_handle($fh), @args );
            my $content = do { local $/ = undef; <$fh> };
            close $fh or die $!;
            ok(
                length $content,
                'info_from_handle resets pos after reading'
            );
        },
    );

    subtest(
        'info_from_handle - handle from scalar ref',
        sub {
            open my $file_fh, '<:raw', $file or die $!;
            my $string = do { local $/ = undef; <$file_fh> };
            close $file_fh or die $!;

            ## no critic (InputOutput::RequireCheckedOpen, InputOutput::RequireCheckedSyscalls)
            open my $string_fh, '<', \$string;
            _test_info( $flm->info_from_handle($string_fh), @args );
            close $string_fh;
            ## use critic
        },
    );
}

sub _test_info {
    my $info     = shift;
    my $desc     = shift;
    my $mime     = shift;
    my $encoding = shift;

    is_any_of(
        $info->{description},
        ref $desc ? $desc : [$desc],
        'description'
    );

    is(
        $info->{mime_type},
        $mime,
        'mime_type',
    );

    like(
        $info->{encoding},
        qr/^$encoding$/,
        'encoding'
    );

    like(
        $info->{mime_with_encoding},
        qr/^$mime; charset=$encoding$/,
        'mime_with_encoding'
    );
}

{
    {

        package My::Magic::Subclass;

        use base qw( File::LibMagic );

        sub checktype_filename {'text/x-test-passes'}
    }

    subtest(
        'subclass of File::LibMagic',
        sub {
            my $subclass = My::Magic::Subclass->new();
            isa_ok( $subclass, 'My::Magic::Subclass' );
            is(
                $subclass->checktype_filename("$Bin/samples/missing"),
                'text/x-test-passes',
                'checktype_filename is overridden'
            );
        }
    );
}

done_testing();
