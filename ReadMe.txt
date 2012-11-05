WmDOT Read-me
v.4, r.52d, 2011-04-08
Copyright © 2011 by W. Minchin. For more info, please visit
    http://openttd-noai-wmdot.googlecode.com/

-- About WmDOT ----------------------------------------------------------------
WmDOT (short for "William's Department of Transportation") is an AI for
    OpenTTD, a freeware clone of Chris Saywer's Transport Tycoon Deluxe. Having
    fallen in love with the original, I was quite delighted to find the
    remake! Of the things that has been added to OpenTTD is custom AI's, of
    which this is one. For me, it's a way to back in touch with a game I fell
    in love with years ago and to bursh up on my programming skills at the same
    time.

-- Requirements ---------------------------------------------------------------
WmDOT required OpenTTD version 1.0 or better. This is available as a free
    download from OpenTTD.org
As dependances, WmDOT also requires:
    - SuperLib, v.6 ('SuperLib-6.tar')
    - Binary Heap, v.1 ('Queue.BinaryHeap-1.tar')

-- Installation ---------------------------------------------------------------
The easiest (and recommended) way to install WmDOT is use OpenTTD's 'Check
    Online Content' inferface. Search for 'WmDOT.' If you have not already
    installed the required libraries, OpenTTD will prompt you to download them
    at the same time. This also makes it very easy for me to provide updates.
Manual installation can be accomplished by putting the 'WmDOT.4.tar' file you
    downloaded in the  '..\OpenTTD\ai'  folder. If you are manually installing,
    the libraries mentioned above need to be in the '..\OpenTTD\ai\library'
    folder.

Once installed, WmDOT can be selected through 'AI Settings' on OpenTTD's main
    interface. Alternately, WmDOT can be launched manually in-game by bringing
    up the console (press the key to the right of the '1', usually the '~' key;
    press the same key to close the console) and typing 'start_ai wmdot'.

-- What WmDOT Does ------------------------------------------------------------
WmDOT is non-competitive. At the present time, it just builds out your highway
    network. It has no revenue source.
WmDOT starts by selecting a 'capital' and builds its Headquarters there. (If
    you run multiple instances of WmDOT, they should pick different towns as
    their respective capitals.) First, WmDOT connects the surrounding towns to
    the capital. Next it connects the towns further out to the existing
    network. Once all towns have been connected to the network, WmDOT looks for
    shorter cross connections to fill out the network.

-- Settings -------------------------------------------------------------------
Settings can be accessed by going to 'AI Settings', selecting WmDOT, and then
    clicking 'Configure'

Number of days to start this AI after the previous one: 1..
    - this determines how soon the AI will start
DOT State (first letter) and (second letter): Default, A..Z
    - what do you want WmDOT to call itself? The default is 'WmDOT'. Note that
        two instances of WmDOT will not take the same name.
Debug Level:
    - How much debugging output do you want on the AI Debug screen in-game?
        0 = next to nothing, 4 = more than you can follow
        Probably only useful to me, or if you wonder what WmDOT is doing
    - This setting can be changing in-game, but takes a little while for the
        change to be registered
Operation DOT: GO! or no go
    - whether Operation DOT (WmDOT's highway building routine) runs or not. At
        present, WmDOT can't do anything else, so turning this off effectively
        keeps WmDOT from doing anything...
The minimum size of towns to connect: 0..10000
    - this is the minimum size of towns WmDOT connects to the highway network
    - this setting can be changed in-game

-- Version History ------------------------------------------------------------
Version 4 [2011-04-08]
    Changes to pathfinder allowing in to run in 1/20 the time in some cases
    Double check the road got built
    Fix problem that was crashing WmDOT on savegame loading
    Rewrite the innerards to make expansion easier
Version 3 [2011-03-25]
    Fix problem loading libraries in v2 by moving pathfinder in house
Version 2
    Intial Bananas release
    Allows multiple instances to work cooperatively
Version 1
    Initial working model

-- Roadmap --------------------------------------------------------------------
These are features I hope to add to WmDOT shortly. However, this is subject to
    change without notice. I am open to suggestions however!
v5. Support for large maps
v6. Bring water and food to towns in the desert and above the snowline to help
        them grow
v7. Provide streetcar service in towns

-- Known Issues ---------------------------------------------------------------
Bankruptcy: Because WmDOT has no revenue source and so may go bankrupt. This
    becomes more of an issue in long games, on mountainous and watery maps, and
    on large maps. Allowing WmDOT to go bankrupt and then restarting itself will
    allowWmDOT to keep going.
Save/Load functionality has no been added. On loading a game, WmDOT will take
    some time but should eventaully pick up where it left off.
Building multiple routes is a tradeoff for pathfinder speed. If it becomes
    excessive, let me know.
Freezes on large maps. Due to the way WmDOT sorts through the map, as map size
    grows (technically, the number of towns), the processing requirements rise
    exponentially. It is not advised to run WmDOT on maps will more than 100
    towns (roughly, a 512x512 map with a high number of towns).
Pathfinding can take an exceptionally long time if there is no possible path.
    This is most often an issue when the two towns in question are on different
    islands.

-- Help! It broke! (Bug Report) -----------------------------------------------
If WmDOT crashes, please help me fix it. Save a screenshot (under the ? on the
    far right of the in-game toolbar) and report the bug to either:
        http://www.tt-forums.net/viewtopic.php?f=65&t=53698
        http://code.google.com/p/openttd-noai-wmdot/issues/

-- Helpful Links --------------------------------------------------------------
Get OpenTTD!                                                    www.openttd.org
TT-Forums - all things Transport Tycoon related               www.tt-forums.net
WmDOT's thread on TT-Forums: release announcements, bug reports,
    suggesions, and general commentary
                            http://www.tt-forums.net/viewtopic.php?f=65&t=53698
WmDOT on Google Code: source code, and WmDOT: Bleeding Edge edition
                                    http://code.google.com/p/openttd-noai-wmdot
To report issues:            http://code.google.com/p/openttd-noai-wmdot/issues
My other projects (for OpenTTD):
    Alberta Town Names      http://www.tt-forums.net/viewtopic.php?f=67&t=53313
    MinchinWeb's Random Town Name Generator
                            http://www.tt-forums.net/viewtopic.php?f=67&t=53579

-- Licence -------------------------------------------------------------------
WmDOT (unless otherwise noted) is licenced under a
    Creative Commons-Attribution 3.0 licence.