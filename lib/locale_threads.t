use strict;
use warnings;

# This file tests interactions with locale and threads

my $LC_ALL;
my $LC_ALL_string;

BEGIN {
    $| = 1;

    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');

    skip_all_without_config('useithreads');

    require './loc_tools.pl';
    if (locales_enabled('LC_ALL')) {
        $LC_ALL_string = 'LC_ALL';
    }
    elsif (locales_enabled('LC_CTYPE')) {
        $LC_ALL_string = 'LC_CTYPE';
    }
    else {
        skip_all("No locales");
    }

    eval { require POSIX; POSIX->import(qw(errno_h locale_h  unistd_h )) };
    if ($@) {
        skip_all("could not load the POSIX module"); # running minitest?
    }

    # Convert to numeric
    $LC_ALL = eval "&POSIX::$LC_ALL_string";
}

use Time::HiRes qw(time usleep);

use Data::Dumper;
use Devel::Peek;
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deepcopy = 1;

plan(2);
my $debug = 0;
$debug = 0; #$^O =~ /MSWin32/i;
my $d = $^D;
#$d |= 0x04000000|0x00100000 if $^O =~ /MSWin32/i and $debug;

# reset the locale environment
delete local @ENV{'LANGUAGE', 'LANG', (grep /^LC_[A-Z]+$/, keys %ENV)};

my @valid_categories = valid_locale_categories();

my @locales = find_locales($LC_ALL);
skip_all("Couldn't find any locales") if @locales == 0;

#splice @locales, 20;
#print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@locales;

my ($utf8_locales_ref, $non_utf8_locales_ref)
                                    = classify_locales_wrt_utf8ness(\@locales);

my $official_ascii_name = 'ansi_x341968';

my %lang_code_to_script = (     # ISO 639.2, but without the many codes that
                                # are for latin (but the few western European
                                # ones that are latin1 are included)
                            am          => 'amharic',
                            amh         => 'amharic',
                            amharic     => 'amharic',
                            ar          => 'arabic',
                            be          => 'cyrillic',
                            bel         => 'cyrillic',
                            ben         => 'bengali',
                            bn          => 'bengali',
                            bg          => 'cyrillic',
                            bul         => 'cyrillic',
                            bulgarski   => 'cyrillic',
                            bulgarian   => 'cyrillic',
                            c           => $official_ascii_name,
                            cnr         => 'cyrillic',
                            de          => 'latin_1',
                            deu         => 'latin_1',
                            deutsch     => 'latin_1',
                            german      => 'latin_1',
                            div         => 'thaana',
                            dv          => 'thaana',
                            dzo         => 'tibetan',
                            dz          => 'tibetan',
                            el          => 'greek',
                            ell         => 'greek',
                            ellada      => 'greek',
                            en          => $official_ascii_name,
                            eng         => $official_ascii_name,
                            american    => $official_ascii_name,
                            british     => $official_ascii_name,
                            es          => 'latin_1',
                            fa          => 'arabic',
                            fas         => 'arabic',
                            flamish     => 'latin_1',
                            fra         => 'latin_1',
                            fr          => 'latin_1',
                            heb         => 'hebrew',
                            he          => 'hebrew',
                            hi          => 'hindi',
                            hin         => 'hindi',
                            hy          => 'armenian',
                            hye         => 'armenian',
                            ita         => 'latin_1',
                            it          => 'latin_1',
                            ja          => 'katakana',
                            jpn         => 'katakana',
                            nihongo     => 'katakana',
                            japanese    => 'katakana',
                            ka          => 'georgian',
                            kat         => 'georgian',
                            kaz         => 'cyrillic',
                            khm         => 'khmer',
                            kir         => 'cyrillic',
                            kk          => 'cyrillic',
                            km          => 'khmer',
                            ko          => 'hangul',
                            kor         => 'hangul',
                            korean      => 'hangul',
                            ku          => 'arabic',
                            kur         => 'arabic',
                            ky          => 'cyrillic',
                            latin1      => 'latin_1',
                            lao         => 'lao',
                            lo          => 'lao',
                            mk          => 'cyrillic',
                            mkd         => 'cyrillic',
                            macedonian  => 'cyrillic',
                            mn          => 'cyrillic',
                            mon         => 'cyrillic',
                            mya         => 'myanmar',
                            my          => 'myanmar',
                            ne          => 'devanagari',
                            nep         => 'devanagari',
                            nld         => 'latin_1',
                            nl          => 'latin_1',
                            nederlands  => 'latin_1',
                            dutch       => 'latin_1',
                            por         => 'latin_1',
                            posix       => $official_ascii_name,
                            ps          => 'arabic',
                            pt          => 'latin_1',
                            pus         => 'arabic',
                            ru          => 'cyrillic',
                            russki      => 'cyrillic',
                            russian     => 'cyrillic',
                            rus         => 'cyrillic',
                            sin         => 'sinhala',
                            si          => 'sinhala',
                            so          => 'arabic',
                            som         => 'arabic',
                            spa         => 'latin_1',
                            sr          => 'cyrillic',
                            srp         => 'cyrillic',
                            tam         => 'tamil',
                            ta          => 'tamil',
                            tg          => 'cyrillic',
                            tgk         => 'cyrillic',
                            tha         => 'thai',
                            th          => 'thai',
                            thai        => 'thai',
                            ti          => 'ethiopian',
                            tir         => 'ethiopian',
                            uk          => 'cyrillic',
                            ukr         => 'cyrillic',
                            ur          => 'arabic',
                            urd         => 'arabic',
                            zgh         => 'arabic',
                            zh          => 'chinese',
                            zho         => 'chinese',
                        );
my %codeset_to_script = (
                            88591  => 'latin_1',
                            88592  => 'latin_2',
                            88593  => 'latin_3',
                            88594  => 'latin_4',
                            88595  => 'cyrillic',
                            88596  => 'arabic',
                            88597  => 'greek',
                            88598  => 'hebrew',
                            88599  => 'latin_5',
                            885910 => 'latin_6',
                            885911 => 'thai',
                            885912 => 'devanagari',
                            885913 => 'latin_7',
                            885914 => 'latin_8',
                            885915 => 'latin_9',
                            885916 => 'latin_10',
                            cp1251 => 'cyrillic',
                            cp1255 => 'hebrew',
                      );

my %script_priorities = (       # In trying to make the results as distinct as
                                # possible, make the ones closest to Unicode,
                                # and ASCII lowest priority
                            $official_ascii_name => 15,
                            latin_1 => 14,
                            latin_9 => 13,
                            latin_2 => 12,
                            latin_4 => 12,
                            latin_5 => 12,
                            latin_6 => 12,
                            latin_7 => 12,
                            latin_8 => 12,
                            latin_10 => 12,
                            latin   => 11,  # Unknown latin version
                        );

my %script_instances;   # Keys are scripts, values are how many locales use
                        # this script.

sub analyze_locale_name($) {

    # Takes the input name of a locale and creates (and returns) a hash
    # containing information about that locale

    my %ret;
    $ret{locale_name} = shift;

    # XPG standard for locale names: language[_territory[.codeset]][@modifier]
    # But, there are instances which violate this, where there is a codeset
    # without a territory so instead match:
    # language[_territory][.codeset][@modifier]
    $ret{locale_name} =~ / ^
                                      ( .+? )          # language
                              (?:  _  ( .+? ) )?       # territory
                              (?: \.  ( .+? ) )?       # codeset
                              (?: \@  ( .+  ) )?       # modifier
                            $
                         /x;

    $ret{language}  = $1 // "";
    $ret{territory} = $2 // "";
    $ret{codeset}   = $3 // "";
    $ret{modifier}  = $4 // "";

    # Normalize all but 'territory' to lowercase
    foreach my $key (qw(language codeset modifier)) {
        $ret{$key} = lc $ret{$key};
    }

    # Often, the codeset is omitted from the locale name, but it is still
    # discoverable (via langinfo() ) for the current locale on many platforms.
    # So switch locales, get it, and switch back.
    my $old_locale = setlocale($LC_ALL);
    die "Unexpectedly can't setlocale($LC_ALL, $ret{locale_name})"
                                    if ! setlocale($LC_ALL, $ret{locale_name});
    use I18N::Langinfo qw(langinfo CODESET);
    my $langinfo_codeset = lc langinfo(CODESET);
    die "Unexpectedly can't restore locale" if ! setlocale($LC_ALL, $old_locale);

    # Normalize the codesets
    foreach my $codeset_ref (\$langinfo_codeset, \$ret{codeset}) {
        $$codeset_ref =~ s/\W//g;
        $$codeset_ref =~ s/iso8859/8859/g;
    }

    # The langinfo codeset, if found, is considered more reliable than the one
    # in the name.  (This is because libc looks into the actual data
    # definition.)  So use it unconditionally when found.  But note any
    # discrepancy as an aid for improving this test.
    if ($langinfo_codeset) {
        $langinfo_codeset =~ s/65001/utf8/;     # Windows synonym
        if ($ret{codeset}) {
            $ret{codeset} =~ s/65001/utf8/;
            if ($ret{codeset} ne $langinfo_codeset) {
                diag "In $ret{locale_name}, codeset from langinfo"
                   . " ($langinfo_codeset) doesn't match codeset in"
                   . " locale_name ($ret{codeset})";
            }
        }
        $ret{codeset} = $langinfo_codeset;
    }

    my $codeset_is_utf8 = $ret{codeset} =~ / ^ ( utf -? 8 | 65001 ) $ /x;

    # If the '@' modifier is a known script, use it as the script.
    if (    $ret{modifier}
        and grep { $_ eq $ret{modifier} } values %lang_code_to_script)
    {
        $ret{script} = $ret{nominal_script} = $ret{modifier};
        $ret{modifier} = "";
    }
    elsif ($ret{codeset} && ! $codeset_is_utf8) {

        # The codeset determines the script being used, except if we don't
        # have the codeset or it is UTF-8 (which covers a multitude of
        # scripts).
        #
        # We have hard-coded the scripts corresponding to a few of these
        # non-UTF-8 codesets.  See if this is one of them.
        $ret{script} = $codeset_to_script{$ret{codeset}};
        if ($ret{script}) {

            # For these, the script is likely a combination of ASCII (from
            # 0-127), and the script from (128-255).  Reflect that in the name
            # used (for distinguishing below)
            $ret{script} .= '_' . $official_ascii_name;
        }
        elsif ($ret{codeset} =~ /^koi/) {   # Another common set.
            $ret{script} = "cyrillic_${official_ascii_name}";
        }
        else {  # Here the codeset name is unknown to us.  Just assume it
                # means a whole new script.  Add the language at the end of
                # the name to further make it distinct
            $ret{script} = $ret{codeset};
            $ret{script} .= "_$ret{language}"
                                    if $ret{codeset} !~ /$official_ascii_name/;
        }
    }
    else {  # Here, the codeset is unknown or is UTF-8.

        # In these cases look up the script based on the language.  The table
        # is meant to be pretty complete, but omits the many scripts that are
        # ASCII or Latin1.  And it omits the fullnames of languages whose
        # scripts are themselves.  The grep below catches those.  Defaulting
        # to Latin means that a non-standard language name is considered to be
        # latin -- maybe not the best outcome but what else is better?
        $ret{script} = $lang_code_to_script{$ret{language}};
        if (! $ret{script}) {
            $ret{script} = (grep { $ret{language} eq $_ }
                                                    values %lang_code_to_script)
                            ? $ret{language}
                            : 'latin';
        }
    }

    # If we have @euro, and the script is ASCII or latin or latin1, change it
    # into latin9, which is closer to what is going on.  latin9 has a few
    # other differences from latin1, but it's not worth creating a whole new
    # script type that differs only in the currency symbol.
    if (  ($ret{modifier} && $ret{modifier} eq 'euro')
        && $ret{script} =~ / ^ ($official_ascii_name | latin (_1)? ) $ /x)
    {
        $ret{script} = 'latin_9';
    }

    #  Look up the priority of this script.  All the non-listed ones have
    #  highest (0 or 1) priority.  We arbitrarily make the ones higher
    #  priority (0) that aren't known to be half-ascii, simply because they
    #  might be entirely different than most locales.
    $ret{priority} = $script_priorities{$ret{script}};
    #print STDERR __FILE__, ": ", __LINE__, ": '", $ret{script}, "'\n";
    #print STDERR __FILE__, ": ", __LINE__, ": '", $official_ascii_name, "'\n";
    #print STDERR __FILE__, ": ", __LINE__, ": ", $ret{priority}, "\n";
    if (! $ret{priority}) {
        $ret{priority} = (   $ret{script} ne $official_ascii_name
                          && $ret{script} =~ $official_ascii_name)
                         ? 0
                         : 1;
    }

    # Script names have been set up so that anything after an underscore is a
    # modifier of the main script.  We keep a counter of which occurence of
    # this script this is.  This is used along with the priority to order the
    # locales so that the characters are as varied as possible.
    my $script_root = ($ret{script} =~ s/_.*//r) . "_$codeset_is_utf8";
    $ret{script_instance} = $script_instances{$script_root}++;

    #print STDERR __FILE__, ": ", __LINE__, ": ", $ret{locale_name}, ": $langinfo_codeset: ", Dumper \%ret;

    return \%ret;
}

# Prioritize locales that are most unlike the standard C/Latin1-ish ones.
# This is to minimize tests for a category passing because they share many of
# the same characteristics as the locale of another category simultaneously in
# effect.
sub sort_locales ()
{
    my $cmp = ($a->{codeset} eq 'utf8') <=> ($b->{codeset} eq 'utf8');
    #XXX return $cmp if $cmp;

    $cmp =  $a->{script_instance} <=> $b->{script_instance};
    return $cmp if $cmp;

    $cmp =  $a->{priority} <=> $b->{priority};
    return $cmp if $cmp;

    $cmp =  $a->{script} cmp $b->{script};
    return $cmp if $cmp;

    $cmp =  $a->{modifier} cmp $b->{modifier};
    return $cmp if $cmp;

    $cmp =  $a->{codeset} cmp $b->{codeset};
    return $cmp if $cmp;

    $cmp =  $a->{territory} cmp $b->{territory};
    return $cmp if $cmp;

    return lc $a cmp lc $b;
}

# Find out extra info about each locale, and sort into priority order.
foreach my $locale (@locales) {
    $locale = analyze_locale_name($locale);
}
@locales = sort sort_locales @locales;
print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@locales;

SKIP: { # perl #127708
    my $locale = $locales[0];
    skip("No valid locale to test with", 1) if $locale->{codeset} eq
                                                            $official_ascii_name;
    local $ENV{LC_MESSAGES} = $locale->{locale_name};

    # We're going to try with all possible error numbers on this platform
    my $error_count = keys(%!) + 1;

    print fresh_perl("
        use threads;
        use strict;
        use warnings;

        my \$errnum = 1;

        my \@threads = map +threads->create(sub {
            #usleep 0.1;
            'threads'->yield();

            for (1..5_000) {
                \$errnum = (\$errnum + 1) % $error_count;
                \$! = \$errnum;

                # no-op to trigger stringification
                next if \"\$!\" eq \"\";
            }
        }), (0..1);
        \$_->join for splice \@threads;",
    {}
    );

    pass("Didn't segfault");
}


my %locale_name_to_object;
for (my $i = 0; $i < @locales; $i++) {
    $locale_name_to_object{$locales[$i]->{locale_name}} = $locales[$i];
}
#print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%locale_name_to_object;

sub sort_by_hashed_locale {
    local $a = $locale_name_to_object{$a};
    local $b = $locale_name_to_object{$b};

    return sort_locales;
}

my $thread_count = 10;
#my $thread_count = $^O =~ /linux/i ? 50 : 10;
my $iterations = 1500;
#$iterations = 50 if $^O =~ /MSWin32/i;
my $max_result_length = 10000;

# Estimate as to how long in seconds to allow a thread to be ready to roll
# after creation, so as to try to get all the threads to start as
# simultaneously as possible
my $per_thread_startup = .02;
$per_thread_startup = .12;

# For use in experimentally tuning the above value
my $die_on_negative_sleep = 1; #1;

# We don't need to test every possible errno, but setting it to negative does
# so
my $max_message_catalog_entries = 10;

# December 18, 1987
my $strftime_args = "'%c', 0, 0, , 12, 18, 11, 87";

my %distincts;  # The distinct 'operation => result' cases
my %op_counts;  # So we can bail early if more test cases than threads
my $separator = '____';     # The operation and result are often melded into a
                            # string separated by this.

sub add_trials($$;$)
{
    # Add a test case for category $1.
    # $2 is the test case operation to perform
    # $3 is a constraint, optional.

    my $category_name = shift;
    #return if $category_name eq 'LC_CTYPE';
    #return unless $category_name ne 'LC_COLLATE';
    #return if $category_name eq 'LC_TIME';
    my $input_op = shift;                   # The eval string to perform
    my $locale_constraint = shift // "";    # If defined, the test will be
                                            # created only for locales that
                                            # match this
  LOCALE:
    foreach my $locale (@locales) {
        my $locale_name = $locale->{locale_name};
        my $op = $input_op;

        # All categories should be set to the same locale to make sure
        # this test gets the valid results.  If this platform doesn't have
        # LC_ALL, we instead set LC_CTYPE, then this category.
        next unless setlocale($LC_ALL, $locale_name);
        if ($LC_ALL_string ne 'LC_ALL') {
            next unless setlocale(eval "&POSIX::$category_name", $locale_name);
        }

        # Use a placeholder if this test requires a particular constraint,
        # which isn't met in this case.
        if ($locale_constraint) {
            die "Only accepted locale constraint is 'a<b'"
                                                if $locale_constraint ne 'a<b';
            # English should make this true; everything else uncertain, so for
            # those make this effectively a no-op
            $op = 'my $a = "a"; study $a' if $locale->{language} ne "en";
        }

        # Calculate what the expected value of the test should be.  We're
        # doing this here in the main thread and with all the locales set to
        # be the same thing.  The test will be that we should get this value
        # under stress, with each thread using different locales for each
        # category, and multiple threads executing with disparate locales
        # XXX op eq ""
        my $eval_string = ($op) ? "use locale; $op;" : "";
        my $result = eval $eval_string;
        #print STDERR "\n", __FILE__, ": ", __LINE__, ": $category_name: $locale_name: Op = ", Dumper($op), "\nReturned ", Dumper $result;
        die "$category_name: '$op': $@" if $@;
        if ($debug) {
        print STDERR __FILE__, ": ", __LINE__, ": Undefined result for $locale_name $category_name: '$op'\n" unless defined $result;
        }
        next unless defined $result;
        if (length $result > $max_result_length) {
            diag("For $locale_name, '$op', result is too long; skipped");
            next;
        }

        my ($which, $alternate);
        my @alternate;
        if (! $utf8_locales_ref || ! $utf8_locales_ref->@*) {
            @alternate = grep { $_ ne $locale_name } $non_utf8_locales_ref->@*;
        }
        elsif (! $non_utf8_locales_ref || ! $non_utf8_locales_ref->@*) {
            @alternate = grep { $_ ne $locale_name } $utf8_locales_ref->@*;
        }
        elsif (grep { $_ eq $locale_name } $utf8_locales_ref->@*) {
            @alternate = $non_utf8_locales_ref->@*;
        }
        else {
            @alternate = $utf8_locales_ref->@*;
        }
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@alternate;

        for (my $i = 1; $i < 5; $i++) {
            my $other = shift @alternate;
            push @alternate, $other;

            if (! setlocale($LC_ALL, $other)) {
                if (   $LC_ALL_string eq 'LC_ALL'
                    || ! setlocale(eval "&POSIX::$category_name", $other))
                {
                    die "Unexpectedly can't set locale to $other";
                }
            }

            my $got = eval $eval_string;

            if (! setlocale($LC_ALL, $locale_name)) {
                if (   $LC_ALL_string eq 'LC_ALL'
                    || ! setlocale(eval "&POSIX::$category_name", $locale_name))
                {
                    die "Unexpectedly can't set locale to $locale_name";
                }
            }

            $got = eval $eval_string;
            next if $got eq $result
                 && utf8::is_utf8($got) == utf8::is_utf8($result);

            diag("For '$eval_string',\nresults in iteration $i differed from"
               . " the original\ngot");
            Dump($got);
            diag("expected");
            Dump($result);
            next LOCALE;
        }

        push $distincts{$category_name}{"$op$separator$result"}{locales}->@*,
             $locale_name;

        # No point in looking at this if we already have all the tests we
        # need.  Note this assumes that the same op isn't used in two
        # categories.
        if ($op && defined $op_counts{$op} && $op_counts{$op} >= $thread_count) {
            print STDERR __FILE__, ": ", __LINE__, ": Now have enough tests for $op=$op_counts{$op}\n" if $debug;
            last ; #if defined $op_counts{$op} && $op_counts{$op} >= $thread_count;
        }
    }
}

SKIP: {
    skip("Unsafe locale threads", 1) unless ${^SAFE_LOCALES};

    # The second test is several threads nearly simulataneously executing
    # locale-sensitive operations with the categories set to disparate
    # locales.  This catches cases where the results of a given category is
    # related to what the locale is of another category.  (As an example, this
    # test showed that some platforms require LC_CTYPE to be the same as
    # LC_COLLATION, and/or LC_MESSAGES for proper results, so that Perl had to
    # change to bring these into congruence under the hood).  And it also
    # catches where there is interference between multiple threads.
    #
    # This test tries to exercise every underlying locale-dependent operation
    # available in Perl.  It doesn't test every use of the operation, but
    # includes some Perl construct that uses each.  For example, it tests lc
    # but not lcfirst.  That would be redundant for this test; it wants to
    # know if lowercasing works under threads and locales.  But if the
    # implementations were disjoint at the time this test was written, it
    # would try each implementation.  So, various things in the POSIX module
    # have separate tests from the ones in core.
    #
    # For each such underlying locale-dependent operation, a Perl-visible
    # construct is chosen that uses it.  And a typical input or set of inputs
    # is passed to that and the results are noted for every available locale
    # on the platform.  Many locales will have identical results, so the
    # duplicates are stored separately.
    #
    # There will be N simultaneous threads.  Each thread is configured to set
    # a locale for each category, to run operations whose results depend on
    # that locale, then check that the result matches the expected value, and
    # to immediately repeat some largish number of iterations.  The goal is to
    # see if the locales on each thread are truly independent of those on the
    # other threads.
    #
    # To that end, the locales are chosen so that the results differ from
    # every other locale.  Otherwise, the thread results wouldn't be truly
    # independent.  But if there are more threads than there are distinct
    # results, duplicates are used to fill up what would otherwise be empty
    # slots.  That is the best we can do on those platforms.
    #
    # Having lots of locales to continually switch between stresses things so
    # as to find potential segfaults where locale changing isn't really thread
    # safe.

    # Create a hash of the errnos:
    #          "1" => "Operation\\ not\\ permitted",
    #          "2" => "No\\ such\\ file\\ or\\ directory",
    #          etc.
    my %msg_catalog;
    foreach my $error (sort keys %!) {
        my $number = eval "Errno::$error";
        $! = $number;
        my $description = "$!";
        next unless "$description";
        $msg_catalog{$number} = quotemeta "$description";
    }
    #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%msg_catalog if $debug;

    # Then just the errnos.
    my @msg_catalog = sort { $a <=> $b } keys %msg_catalog;

    # Remove the excess ones.
    splice @msg_catalog, $max_message_catalog_entries
                                            if $max_message_catalog_entries >= 0;
    my $msg_catalog = join ',', @msg_catalog;

    # Create some tests that are too long to be convenient one-liners.  These
    # will be used in the loop below along with the one-liners.
    my $langinfo_LC_CTYPE = <<~EOT;
        use I18N::Langinfo qw(langinfo CODESET);
        no warnings 'uninitialized';
        langinfo(CODESET);
        EOT

    my $langinfo_LC_MESSAGES = <<~EOT;
        use I18N::Langinfo qw(langinfo YESSTR NOSTR YESEXPR NOEXPR);
        no warnings 'uninitialized';
        join ",",  map { langinfo(\$_) } YESSTR, NOSTR, YESEXPR, NOEXPR;
        EOT

    my $langinfo_LC_MONETARY = <<~EOT;
        use I18N::Langinfo qw(langinfo CRNCYSTR);
        no warnings 'uninitialized';
        join "|",  map { langinfo(\$_) } CRNCYSTR;
        EOT

    my $langinfo_LC_NUMERIC = <<~EOT;
        use I18N::Langinfo qw(langinfo RADIXCHAR THOUSEP);

        no warnings 'uninitialized';
        join "|",  map { langinfo(\$_) } RADIXCHAR, THOUSEP;
        EOT

    my $langinfo_LC_TIME = <<~EOT;
        use I18N::Langinfo qw(langinfo
                          ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5 ABDAY_6 ABDAY_7
                          ABMON_1 ABMON_2 ABMON_3 ABMON_4 ABMON_5 ABMON_6
                          ABMON_7 ABMON_8 ABMON_9 ABMON_10 ABMON_11 ABMON_12
                          DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7
                          MON_1 MON_2 MON_3 MON_4 MON_5 MON_6
                          MON_7 MON_8 MON_9 MON_10 MON_11 MON_12
                          D_FMT D_T_FMT T_FMT
                         );

        no warnings 'uninitialized';
        join "|",  map { langinfo(\$_) }
                         ABDAY_1,ABDAY_2,ABDAY_3,ABDAY_4,ABDAY_5,ABDAY_6,ABDAY_7,
                         ABMON_1,ABMON_2,ABMON_3,ABMON_4,ABMON_5,ABMON_6,
                         ABMON_7,ABMON_8,ABMON_9,ABMON_10,ABMON_11,ABMON_12,
                         DAY_1,DAY_2,DAY_3,DAY_4,DAY_5,DAY_6,DAY_7,
                         MON_1,MON_2,MON_3,MON_4,MON_5,MON_6,
                         MON_7,MON_8,MON_9,MON_10,MON_11,MON_12,
                         D_FMT,D_T_FMT,T_FMT;
        EOT

    my $case_insensitive_matching_test = <<~'EOT';
        no warnings "locale";
        my $uc = CORE::uc join "", map { chr } (0..255);
        my $fc = quotemeta CORE::fc $uc;
        $uc =~ / \A $fc \z /xi;
        EOT

    # Now go through and create tests for each locale category on the system.
    # These tests were determined by grepping through the code base for
    # locale-sensitive operations, and then figuring out something to exercise
    # them.
    my %map_category_name_to_number;
    foreach my $category (@valid_categories) {
        if ($category eq 'LC_ALL') {
            next;   #XXX we don't currently test this separately
        }

        #print STDERR __FILE__, ": ", __LINE__, ": $category\n" if $debug;
        my $cat_num = eval "&POSIX::$category";
        if ($@) {
            print STDERR "$@\n";
            return 0;
        }
        $map_category_name_to_number{$category} = $cat_num;

        if ($category eq 'LC_COLLATE') {
            add_trials('LC_COLLATE',
                       'quotemeta join "", sort reverse map { chr } (0..255)');

            # We pass an re to exclude testing locales that don't necessarily
            # have a lt b.
            #add_trials('LC_COLLATE', '"a" lt "B"', 'a<b');
            #add_trials('LC_COLLATE',    'my $a = "a"; my $b = "B";'
            #                          . ' POSIX::strcoll($a, $b) < 0;',
            #                       'a<b');

            # XXX not NUL
            add_trials('LC_COLLATE', 'my $string = quotemeta join "",'
                                   . ' map { chr } (1..255);'
                                   . ' POSIX::strxfrm($string)');
            next;
        }

        if ($category eq 'LC_CTYPE') {
            add_trials('LC_CTYPE', 'no warnings "locale"; quotemeta lc'
                                 . ' join "" , map { chr } (0..255)');
            add_trials('LC_CTYPE', 'no warnings "locale"; quotemeta uc'
                                 . ' join "", map { chr } (0..255)');
            add_trials('LC_CTYPE', 'no warnings "locale"; quotemeta CORE::fc'
                                 . ' join "", map { chr } (0..255)');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                                 . ' my $string = join "", map { chr } 0..255;'
                                 . ' $string =~ s|(.)|$1=~/\d/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                                 . ' my $string = join "", map { chr } 0..255;'
                                 . ' $string =~ s|(.)|$1=~/\s/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                                 . ' my $string = join "", map { chr } 0..255;'
                                 . ' $string =~ s|(.)|$1=~/\w/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:alpha:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:alnum:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:ascii:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:blank:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:cntrl:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:graph:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:lower:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:print:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:punct:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                               . ' my $string = join "", map { chr } 0..255;'
                               . ' $string =~ s|(.)|$1=~/[[:upper:]]/?1:0|gers');
            add_trials('LC_CTYPE', 'no warnings "locale";'
                              . ' my $string = join "", map { chr } 0..255;'
                              . ' $string =~ s|(.)|$1=~/[[:xdigit:]]/?1:0|gers');
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_CTYPE', $langinfo_LC_CTYPE);  # unless $debug;;
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_CTYPE', 'my $string = chr 0x100;'
                                 . ' utf8::encode($string);'
                                 . ' POSIX::mblen($string)');
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_CTYPE', 'my $value; my $str = "\x{100}";'
                                 . ' utf8::encode($str);'
                                 . ' POSIX::mbtowc($value, $str); $value;');
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_CTYPE', 'my $value; POSIX::wctomb($value, 0xFF);'
                                 . ' $value;');
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_CTYPE', $case_insensitive_matching_test);
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            next;
        }

        if ($category eq 'LC_MESSAGES') {
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_MESSAGES',
                       "join \"\n\", map { \$! = \$_; \"\$!\" } ($msg_catalog)");
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_MESSAGES', $langinfo_LC_MESSAGES);
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            next;
        }

        if ($category eq 'LC_MONETARY') {
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            #add_trials('LC_MONETARY', "localeconv()->{currency_symbol}") unless $^O =~ /MSWin32/i;
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_MONETARY', $langinfo_LC_MONETARY);
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            next;
        }

        if ($category eq 'LC_NUMERIC') {
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            #add_trials('LC_NUMERIC', "no warnings; 'uninitialised'; join '|',"
            #                       . " localeconv()->{decimal_point},"
            #                       . " localeconv()->{thousands_sep}");
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_NUMERIC', $langinfo_LC_NUMERIC);
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;

            # Use a variable to avoid runtime bugs being hidden by constant
            # folding
            add_trials('LC_NUMERIC', 'my $in = 4.2; sprintf("%g", $in)');
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            next;
        }

        if ($category eq 'LC_TIME') {
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_TIME', "POSIX::strftime($strftime_args)");
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            add_trials('LC_TIME', $langinfo_LC_TIME);
            print STDERR __FILE__, ": ", __LINE__, ": Got here\n" if $debug;
            next;
        }
    } # End of creating test cases.

    print STDERR __FILE__, __LINE__, ": ", Dumper \%distincts ;#if $debug;

    # Now analyze the test cases
    my %all_tests;
    foreach my $category (keys %distincts) {
        #print STDERR __FILE__, ": ", __LINE__, ": $category: ", scalar keys $distincts{$category}->%*, " operations\n";
        my %results;
        my %distinct_results_count;

        # Find just the distinct test operations; sort for repeatibility
        my %distinct_ops;
        for my $op_result (sort keys $distincts{$category}->%*) {
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $op_result;
            my ($op, $result) = split $separator, $op_result;
            $distinct_ops{$op}++;
            push $results{$op}->@*, $result;
            $distinct_results_count{$result} += scalar $distincts{$category}{$op_result}{locales}->@*;
        }

        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%distinct_ops;
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%results;
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%distinct_results_count;

        # And get a sorted list of all the test operations
        my @ops = sort keys %distinct_ops;
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@ops;

        sub gen_combinations {

            # Generate all the non-empty combinations of operations and
            # results (for the current category) possible on this platform.
            # That is, if a category has N operations, it will generate a list
            # of entries.  Each entry will itself have N elements, one for
            # each operation, and when all the entries are considered
            # together, every possible outcome is represented.

            my $op_ref = shift;         # Reference to list of operations
            my $results_ref = shift;    # Reference to hash; key is operation;
                                        # value is an array of all possible
                                        # outcomes of this operation.
            my $distincts_ref = shift;  # Reference to %distincts of this
                                        # category
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $op_ref, $results_ref, $distincts_ref;

            # Get the first operation on the list
            my $op = shift $op_ref->@*;
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $op;

            # The return starts out as a list of hashes of all possible
            # outcomes for executing 'op'.  Each hash has two keys:
            #   'op_results' is an array of one element: 'op => result',
            #                packed into a string.
            #   'locales'    is an array of all the locales which have the
            #                same result for 'op'
            my @return;
            foreach my $result ($results_ref->{$op}->@*) {
                my $op_result = $op . $separator . $result;
                push @return, {
                            op_results => [ $op_result ],
                            locales    => $distincts_ref->{$op_result}{locales},
                          };
            }

            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@return;
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $op_ref;

            # If this is the final element of the list, we are done.
            return (\@return) unless $op_ref->@*;

            # Otherwise recurse to generate the combinations for the remainder
            # of the list.
            my $recurse_return = &gen_combinations($op_ref,
                                                   $results_ref,
                                                   $distincts_ref);
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $recurse_return;
            # Now we have to generate the combinations of the current item
            # with the ones returned by the recusrion.  Each element of the
            # current item is combined with each element of the recursed.
            my @combined;
            foreach my $this (@return) {
                #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $this;
                my @this_locales = $this->{locales}->@*;
                foreach my $recursed ($recurse_return->@*) {
                    #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $recursed;
                    my @recursed_locales = $recursed->{locales}->@*;

                    # @this_locales is a list of locales this op => result is
                    # valid for.  @recursed_locales is similarly a list of the
                    # valid ones for the recursed return.  Their intersection
                    # is a list of the locales valid for this combination.
                    #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@this_locales, \@recursed_locales;
                    my %seen;
                    $seen{$_}++ foreach @this_locales, @recursed_locales;
                    my @intersection = grep $seen{$_} == 2, keys %seen;

                    # An alternative intersection algorithm:
                    # my (%set1, %set2);
                    # @set1{@list1} = ();
                    # @set2{@list2} = ();
                    # my @intersection = grep exists $set1{$_}, keys %set2;
                    #print STDERR __FILE__, ": ", __LINE__, ": Empty intersection: ", Dumper \@this_locales, \@recursed_locales unless @intersection;

                    # If the intersection is empty, this combination can't
                    # actually happen on this platform.
                    next unless @intersection;
                    #print STDERR __FILE__, ": ", __LINE__, ": intersection: ", Dumper \@intersection;

                    #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $recursed->{op_results};
                    #print STDERR __FILE__, ": ", __LINE__, ": ", ref $recursed->{op_results}, "\n";
                    # Append the recursed list to the current list to form the
                    # combined list.
                    my @combined_result = $this->{op_results}->@*;
                    push @combined_result, $recursed->{op_results}->@*;
                    #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@combined_result;
                    # And create the hash for the combined result, including
                    # the locales it is valid for
                    push @combined, {
                                      op_results => \@combined_result,
                                      locales    => \@intersection,
                                    };
                    #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@combined;
                }
            }

            return \@combined;
        } # End of gen_combinations() definition

        # The result of calling gen_combinations() will be an array of hashes.
        #
        # The main value in each hash is an array (whose key is 'op_results')
        # containing all the tests for this category for a thread.  If there
        # were N calls to 'add_trial' for this category, there will be 'N'
        # elements in the array.  Each element is a string consisting of the
        # operation to eval in a thread, followed by $separator followed by
        # the operation's expected result.
        #
        # The other data structure in each hash is an array with the key
        # 'locales'.  That array is a list of every locale which yields the
        # identical results in 'op_results'.
        #
        # Effectively, each hash gives all the tests for this category for a
        # thread.  The total array of hashes gives the complete list of
        # distinct tests possible on this system.  So later, a thread will
        # pluck the next available one from the array..
        my $combinations_ref = gen_combinations(\@ops, \%results,
                                                $distincts{$category});
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $combinations_ref;

        # Fix up the entries ...
        foreach my $test ($combinations_ref->@*) {

            # Sort the locale names; this makes it work for later comparisons
            # to look at just the first element of each list.
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $test->{locales};
            $test->{locales}->@* =
                                sort sort_by_hashed_locale $test->{locales}->@*;
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $test->{locales};

            # And for each test, calculate and store how many locales have the
            # same result (saves recomputation later in a sort).  This adds
            # another data structure to each hash in the main array.
            my @individual_tests = $test->{op_results}->@*;
            my @in_common_locale_counts;
            foreach my $this_test (@individual_tests) {

                # Each test came from %distincts, and there we have stored the
                # list of all locales that yield the same result
                push @in_common_locale_counts,
                        scalar $distincts{$category}{$this_test}{locales}->@*;
                #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $distincts{$category}{$this_test};
            }
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@in_common_locale_counts;
            push $test->{in_common_locale_counts}->@*, @in_common_locale_counts;
        }
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $combinations_ref;

        # Make a copy
        my @cat_tests = $combinations_ref->@*;

        # This sorts the test cases so that the ones with the least overlap
        # with other cases are first.
        sub sort_test_order {
            #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper $a, $b;
            my $a_tests_count = scalar $a->{in_common_locale_counts}->@*;
            my $b_tests_count = scalar $b->{in_common_locale_counts}->@*;
            my $tests_count = ($a_tests_count <= $b_tests_count)
                              ? $a_tests_count
                              : $b_tests_count;
            #print STDERR __FILE__, ": ", __LINE__, ": tests count: ", $tests_count, "\n";

            # Choose the one that is most distinctive (least overlap); that is
            # the one that has the most tests whose results are not shared by
            # any other locale.
            my $a_nondistincts = 0;
            my $b_nondistincts = 0;
            for (my $i = 0; $i < $tests_count; $i++) {
                $a_nondistincts += ($a->{in_common_locale_counts}[$i] != 1);
                $b_nondistincts += ($b->{in_common_locale_counts}[$i] != 1);
            }
            #print STDERR __FILE__, ": ", __LINE__, ": $a_nondistincts, $b_nondistincts\n";

            my $cmp = $a_nondistincts <=> $b_nondistincts;
            return $cmp if $cmp;

            # If they have the same number of those, choose the one with the
            # fewest total number of locales that have the same result
            my $a_count = 0;
            my $b_count = 0;
            for (my $i = 0; $i < $tests_count; $i++) {
                $a_count += $a->{in_common_locale_counts}[$i];
                $b_count += $b->{in_common_locale_counts}[$i];
            }
            #print STDERR __FILE__, ": ", __LINE__, ": $a_count, $b_count\n";

            $cmp = $a_count <=> $b_count;
            return $cmp if $cmp;

            # If that still doesn't yield a winner, use the general sort order.
            local $a = $a->{locales}[0];
            local $b = $b->{locales}[0];
            return sort_by_hashed_locale;
        }

        # Actually perform the sort.
        @cat_tests = sort sort_test_order @cat_tests;
        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \@cat_tests;

        # This category will now have all the distinct tests possible for it
        # on this platform, with the first test being the one with the least
        # overlap with other test cases
        push $all_tests{$category}->@*, @cat_tests;
    }     # End of loop through the categories creating an sorting the test
          # cases
    print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%all_tests;

    # Now generate the tests for each thread.
    my @tests_by_thread;
    for my $i (0 .. $thread_count - 1) {

        # Avoid using the same locale twice in different categories in a
        # single thread
        my @thread_already_used_locales;

        #print STDERR __FILE__, ": ", __LINE__, ": using all_tests, thread=$i\n";
        foreach my $category (sort keys %all_tests) {
            #print STDERR __FILE__, ": ", __LINE__, ": thread $i, $category\n";
            #print STDERR __FILE__, ": ", __LINE__, ": $category count is ", scalar ($all_tests{$category}->@*) if $all_tests{$category};
            #print STDERR ", first name=$all_tests{$category}[0]->{locales}[0]\n" if $all_tests{$category}; #[0]->{locale_name}\n";
            my $skipped = 0;    # Used below to not loop infinitely

            # Get the next test case
          NEXT_CANDIDATE:
            my $candidate = shift $all_tests{$category}->@*;
            #print STDERR __FILE__, ": ", __LINE__, ": current= ", Dumper $candidate;

            my $locale_name = $candidate->{locales}[0];

            # Avoid, if possible, using the same locale name twice (for
            # different categories) in the same thread.
            if (grep { $locale_name eq $_ } @thread_already_used_locales) {
                #print STDERR __FILE__, ": ", __LINE__, ": ", "Already used $locale_name\n";
                # Look through the synonyms of this locale for an
                # as-yet-unused one
                for (my $j = 1; $j < $candidate->{locales}->@*; $j++) {
                    my $synonym = $candidate->{locales}[$j];
                    next if grep { $synonym eq $_ } @thread_already_used_locales;

                    $locale_name = $synonym;
                    #print STDERR __FILE__, ": ", __LINE__, ": ", "Found synonym $locale_name\n";
                    goto found_synonym;
                }

                # Here, no synonym was found.  If we haven't cycled through
                # all the possible tests, try another (putting this one at the
                # end as a last resort in the future).
                $skipped++;
                if ($skipped < scalar $all_tests{$category}->@*) {
                    push $all_tests{$category}->@*, $candidate;
                    goto NEXT_CANDIDATE;
                }

                # Here no synonym was found, this test has already been used,
                # but there are no unused ones, so have to re-use it.

                #print STDERR __FILE__, ": ", __LINE__, ": $locale_name: ", Dumper $candidate;
              found_synonym:
            }

            # Here, we have found a test case.  The thread needs to know what
            # locale to use,
            $tests_by_thread[$i]->{$category}{locale_name} = $locale_name;

            # And it needs to know each test to run, and the expected result.
            my @cases;
            for (my $j = 0; $j < scalar $candidate->{op_results}->@*; $j++) {
                my ($op, $result) = split $separator,   # Unpack these.
                                          $candidate->{op_results}[$j];
                push @cases, { op => $op, expected => $result };
            }
            push $tests_by_thread[$i]->{$category}{locale_tests}->@*, @cases;

            # Done with this category in this thread.  Setup for subsequent
            # categories in this thread, and subsequent threads.
            #
            # It's best to not have two categories in a thread use the same
            # locale.  Save this locale name so that later iterations handling
            # other categories can avoid using it, if possible.
            push @thread_already_used_locales, $locale_name;

            # In pursuit of using as many different locales as possible, the
            # first shall be last in line next time, and eventually the last
            # shall be first
            push $candidate->{locales}->@*, shift $candidate->{locales}->@*;

            # Similarly, this test case is added back at the end of the list,
            # so will be used only as a last resort in the next thread, and as
            # the penultimate resort in the thread following that, etc. as the
            # test cases are cycled through.
            push $all_tests{$category}->@*, $candidate;
        } # End of looping through the categories for this thread
        #print STDERR __FILE__, ": ", __LINE__, ": end of this thread\n";

        #print STDERR __FILE__, ": ", __LINE__, ": ", Dumper \%all_tests;
    } # End of generating all threads

    #print STDERR __FILE__, ': ', __LINE__, ': ', Dumper \@tests_by_thread;

    my @cooked_tests;
    for (my $i = 0; $i < @tests_by_thread; $i++) {
        #print STDERR __FILE__, ': ', __LINE__, ': ', $i, ': ', Dumper \$tests_by_thread[$i];

        my $this_thread_tests = $tests_by_thread[$i];
        my @this_thread_cooked_tests;
        my %categories_locales;
        foreach my $category_name (keys $this_thread_tests->%*) {
            my $category_number = $map_category_name_to_number{$category_name};
            $categories_locales{$category_number} =
                                    $this_thread_tests->{$category_name}{locale_name};
        }

        while (keys $this_thread_tests->%*) {
            foreach my $category_name (sort keys $this_thread_tests->%*) {
                my $this_category_tests = $this_thread_tests->{$category_name};
                my $test = shift
                                $this_category_tests->{locale_tests}->@*;
                #print STDERR __FILE__, ': ', __LINE__, ': ', Dumper $test;
                if (! $test) {
                    delete $this_thread_tests->{$category_name};
                    next;
                }

                $test->{category_name} = $category_name;
                $test->{locale_name} = $this_category_tests->{locale_name};

                push @this_thread_cooked_tests, $test;
            }
        }

        push @cooked_tests, {
                              categories_locales => \%categories_locales,
                              tests => \@this_thread_cooked_tests,
                            };
    }

    my $tests_expanded = Data::Dumper->Dump([ \@cooked_tests ], [ 'all_tests_ref' ]);
    print STDERR __FILE__, ": ", __LINE__, ": ", $tests_expanded;

    my $starting_time = sprintf "%.16e", (    time() + 1     # overhead insurance
                                                     + (  $thread_count
                                                        * $per_thread_startup))
                                           * 1_000_000;
    my $switches = "";
    #$switches = "switches => [ -DLv ]" ;#if $^O =~ /MSWin32/i;; # if $debug;


    # See if multiple threads can simultaneously change the locale, and give
    # the expected radix results.  On systems without a comma radix locale,
    # run this anyway skipping the use of that, to verify that we dont
    # segfault
    fresh_perl_is("
        use threads;
        use strict;
        use warnings;
        use POSIX qw(locale_h);
        use utf8;
        use Time::HiRes qw(time usleep);
        use Data::Dumper;
        \$Data::Dumper::Sortkeys=1;
        \$Data::Dumper::Useqq = 1;
        \$Data::Dumper::Deepcopy = 1;

        sub iterate {       # Run some iterations of the tests
            my (\$initial_iteration,    # The number of the first iteration
                \$count,                # How many
                \$tests_ref,            # The tests
                \$corrects_ref)         # What is correct so far
             = \@_;

            my \$iteration = \$initial_iteration;
            \$count += \$initial_iteration;
            #print STDERR __FILE__, ': ', __LINE__, ': ', Dumper \$tests_ref;
            #print STDERR __FILE__, ': ', __LINE__, ': ', Dumper \$corrects_ref;

            # Repeatedly ...
            while (\$iteration < \$count) {
                my \$errors = 0;

                use locale;

                # ... execute the tests
                foreach my \$test (\$tests_ref->@*) {

                    # We know what we are expecting
                    my \$expected = \$test->{expected};

                    #print STDERR __FILE__, ': ', __LINE__, ': ', threads->tid, ': ', \$iteration, ': ', Dumper \$test;

                    # And do the test.
                    my \$got = eval \$test->{op};

                    my \$category_name = \$test->{category_name};

                    # Then verify it is the expected value
                    if (defined \$got && \$got eq \$expected) {
                        no warnings 'uninitialized';
                        \$corrects_ref->{\$category_name}++;
                    }
                    else {
                        no locale;
                        use Devel::Peek;
                        \$|=1;
                        \$errors++;
                        print STDERR \"\\nthread \", threads->tid(),
                                     \" failed in iteration \$iteration\",
                                     \" for locale \$test->{locale_name}\",
                                     \" \$category_name\",
                                     \" op='\$test->{op}'\",
                                     \" after getting\",
                                     \" \$corrects_ref->{\$category_name}\",
                                     \" previous corrects\n\";
                        if (\$got eq \$expected) {
                            print STDERR \"Only difference is UTF8ness\",
                                         \" of results\\n\";
                        }
                        print STDERR \"expected\";
                        if (utf8::is_utf8(\$expected)) {
                            print STDERR \" (already was UTF-8)\";
                        }
                        else {
                            utf8::upgrade(\$expected);
                            print STDERR \" (converted to UTF-8)\";
                        }
                        print STDERR \":\\n\";
                        Dump \$expected;

                        print STDERR \"\\ngot\";
                        if (! defined \$got) {
                            print STDERR \":\\n(undef)\\n\";
                        }
                        else {
                            if (utf8::is_utf8(\$got)) {
                                print STDERR \" (already was UTF-8)\";
                            }
                            else {
                                utf8::upgrade(\$got);
                                print STDERR \" (converted to UTF-8)\";
                            }
                            print STDERR \":\\n\";
                            Dump \$got;
                        }
                    }
                } # Loop to do the remaining categories for this iteration

                return 0 if \$errors;

                \$iteration++;

                #study if \$iteration % 10 == 0;

                threads->yield();
            }

            return 1;
        } # End of iterate() definition

        sub setup {
            \$|=1;
            \$SIG{'KILL'} = sub { threads->exit(); };
        
            # Sleep until the time when all the threads are due to wake up, so
            # they run as simultaneously as we can make it.
            my \$sleep_time = $starting_time - time() * 1_000_000;
            #printf STDERR \"thread %d started, sleeping %g sec\\n\", threads->tid, \$sleep_time / 1_000_000;
            if (\$sleep_time < 0) {
                if ($die_on_negative_sleep) {
                    printf STDERR '\\\$per_thread_startup would need to be '
                                . \"%g for thread %d to have slept\n\",
                                  (-\$sleep_time / $thread_count / 1_000_000),
                                  threads->tid;
                    return;
                }
            }
            else {
                usleep(\$sleep_time) if \$sleep_time > 0;
                threads->yield();
            }

            #print STDERR 'thread ', threads->tid, \" taking off\\n\";

            my \$i = shift;     # Thread id

            my $tests_expanded;

            # Tests and locale settings for just this thread
            my \$thread_tests_ref = \$all_tests_ref->[\$i];

            # Each thread should have been set up so all its tests for a given
            # category are from the same locale.  Set each category's locale
            #print STDERR __FILE__, ': ', __LINE__, ': ', Dumper \$thread_tests_ref;
            # Set the locale for each category for this thread
            my \$categories_locales_ref = 
                                       \$thread_tests_ref->{categories_locales};
            foreach my \$category_number (sort keys \$categories_locales_ref->%*)
            {
                my \$locale = \$categories_locales_ref->{\$category_number};
                if (! setlocale(\$category_number, \$locale)) {
                    print STDERR \"\\nthread \", threads->tid(),
                            \" setlocale(\$category_number, \$locale) failed\";
                    return 0;
                }
            }

            # Finished setup. return the tests data structure for this thread
            return \$thread_tests_ref->{tests};

        } # End of setup() definition

        # Create all the threads: 1..n
        my \@threads = map +threads->create(sub {

            # We just set up and run all the iterations
            my \%corrects = ();
            my \$tests_ref = setup(shift);

            return unless defined \$tests_ref;
            return iterate(1, $iterations, \$tests_ref, \\\%corrects);

        }, \$_), (1..$thread_count - 1);

        # Here is thread 0.  We do a smaller chunk of iterations in it; then
        # join whatever threads have finished so far, then do another chunk.
        # This tests for bugs that arise as a result of joining.

        my \$thread0_tests_ref = setup(0);

        # If we didn't set up thread 0 properly, it is a serious problem that
        # we should abort testing for.  Kill everything else and quit.
        if (! ref \$thread0_tests_ref) {
            \$_->kill('KILL')->detach() for threads->list();
            print 0;
            exit;
        }

        my \%thread0_corrects = ();
        my \$result = 1;    # So far, everything is ok
        my \$iteration_chunk = $iterations / 10 || 1;
        my \$this_iteration_start = 1;

        do {

            # If everything is ok so far, do another chunk of iterations on
            # this thread 0.
            if (\$result) {
                \$result &= iterate(\$this_iteration_start,
                                    \$iteration_chunk,
                                    \$thread0_tests_ref,
                                    \\\%thread0_corrects);
                \$this_iteration_start += \$iteration_chunk;
            }

            # After this chunk, join anything already finished.
            for my \$thread (threads->list(threads::joinable)) {
                my \$thread_result = \$thread->join;

                # If the thread failed badly, stop testing anything else.
                if (! defined \$thread_result) {
                    \$_->kill('KILL')->detach() for threads->list();
                    print 0;
                    exit;
                }

                # Update the running status
                \$result &= \$thread_result;

                # Let the other threads run
                threads->yield();
            }

          # And repeat as long as there are other tests
        } while (threads->list(threads::running));

        # Here, everything is done; make sure it all gets cleaned up
        \$result &= \$_->join for threads->list(threads::joinable);

        # And do a final chunk on thread 0 to verify that it still is working
        # after everything has joined.
        \$result &= iterate(\$this_iteration_start,
                            \$iteration_chunk,
                            \$thread0_tests_ref,
                            \\\%thread0_corrects);
        print \$result",
        1,
        { eval $switches },
        "Verify there were no failures with simultaneous running threads"
    );
}
