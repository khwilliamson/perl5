#!perl

use 5.008001;
# XXX broken

use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval { require Socket }) {
        plan skip_all => "no Socket";
    }
    elsif (ord('A') == 193 && $] lt "5.008") {
        plan skip_all => "EBCDIC needs at least v5.8";
    }
    else {
        plan tests => 54;
    }
}

BEGIN {
  package Foo;

  use IO::File;
  use Net::Cmd;
  our @ISA = qw(Net::Cmd IO::File);

  sub timeout { 0 }

  sub new {
    my $fh = shift->new_tmpfile;
    binmode($fh);
    $fh;
  }

  sub output {
    my $self = shift;
    seek($self,0,0);
    local $/ = undef;
    scalar(<$self>);
  }

  sub response {
    return Net::Cmd::CMD_OK;
  }
}

sub check {
  my $expect = pop;
  my $cmd = Foo->new;
  ok($cmd->datasend, 'datasend') unless @_;
  foreach my $line (@_) {
    ok($cmd->datasend($line), 'datasend');
  }
  ok($cmd->dataend, 'dataend');
  is(
    unpack("H*",$cmd->output),
    unpack("H*",$expect)
  );
}

my $cr = "\015";
my $lf = "\012";
my $cmd;

check(
  # nothing

  ".${cr}${lf}"
);

check(
  "a",

  "a${cr}${lf}.${cr}${lf}",
);

check(
  "a\r",

  "a${cr}${cr}${lf}.${cr}${lf}",
);

check(
  "a\rb",

  "a${cr}b${cr}${lf}.${cr}${lf}",
);

check(
  "a\rb\n",

  "a${cr}b${cr}${lf}.${cr}${lf}",
);

check(
  "a\rb\n\n",

  "a${cr}b${cr}${lf}${cr}${lf}.${cr}${lf}",
);

check(
  "a\r",
  "\nb",

  "a${cr}${lf}b${cr}${lf}.${cr}${lf}",
);

check(
  "a\r",
  "\nb\n",

  "a${cr}${lf}b${cr}${lf}.${cr}${lf}",
);

check(
  "a\r",
  "\nb\r\n",

  "a${cr}${lf}b${cr}${lf}.${cr}${lf}",
);

check(
  "a\r",
  "\nb\r\n\n",

  "a${cr}${lf}b${cr}${lf}${cr}${lf}.${cr}${lf}",
);

check(
  "a\n.b\n",

  "a${cr}${lf}..b${cr}${lf}.${cr}${lf}",
);

check(
  ".a\n.b\n",

  "..a${cr}${lf}..b${cr}${lf}.${cr}${lf}",
);

check(
  ".a\n",
  ".b\n",

  "..a${cr}${lf}..b${cr}${lf}.${cr}${lf}",
);

check(
  ".a",
  ".b\n",

  "..a.b${cr}${lf}.${cr}${lf}",
);

check(
  "a\n.",

  "a${cr}${lf}..${cr}${lf}.${cr}${lf}",
);

# Test that datasend() plays nicely with bytes in an upgraded string,
# even though the input should really be encode()d already.
check(
  substr("\x{100}", 0, 0) . "\x{e9}",

  "\x{e9}${cr}${lf}.${cr}${lf}"
);
