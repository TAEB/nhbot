use IO::Socket;
use Telnet;

$| = 1; #autoflush output so logfiles are updated immediately

my $sock;
my ($logdebug, $logoutput, $loginput);

sub open_logs($$$)
{
  ($logdebug, $logoutput, $loginput) = @_;
  open (DEBUGLOG, ">logs/debug.log")  if $logdebug;
  open (OUTLOG,   ">logs/output.log") if $logoutput;
  open (INLOG,    ">logs/input.log")  if $loginput;
}

sub close_logs()
{
  close DEBUGLOG if $logdebug;
  close OUTLOG   if $logoutput;
  close INLOG    if $loginput;
}

sub timestamp()
{
  my $ret = "[".scalar(localtime)."] ";
  $ret =~ s/([A-Z][a-z][a-z] [A-Z][a-z][a-z] \d\d) (\d\d:\d\d:\d\d)/$2 $1/;
  return $ret;
}

sub debug($)
{
  return unless $logdebug;
  my $line = shift;
  $line = timestamp() . $line . "\n";
  print DEBUGLOG $line;
  print STDOUT $line;
}

sub out($)
{
  my $line = shift;
  print $sock $line;
  return unless $logoutput;
  $line =~ s/\n//mg;
  #commented out the timestamp because it was making huge logs...
  $line = #timestamp() . 
          $line . "\n";
  print OUTLOG $line;
}

sub response()
{
  my ($buf, $ret, $timeout);
  my $recursion = shift;

  print $sock "\xFF\xFA\x05\x01\xFF\xF0"; #iac subnegotiation status send iac endsubnegotiation
  $timeout = 60 + time; #one minute is very generous..

  $ret = '';

  while (time < $timeout)
  {
    $ret .= $buf if recv($sock, $buf, 1024, 0);
    sleep 0.1;

    if ($ret =~ /\xFF\xFA\x05\x00.*?\xFF\xF0/) #iac subnegotiation status is .* iac endsubnegitiation
    {
      $ret = parse_telnet($ret);

      if ($ret =~ /--More--/)
      {
        print $sock "\n";
        $ret .= &response(++$recursion); #ampersand exists to bypass (W prototype)
      }

      $ret =~ s/--More--//g;
      #commented out the timestamp because it was making huge logs...
      print INLOG #timestamp . 
                  $ret . "\n" if ($recursion && $loginput);
      return $ret;
    }
  }

  die "timed out while waiting for pong";
}

sub create_sock()
{
  $sock = new IO::Socket::INET(PeerAddr => 'nethack.alt.org',
                               PeerPort => 23,
                               Proto => 'tcp');
  die "Could not create socket: $!\n" unless $sock;
  $sock->blocking(0);
  debug("Socket blocked and loaded. Let's negotiate.");

  initial_negotiations($sock);
}

sub close_sock()
{
  close $sock;
}

1;
