#!/usr/bin/perl -w
use strict;
use diagnostics;

use Comm;
use Brain;

# === configuration ===
my $logdebug  = 1;
my $logoutput = 1;
my $loginput  = 1;
#set user/pass in Telnet.pm
# === configuration ===

srand;
open_logs($logdebug, $logoutput, $loginput);
create_sock();
debug("Started up.");

think();

debug("Shutting down.");
close_sock();
close_logs();
