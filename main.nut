/*	WmDOT v.6-GS  r.164 [2011-12-17],
 *		adapted from WmDOT v.6  r.118 [2011-04-28]
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

import("util.MinchinWeb", "MetaLib", 2);
	RoadPathfinder <- MetaLib.RoadPathfinder;
	Array <- MetaLib.Array;
import("util.superlib", "SuperLib", 17);		//	For loan management
		
require("OpDOT.nut");				//	OperationDOT
require("OpLog.nut");				//	Operation Log
require("TownRegistrar.nut");		//	Town Registrar
require("Neighbourhood.nut");		//	Neighbourhood Class	
// require("Fibonacci.Heap.WM.nut");	//	Fibonacci Heap (Max)
require("Cleanup.Crew.nut");		//	Cleanup Crew
		

 
 class WmDOT extends GSController 
{
	//	SETTINGS
	WmDOTv = 6;
	/*	Version number of GS
	 */	
	WmDOTr = 163;
	/*	Reversion number of GS
	 */
	//	END SETTINGS
	
	Log = OpLog();
	Towns = TownRegistrar();
	DOT = OpDOT();
	CleanupCrew = OpCleanupCrew();
  
	function Start();
}

/*	TO DO
	- figure out how to get the version number to show up in Start()
 */

function WmDOT::Start()
{
//	For debugging crashes...
	local Debug_2 = "/* Settings: " + GetSetting("DOT_name1") + "-" + GetSetting("DOT_name2") + " - dl" + GetSetting("Debug_Level") + " // OpDOT: " + GetSetting("OpDOT") + " - " + GetSetting("OpDOT_MinTownSize") + " - " + GetSetting("TownRegistrar_AtlasSize") + " - " + GetSetting("OpDOT_RebuildAttempts") + " */" ;
	local Debug_1 = "/* v." + WmDOTv + "-GS, r." + WmDOTr + " // " + GSDate.GetYear(GSDate.GetCurrentDate()) + "-" + GSDate.GetMonth(GSDate.GetCurrentDate()) + "-" + GSDate.GetDayOfMonth(GSDate.GetCurrentDate()) + " start // " + GSMap.GetMapSizeX() + "x" + GSMap.GetMapSizeY() + " map - " + GSTown.GetTownCount() + " towns */";
	
//	GSLog.Info("Welcome to WmDOT, version " + GetVersion() + ", revision " + WmDOTr + " by " + GetAuthor() + ".");
	GSLog.Info("Welcome to WmDOT, version " + WmDOTv + ", revision " + WmDOTr + ", GameScript Edition, by W. Minchin.");
	GSLog.Info("Copyright © 2011 by W. Minchin. For more info, please visit http://www.tt-forums.net/viewtopic.php?f=65&t=53698")
	GSLog.Info(" ");
	
	Log.Settings.DebugLevel = GetSetting("Debug_Level");
	Log.Note("Loading Libraries...",0);		// Actually, by this point it's already happened

	Log.Note("     " + Log.GetName() + ", v." + Log.GetVersion() + " r." + Log.GetRevision() + "  loaded!",0);
	Log.Note("     " + DOT.GetName() + ", v." + DOT.GetVersion() + " r." + DOT.GetRevision() + "  loaded!",0);
	Log.Note("     " + Towns.GetName() + ", v." + Towns.GetVersion() + " r." + Towns.GetRevision() + "  loaded!",0);
	Log.Note("     " + CleanupCrew.GetName() + ", v." + CleanupCrew.GetVersion() + " r." + CleanupCrew.GetRevision() + "  loaded!",0);
	StartInfo();		//	AyStarInfo()
						//	RoadPathfinder()
						//	NeighbourhoodInfo()
						//	Fibonacci_Heap_Info()
	Log.Note("",0);
	
	Log.Settings.DebugLevel = GetSetting("Debug_Level");
	TheGreatLinkUp();
		
	if (GetSetting("Debug_Level") == 0) {
		Log.Note("Increase Debug Level in GS settings to get more verbose output.",0);
		Log.Note("",0);
	}
	
	GSRoad.SetCurrentRoadType(GSRoad.ROADTYPE_ROAD);
		//	Build normal road (no tram tracks)
	
	local Time;
	DOT.Settings.HQTown = BuildWmHQ();

	while (true) {
		Time = this.GetTick();	
		Log.Settings.DebugLevel = GetSetting("Debug_Level");

		if (Time > Towns.State.NextRun)			{ Towns.Run(); }
		if (Time > CleanupCrew.State.NextRun)	{ CleanupCrew.Run(); }
		if (Time > DOT.State.NextRun)			{ DOT.Run(); }

//		this.Sleep(1);		
	}
}

function WmDOT::StartInfo()
{
//	By placing classes here that need to be created to get their info, we
//		destroy them right away (which double to clean up the bug report
//		screens and to free up a little bit of memory)
//	local MyAyStar = AyStarInfo();
//	Log.Note("     " + MyAyStar.GetName() + ", v." + MyAyStar.GetVersion() + " r." + MyAyStar.GetRevision() + "  loaded!",0);
	local MyRoadPathfiner = RoadPathfinder();
	Log.Note("     " + MyRoadPathfiner.Info.GetName() + ", v." + MyRoadPathfiner.Info.GetVersion() + " r." + MyRoadPathfiner.Info.GetRevision() + "  loaded!",0);	
	local MyNeighbourhood = NeighbourhoodInfo();
	Log.Note("     " + MyNeighbourhood.GetName() + ", v." + MyNeighbourhood.GetVersion() + " r." + MyNeighbourhood.GetRevision() + "  loaded!",0);
//	local FHI = Fibonacci_Heap_Info();
//	Log.Note("     " + FHI.GetName() + ", v." + FHI.GetVersion() + " r." + FHI.GetRevision() + "  loaded!",0);
}

function WmDOT::BuildWmHQ()
{
	//  TO-DO
	//	- create other options for where to build HQ (random, setting?)
	
	//	There is no check to keep the map co-ordinates from wrapping around the edge of the map
	//	There is a safety in place that if it tries twenty squares in a line in one step, it exits
	
	Log.Note("Building Headquarters...",1)
	
	local tick;
	tick = this.GetTick();
	
	// Gets a list of the towns	
	local WmTownList = GSTownList();
	//	Remove the towns with a DOT HQ and make a note of them - TODO
	local DotHQList = [];
	for (local i=0; i < GSCompany.COMPANY_LAST; i++) {
		//	Test if company has built HQ
//		GSLog.Info("     Testing Company " + i + ".");
		if (GSCompany.GetCompanyHQ(GSCompany.ResolveCompanyID(i)) != -1) {
			local TestName = GSCompany.GetName(i);
			if (TestName.find("DOT") != null) {
				Log.Note("DOT HQ found for company no. " + i + " in town " + HQInWhatTown(i) + ".",3);
				DotHQList.append(HQInWhatTown(i));
			}
		}
	}

	WmTownList.Valuate(GSTown.GetPopulation);	
	local HQTown = GSTown();	
	HQTown = WmTownList.Begin();
	local OriginalHQTown = HQTown;
	
	while (Array.ContainedIn1D(DotHQList, HQTown)) {
		Log.Note("Failed best for HQTown " + HQTown + ".",3);
		HQTown = WmTownList.Next();
	}
	//	TO-DO: Doesn't address the case where all towns have a DOT HQ in them...
	
	tick = this.GetTick() - tick;
//	Log.Note("HQ built at "+ GSMap.GetTileX(Walker.GetTile()) + ", " + GSMap.GetTileY(Walker.GetTile()) + ". Took " + Walker.GetStep() + " tries. Took " + tick + " tick(s).",2);
	return HQTown;
}

function WmDOT::HQInWhatTown(CompanyNo)
{
//	Given a company ID, returns the townID of where the HQ is located
//	-1 means that an invalid Company ID was given
//	-2 means that the HQ is beyond a town's influence
	
	//	Test for valid CompanyID
	if (GSCompany.ResolveCompanyID(CompanyNo) == -1) {
		Log.Warning("Invalid Company ID!");
		return -1;
	}
	
	local PreReturn = GSCompany.GetCompanyHQ(CompanyNo);
	PreReturn = TileIsWhatTown(PreReturn);
	if (PreReturn == -1) {
		Log.Warning("Company in Invalid Town!");
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
	
	for (local i = 0; i < GSTown.GetTownCount(); i++) {
		TestValue = GSTown.IsWithinTownInfluence(i, TileIn);
//		GSLog.Info("          " + i + ". Testing Town " + " and returns " + TestValue);
		if (TestValue == true) {
			return i;
		}
	}
	
	//	If it get this far, it's not in any town's influence
	return -1;
}

function WmDOT::TheGreatLinkUp()
{
	DOT.LinkUp();
	Towns.LinkUp();
	CleanupCrew.LinkUp();
	Log.Note("The Great Link Up is Complete!",1);
	Log.Note("",1);
}


/*
function TestGS::Save()
 {
   local table = {};	
   //TODO: Add your save data to the table.
   return table;
 }
 
 function TestGS::Load(version, data)
 {
   GSLog.Info(" Loaded");
   //TODO: Add your loading routines.
 }
 */