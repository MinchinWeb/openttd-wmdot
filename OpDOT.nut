/*	OperationDOT v.3, part of 
 *	WmDOT v.5  r.69  [2011-04-13]
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	Operation DOT
 *		Operation DOT (for "Department of Transportation") tries to build out
 *		the highway (road) network. Starting at the HQ town (it's "capital"),
 *		it first build out to surrounding towns, then town surrounding the
 *		connected towns, and then any pair of towns on the map, including
 *		generating alternate connections. No revenue stream.
 */ 
 
//	Requires SuperLib v6 or better
//	Requires "Road.Pathfinder.WM.nut"
//		Requires "AyStar.WM.nut"
//			Requires queue.binary_heap v1
//	Requires "OpLog.nut"
//	Requires "OpMoney.nut"
//		Note that OpDOT runs a seperate money manager from the main program
//	Requires "TownRegistrar.nut"

//	TO-DO
//	- break into more steps (Modes) to allow breaking during pathfinding
 
 
/*	AILog.Info("OpDOT settings: " + MyDOT.Settings.PrintTownAtlas + " " + MyDOT.Settings.MaxAtlasSize + " " + MyDOT.Settings.FloatOffset);
	
	MyDOT.Settings.PrintTownAtlas = true;
	MyDOT.Settings.MaxAtlasSize = 250;
	MyDOT.Settings.FloatOffset = 0.1;
	
	AILog.Info("OpDOT settings: " + MyDOT.Settings.PrintTownAtlas + " " + MyDOT.Settings.MaxAtlasSize + " " + MyDOT.Settings.FloatOffset);
*/


 class OpDOT {
	function GetVersion()       { return 3; }
	function GetRevision()		{ return 69; }
	function GetDate()          { return "2011-04-13"; }
	function GetName()          { return "Operation DOT"; }
 
	_MaxAtlasSize = null;		//  UNUSED
	//	This sets the maximum number of towns that will printed to the debug
	//	screen.
	 
	_SleepLength = null;
	//	Controls how many ticks the AI sleeps between iterations.
	 
	_FloatOffset = null;
	//	Offset used to convert numbers from intregers to floating point
	 
	_PathFinderCycles = null;
	//	Set the number of tries the pathfinders should run for
	 
	_MaxBridge = null;
	_MaxTunnel = null;
	//	Max tunnel and bridge length it will build
	
	_DebugLevel = null;
	//	How much is output to the AIDebug Screen
	//	0 - run silently
	//	1 - only that the mode is running and the town pair it tries to join
	//	2 - 'normal' debugging - each step
	//	3 - output arrays
	
	_Mode = null;
	_HQTown = null;		//	HQInWhatTown
	_Atlas = null;
	_TownArray = null;
	_PairsToConnect = null;
	_ConnectedPairs = null;			//	TO-DO: Tranisition to TownRegistrar
	_SomeoneElseConnected = null;	//	TO-DO: Tranisition to TownRegistrar
	_NumOfTownsOnList = null;
	_BuiltSomething = null;
	_ModeStart = null;
	_RoadType = null;
	_PathfinderDistancePenalty = null;	//	Extra distance penalty applied
											//	to pathfinder. Higher numbers
											//	make it run faster but can do
											//	funny things to the resulting
											//	path...
	_Mode7Counter = null;
	
	_NextRun = null;
	_ROI = null;
	_Cost = null;
	
	Log = null;
	Money = null;
	Towns = null;
	
	 
	constructor()
	{
		this._MaxAtlasSize = 99;
		this._SleepLength = 50;
		this._FloatOffset = 0.001;
		this._PathFinderCycles = 100;
		this._MaxBridge = 16;
		this._MaxTunnel = 10;
		this._Mode = 1;
		this._HQTown = null;
		this._Atlas = [];
		this._TownArray = [];
		this._PairsToConnect = [];
		this._ConnectedPairs = [];
		this._SomeoneElseConnected = [];
		this._NumOfTownsOnList = 0;
		this._BuiltSomething = false;
		this._ModeStart = true;
		this._NextRun = 0;
		this._RoadType = AIRoad.ROADTYPE_ROAD;
		this._PathfinderDistancePenalty = 5;
		this._Mode7Counter = 0;
		
		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
		Towns = TownRegistrar();
	}
}

class OpDOT.Settings {

	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "MaxAtlasSize":		this._main._MaxAtlasSize = val; break;
			case "SleepLength":			this._main._SleepLength = val; break;
			case "FloatOffset":			this._main._FloatOffset = val; break;
			case "PathFinderCycles":	this._main._PathFinderCycles = val; break;
			case "MaxBridge":			this._main._MaxBridge = val; break;
			case "MaxTunnel":			this._main._MaxTunnel = val; break;
			case "Mode":				this._main._Mode = val; break;
			case "HQTown":				this._main._HQTown = val; break;
			case "Atlas":				this._main._Atlas = val; break;
			case "TownArray":			this._main._TownArray = val; break;
			case "PairsToConnect":		this._main._PairsToConnect = val; break;
			case "ConnectedPairs":		this._main._ConnectedPairs = val; break;
			case "SomeoneElseConnected":	this._main._SomeoneElseConnected = val; break;
			case "DebugLevel":			this._main._DebugLevel = val; break;
			case "RoadType":			this._main._RoadType = val; break;
			case "PathfinderDistancePenalty":	this._main._PathfinderDistancePenalty = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx)
	{
		switch (idx) {
			case "MaxAtlasSize":		return this._main._MaxAtlasSize; break;
			case "SleepLength":			return this._main._SleepLength; break;
			case "FloatOffset":			return this._main._FloatOffset; break;
			case "PathFinderCycles":	return this._main._PathFinderCycles; break;
			case "MaxBridge":			return this._main._MaxBridge; break;
			case "MaxTunnel":			return this._main._MaxTunnel; break;
			case "Mode":				return this._main._Mode; break;
			case "HQTown":				return this._main._HQTown; break;
			case "Atlas":				return this._main._Atlas; break;
			case "TownArray":			return this._main._TownArray; break;
			case "PairsToConnect":		return this._main._PairsToConnect; break;
			case "ConnectedPairs":		return this._main._ConnectedPairs; break;
			case "SomeoneElseConnected":	return this._main._SomeoneElseConnected; break;
			case "DebugLevel":			return this._main._DebugLevel; break;
			case "RoadType":			return this._main._RoadType; break;
			case "PathfinderDistancePenalty":	return this._main._PathfinderDistancePenalty; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}
 
class OpDOT.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
			case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._NextRun; break;
			case "ROI":				return this._main._ROI; break;
			case "Cost":			return this._main._Cost; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function OpDOT::LinkUp() 
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
	this.Towns = WmDOT.Towns;
	Log.Note(this.GetName() + " linked up!",3);
}
 
function OpDOT::Run() {
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
	
	this._NextRun = AIController.GetTick();
	Log.Note("OpDOT running in Mode " + this._Mode + " at tick " + this._NextRun + ".",1);
	
	if (WmDOT.GetSetting("OpDOT") != 1) {
		this._NextRun = AIController.GetTick() + 13001;			//	6500 ticks is about a year
		Log.Note("** OpDOT has been disabled. **",0);
		return;
	}
	
//	if (this._ModeStart == true) {
		/* if (this._Mode == 1) {
			this._TownArray = GenerateTownList(0);
				// In Mode 1, all towns are considered regardless of the
				// 	population limit (this doesn't become too onerous because
				// 	Mode 1 has a very small distance limit)
		} else {
			this._TownArray = GenerateTownList();
		} */
//		this._TownArray = Towns.GenerateTownList(this._HQTown);
		//	Moving to the TownRegistrar doesn't support overriding the
		//		population limit on the fly
		//	Setting population limits can be done by Setting TownRegistrar Mode
		//		to 0 and then explicitily setting the population limit, and
		//		then running TownRegistrar
//	}
	
	//	If another town goes above the population threshold, restart 'Mode 1'
	//	Ignores what happens if you change the population threshold limit down externally...
//	if ( (this._NumOfTownsOnList < this._TownArray.len()) && (this._Mode != 1) ) {
//		Log.Note("** Returning to Mode 1. **",2);
//		this._Mode = 1;
//		this._BuiltSomething = false;
//		this._NumOfTownsOnList = this._TownArray.len();
//		this._TownArray = GenerateTownList(0);
//		this._ModeStart = true;
//	}
	
	switch (this._Mode) {
		case 1:
		case 2:
		case 3:
		case 4:
		case 5:
		case 6:
			if (this._ModeStart == true) {
				if (this._Mode == 2 && this.Towns.Settings.PopLimit == 0) {
				//	This should only run after moving out of Mode 1 for the
				//		first time
					this.Towns.UpdateMode(1);	//	Abide by PopLimit setting
					this.Towns.Run();			//	Regenerate Neighbourhoods
				}
			
				this._TownArray = this.Towns.GenerateTownList(this._HQTown);
				//	Moving to the TownRegistrar doesn't support overriding the
				//		population limit on the fly
				//	Setting population limits can be done by Setting
				//		TownRegistrar Mode to 0 and then explicitily setting
				//		 the population limit, and then running TownRegistrar
				this._Atlas = GenerateAtlas(this._TownArray);
				if (this._Mode != 6) {
					this._Atlas = RemoveExculsiveDepart(this._Atlas, this._HQTown, this._ConnectedPairs, this._Mode);
				}
				this._Atlas = RemoveBuiltConnections(this._Atlas, this._ConnectedPairs);
				if (this._Mode != 6) {
					this._Atlas = RemoveBuiltConnections(this._Atlas, this._SomeoneElseConnected);
					this._Atlas = RemoveOverDistance(this._Atlas, GetMaxDistance(this._Mode));
				}
				this._Atlas = ApplyTripGenerationModel(this._Atlas);
				this._ModeStart = false;
			}
			
			this._PairsToConnect = PickTowns(this._Atlas);
			
			//	If everything is connected, bump it up to 'Mode 2' or 3
			if (this._PairsToConnect == null) {
			//	No pairs left to connect in this mode
				if (this._BuiltSomething == false) {
				//	If nothing has been built, move to next mode; if
				//		something has been built (in Modes 3, 4, 5),
				//		rebuild atlas and try again
					this._Mode++;
					Log.Note("** Moving to Mode " + this._Mode + ". **",2);
				} else {
				//	That is to say, something has been built...
					if (this._Mode <= 2) {
					//	If we're in Mode 1 or 2, we don't care; bump
					//		up the level (all possible connections are
					//		maintained in the given Atlas)
						this._Mode++;
						Log.Note("** Moving to Mode " + this._Mode + ". **",2);
					} else if (this._Mode == 6) {
					//	if something has been built (in Modes 6), rebuild atlas
					//		 and try again
						Log.Note("** Restarting in Mode " + this._Mode + ". **",2);
					} else {
					//	If we're in Mode 3 or higher, have built a
					//		connection might open up new possibilities;
					//		restart in Mode 3 and rebuild the Atlas
					//		(i.e. restart the Mode)
						this._Mode = 3;
						Log.Note("** Restarting in Mode " + this._Mode + ". **",2);
					}
				}
				this._ModeStart = true;
				this._BuiltSomething = false;
			} else {
				local TestAtlas = [[this._PairsToConnect[0], 0, 1],[this._PairsToConnect[1], 0, 0]];
				if (this._Mode != 6) {
					//	Now that we have the pair, test for an existing connection and only build the road if it doesn't exist
					TestAtlas = RemoveExistingConnections(TestAtlas);
				}
				
				if ((this._Mode == 6) || (TestAtlas[0][2] == 1) ) {
					local tick = AIController.GetTick();
					local KeepTrying = true;
					local Tries = 1;
					local Path;
					local BuildCost = 0;
					
					Log.Note("Attempt " + Tries + " to connect " +AITown.GetName(this._PairsToConnect[0]) + " to " + AITown.GetName(this._PairsToConnect[1]) + ".", 3);
					Path = RunPathfinderOnTownPairs(this._PairsToConnect);
					
					while (KeepTrying == true && Path != null) {
						Tries++;
						Log.Note("Pathfinding took " + (AIController.GetTick() - tick) + " ticks. (MD = " + AIMap.DistanceManhattan(AITown.GetLocation(this._PairsToConnect[0]),AITown.GetLocation(this._PairsToConnect[1])) + ", Length = " + Path.GetLength() + ").",3);
						tick = AIController.GetTick();
						BuildCost = GetPathBuildCost(Path);
						Log.Note("Cost of path is " + BuildCost + "£. Took " + (AIController.GetTick() - tick) + " ticks.", 3);
						Money.FundsRequest(BuildCost*1.1);		//	To allow for inflation during construction
						BuildPath(Path);
						
						//	Test to see if construction worked by running the
						//		pathfinder and computing build cost of the 
						//		second path
						tick = AIController.GetTick();
						Log.Note("Attempt " + Tries + " to connect " +AITown.GetName(this._PairsToConnect[0]) + " to " + AITown.GetName(this._PairsToConnect[1]) + ".", 3)
//						Path = RunPathfinderOnTownPairs(this._PairsToConnect);
						BuildCost = GetPathBuildCost(Path);
						// TO-DO:	Check that the bridges and tunnels got
						//			built; if unbuildable, their cost remains 0£
						
						if (BuildCost == 0) {
							Log.Note("Successful connection!",3);
							KeepTrying = false;
						}						
						if ((Tries >= (WmDOT.GetSetting("OpDOT_RebuildAttempts") + 1)) && (KeepTrying == true)) {
							Log.Warning("After " + Tries + " tries, unable to build path from " +AITown.GetName(this._PairsToConnect[0]) + " to " + AITown.GetName(this._PairsToConnect[1]) + ".")
							KeepTrying = false;
						}
					}
					
					if (Path == null) {
						Log.Warning("Pathfinding took " + (AIController.GetTick() - tick) + " ticks and failed. (MD = " + AIMap.DistanceManhattan(AITown.GetLocation(this._PairsToConnect[0]),AITown.GetLocation(this._PairsToConnect[1])) + ").");
					}

					this._ConnectedPairs.push(this._PairsToConnect);	//	Add the pair to the list of built roads
					// Towns.RegisterConnection(this._PairsToConnect[0],this._PairsToConnect[1]);
					this._Atlas = RemoveBuiltConnections(this._Atlas, [this._PairsToConnect]);
					this._BuiltSomething = true;
				} else if (TestAtlas[0][2] == 0) {
					//	If there already is a link, remove the
					//		connection from the Atlas
					this._Atlas = RemoveBuiltConnections(this._Atlas, [this._PairsToConnect]);
					this._SomeoneElseConnected.push(this._PairsToConnect);	//	Add the pair to the list of roads built by someone else
				} else {
					Log.Note("Unexplected result from route checking module in OpDOT. Returned " + TestAtlas[0][2] + ".",0);
				}
			}
			
			this._NextRun = AIController.GetTick() + (this._SleepLength - (AIController.GetTick() % this._SleepLength));
			break;

		case 7:
			// Checks if the number of neighbourhoods == 1; if so sleep; if
			//		not, increase the population limit in steps of the PopLimit
			//		setting, and rerun the TownRegistrar and then OpDOT,
			//		starting in Mode 3
			if (this.Towns.State.NeighbourhoodCount == 1) {
				this._NextRun = AIController.GetTick() + ((this._SleepLength * 10) - (AIController.GetTick() % (this._SleepLength * 10)));
				Log.Note("In Mode 7: It's tick " + AIController.GetTick() + " and apparently I've done everything! I'm taking a nap... Next run at " + this._NextRun + ".",2);
			} else {
				this._Mode7Counter ++;
				Log.Note("In Mode 7: It's tick " + AIController.GetTick() + " and I'm resetting the Atlas with a population limit of " + (WmDOT.GetSetting("OpDOT_MinTownSize") * (this._Mode7Counter + 1) ) + ".",2);				
				this.Towns.UpdateMode(0);
				this.Towns.Settings.PopLimit = (WmDOT.GetSetting("OpDOT_MinTownSize") * (this._Mode7Counter + 1) );
				this._Mode = 3;
				this._ModeStart = true;
				this._BuiltSomething = false;
			}
			break;
	}

	this._NumOfTownsOnList = this._TownArray.len();	//	Used as a baseline for the next time
											//	around to see if any towns have been
											//	added to the list
 }
 
 function OpDOT::GenerateTownList(SetPopLimit = -1)
{
//	'SetPopLimit' allows overriding of the AI setting for the minimum size of
//		towns to consider 

	Log.Note("Generating Atlas...",2);
	// Generate TownList
	local WmTownList = AITownList();
	WmTownList.Valuate(AITown.GetPopulation);
	local PopLimit;
	if (SetPopLimit < 0) {
	PopLimit = WmDOT.GetSetting("OpDOT_MinTownSize");
	} else {
	PopLimit = SetPopLimit;
	}
	WmTownList.KeepAboveValue(PopLimit);				// cuts under the pop limit
	Log.Note("     Ignoring towns with population under " + PopLimit + ". " + WmTownList.Count() + " of " + AITown.GetTownCount() + " towns left.",2);
	
	local WmTownArray = [];
	WmTownArray.resize(WmTownList.Count());
	local iTown = WmTownList.Begin();
	for(local i=0; i < WmTownList.Count(); i++) {
		WmTownArray[i]=iTown;
		iTown = WmTownList.Next();
	}
	

	return WmTownArray;
}

function OpDOT::GenerateAtlas(WmTownArray)
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
	 

	 
	Log.Note("Generating distance matrix.",2);
	Log.Note("TOWN NAME - POPULATION - LOCATION",4);

	// Generate Distance Matrix
	local iTown;
	local WmAtlas = [];
	WmAtlas.resize(WmTownArray.len());
	
	for(local i=0; i < WmTownArray.len(); i++) {
		iTown = WmTownArray[i];
		Log.Note(iTown + ". " + AITown.GetName(iTown) + " - " + AITown.GetPopulation(iTown) + " - " + AIMap.GetTileX(AITown.GetLocation(iTown)) + ", " + AIMap.GetTileY(AITown.GetLocation(iTown)),4);
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

	Log.Note(ToSting2DArray(WmAtlas), 4);

	return WmAtlas;
}

function OpDOT::RemoveExculsiveDepart(WmAtlas, HQTown, ConnectedPairs, Mode)
{
//	Designed to only allow connections based on already connected towns.
//	In Modes 1 & 2, anything not connecting directly to the 'capital' is removed
//	In Modes 3, 4, & 5, anything not connected to the capital is (directly or
//		via already built roads) is removed

	local tick;
	tick = AIController.GetTick();
	
	local Count = 0;
	
	switch (Mode) {
		case 1:
		case 2:
			Log.Note("Removing towns not directly connected to the capital...", 2);
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
			
			Log.Note(ToSting2DArray(WmAtlas), 4);
			Log.Note(Count + " routes removed. Took " + (AIController.GetTick() - tick) + " ticks.",3);
			return WmAtlas;
		case 3:
		case 4:
		case 5:
			Log.Note("     Removing towns not indirectly connected to the capital...", 2);
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
			
			Log.Note(ToSting2DArray(WmAtlas), 4);
			Log.Note(Count + " routes removed. Took " + (AIController.GetTick() - tick) + " ticks.", 3);
			return WmAtlas;
		default:
			return WmAtlas;
	}
}

function OpDOT::RemoveBuiltConnections(WmAtlas, ConnectedPairs)
{
//	Removes roadpairs that have already been built
	Log.Note("Removing already built roads...",2);
	
	local tick = AIController.GetTick();
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
	
	Log.Note(ToSting2DArray(WmAtlas), 4);
//	if (this._PrintTownAtlas == true) AILog.Info("               " + WmArray.2D.Print(WmAtlas));
	Log.Note(Count + " routes removed. Took " + (AIController.GetTick() - tick) + " ticks.", 3);

	return WmAtlas;

}

function OpDOT::RemoveOverDistance(WmAtlas, MaxDistance)
{
	//	Zeros out distances in the Atlas over an predefined distancez
	//	You don't really want to drive all the way across the map, do you?
	
	Log.Note("Removing towns further than " + MaxDistance + " tiles apart...",2)
	
	local tick;
	tick = AIController.GetTick();
	
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
	Log.Note(ToSting2DArray(WmAtlas),4);
//	if (this._PrintTownAtlas == true) AILog.Info("               " + WmArray.2D.Print(WmAtlas));
	Log.Note(Count + " routes removed. Took " + (AIController.GetTick() - tick) + " ticks.", 3);

	return WmAtlas;
}

function OpDOT::ApplyTripGenerationModel(WmAtlas)
{
	//	Trip Generation, Trip Distribution
	//	A[i,j] = (P[i] + P[j]) / T[i,j]^2		A - 'Attration' - trips from i to j
	//											P - Populaiton of i
	//											T - distance (in time) from i to j
	//	T is calculated by assuming each tile is 1 mile square = (d/v)

//	local tick;
//	tick = AIController.GetTick();
	
	local Speed = GetSpeed();
	
	Log.Note("Applying traffic model. Speed (v) is " + Speed + "...", 2);
	
	//  Applys equation to matrix
//	local ZeroCheck = 0;				//	Uses this to check that the distance matrix is not all zeroes
	for (local i = 0; i < WmAtlas.len(); i++ ) {
		for (local j=1; j < WmAtlas[i].len(); j++ ) {
			local dtemp = WmAtlas[i][j];
			local FactorTemp = 0.0;
			if (dtemp != 0) {					// avoid divide by zero
//				ZeroCheck++;
				dtemp = WmAtlas[i][j] + this._FloatOffset;	//	small offset to make it a floating point number
				local Ttemp = (dtemp / Speed);
				local TPop = (AITown.GetPopulation(WmAtlas[i][0]) + AITown.GetPopulation(WmAtlas[j-1][0]) + this._FloatOffset);
														// j-1 offset needed to get town
				FactorTemp = (TPop / (Ttemp * Ttemp));		// doesn't recognize exponents
			}
			else {
				FactorTemp = dtemp;
			}
			WmAtlas[i][j] = FactorTemp;
		}
	}
	Log.Note(ToSting2DArray(WmAtlas), 4);
	return WmAtlas
}

function OpDOT::PickTowns(WmAtlas)
{	
	//	Picks to towns to connect, returns an array with the two of them
	//	A zero entry in the matrix is used to ignore the possibily of connecting
	//		the two (eg. same town, connection already exists)
	//	Assumes WmAtlas comes in the form of a 2D matrix with the first
	//		column being the TownID and the rest being the distance between
	//		each town pair

	local tick;
	tick = AIController.GetTick();
	
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
		
		Log.Note("     The best rated pair is " + AITown.GetName(Maxi) + " and " + AITown.GetName(Maxj) + ". Took " + (AIController.GetTick() - tick) + " ticks.",2)
		
		return [Maxi, Maxj];
	}
	else {
		Log.Note("     No remaining town pairs to join!",2);
		return null;
	}
}

function OpDOT::RemoveExistingConnections(WmAtlas)
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
	
	Log.Note("Removing already joined towns. This can take a while...",2)
	
	local tick;
	tick = AIController.GetTick();
	
	//	create instance of road pathfinder
	local pathfinder = RoadPathfinder();
	//	pathfinder settings
	pathfinder.cost.max_bridge_length = this._MaxBridge;
	pathfinder.cost.max_tunnel_length = this._MaxTunnel;
//	pathfinder.cost.no_existing_road = pathfinder.cost.max_cost;	// only use exisiting roads
	pathfinder.cost.only_existing_roads = true;
	pathfinder.cost.distance_penalty = max(this._PathfinderDistancePenalty/2, 1);
	
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
					path = pathfinder.FindPath(this._PathFinderCycles);
//					AIController.Sleep(1);
					CycleCounter+=this._PathFinderCycles;
					if (CycleCounter > 2000) {
						//	A safety to make sure that the AI doesn't run out
						//		of money while pathfinding...
						Money.GreaseMoney();
						CycleCounter = 0;
					}
				}
				
				Log.Note("Was trying to find path from " + iTown + " to " + jTown + ": " + path, 4)
				
				if (path != null) {
					WmAtlas[i][j] = 0;
					Log.Note("Path found from " + AITown.GetName(WmAtlas[i][0]) + " to " + AITown.GetName(WmAtlas[j-1][0]) + ".", 4);
					RemovedCount++;
				}
				ExaminedCount++;
				if ((ExaminedCount % 10) == 0) {
					//	Make sure we don't run out of money...
					Money.GreaseMoney();
				}
			}
		}
	}
	
	Log.Note(ToSting2DArray(WmAtlas),4);
	
	tick = AIController.GetTick() - tick;
	Log.Note(RemovedCount + " of " + ExaminedCount + " routes removed. Took " + tick + " tick(s).", 3);
	
	return WmAtlas;
}

//	function OpDOT::BuildRoad(ConnectPairs)
//	require("GNU_FDL.nut");

/* ===== END OF MAIN LOOP FUNCTIONS ====== */

function OpDOT::GetSpeed()
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
	
	Log.Note("Before Return: " + ReturnSpeed + " mph in GameYear " + GameYear, 4);
	return ReturnSpeed;
}

function OpDOT::GetMaxDistance(Mode)
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

function OpDOT::MirrorAtlas(WmAtlas)
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

function OpDOT::RunPathfinder(Start, End)
{
//	Takes the starting and ending tiles, and runs the pathfinder to join the two.
//	Takes Bridge Length, Tunnel Lenght, and Road Type from OpDOT settings.
	
	AIRoad.SetCurrentRoadType(this._RoadType);
	local pathfinder = RoadPathfinder();
	
	//	Set Parameters
												//	default tile cost is 30
	pathfinder.cost.max_bridge_length = this._MaxBridge;
	pathfinder.cost.max_tunnel_length = this._MaxTunnel;
	pathfinder.cost.no_existing_road = 301;		//	default = 40
	pathfinder.cost.slope = 150;				//	default = 200
	pathfinder.cost.bridge_per_tile = 750;		//	default = 150
												//	the hope is that random bridges on flat ground won't
												//		show up, but they will for the little dips  \_/
	pathfinder.cost.turn = 50;					//	default = 100
	pathfinder.cost.distance_penalty = this._PathfinderDistancePenalty;	// 5
	
	// Give the source and goal tiles to the pathfinder.
	pathfinder.InitializePath([Start], [End]);
	
	local path = false;
	local CycleCounter = 0;

	while (path == false) {
		path = pathfinder.FindPath(this._PathFinderCycles);
		CycleCounter+=this._PathFinderCycles;
		if ((CycleCounter % 2000 < this._PathFinderCycles) || (this._PathFinderCycles > 2000) ) {
			//	A safety to make sure that the AI doesn't run out
			//		of money while pathfinding...
			Money.GreaseMoney();
			WmDOT.Sleep(1);
		}
	}
	
	if (path == null) {
	//	No path was found
		Log.Warning("pathfinder.FindPath return null - seeking path from " + AIMap.GetTileX(Start) + "," + AIMap.GetTileY(Start) + " to " + AIMap.GetTileX(End) + "," + AIMap.GetTileY(End) + ".");
	}
	
	return path;
}

function OpDOT::RunPathfinderOnTowns(TownA, TownB)
{
//	Runs the pathfinder between the given towns
//	TO-DO:
//	- add check that the center of town is indeed a road tile

	Log.Note("Connecting " + AITown.GetName(TownA) + " and " + AITown.GetName(TownB) + "...", 2);
	
	return RunPathfinder(AITown.GetLocation(TownA),AITown.GetLocation(TownB));
}

function OpDOT::RunPathfinderOnTownPairs(ConnectPairs)
{
//	ConnectedPairs is expected to be an array with two TownID's
	return RunPathfinderOnTowns(ConnectPairs[0], ConnectPairs[1]);
}

function OpDOT::GetPathBuildCost(Path)
{
//	Turns to 'test mode,' builds the route provided, and returns the cost (all
//		money for AI's is in British Pounds)
//	Note that due to inflation, this value can get stale
//	Returns null if the test build fails

//	Log.Note("Starting the Bean Counters...",4);
	local BeanCounter = AIAccounting();
	local TestMode = AITestMode();

	AIRoad.SetCurrentRoadType(this._RoadType);
	while (Path != null) {
		local SubPath = Path.GetParent();
		if (SubPath != null) {
			local Node = Path.GetTile();
			if (AIMap.DistanceManhattan(Path.GetTile(), SubPath.GetTile()) == 1) {
			//	MD == 1 == road joining the two tiles
				if (!AIRoad.BuildRoad(Path.GetTile(), SubPath.GetTile())) {
				//	If we get here, then the road building has failed
				//	Possible that the road already exists
				//	TO-DO
				//	- fail the road builder if the road cannot be built and
				//		does not already exist
				//	return null;
				}
			} else {
			//	Implies that we're building either a tunnel or a bridge
				if (!AIBridge.IsBridgeTile(Path.GetTile()) && !AITunnel.IsTunnelTile(Path.GetTile())) {
					if (AIRoad.IsRoadTile(Path.GetTile())) {
					//	Original example demolishes tile if it's already a road
					//		tile to get around expanded roadbits.
					//	I don't like this approach as it could destroy Railway
					//		tracks/tram tracks/station
					//	TO-DO
					//	- figure out a way to do this while keeping the other
					//		things I've built on the tile
					//	(can I just remove the road?)
						AITile.DemolishTile(Path.GetTile());
					}
					if (AITunnel.GetOtherTunnelEnd(Path.GetTile()) == SubPath.GetTile()) {
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, Path.GetTile())) {
						//	At this point, an error has occured while building the tunnel.
						//	Fail the pathfiner
						//	return null;
						Log.Warning("OpDOT::GetPathBuildCost can't build a tunnel from " + AIMap.GetTileX(Path.GetTile()) + "," + AIMap.GetTileY(Path.GetTile()) + " to " + AIMap.GetTileX(SubPath.GetTile()) + "," + AIMap.GetTileY(SubPath.GetTile()) + "!!" );
						}
					} else {
					//	if not a tunnel, we assume we're buildng a bridge
						local BridgeList = AIBridgeList_Length(AIMap.DistanceManhattan(Path.GetTile(), SubPath.GetTile() + 1));
						BridgeList.Valuate(AIBridge.GetMaxSpeed);
						BridgeList.Sort(AIAbstractList.SORT_BY_VALUE, false);
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, BridgeList.Begin(), Path.GetTile(), SubPath.GetTile())) {
						//	At this point, an error has occured while building the bridge.
						//	Fail the pathfiner
						//	return null;
						Log.Warning("OpDOT::GetPathBuildCost can't build a bridge from " + AIMap.GetTileX(Path.GetTile()) + "," + AIMap.GetTileY(Path.GetTile()) + " to " + AIMap.GetTileX(SubPath.GetTile()) + "," + AIMap.GetTileY(SubPath.GetTile()) + "!!" );
						}
					}
				}
			}
		}
	Path = SubPath;
	}
	
	//	End build sequence
//	Log.Note("BuildCost is " + BeanCounter.GetCosts() + "£.",4);
//	if (BeanCounter.GetCosts() == null) {
//		Log.Warning("GetPathBuildCost returns 'null'.");
//		return 0;	//	not ideal, but it keeps the rest from crashing
//	TO-DO: Why would this return 'null' in any case?		
//	} else {
		return BeanCounter.GetCosts();
//	}
}

function OpDOT::BuildPath(Path)
{
//	Exits and returns null if the test build fails (doesn't try to finish building the path)

	local TestMode = AIExecMode();	//	We're really doing this!

	AIRoad.SetCurrentRoadType(this._RoadType);
	while (Path != null) {
		local SubPath = Path.GetParent();
		if (SubPath != null) {
			local Node = Path.GetTile();
			if (AIMap.DistanceManhattan(Path.GetTile(), SubPath.GetTile()) == 1) {
			//	MD == 1 == road joining the two tiles
				if (!AIRoad.BuildRoad(Path.GetTile(), SubPath.GetTile())) {
				//	If we get here, then the road building has failed
				//	Possible that the road already exists
				//	TO-DOz
				//	- fail the road builder if the road cannot be built and
				//		does not already exist
				//	return null;
				}
			} else {
			//	Implies that we're building either a tunnel or a bridge
				if (!AIBridge.IsBridgeTile(Path.GetTile()) && !AITunnel.IsTunnelTile(Path.GetTile())) {
					if (AIRoad.IsRoadTile(Path.GetTile())) {
					//	Original example demolishes tile if it's already a road
					//		tile to get around expanded roadbits.
					//	I don't like this approach as it could destroy Railway
					//		tracks/tram tracks/station
					//	TO-DO
					//	- figure out a way to do this while keeping the other
					//		things I've built on the tile
					//	(can I just remove the road?)
						AITile.DemolishTile(Path.GetTile());
					}
					if (AITunnel.GetOtherTunnelEnd(Path.GetTile()) == SubPath.GetTile()) {
					//	The assumption here is that the land hasn't changed
					//		from when the pathfinder was run and when we try to
					//		build the path. If the tunnel building fails, we
					//		get the 'can't build tunnel' message, but if the
					//		land has changed such that the tunnel end is at a
					//		different spot than is was when the pathfinder ran,
					//		we skip tunnel building and try and build a bridge
					//		instead, which will fail because the slopes are wrong...
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, Path.GetTile())) {
						//	At this point, an error has occured while building the tunnel.
						//	Fail the pathfiner
						//	return null;
							Log.Warning("OpDOT::BuildPath can't build a tunnel from " + AIMap.GetTileX(Path.GetTile()) + "," + AIMap.GetTileY(Path.GetTile()) + " to " + AIMap.GetTileX(SubPath.GetTile()) + "," + AIMap.GetTileY(SubPath.GetTile()) + "!!" );
						}
					} else {
					//	if not a tunnel, we assume we're buildng a bridge
						local BridgeList = AIBridgeList_Length(AIMap.DistanceManhattan(Path.GetTile(), SubPath.GetTile() + 1));
						BridgeList.Valuate(AIBridge.GetMaxSpeed);
						BridgeList.Sort(AIAbstractList.SORT_BY_VALUE, false);
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, BridgeList.Begin(), Path.GetTile(), SubPath.GetTile())) {
						//	At this point, an error has occured while building the bridge.
						//	Fail the pathfiner
						//	return null;
						Log.Warning("OpDOT::BuildPath can't build a bridge from " + AIMap.GetTileX(Path.GetTile()) + "," + AIMap.GetTileY(Path.GetTile()) + " to " + AIMap.GetTileX(SubPath.GetTile()) + "," + AIMap.GetTileY(SubPath.GetTile()) + "!! (or the tunnel end moved...)" );
						}
					}
				}
			}
		}
	Path = SubPath;
	}
	
	//	End build sequence
	return true;
}

function OpDOT::LengthOfExistingConnections(TileA, TileB)
{
	Log.Note("Checking existing Connection.",3)
	
	local tick;
	tick = AIController.GetTick();
	
	//	create instance of road pathfinder
	local pathfinder = RoadPathfinder();
	//	pathfinder settings
	pathfinder.cost.max_bridge_length = 9999;
	pathfinder.cost.max_tunnel_length = 9999;
//	pathfinder.cost.no_existing_road = pathfinder.cost.max_cost;	// only use exisiting roads
	pathfinder.cost.only_existing_roads = true;
	pathfinder.cost.distance_penalty = max(this._PathfinderDistancePenalty, 1);
	
	pathfinder.InitializePath([TileA], [TileB]);
	
	local path = false;
	local CycleCounter = 0;
	while (path == false) {
		path = pathfinder.FindPath(this._PathFinderCycles);
//					AIController.Sleep(1);
		CycleCounter+=this._PathFinderCycles;
		if (CycleCounter % 2000 == 0) {
			//	A safety to make sure that the AI doesn't run out
			//		of money while pathfinding...
			Money.GreaseMoney();
//			CycleCounter = 0;
			AIController.Sleep(1);
		}
	}
	
	if (path != null) {
		Log.Note("Path found from " + AIMap.GetTileX(TileA) + "," + AIMap.GetTileY(TileA) + " to " + AIMap.GetTileX(TileB) + "," + AIMap.GetTileY(TileB) + ". Took " + (AIController.GetTick() - tick) + " tick(s).", 4);
		return path.GetLength();
	} else {
		Log.Note("No path found from " + AIMap.GetTileX(TileA) + "," + AIMap.GetTileY(TileA) + " to " + AIMap.GetTileX(TileB) + "," + AIMap.GetTileY(TileB) + ". Took " + (AIController.GetTick() - tick) + " tick(s).", 4);
		return -1;	
	}
}

function OpDOT::LengthOfExistingConnectionsOnTowns(TownA, TownB)
{
//	Runs the pathfinder between the given towns, but just checks for the length of the exisiting connection
//	TO-DO:
//	- add check that the center of town is indeed a road tile

	Log.Note("Checking connection length between " + AITown.GetName(TownA) + " and " + AITown.GetName(TownB) + "...", 2);
	
	return LengthOfExistingConnections(AITown.GetLocation(TownA),AITown.GetLocation(TownB));
}

function OpDOT::LengthOfExistingConnectionsOnTownPairs(ConnectPairs)
{
//	ConnectedPairs is expected to be an array with two TownID's
	return LengthOfExistingConnectionsOnTowns(ConnectPairs[0], ConnectPairs[1]);
}