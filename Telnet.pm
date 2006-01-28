use Comm;

# === configuration ===
my $username = 'nhbot';
my $password = '';
# === configuration ===

my $IAC = 255;
my $TEXT = 0;
my $SB = 250;
my $SE = 240;
my $WILL = 251;
my $WONT = 252;
my $DO = 253;
my $DONT = 254;
my $SBIAC = 300; #outside of the normal range..
my $TTYPE = 24;
my $TSPEED = 32;
my $XDISPLOC = 35;
my $NEWENVIRON = 39;
my $IS = 0;
my $GOAHEAD = 3;
my $ECHO = 1;
my $NAWS = 31;
my $STATUS = 5;
my $RFC = 33;

my $sock;
my $telnetmode = $TEXT;
my $subbuf;

sub parse_telnet($)
{
  my $input = shift;
  my $ret = '';
  my $c;

  while ($input)
  {
    if ($telnetmode == $TEXT)
    {
      while ($input && $telnetmode == $TEXT)
      {
        $c = substr($input, 0, 1);

        if (ord($c) == $IAC)
        {
          $telnetmode = $IAC;
        }
        else
        {
          $ret .= $c;
        }
        $input = substr($input, 1);
      }
    }
    elsif ($telnetmode == $IAC)
    {
      while ($input && $telnetmode == $IAC)
      {
        $c = substr($input, 0, 1);

        if (ord($c) == $IAC)
        {
          $ret .= $c;
          $telnetmode = $TEXT;
        }
        elsif (ord($c) == $SB)
        {
          $telnetmode = $SB;
        }
        elsif (ord($c) == $DO)
        {
          $telnetmode = $DO;
        }
        elsif (ord($c) == $DONT)
        {
          $telnetmode = $DONT;
        }
        elsif (ord($c) == $WILL)
        {
          $telnetmode = $WILL;
        }
        elsif (ord($c) == $WONT)
        {
          $telnetmode = $WONT;
        }
        else
        {
          die 'unrecognized negotiation option "'.ord($c).'"';
        }
        $input = substr($input, 1);
      }
    }
    elsif ($telnetmode == $SB)
    {
      while ($input && $telnetmode == $SB)
      {
        $c = substr($input, 0, 1);

        if (ord($c) == $IAC)
        {
          $telnetmode = $SBIAC;
        }
        else
        {
          $subbuf .= $c;
        }
        $input = substr($input, 1);
      }
    }
    elsif ($telnetmode == $DO || $telnetmode == $WILL || $telnetmode == $DONT || $telnetmode == $WONT)
    {
      if ($input)
      {
        $c = substr($input, 0, 1);
        $input = substr($input, 1);

        if (ord($c) == $TTYPE)
        {
          printf $sock "%c%c%c", $IAC, $WILL, $TTYPE;
        }
        elsif (ord($c) == $TSPEED)
        {
          printf $sock "%c%c%c", $IAC, $WONT, $TSPEED;
        }
        elsif (ord($c) == $XDISPLOC)
        {
          printf $sock "%c%c%c", $IAC, $WILL, $XDISPLOC;
        }
        elsif (ord($c) == $NEWENVIRON)
        {
          printf $sock "%c%c%c", $IAC, $WILL, $NEWENVIRON;
        }
        elsif (ord($c) == $GOAHEAD)
        {
          printf $sock "%c%c%c", $IAC, $DO, $GOAHEAD;
        }
        elsif (ord($c) == $ECHO)
        {
          if ($telnetmode == $DO)
          {
            printf $sock "%c%c%c", $IAC, $WILL, $ECHO;
          }
          elsif ($telnetmode == $DONT)
          {
            printf $sock "%c%c%c", $IAC, $WONT, $ECHO;
          }
          else
          {
            printf $sock "%c%c%c", $IAC, $DO, $ECHO;
          }
        }
        elsif (ord($c) == $NAWS)
        {
          printf $sock "%c%c%c", $IAC, $WILL, $NAWS;
          printf $sock "%c%c%c%c%c%c%c%c%c", $IAC, $SB, $NAWS, 0, 80, 0, 24, $IAC, $SE;
        }
        elsif (ord($c) == $STATUS)
        {
          printf $sock "%c%c%c", $IAC, $DO, $STATUS;
        }
        elsif (ord($c) == $RFC)
        {
          printf $sock "%c%c%c", $IAC, $WILL, $RFC;
        }
        else
        {
          die 'unrecognized do/dont/will/wont mode requested/informed: '.ord($c)."\n";
        }

        $telnetmode = $TEXT;
      }
    }
    elsif ($telnetmode == $SBIAC)
    {
      if ($input)
      {
        $c = substr($input, 0, 1);
        $input = substr($input, 1);

        if (ord($c) == $IAC)
        {
          $subbuf .= $c;
          $telnetmode = $SB;
        }
        elsif (ord($c) == $SE)
        {
          $c = substr($subbuf, 0, 1);
          if (ord($c) == $TTYPE)
          {
            printf $sock "%c%c%c%cXTERM%c%c", $IAC, $SB, $TTYPE, $IS, $IAC, $SB;
          }
          elsif (ord($c) == $TSPEED)
          {
            printf $sock "%c%c%cc38400,38400%c%c", $IAC, $SB, $TSPEED, $IS, $IAC, $SB;
          }
          elsif (ord($c) == $NEWENVIRON)
          {
            printf $sock "%c%c%c%c%c%c", $IAC, $SB, $NEWENVIRON, $IS, $IAC, $SB;
          }
          elsif (ord($c) == $XDISPLOC)
          {
            printf $sock "%c%c%c%c%c%c", $IAC, $SB, $XDISPLOC, $IS, $IAC, $SB;
          }
          $telnetmode = $TEXT;
          $subbuf = '';
        }
        else
        {
          debug("unrecognized subrequest-iac byte: $c. clearing subbuf and returning to text\n");
          $telnetmode = $TEXT;
          $subbuf = '';
        }
      }
    }
    else
    {
      die "unrecognized mode $telnetmode";
    }
  }

  return $ret;
}

#does the login function belong in the telnet module? not at all.
#do I care right now? not at all.
sub login()
{
  #precondition: at the login screen, ready to log in.
  #postcondition: in game.

  my $response;
  debug("Logging in.");

  out("l"); #login
  $response = response();
  die "login failed, unable to input username" if $response !~ /Please enter your username/;
  out($username . "\n");
  debug("Username sent.");
  $response = response();
  die "login failed, unable to input password" if $response !~ /Please enter your password/;
  out($password . "\n");
  debug("Password sent.");

  $response = response();
  die "login failed, bad password?" if $response !~ /Logged in as: $username/;

  out("p");

  $response = response();
  if ($response =~ /Shall I pick a character's race, role, gender and alignment for you\?/)
  {
    debug("Creating a new valkyrie.");
    out("n");
    response();
    out("v");
    response();
    out("d");
  }
  else
  {
    debug("Seems we have a saved game.");
  }

  $logged_in = 1;
  debug("Now awaiting my loyal audience.");
  for (0..4)
  {
    debug(5-$_."...");
    sleep 1;
  }
}

sub initial_negotiations($)
{
  $sock = shift;
  my $buf = '';
  my $recv = '';
  my $timeout = 10 + time;

  while (time < $timeout)
  {
    next unless recv($sock, $recv, 1024, 0);
    $buf .= parse_telnet($recv);
    if ($buf =~ /l\) Login/)
    {
      $response = response(); # (BUG?) for some reason this is necessary.. ugh
      login();
      return 1;
    }

  }

  die "initial negotiations timed out";
}

1;
