use Comm;

my @safefoods = ("lichen corpse", "lizard corpse", "food ration", "perl", 
                 "fortune cookie", "K-ration", "kelp frond", 
                 "eucalyptus lea(?:f|ves)", "apple", "orange", "pear", 
                 "melon", "banana", "carrot", "sprigs? of wolfsbane", 
                 "cloves? of garlic", "lumps? of royal jelly", "cream pie",
                 "candy bar", "fortune cookie", "pancake", "lembas wafer",
                 "cram ration", "C-ration");

sub pickup_safefood($)
{
  my $food = shift;
  my $response;
  foreach $safefood (@safefoods)
  {
    if ($food =~ /^(?:$safefood)s?$/)
    {
      out(",");
      $response = response();
      if ($response =~ /Pick up (?:an?|[0-9]+) (?:blessed |uncursed |cursed )?(.*?)s?\? \[yn#?aq\] \(y\)/)
      {
        out("y");
        $response = response();
      }
      if ($response =~ /([a-zA-Z]) - (.*?)\./)
      {
        debug("Picked up safe? food item: $2 [slot $1] matches /$safefood/");
      }
      return 1;
    }
  }
  return 0;
}

sub pickup_safefoods()
{
  my ($response, $food, $safefood, $safe);

  out(",");
  response();
  out("%\n");
  while (1)
  {
    $response = response();
    if ($response =~ /There are no %'s here\./)
    {
      out("q");
      last;
    }
    elsif ($response =~ /Pick up (?:an?|[0-9]+) (?:blessed |uncursed |cursed )?(.*?)s?\? \[yn#?aq\] \(y\)/)
    {
      $food = $1;
      $safe = 0;
      foreach $safefood (@safefoods)
      {
        if ($food =~ /^$safefood$/)
        {
          debug("Picking up $food, matches /$safefood/");
          out("y");
          $safe = $safefood;
          last;
        }
      }
      out("n") unless ($safe);
    }
    elsif ($response =~ /([a-zA-Z]) - (.*?)\./)
    {
      debug("Picked up safe? food item: $2 [slot $1] matches /$safe/");
    }
    else
    {
      last;
    }
  }
  return 0;
}

sub fix_hungry()
{
  my ($response, $food, $safe);

  out('e');

  while (1)
  {
    $response = response();
    return 0 if ($response =~ /You don't have anything to eat\./);
    if ($response =~ /What do you want to eat\? \[([a-zA-Z-])+ or /)
    {
      $food = $1;
      debug("Eating inventory item $food.");
      out($food);
      return 1;
    }
    elsif ($response =~ /There (?:is an?|are [0-9]+) (?:blessed |uncursed |cursed )?(.*?)(?:e?s)? here; eat (?:it|one)\?/)
    {
      $food = $1;
      foreach $safe (@safefoods)
      {
        if ($food =~ /$safe/)
        {
          debug("Eating floor item $food.");
          out('y');
          return 1;
        }
      }
      out('n');
    }
  }
  return 0;
}

sub fix_weak()
{
  my $response;

  return 1 if fix_hungry();
  # if fix_hungry fails, let's try some more drastic measures like prayer..

  out("#pray\n");
  return 1; #assume it worked for now..
}

sub fix_fainting()
{
  return fix_weak();
}

1;
