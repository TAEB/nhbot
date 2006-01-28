use Comm;

my @attack_dir = (1, 2, 3, 4, 6, 7, 8, 9);

#argument:      string denoting what to attack (must be regex-friendly)
#return values: 0 if nothing was attacked, otherwise the direction swung
sub attack($)
{
  my $victim = shift;
  my ($response, $i, $dir);

  for($i = 0; $i < @attack_dir; ++$i) #check each direction
  {
    $dir = $attack_dir[$i];
    out(";".$dir.".");
    $response = response();
    next if ($response =~ /corpse/i); #don't want to fight a "corpse of a newt"
    if ($response =~ /\(.*$victim.*\)/i || 
        $response =~ /I +a remembered, unseen, creature/)
    {
      out("F".$dir);
      ($attack_dir[$i], $attack_dir[0]) = ($attack_dir[0], $attack_dir[$i]);
      return $dir;
    }
  }

  return 0;
}

sub attack_door()
{
  my ($response, $i);
  for ($i = 1; $i < 10; ++$i) #check each direction
  {
    next if $i == 5;

    out(";".$i.".");
    $response = response();
    if ($response =~ /\(closed door\)/i)
    {
      return negotiate_door($i);
    }
  }
  return 0;
}

sub negotiate_door($)
{
  my $dir = shift;
  my $attempts = 0;
  my $response;

  # try opening it
  while ($attempts++ < 10)
  {
    out("o".$dir);
    $response = response();

    return 1 if $response =~ /The door opens\./;
    return 1 if $response =~ /This door is already open\./;
    next     if $response =~ /The door resists!/;
    last     if $response =~ /This door is locked\./;
    return -1; # something unexpected, let the Brain figure it out!
  }

  # Opening it failed; it must be locked. Notice how I don't reset $attempts...

  while ($attempts++ < 10)
  {
    out("k".$dir);
    $response = response();

    return 1 if $response =~ /As you kick the door, it (?:crashes open|shatters to pieces)!/;
    next     if $response =~ /WHAMMM!!!/;
    return -1; # something unexpected, let the Brain figure it out!
  }

  return 0;
}

1;
