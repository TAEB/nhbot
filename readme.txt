-----------------------------------[LICENSE]------------------------------------
nhbot is released under the MIT license. I'll get around to actually including 
the license in the code in a later revision.

---------------------------------[INSTALLATION]---------------------------------
1. Create an account on nethack.alt.org (or your server of choice). This is not
     mandatory but highly recommended.
2. Use the following options to ensure compatibility with the code. For
     example, many of the regular expressions expect menustyle:traditional
     output. Also, nhbot plays petless. He will ignore tame/peaceful monsters,
     but wants all the points and food to himself.
       http://alt.org/nethack/rcfiles/nhbot.nethackrc
3. Modify lines 4 and 5 of Telnet.pm. This is where you put in your username
     and password for NAO.
4. nhbot.pl has some additional configuration options (such as how much info
     should be logged). You can modify these if you wish. By default, it logs
     all input, output, and debug info (mainly what the bot thinks it is doing
     at the moment)

------------------------------------[RUNNING]-----------------------------------
Start the bot with `perl nhbot.pl` or `./nhbot.pl`.

---------------------------------[TROUBLESHOOTING]------------------------------
The main problem I expect people will have is actually getting the script to
connect to NAO. I used some hardcoded values in the telnet negotiation - I 
stopped messing with that chunk of code when it started working appreciably. For
what it's worth, nhbot was developed under Cygwin+rxvt, so I expect anyone 
using a similar setup will have no trouble getting it to work. Hopefully...

Talk to Eidolos on irc.freenode.org #nethack or mail me at sartak@gmail.com
about any issues you have.

----------------------------------[MISCELLANEOUS]-------------------------------
The only throttling nhbot does is in the response function. This gets all 
output from the server. The sequence is as follows. Steps B and C are where
all of the forced waiting is done. If B and C take longer than one minute the
script halts, because something wonky is happening with the connection.

1. Send off game-based input.
2. Call response.
     A. Send off a ping.
     B. Collect all game-based output.
     C. Collect a pong.
     D. Return with all game-based output.
3. React to output.

nhbot will:
  * Pick up only food that never rots. (though this part seems a little buggy)
  * Eat when Hungry.
  * Pray when Weak.
  * React appropriately in combat. (and I mean 'react' literally)
  * Open unlocked doors, kick down locked doors.
  * Dip for Excalibur.
  * Use #enhance.
  
nhbot will not:
  * Explore systematically.
  * Go up or down stairs.
  * Pray when hit with lycanthropy.
  * Pray when at low HP.
  * Use any scrolls, potions, wands, etc.
  * Pick up his sword or shield if lost (due to lycanthropy, a nymph, &c.)
  * Avoid dangerous things (floating eyes, magic traps, pools of water, &c.)


  
Have fun!
Shawn M Moore
