#!perl

use 5.008001;

use strict;
use warnings;

BEGIN {
    if (!eval { require Socket }) {
        print "1..0 # Skip: no Socket\n"; exit 0;
    }
    elsif (ord('A') == 193 && $] lt "5.008") {
        print "1..0 # Skip: EBCDIC needs at least v5.8";
    }
}

print "1..9\n";
my $i = 1;
eval { require Net::Config; } || print "not "; print "ok ",$i++,"\n";
eval { require Net::Domain; } || print "not "; print "ok ",$i++,"\n";
eval { require Net::Cmd; }    || print "not "; print "ok ",$i++,"\n";
eval { require Net::Netrc; }  || print "not "; print "ok ",$i++,"\n";
eval { require Net::FTP; }    || print "not "; print "ok ",$i++,"\n";
eval { require Net::SMTP; }   || print "not "; print "ok ",$i++,"\n";
eval { require Net::NNTP; }   || print "not "; print "ok ",$i++,"\n";
eval { require Net::POP3; }   || print "not "; print "ok ",$i++,"\n";
eval { require Net::Time; }   || print "not "; print "ok ",$i++,"\n";


