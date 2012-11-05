/*	OperationDOT, part of 
 *	WmDOT v.3  r.40  [2011-03-25]
 *	Copyright © 2011 by William Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
//	Requires SuperLib v6 or better
 
 class OpDOT {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 38; }
	function GetDate()          { return "2011-03-24"; }
	function GetName()          { return "Operation DOT"; }
 
 	_PrintTownAtlas = null;
	//	Controls whether the list of towns in the Atlas is printed to the debug screen.
	 
	_PrintArrays = null;
	//	Controls whether the array of the Atlas is printed to the debug screen
	
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
	
	_Mode = null;
	_HQTown = null;
	_Atlas = null;
	_TownArray = null;
	_PairsToConnect = null;
	_ConnectedPairs = null;
	_SomeoneElseConnected = null;
	_NumOfTownsOnList = null;
	_BuiltSomething = null;
	
	 
	constructor()
	{
		this._PrintTownAtlas = false;
		this._PrintArrays = false;
		this._MaxAtlasSize = 99;
		this._SleepLength = 50;
		this._FloatOffset = 0.001;
		this._PathFinderCycles = 100;
		this._MaxBridge = 10;
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
		
		this.Settings = this.Settings(this);
	}
};

class OpDOT.Settings {

	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "PrintTownAtlas":		this._main._PrintTownAtlas = val; break;
			case "PrintArrays":			this._main._PrintArrays = val; break;
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
			default: throw("the index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx)
	{
		switch (idx) {
			case "PrintTownAtlas":		return this._main._PrintTownAtlas; break;
			case "PrintArrays":			return this._main._PrintArrays; break;
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
			default: throw("the index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
 };
 
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
	
	// Pay off most of the loan
	SLMoney.MakeMaximumPayback();
	SLMoney.MakeSureToHaveAmount(100);
	
	if (this._Mode == 1) {
		this._TownArray = GenerateTownList(0);
		//	In Mode 1, all towns are considered regardless of the
		//		population limit (this doesn't become too onerous because
		//		Mode 1 has a very small distance limit)
	} else {
		this._TownArray = GenerateTownList();
	}
	
	//	If another town goes above the population threshold, restart 'Mode 1'
	//	Ignores what happens if you change the population threshold limit down externally...
	if ( (this._NumOfTownsOnList < this._TownArray.len()) && (this._Mode != 1)) {
		AILog.Info("** Returning to Mode 1. **");
		this._Mode = 1;
		this._BuiltSomething = false;
		this._NumOfTownsOnList = this._TownArray.len();
		this._TownArray = GenerateTownList(0);
	}
	
	switch (this._Mode) {
		case 1:
		case 2:
		case 3:
		case 4:
		case 5:
			this._Atlas = GenerateAtlas(this._TownArray);
			this._Atlas = RemoveExculsiveDepart(this._Atlas, this._HQTown, this._ConnectedPairs, this._Mode);
			this._Atlas = RemoveBuiltConnections(this._Atlas, this._ConnectedPairs);
			this._Atlas = RemoveBuiltConnections(this._Atlas, this._SomeoneElseConnected);
			this._Atlas = RemoveOverDistance(this._Atlas, GetMaxDistance(this._Mode));
			this._Atlas = ApplyTripGenerationModel(this._Atlas);

			do  {
				this._PairsToConnect = PickTowns(this._Atlas);
				
				//	If everything is connected, bump it up to 'Mode 2' or 3
				if (this._PairsToConnect == null) {
				//	No pairs left to connect in this mode
					if (this._BuiltSomething == false) {
					//	If nothing has been built, move to next mode; if
					//		something has been built (in Modes 3, 4, 5),
					//		rebuild atlas and try again
						this._Mode++;
						AILog.Info("** Moving to Mode " + this._Mode + ". **");
					} else {
					//	That is to say, something has been built...
						if (this._Mode <= 2) {
						//	If we're in Mode 1 or 2, we don't care; bump
						//		up the level (all possible connections are
						//		maintained in the given Atlas)
							this._Mode++;
							AILog.Info("** Moving to Mode " + this._Mode + ". **");
						} else {
						//	If we're in Mode 3 or higher, have built a
						//		connection might open up new possibilities;
						//		restart in Mode 3 and rebuild the Atlas
						//		(i.e. restart the Mode)
							this._Mode = 3;
							AILog.Info("** Restarting in Mode " + this._Mode + ". **");
						}
					}
					this._BuiltSomething = false;
				} else {
					//	Now that we have the pair, best for an existing connection and only build the road if it doesn't exist				
					local TestAtlas = [[this._PairsToConnect[0], 0, 1],[this._PairsToConnect[1], 0, 0]];
					TestAtlas = RemoveExistingConnections(TestAtlas);
					
					if (TestAtlas[0][2] == 1) {
						BuildRoad(this._PairsToConnect);
						this._ConnectedPairs.push(this._PairsToConnect);	//	Add the pair to the list of built roads
						this._Atlas = RemoveBuiltConnections(this._Atlas, [this._PairsToConnect]);
						this._BuiltSomething = true;
					} else if (TestAtlas[0][2] == 0) {
						//	If there already is a link, remove the
						//		connection from the Atlas
						this._Atlas = RemoveBuiltConnections(this._Atlas, [this._PairsToConnect]);
						this._SomeoneElseConnected.push(this._PairsToConnect);	//	Add the pair to the list of roads built by someone else
					} else {
						AILog.Warning("Unexplected result from route checking module. Returned " + TestAtlas[0][2] + ".");
					}
					
					SLMoney.MakeSureToHaveAmount(100);
					
					local i = WmDOT.GetTick();
					i = i % this._SleepLength;
					AILog.Info("-----  Sleeping for " + i + " ticks. Still in Mode " + this._Mode + ".  -----");
					WmDOT.Sleep(50 - i);
				}
			} while (this._PairsToConnect != null);
			break;
			
		case 6:
			this._Atlas = GenerateAtlas(this._TownArray);
			this._Atlas = RemoveBuiltConnections(this._Atlas, this._ConnectedPairs);
			this._Atlas = ApplyTripGenerationModel(this._Atlas);
			//	Doesn't consider roads built by others or indirect connections
			//	Doesn't require potential new roads to attach to exisiting network

			do  {
				this._PairsToConnect = PickTowns(this._Atlas);
				
				//	If everything is connected, bump it up to 'Mode 7'
				if (this._PairsToConnect == null) {
					if (this._BuiltSomething == false) {
					//	If nothing has been built, move to next mode; if
					//		something has been built (in Modes 6),
					//		rebuild atlas and try again
						this._Mode++;
						AILog.Info("** Moving to Mode " + this._Mode + ". **");
					} else {
						AILog.Info("** Restarting in Mode " + this._Mode + ". **");
					}
					this._BuiltSomething = false;
				} else {
					//	Now that we have the pair, test for an existing
					//		connection and only build the road if it 
					//		doesn't exist				
					BuildRoad(this._PairsToConnect);
					this._ConnectedPairs.push(this._PairsToConnect);	//	Add the pair to the list of built roads
					this._Atlas = RemoveBuiltConnections(this._Atlas, [this._PairsToConnect]);
					this._BuiltSomething = true;
					
					SLMoney.MakeSureToHaveAmount(100);
					
					local i = WmDOT.GetTick();
					i = i % this._SleepLength;
					AILog.Info("-----  Sleeping for " + i + " ticks. Still in Mode " + this._Mode + ".  -----");
					WmDOT.Sleep(50 - i);
				}
			} while (this._PairsToConnect != null);
			break;

		case 7:
			SLMoney.MakeSureToHaveAmount(100);
			AILog.Info("It's tick " + WmDOT.GetTick() + " and apparently I've done everything! I'm taking a nap...");
			local i = WmDOT.GetTick();
			i = i % this._SleepLength;
			i = 10 * this._SleepLength - i;
			WmDOT.Sleep(i);
			break;
	}

	SLMoney.MakeSureToHaveAmount(100);
	this._NumOfTownsOnList = this._TownArray.len();	//	Used as a baseline for the next time
											//	around to see if any towns have been
											//	added to the list

	AILog.Info("----------------------------------------------------------------");
	AILog.Info(" ");
	AILog.Info("Running in Mode " + this._Mode + " at tick " + WmDOT.GetTick() + ".");
 }
 
 function OpDOT::GenerateTownList(SetPopLimit = -1)
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
	 

	 
	AILog.Info("     Generating distance matrix.");
	if (this._PrintTownAtlas == true) AILog.Info("          TOWN NAME - POPULATION - LOCATION");

	// Generate Distance Matrix
	local iTown;
	local WmAtlas = [];
	WmAtlas.resize(WmTownArray.len());
	
	for(local i=0; i < WmTownArray.len(); i++) {
		iTown = WmTownArray[i];
		if (this._PrintTownAtlas == true) AILog.Info("          " + iTown + ". " + AITown.GetName(iTown) + " - " + AITown.GetPopulation(iTown) + " - " + AIMap.GetTileX(AITown.GetLocation(iTown)) + ", " + AIMap.GetTileY(AITown.GetLocation(iTown)));
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

	if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (this._PrintTownAtlas == true) AILog.Info("          " + WmArray.2D.Print(WmAtlas));

	return WmAtlas;
}

function OpDOT::RemoveExculsiveDepart(WmAtlas, HQTown, ConnectedPairs, Mode)
{
//	Designed to only allow connections based on already connected towns.
//	In Modes 1 & 2, anything not connecting directly to the 'capital' is removed
//	In Modes 3 & 4, anything not connected to the capital is (directly or via
//		already built roads) is removed

	local tick;
	tick = WmDOT.GetTick();
	
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
			
			if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
			AILog.Info("          " + Count + " routes removed. Took " + (WmDOT.GetTick() - tick) + " ticks.");
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
			
			if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
			AILog.Info("          " + Count + " routes removed. Took " + (WmDOT.GetTick() - tick) + " ticks.");
			return WmAtlas;
		default:
			return WmAtlas;
	}
}

function OpDOT::RemoveBuiltConnections(WmAtlas, ConnectedPairs)
{
//	Removes roadpairs that have already been built
	AILog.Info("     Removing already built roads...");
	
	local tick = WmDOT.GetTick();
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
	
	if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (this._PrintTownAtlas == true) AILog.Info("          " + WmArray.2D.Print(WmAtlas));
	AILog.Info("          " + Count + " routes removed. Took " + (WmDOT.GetTick() - tick) + " ticks.");

	return WmAtlas;

}

function OpDOT::RemoveOverDistance(WmAtlas, MaxDistance)
{
	//	Zeros out distances in the Atlas over an predefined distancez
	//	You don't really want to drive all the way across the map, do you?
	
	AILog.Info("     Removing towns further than " + MaxDistance + " tiles apart...")
	
	local tick;
	tick = WmDOT.GetTick();
	
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
	if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (this._PrintTownAtlas == true) AILog.Info("          " + WmArray.2D.Print(WmAtlas));
	AILog.Info("          " + Count + " routes removed. Took " + (WmDOT.GetTick() - tick) + " ticks.");

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
//	tick = WmDOT.GetTick();
	
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
	if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (this._PrintTownAtlas == true) AILog.Info("          " + WmArray.2D.Print(WmAtlas));
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
	tick = WmDOT.GetTick();
	
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
		
		AILog.Info("          The best rated pair is " + AITown.GetName(Maxi) + " and " + AITown.GetName(Maxj) + ". Took " + (WmDOT.GetTick() - tick) + " ticks.")
		
		return [Maxi, Maxj];
	}
	else {
		AILog.Info("          No remaining town pairs to join!");
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
	
	AILog.Info("     Removing already joined towns. This can take a while...")
	
	local tick;
	tick = WmDOT.GetTick();
	
	//	create instance of road pathfinder
	local pathfinder = RoadPathfinder();
	//	pathfinder settings
	pathfinder.cost.max_bridge_length = this._MaxBridge;
	pathfinder.cost.max_tunnel_length = this._MaxTunnel;
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
					path = pathfinder.FindPath(this._PathFinderCycles);
//					AIController.Sleep(1);
					CycleCounter+=this._PathFinderCycles;
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
	
	if (this._PrintTownAtlas == true) AILog.Info("          " + ToSting2DArray(WmAtlas));
//	if (this._PrintTownAtlas == true) AILog.Info("          " + WmArray.2D.Print(WmAtlas));

	
	tick = WmDOT.GetTick() - tick;
	AILog.Info("          " + RemovedCount + " of " + ExaminedCount + " routes removed. Took " + tick + " tick(s).");
	
	return WmAtlas;
}

//	function OpDOT::BuildRoad(ConnectPairs)
	require("GNU_FDL.nut");

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
	
//	AILog.Info("     Before Return " + ReturnSpeed + " GameYear " + GameYear);
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

function OpDOT::HQInWhatTown(CompanyNo)
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

function OpDOT::TileIsWhatTown(TileIn)
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
 