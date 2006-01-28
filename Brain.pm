use Comm;
use Combat;
use Fixself;
use Exercise;

my $logged_in = 0;
my $xplevel = 1;
my $dip_for_excal = 1;
my $angry_deity = 0;

sub think()
{
  my $response;

  while (1) # the program will die when the ping/pong fails anyway!
  {
    $response = response();

    if ($response =~ /Do you want your possessions identified\?/)
    {
      debug("We appear to be dead, Jim.");

      while (1)
      {
        out("\n");
        sleep 3;
      }

      last;
    }

    if ($response =~ /You (?:kill|destroy) (.*?)[.!]/)
    {
      debug("Killed $1.");
    }

    if ($response =~ /(\d+|a) gold (pieces?)\./)
    {
      debug("Picked up $1 gold $2.");
    }

    if ($response =~ /Welcome to experience level (\d+)\./)
    {
      $xplevel = $1;
      debug("Welcome to experience level $1.");
    }
    
    if ($response =~ /(.*?) is displeased\./)
    {
      $angry_deity = 1;
      debug("$1 is displeased. Aw crap.");
    }
    
    if ($response =~ /stomach feels content/)
    {
      debug("No longer hungry.");
    }

    if ($response =~ /Call a (.*?):/)
    {
      debug("What was that $1 again?");
      out ("\n");
      next;
    }
    
    if ($response =~ /Really attack .*? \[yn\] \(n\)/)
    {
      # nhbot shows much mercy
      out("n");
      next;
    }

    # note carefully the differences between the next two if statements.
    #   the first tries to pick up a single known item
    #   the second tries to pick up multiple unknown items
    # these two if statements are calling different functions!

    if ($response =~ /There is a fountain here\./ && $xplevel >= 5 && $dip_for_excal)
    {
      debug("Dipping for Excalibur, hey!");
      out("#dip\nay");
      $response = response();
      if ($response =~ /From the murky depths, a hand reaches up to bless the sword\./)
      {
        debug("Wow, we now have Excalibur. Rock on, San Francisco!");
        $dip_for_excal = 0;
      }
      next;
    }
    
    if ($response =~ /You see here (?:an?|[0-9]+) (?:blessed |uncursed |cursed )?(.*?)\./)
    {
      next if (pickup_safefood($1));
    }

    if ($response =~ /Things that are here:/ ||
        $response =~ /There are (?:several|many) (?:more )?objects here\./)
    {
      next if (pickup_safefoods());
    }

    if ($response =~ /You are beginning to feel hungry\./)
    {
      debug("We are hungry. Let's fix that.");
      if (fix_hungry())
      {
        debug("Success!");
      }
      else
      {
        debug("Looks like we failed.");
      }
      next;
    }

    if ($response =~ /Valkyrie needs food, badly!/)
    {
      if ($angry_deity)
      {
        debug("We are weak. Deity is angry. Oh well. Trying to eat...");
        if (fix_hungry())
        {
          debug("Success!");
        }
        else
        {
          debug("Looks like we failed.");
        }
        next;
      }
      
      debug("We are weak. Let's fix that.");
      fix_weak();
      next;
    }

    if ($response =~ /faint from lack of food/)
    {
      if ($angry_deity)
      {
        debug("We just fainted. Deity is angry. Oh well. Trying to eat...");
        if (fix_hungry())
        {
          debug("Success!");
        }
        else
        {
          debug("Looks like we failed.");
        }
        next;
      }

      debug("Uh oh. We just fainted. Try to fix...");
      fix_fainting();
      next;
    }

    if ($response =~ /You feel more confident/)
    {
      debug("Ahoy hoy, skill!");
      enhance();
      next;
    }

    if ($response =~ /you cannot escape from (?:(the |an? )?([-.a-z ]+?)|it)[.!]/i)
    {
      debug("Killing $2 so we can pull free.");
      attack($2);
      next;
    }

    if ($response =~ /you (?:just )?(?:hit|miss) (?:(?:the |an? )([-.a-z ]+?)|it)[.!]/i)
    {
      debug("Reattacking the $1.");
      attack($1);
      next;
    }

    if ($response =~ /(?:(?:the |an? )([-.a-z ]+?)|it) (?:just )?(?:hits|misses|bites|grabs|stings|touches)(?: you)?[.!]/i)
    {
      debug("Counterattacking the $1.");
      attack($1);
      next;
    }

    if ($response =~ /That door is closed\./)
    {
      if (attack_door())
      {
        debug("Door negotiated.");
        next;
      }
    }

    #heeellloooo random walk!
    my @movement = ( "1",  "2",  "3",  "4",  "6",  "7",  "8",  "9",
                    "51", "52", "53", "54", "56", "57", "58", "59",
                    "s", "_<.", "_>.", "_{.", "__.", "_{.:", "\n");
    my $movement = $movement[rand @movement];

    #let's lower the odds of getting the travel commands a little, except fountains (we want excal!)
    $movement = $movement[rand @movement] if ($movement =~ /^_[^{]/ || ((!$dip_for_excal || $xplevel < 5) && $movement =~ /^_/));

    out($movement);
  }
}

1;
