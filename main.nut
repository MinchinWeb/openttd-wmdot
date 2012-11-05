/*	WmDOT v.2  r.33
 *	Copyright © 2011 by William Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

//	Road pathfinder as provided by the NoAI team
		import("pathfinder.road", "RoadPathFinder", 4);
//	For loan management
		import("util.superlib", "SuperLib", 6);
		SLMoney <- SuperLib.Money;
//	My Array library
//		import("util.wmarray", "WmArray", 1);
//			I need to play with this more to get it to work the way I want
		require("Arrays.nut");
//	function BuildRoad(ConnectPairs)
//		require("GNU_FDL.nut");	//	Included at the end of the file
 
 class WmDOT extends AIController 
{
	//	SETTINGS
	WmDOTv = 2;
	/*	Version number of AI
	 */	
	WmDOTr = 33;
	/*	Reversion number of AI
	 */
	 
	SingleLetterOdds = 7;
	/*	Control on single letter companies.  Set this value higher to increase
	 *	the chances of a single letter DOT name (eg. 'CDOT').		
	 */
	
	PrintTownAtlas = 0;			// 0 == off, 1 == on
	/*	Controls whether the list of towns in the Atlas is printed to the debug screen.
	 */
	 
	PrintArrays = 0;			// 0 == off, 1 == on
	/*	Controls whether the array of the Atlas is printed to the debug screen;
	 */
	
	MaxAtlasSize = 99;		//  UNUSED
	/*	This sets the maximum number of towns that will printed to the debug
	 *	screen.
	 */
	 
	SleepLength = 50;
	/*	Controls how many ticks the AI sleeps between iterations.
	 */
	 
	FloatOffset = 0.001;
	/*	Offset used to convert numbers from intregers to floating point
	 */
	 
	PathFinderCycles = 100;
	/*	Set the number of tries the pathfinders should run for
	 */
	 
	WmMaxBridge = 10;
	WmMaxTunnel = 10;
	/*	Max tunnel and bridge length it will build
	 */
	//	END SETTINGS
  
  function Start();
}

/*	TO DO
	- figure out how to get the version number to show up in Start()
 */

function WmDOT::Start()
{
//	AILog.Info("Welcome to WmDOT, version " + GetVersion() + ", revision " + WmDOTr + " by " + GetAuthor() + ".");
	AILog.Info("Welcome to WmDOT, version " + WmDOTv + ", revision " + WmDOTr + " by William Minchin.");
	AILog.Info("Copyright © 2011 by William Minchin. For more info, please visit http://openttd-noai-wmdot.googlecode.com/")
	AILog.Info(" ");
	
	AILog.Info("Loading Libraries...");		// Actually, by this point it's already happened
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		//	Build normal road (no tram tracks)
	
	NameWmDOT();
	local HQTown = BuildWmHQ();
	local WmAtlas=[];
	local WmTownArray = [];
	local PairsToConnect = [];
	local ConnectedPairs = [];
	local SomeoneElseConnected = [];
	
	local WmMode = 1;		
	//	This is used to keep track of what 'step' the AI is at
	//		1 - joins all towns under first distance threshold to capital
	//		2 - joins all towns under second distance threshold and over
	//			population threshold to capital
	//		3 - joins all towns under first distance threshold and over
	//			population threshold to built road network
	//		4 - joins all towns under second distance threshold and over
	//			population threshold to built road network
	//		5 - joins all towns over the population threshold to the network
	//			(without regard to distance)
	//		6 - considers (and builts as apppropriate) all possible connections
	//			of towns above the population threshold
	//		7 - the AI naps ... zzz ...
	
	local NumOfTownsOnList = 0;
	local BuiltSomething = false;
	
	// Pay off most of the loan
	SLMoney.MakeMaximumPayback();
	SLMoney.MakeSureToHaveAmount(100);
	
	// Keep us going forever
	while (true) {
		if (WmMode == 1) {
			WmTownArray = GenerateTownList(0);
			//	In Mode 1, all towns are considered regardless of the
			//		population limit (this doesn't become too onerous because
			//		Mode 1 has a very small distance limit)
		} else {
			WmTownArray = GenerateTownList();
		}
		
		//	If another town goes above the population threshold, restart 'Mode 1'
		//	Ignores what happens if you change the population threshold limit down externally...
		if ( (NumOfTownsOnList < WmTownArray.len()) && (WmMode != 1)) {
			AILog.Info("** Returning to Mode 1. **");
			WmMode = 1;
			BuiltSomething = false;
			NumOfTownsOnList = WmTownArray.len();
			WmTownArray = GenerateTownList(0);
		}
		
		switch (WmMode) {
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
				WmAtlas = GenerateAtlas(WmTownArray);
				WmAtlas = RemoveExculsiveDepart(WmAtlas, HQTown, ConnectedPairs, WmMode);
				WmAtlas = RemoveBuiltConnections(WmAtlas, ConnectedPairs);
				WmAtlas = RemoveBuiltConnections(WmAtlas, SomeoneElseConnected);
				WmAtlas = RemoveOverDistance(WmAtlas, GetMaxDistance(WmMode));
				WmAtlas = ApplyTripGenerationModel(WmAtlas);

				do  {
					PairsToConnect = PickTowns(WmAtlas);
					
					//	If everything is connected, bump it up to 'Mode 2' or 3
					if (PairsToConnect == null) {
					//	No pairs left to connect in this mode
						if (BuiltSomething == false) {
						//	If nothing has been built, move to next mode; if
						//		something has been built (in Modes 3, 4, 5),
						//		rebuild atlas and try again
							WmMode++;
							AILog.Info("** Moving to Mode " + WmMode + ". **");
						} else {
						//	That is to say, something has been built...
							if (WmMode <= 2) {
							//	If we're in Mode 1 or 2, we don't care; bump
							//		up the level (all possible connections are
							//		maintained in the given Atlas)
								WmMode++;
								AILog.Info("** Moving to Mode " + WmMode + ". **");
							} else {
							//	If we're in Mode 3 or higher, have built a
							//		connection might open up new possibilities;
							//		restart in Mode 3 and rebuild the Atlas
							//		(i.e. restart the Mode)
								WmMode = 3;
								AILog.Info("** Restarting in Mode " + WmMode + ". **");
							}
						}
						BuiltSomething = false;
					} else {
						//	Now that we have the pair, best for an existing connection and only build the road if it doesn't exist				
						local TestAtlas = [[PairsToConnect[0], 0, 1],[PairsToConnect[1], 0, 0]];
						TestAtlas = RemoveExistingConnections(TestAtlas);
						
						if (TestAtlas[0][2] == 1) {
							BuildRoad(PairsToConnect);
							ConnectedPairs.push(PairsToConnect);	//	Add the pair to the list of built roads
							WmAtlas = RemoveBuiltConnections(WmAtlas, [PairsToConnect]);
							BuiltSomething = true;
						} else if (TestAtlas[0][2] == 0) {
							//	If there already is a link, remove the
							//		connection from the Atlas
							WmAtlas = RemoveBuiltConnections(WmAtlas, [PairsToConnect]);
							SomeoneElseConnected.push(PairsToConnect);	//	Add the pair to the list of roads built by someone else
						} else {
							AILog.Warning("Unexplected result from route checking module. Returned " + TestAtlas[0][2] + ".");
						}
						
						SLMoney.MakeSureToHaveAmount(100);
						
						local i = this.GetTick();
						i = i % SleepLength;
						AILog.Info("-----  Sleeping for " + i + " ticks. Still in Mode " + WmMode + ".  -----");
						this.Sleep(50 - i);
					}
				} while (PairsToConnect != null);
				break;
				
			case 6:
				WmAtlas = GenerateAtlas(WmTownArray);
				WmAtlas = RemoveBuiltConnections(WmAtlas, ConnectedPairs);
				WmAtlas = ApplyTripGenerationModel(WmAtlas);
				//	Doesn't consider roads built by others or indirect connections
				//	Doesn't require potential new roads to attach to exisiting network

				do  {
					PairsToConnect = PickTowns(WmAtlas);
					
					//	If everything is connected, bump it up to 'Mode 7'
					if (PairsToConnect == null) {
						if (BuiltSomething == false) {
						//	If nothing has been built, move to next mode; if
						//		something has been built (in Modes 6),
						//		rebuild atlas and try again
							WmMode++;
							AILog.Info("** Moving to Mode " + WmMode + ". **");
						} else {
							AILog.Info("** Restarting in Mode " + WmMode + ". **");
						}
						BuiltSomething = false;
					} else {
						//	Now that we have the pair, test for an existing
						//		connection and only build the road if it 
						//		doesn't exist				
						BuildRoad(PairsToConnect);
						ConnectedPairs.push(PairsToConnect);	//	Add the pair to the list of built roads
						WmAtlas = RemoveBuiltConnections(WmAtlas, [PairsToConnect]);
						BuiltSomething = true;
						
						SLMoney.MakeSureToHaveAmount(100);
						
						local i = this.GetTick();
						i = i % SleepLength;
						AILog.Info("-----  Sleeping for " + i + " ticks. Still in Mode " + WmMode + ".  -----");
						this.Sleep(50 - i);
					}
				} while (PairsToConnect != null);
				break;

			case 7:
				SLMoney.MakeSureToHaveAmount(100);
				AILog.Info("It's tick " + this.GetTick() + " and apparently I've done everything! I'm taking a nap...");
				local i = this.GetTick();
				i = i % SleepLength;
				i = 10 * SleepLength - i;
				this.Sleep(i);
				break;
		}

		SLMoney.MakeSureToHaveAmount(100);
		NumOfTownsOnList = WmTownArray.len();	//	Used as a baseline for the next time
												//	around to see if any towns have been
												//	added to the list

		AILog.Info("----------------------------------------------------------------");
		AILog.Info(" ");
		AILog.Info("Running in Mode " + WmMode + " at tick " + this.GetTick() + ".");
	}
}


function WmDOT::NameWmDOT()
{
	/*	This function names the company based on the AI settings.  If the names
	 *	given by the settings is already taken, a default ('WmDOT', for
	 *	'William Department of Transportation') is used.  Failing that, a
	 *	second default ('ZxDOT', chosed becuase I thought it looked cool) is
	 *	tried.  Failing that, a random one or two letter prefix is chosen and
	 *	added to DOT until and unused name is found.
	 */
		
	AILog.Info("Naming Company...");
	
	// Test for already named company (basically just an issue on
	//		savegame loading)
	local OldName = AICompany.GetName(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	AILog.Info("     Currently named " + OldName + "." + OldName.find("DOT"));
	if (OldName.find("DOT")== null) {
		local tick;
		tick = this.GetTick();
		
		// Get Name Settings and Build Name String
		local Name2 = WmDOT.GetSetting("DOT_name2");
		local NewName = "";
		AILog.Info("     Name settings are " + WmDOT.GetSetting("DOT_name1") + " " + WmDOT.GetSetting("DOT_name2") + ".");
		switch (WmDOT.GetSetting("DOT_name1"))
		{
			case 0: 
				NewName = "Wm";
				break;
			case 1: 
				NewName = "A";
				break;
			case 2: 
				NewName = "B";
				break;
			case 3: 
				NewName = "C";
				break;
			case 4: 
				NewName = "D";
				break;
			case 5: 
				NewName = "E";
				break;
			case 6: 
				NewName = "F";
				break;
			case 7: 
				NewName = "G";
				break;
			case 8: 
				NewName = "H";
				break;
			case 9: 
				NewName = "I";
				break;
			case 10: 
				NewName = "J";
				break;
			case 11: 
				NewName = "K";
				break;
			case 12: 
				NewName = "L";
				break;
			case 13: 
				NewName = "M";
				break;
			case 14: 
				NewName = "N";
				break;
			case 15: 
				NewName = "O";
				break;
			case 16: 
				NewName = "P";
				break;
			case 17: 
				NewName = "Q";
				break;
			case 18: 
				NewName = "R";
				break;
			case 19: 
				NewName = "S";
				break;
			case 20: 
				NewName = "T";
				break;
			case 21: 
				NewName = "U";
				break;
			case 22: 
				NewName = "V";
				break;
			case 23: 
				NewName = "W";
				break;
			case 24: 
				NewName = "X";
				break;
			case 25: 
				NewName = "Y";
				break;
			case 26: 
				NewName = "Z";
				break;
			default:
				AILog.Warning("          Unexpected DOT_name1 parameter");
				break;
		}
		switch (WmDOT.GetSetting("DOT_name2"))
		{
			case 0: 
				break;
			case 1: 
				NewName = NewName + "a";
				break;
			case 2: 
				NewName = NewName + "b";
				break;
			case 3: 
				NewName = NewName + "c";
				break;
			case 4: 
				NewName = NewName + "d";
				break;
			case 5: 
				NewName = NewName + "e";
				break;
			case 6: 
				NewName = NewName + "f";
				break;
			case 7: 
				NewName = NewName + "g";
				break;
			case 8: 
				NewName = NewName + "h";
				break;
			case 9: 
				NewName = NewName + "i";
				break;
			case 10: 
				NewName = NewName + "j";
				break;
			case 11: 
				NewName = NewName + "k";
				break;
			case 12: 
				NewName = NewName + "l";
				break;
			case 13: 
				NewName = NewName + "m";
				break;
			case 14: 
				NewName = NewName + "n";
				break;
			case 15: 
				NewName = NewName + "o";
				break;
			case 16: 
				NewName = NewName + "p";
				break;
			case 17: 
				NewName = NewName + "q";
				break;
			case 18: 
				NewName = NewName + "r";
				break;
			case 19: 
				NewName = NewName + "s";
				break;
			case 20: 
				NewName = NewName + "t";
				break;
			case 21: 
				NewName = NewName + "u";
				break;
			case 22: 
				NewName = NewName + "v";
				break;
			case 23: 
				NewName = NewName + "w";
				break;
			case 24: 
				NewName = NewName + "x";
				break;
			case 25: 
				NewName = NewName + "y";
				break;
			case 26: 
				NewName = NewName + "z";
				break;
			default:
				AILog.Warning("          Unexpected DOT_name2 parameter");
				break;
		}
		NewName = NewName + "DOT"
		if (!AICompany.SetName(NewName))
		{
			AILog.Info("     Setting Company Name failed. Trying default...");
			if (!AICompany.SetName("WmDOT"))
			{
				AILog.Info("     Default failed. Trying backup...")
				if (!AICompany.SetName("ZxDOT"))
				{
					AILog.Info("     Backup failed. Trying random...")
					do
					{
						local c;
						c = AIBase.RandRange(26) + 65;
						NewName = c.tochar();
						c = AIBase.RandRange(26 + SingleLetterOdds) + 97;
						if (c <= 122)
						{
							NewName = NewName + c.tochar();
						}
						NewName = NewName + "DOT";					
					} while (!AICompany.SetName(NewName))
				}
			}
		}
		
		//	Add 'P.Eng' to the end of the founder's name
		NewName = AICompany.GetPresidentName(AICompany.COMPANY_SELF);
		NewName += ", P.Eng"
		AICompany.SetPresidentName(NewName);
		
		tick = this.GetTick() - tick;
		AILog.Info("     Company named " + AICompany.GetName(AICompany.COMPANY_SELF) + ". " + AICompany.GetPresidentName(AICompany.COMPANY_SELF) + " is in charge. Took " + tick + " tick(s).");
	}
	else {
		AILog.Info("     Company ALREADY named " + AICompany.GetName(AICompany.COMPANY_SELF) + ". " + AICompany.GetPresidentName(AICompany.COMPANY_SELF) + " remains in charge.")
	}
}

function WmDOT::BuildWmHQ()
{
	//  TO-DO
	//	- create other options for where to build HQ (random, setting?)
	
	//	There is no check to keep the map co-ordinates from wrapping around the edge of the map
	//	There is a safety in place that if it tries twenty squares in a line in one step, it exits
	
	AILog.Info("Building Headquarters...")
	
	local tick;
	tick = this.GetTick();
	
//	AICompany.BuildCompanyHQ(0xA284);
	
	// Check for exisiting HQ (mine)
	if (AICompany.GetCompanyHQ(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) != -1) {
		AILog.Info("     What are you trying to pull on me?? HQ are already established at " + AIMap.GetTileX(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF)) + ", " +  AIMap.GetTileY(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF)) + " in town no. " + HQInWhatTown(AICompany.COMPANY_SELF) + ".");
		return HQInWhatTown(AICompany.COMPANY_SELF);		//	Actually return the town where the HQ is...
	}
	
	// Gets a list of the towns	
	local WmTownList = AITownList();
	//	Remove the towns with a DOT HQ and make a note of them - TODO
	local DotHQList = [];
	for (local i=0; i < AICompany.COMPANY_LAST; i++) {
		//	Test if company has built HQ
//		AILog.Info("     Testing Company " + i + ".");
		if (AICompany.GetCompanyHQ(AICompany.ResolveCompanyID(i)) != -1) {
			local TestName = AICompany.GetName(i);
			if (TestName.find("DOT") != null) {
				AILog.Info("     DOT HQ found for company no. " + i + " in town " + HQInWhatTown(i) + ".");
				DotHQList.append(HQInWhatTown(i));
			}
		}
	}

	WmTownList.Valuate(AITown.GetPopulation);	
	local HQTown = AITown();	
	HQTown = WmTownList.Begin();
	
	while (ContainedIn1DArray(DotHQList, HQTown)) {
		AILog.Info("     Failed best for HQTown " + HQTown + ".");
		HQTown = WmTownList.Next();
	}
	
	// Get tile index of the centre of town
	local HQx;
	local HQy;
	HQx = AIMap.GetTileX(AITown.GetLocation(HQTown));
	HQy = AIMap.GetTileY(AITown.GetLocation(HQTown));
	AILog.Info("     HQ will be build in " + AITown.GetName(HQTown) + " at " + HQx + ", " + HQy + ".");
	
	// Starts a spiral out from the centre of town, trying to build the HQ until it works!
	local dx = -1;
	local dy =  0;
	local Steps = 0;
	local Stage = 1;
	local StageMax = 1;
	local StageSteps = 0;
	local HQBuilt = false;
	
	while (HQBuilt == false) {
		HQx += dx;
		HQy += dy;
		HQBuilt = AICompany.BuildCompanyHQ(AIMap.GetTileIndex(HQx,HQy));
		Steps ++;
		StageSteps ++;
//			AILog.Info("          Step " + Steps + ". dx=" + dx + " dy=" + dy + ". Trying at "+ HQx + ", " + HQy + ". Stage: " + Stage + ". StageMax: " + StageMax + ". StageSteps: " + StageSteps + ".")

		// Check if it's time to turn
		if (StageSteps == StageMax) {
			StageSteps = 0;
			if (Stage % 2 == 0) {
				StageMax++;
			}
			Stage ++;
			
			// Turn Clockwise
			switch (dx) {
				case 0:
					switch (dy) {
						case -1:
							dx = -1;
							dy =  0;
							break;
						case 1:
							dx = 1;
							dy = 0;
							break;
					}
					break;
				case -1:
					dx = 0;
					dy = 1;
					break;
				case 1:
					dx =  0;
					dy = -1;
					break;
			}
		}

		// Safety: Break if it tries for 20 times and still doesn't work!
		if (Stage == 20) return -1;			
	}
		
	tick = this.GetTick() - tick;
	AILog.Info("     HQ built at "+ HQx + ", " + HQy + ". Took " + Steps + " tries. Took " + tick + " tick(s).");
	return HQTown;
}

function WmDOT::GenerateTownList(SetPopLimit = -1)
{
//	'SetPopLimit' allows overriding of the AI setting for the minimum size of
//		towns to consider 

	AILog.Info("Generating Atlas...");
	// Generate TownList
	local WmTownList = AITownList();
	WmTownList.Valuate(AITown.GetPopulation);
	local PopLimit;
	if (SetPopLimit < 0) {
	PopLimit = WmDOT.GetSetting("MinTownSize");
	} else {
	PopLimit = SetPopLimit;
	}
	WmTownList.KeepAboveValue(PopLimit);				// cuts under the pop limit
	AILog.Info("     Ignoring towns with population under " + PopLimit + ". " + WmTownList.Count() + " of " + AITown.GetTownCount() + " towns left.");
	
	local WmTownArray = [];
	WmTownArray.resize(WmTownList.Count());
	local iTown = WmTownList.Begin();
	for(local i=0; i < WmTownList.Count(); i++) {
		WmTownArray[i]=iTown;
		iTown = WmTownList.Next();
	}
	

	return WmTownArray;
}

function WmDOT::GenerateAtlas(WmTownArray)
{
   /*	Everyone loves the Atlas, right?  Well, the guys at the local DOT
	*	figure it's pretty much essential for their work, so it's one of the
	*	first things they do when they set up shop.
	*
	*	The Atlas is generated in several steps:
	*	  - a list of towns is pulled from the server
	*     - the list is sorted by population
	*     - the location of each town is pulled from the server
	*     - an array is generated with all of the Manhattan distance pairs
	*     - an array is generated with the existing links
	*	  (- an array is generated with the real travel distances along
	*			existing routes)
	*	  (- an array is generated with the differences between real travel
	*			distances and Manhattan distances)
	*	  (- the atlas is printed (to the Debug screen))
	*/
	 

	 
	AILog.Info("     Generating distance matrix.");
	if (PrintTownAtlas > 0) AILog.Info("          TOWN NAME - POPULATION - LOCATION");

	// Generate Distance Matrix
	local iTown;
	local WmAtlas = [];
	WmAtlas.resize(WmTownArray.len());
	
	for(local i=0; i < WmTownArray.len(); i++) {
		iTown = WmTownArray[i];
		if (PrintTownAtlas > 0) AILog.Info("          " + iTown + ". " + AITown.GetName(iTown) + " - " + AITown.GetPopulation(iTown) + " - " + AIMap.GetTileX(AITown.GetLocation(iTown)) + ", " + AIMap.GetTileY(AITown.GetLocation(iTown)));
		local TempArray = [];		// Generate the Array one 'line' at a time
		TempArray.resize(WmTownArray.len()+1);
		TempArray[0]=iTown;
		local jTown = AITown();
//		local TempDist = "";
		for (local j = 0; j < WmTownArray.len(); j++) {
			if (i >= j) {
				TempArray[j+1] = 0;		// Make it so it only generates half the array.
			}
			else {
				jTown = WmTownArray[j];
				TempArray[j+1] = AIMap.DistanceManhattan(AITown.GetLocation(iTown),AITown.GetLocation(jTown));
			}
		}
		WmAtlas[i]=TempArray;
	}

	if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (PrintArrays > 0) AILog.Info("          " + WmArray.2D.Print(WmAtlas));

	return WmAtlas;
}

function WmDOT::RemoveExculsiveDepart(WmAtlas, HQTown, ConnectedPairs, Mode)
{
//	Designed to only allow connections based on already connected towns.
//	In Modes 1 & 2, anything not connecting directly to the 'capital' is removed
//	In Modes 3 & 4, anything not connected to the capital is (directly or via
//		already built roads) is removed

	local tick;
	tick = this.GetTick();
	
	local Count = 0;
	
	switch (Mode) {
		case 1:
		case 2:
			AILog.Info("     Removing towns not directly connected to the capital...");
			WmAtlas = MirrorAtlas(WmAtlas);		//	Thus it doesn't matter if the HQ town is not the first on the list
			for (local i = 0; i < WmAtlas.len(); i++ ) {
				if (WmAtlas[i][0] != HQTown) {
					for (local j=1; j < WmAtlas[i].len(); j++ ) {
						if (WmAtlas[i][j] != 0) {		//	Avoid alredy zeroed entries
							WmAtlas[i][j] = 0;
							Count++;
						}
					}
				}
			}
			
			if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
			AILog.Info("          " + Count + " routes removed. Took " + (this.GetTick() - tick) + " ticks.");
			return WmAtlas;
		case 3:
		case 4:
		case 5:
			AILog.Info("     Removing towns not indirectly connected to the capital...");
			WmAtlas = MirrorAtlas(WmAtlas);		//	Thus it doesn't matter if the HQ town is not the first on the list
			for (local i = 0; i < WmAtlas.len(); i++ ) {
				if (!ContainedIn2DArray(ConnectedPairs, WmAtlas[i][0])) {
					for (local j=1; j < WmAtlas[i].len(); j++ ) {
						if (WmAtlas[i][j] != 0) {		//	Avoid alredy zeroed entries
							WmAtlas[i][j] = 0;
							Count++;
						}
					}
				}
			}			
			
			if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
			AILog.Info("          " + Count + " routes removed. Took " + (this.GetTick() - tick) + " ticks.");
			return WmAtlas;
		default:
			return WmAtlas;
	}
}

function WmDOT::RemoveBuiltConnections(WmAtlas, ConnectedPairs)
{
//	Removes roadpairs that have already been built
	AILog.Info("     Removing already built roads...");
	
	local tick = this.GetTick();
	local TownA = 0;
	local TownB = 0;
	local Count = 0;
	
	for (local i = 0; i < ConnectedPairs.len(); i++) {
		TownA = ConnectedPairs[i][0];
		TownB = ConnectedPairs[i][1];
		
		local IndexA = -1;
		local IndexB = -1;
		
		for (local j = 0; j < WmAtlas.len(); j++ ) {
			if (WmAtlas[j][0] == TownA) {
				IndexA = j;
			}
			if (WmAtlas[j][0] == TownB) {
				IndexB = j;
			}
		}
		
		if (IndexA != -1 && IndexB != -1) {
			WmAtlas[IndexA][IndexB + 1] = 0;
			WmAtlas[IndexB][IndexA + 1] = 0;
		}
		
		Count++;
	}
	
	if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (PrintArrays > 0) AILog.Info("          " + WmArray.2D.Print(WmAtlas));
	AILog.Info("          " + Count + " routes removed. Took " + (this.GetTick() - tick) + " ticks.");

	return WmAtlas;

}

function WmDOT::RemoveOverDistance(WmAtlas, MaxDistance)
{
	//	Zeros out distances in the Atlas over an predefined distancez
	//	You don't really want to drive all the way across the map, do you?
	
	AILog.Info("     Removing towns further than " + MaxDistance + " tiles apart...")
	
	local tick;
	tick = this.GetTick();
	
	local Count = 0;
	
	for (local i = 0; i < WmAtlas.len(); i++ ) {
		for (local j=1; j < WmAtlas[i].len(); j++ ) {
			local dtemp = WmAtlas[i][j];
			local FactorTemp = 0.0;
			if (dtemp != 0) {					// avoid already zeroed entries
				if (dtemp > MaxDistance) {
					WmAtlas[i][j] = 0;
					Count++;
				}
			}
		}
	}
	if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (PrintArrays > 0) AILog.Info("          " + WmArray.2D.Print(WmAtlas));
	AILog.Info("          " + Count + " routes removed. Took " + (this.GetTick() - tick) + " ticks.");

	return WmAtlas;
}

function WmDOT::ApplyTripGenerationModel(WmAtlas)
{
	//	Trip Generation, Trip Distribution
	//	A[i,j] = (P[i] + P[j]) / T[i,j]^2		A - 'Attration' - trips from i to j
	//											P - Populaiton of i
	//											T - distance (in time) from i to j
	//	T is calculated by assuming each tile is 1 mile square = (d/v)

//	local tick;
//	tick = this.GetTick();
	
	local Speed = GetSpeed();
	
	AILog.Info("     Applying traffic model. Speed (v) is " + Speed + "...");
	
	//  Applys equation to matrix
//	local ZeroCheck = 0;				//	Uses this to check that the distance matrix is not all zeroes
	for (local i = 0; i < WmAtlas.len(); i++ ) {
		for (local j=1; j < WmAtlas[i].len(); j++ ) {
			local dtemp = WmAtlas[i][j];
			local FactorTemp = 0.0;
			if (dtemp != 0) {					// avoid divide by zero
//				ZeroCheck++;
				dtemp = WmAtlas[i][j] + FloatOffset;	//	small offset to make it a floating point number
				local Ttemp = (dtemp / Speed);
				local TPop = (AITown.GetPopulation(WmAtlas[i][0]) + AITown.GetPopulation(WmAtlas[j-1][0]) + FloatOffset);
														// j-1 offset needed to get town
				FactorTemp = (TPop / (Ttemp * Ttemp));		// doesn't recognize exponents
			}
			else {
				FactorTemp = dtemp;
			}
			WmAtlas[i][j] = FactorTemp;
		}
	}
	if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (PrintArrays > 0) AILog.Info("          " + WmArray.2D.Print(WmAtlas));
	return WmAtlas
}

function WmDOT::PickTowns(WmAtlas)
{	
	//	Picks to towns to connect, returns an array with the two of them
	//	A zero entry in the matrix is used to ignore the possibily of connecting
	//		the two (eg. same town, connection already exists)
	//	Assumes WmAtlas comes in the form of a 2D matrix with the first
	//		column being the TownID and the rest being the distance between
	//		each town pair

	local tick;
	tick = this.GetTick();
	
//	if (ZeroCheck > 0) {
		//	Ok, next step: find the highest rated pair
		local Maxi = null;
		local Maxj = null;
		local MaxLink = 0.0;
		for (local i = 0; i < WmAtlas.len(); i++ ) {
			for (local j=1; j < WmAtlas[i].len(); j++ ) {
				if (WmAtlas[i][j] > MaxLink) {
					MaxLink = WmAtlas[i][j];
					Maxi = i;
					Maxj = j - 1;	// j-1 offset needed to get town
				}
			}
		}
		
	if (Maxi != null) {
		//	Convert from matrix index to TownID
		Maxi = WmAtlas[Maxi][0];
		Maxj = WmAtlas[Maxj][0];
		
		AILog.Info("          The best rated pair is " + AITown.GetName(Maxi) + " and " + AITown.GetName(Maxj) + ". Took " + (this.GetTick() - tick) + " ticks.")
		
		return [Maxi, Maxj];
	}
	else {
		AILog.Info("          No remaining town pairs to join!");
		return null;
	}
}

function WmDOT::RemoveExistingConnections(WmAtlas)
{
	//	Zeros out distances in the Atlas of existing connections
	//	Required as a precondition to PickTowns() to get anything useful out of it
	//	Note that a connection could be around the far end of the map and back...
	//	Assumes the centre of town is a road tile and that you can follow a road
	//		'out of town'
	//
	//	TO-DO
	//	- check that the centre of town is a road tile
	//	- check to see if you can get out of town and then do something when you can't
	//	- make it only set one check one set of routes (half the matrix)
	
	AILog.Info("     Removing already joined towns. This can take a while...")
	
	local tick;
	tick = this.GetTick();
	
	//	create instance of road pathfinder
	local pathfinder = RoadPathFinder();
	//	pathfinder settings
	pathfinder.cost.max_bridge_length = WmMaxBridge;
	pathfinder.cost.max_tunnel_length = WmMaxTunnel;
//	pathfinder.cost.no_existing_road = pathfinder.cost.max_cost;	// only use exisiting roads
	pathfinder.cost.only_existing_roads = true;
	
	local iTown = AITile();
	local jTown = AITile();
	local RemovedCount = 0;
	local ExaminedCount = 0;
	
	for (local i = 0; i < WmAtlas.len(); i++ ) {
		for (local j=1; j < WmAtlas[i].len(); j++ ) {
			if (WmAtlas[i][j] > 0) {		// Ignore already zeroed entries
				iTown = AITown.GetLocation(WmAtlas[i][0]);
				jTown = AITown.GetLocation(WmAtlas[j-1][0]);	// j-1 needed to get town index
				pathfinder.InitializePath([iTown], [jTown]);
				
				local path = false;
				local CycleCounter = 0;
				while (path == false) {
					path = pathfinder.FindPath(PathFinderCycles);
//					AIController.Sleep(1);
					CycleCounter+=PathFinderCycles;
					if (CycleCounter > 2000) {
						//	A safety to make sure that the AI doesn't run out
						//		of money while pathfinding...
						SLMoney.MakeSureToHaveAmount(100);
						CycleCounter = 0;
					}
				}
				
//				AILog.Info("          Was trying to find path from " + iTown + " to " + jTown + ": " + path)
				
				if (path != null) {
					WmAtlas[i][j] = 0;
//					AILog.Info("          Path found from " + AITown.GetName(WmAtlas[i][0]) + " to " + AITown.GetName(WmAtlas[j-1][0]) + ".");
					RemovedCount++;
				}
				ExaminedCount++;
				if ((ExaminedCount % 10) == 0) {
					//	Make sure we don't run out of money...
					SLMoney.MakeSureToHaveAmount(999);
				}
			}
		}
	}
	
	if (PrintArrays > 0) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (PrintArrays > 0) AILog.Info("          " + WmArray.2D.Print(WmAtlas));

	
	tick = this.GetTick() - tick;
	AILog.Info("          " + RemovedCount + " of " + ExaminedCount + " routes removed. Took " + tick + " tick(s).");
	
	return WmAtlas;
}

//	function WmDOT::BuildRoad(ConnectPairs)
	require("GNU_FDL.nut");

/* ===== END OF MAIN LOOP FUNCTIONS ====== */

function WmDOT::GetSpeed()
{
	//	Gets max travel speed, given the game year
	//	Based on original game buses in temporate
	//		http://wiki.openttd.org/Buses
	
	//	TO-DO
	//	- get speeds from vehicles acually introduced in the game
	
	local GameYear = 0;
	GameYear = AIDate.GetYear(AIDate.GetCurrentDate());
	
	local GameYearCase = 4;		// Convert to case numbers here because 
								//		Squirrel's switch statement doesn't
								//		seem to play nice with inline evaluations
	if (GameYear < 2008) {
		GameYearCase = 3;
	}
	if (GameYear < 1986) {
		GameYearCase = 2;
	}
	if (GameYear < 1964)
		GameYearCase = 1;
		
	local ReturnSpeed;
	switch (GameYearCase)
	{
		case 4:
			ReturnSpeed = 79;	// mph, only because they're nicer numbers
			break;
		case 3:
			ReturnSpeed = 70;
			break;
		case 2:
			ReturnSpeed = 55;
			break;
		case 1:
			ReturnSpeed = 35;
			break;
		default:
			ReturnSpeed = 1;
			break;
	}
	
//	AILog.Info("     Before Return " + ReturnSpeed + " GameYear " + GameYear);
	return ReturnSpeed;
}

function WmDOT::GetMaxDistance(Mode)
{
	//	Returns the 'max' connection distance
	//	Uses either the speed or 'quarter map'
	//	The idea is the towns within the closer one are all joined, then the
	//		towns in the further one, and then lastly, all towns
	
	local Speed = GetSpeed();
	local FractionMap = ((AIMap.GetMapSizeX() + AIMap.GetMapSizeY()) /2) / 2;	//	That gives you access to about a quarter of the map
	if (Mode == 1 || Mode == 3) {
		return min(Speed, FractionMap);
	}
	if (Mode == 2 || Mode == 4) {
		return max(Speed, FractionMap);
	}
	else {
		return 9999;	//	The current biggest map is 2048x2048
	}
}

function WmDOT::MirrorAtlas(WmAtlas)
{
//	Generally, only half the matrix is generated to save on processing time
//		This mirrors the generated half onto the 'empty' half. The implied
//		assumption is that the distance is the same in both directions.

	for (local i=0; i < WmAtlas.len(); i++) {
		for (local j=1; j < WmAtlas[0].len(); j++) {
			if (WmAtlas[i][j] != 0) {	//	This avoids zero entries to save on processing capacity, but also to avoid erasing the whole array!!
				WmAtlas[j-1][i+1] = WmAtlas[i][j];
			}
		}
	}
	
	return WmAtlas;
}

function WmDOT::HQInWhatTown(CompanyNo)
{
//	Given a company ID, returns the townID of where the HQ is located
//	-1 means that an invalid Company ID was given
//	-2 means that the HQ is beyond a town's influence
	
	//	Test for valid CompanyID
	if (AICompany.ResolveCompanyID(CompanyNo) == -1) {
		AILog.Info("Invalid Company ID!");
		return -1;
	}
	
	local PreReturn = AICompany.GetCompanyHQ(CompanyNo);
	PreReturn = TileIsWhatTown(PreReturn);
	if (PreReturn == -1) {
		AILog.Info("Company in Invalid Town!");
		return -2;
	}
	else {
		return PreReturn;
	}
}

function WmDOT::TileIsWhatTown(TileIn)
{
//	Given a tile, returns the town whose influence it falls under
//	Else returns -1 (i.e. under no town's incfluence)
	
	local TestValue = false;
	
	for (local i = 0; i < AITown.GetTownCount(); i++) {
		TestValue = AITown.IsWithinTownInfluence(i, TileIn);
//		AILog.Info("          " + i + ". Testing Town " + " and returns " + TestValue);
		if (TestValue == true) {
			return i;
		}
	}
	
	//	If it get this far, it's not in any town's influence
	return -1;
}


