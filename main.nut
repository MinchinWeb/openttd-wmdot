﻿/*	WmDOT v.3  r.40  [2011-03-25]
 *	Copyright © 2011 by William Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

//	Road pathfinder as provided by the NoAI team
//		import("pathfinder.road", "RoadPathFinder", 3);
		require("Road.Pathfinder.4.WM.nut");	//	class RoadPathfinder
//	For loan management
		import("util.superlib", "SuperLib", 6);
		SLMoney <- SuperLib.Money;
//	My Array library
//		import("util.wmarray", "WmArray", 1);
//			I need to play with this more to get it to work the way I want
		require("Arrays.nut");
//	OperationDOT		
		require("OpDOT.nut");					//	class OpDOT
		
//	Check for more required files at the end of this file!!
 
 class WmDOT extends AIController 
{
	//	SETTINGS
	WmDOTv = 3;
	/*	Version number of AI
	 */	
	WmDOTr = 38;
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
	
	local MyOpDOT = OpDOT();
/*	AILog.Info("OpDOT settings: " + MyDOT.Settings.PrintTownAtlas + " " + MyDOT.Settings.MaxAtlasSize + " " + MyDOT.Settings.FloatOffset);
	
	MyDOT.Settings.PrintTownAtlas = true;
	MyDOT.Settings.MaxAtlasSize = 250;
	MyDOT.Settings.FloatOffset = 0.1;
	
	AILog.Info("OpDOT settings: " + MyDOT.Settings.PrintTownAtlas + " " + MyDOT.Settings.MaxAtlasSize + " " + MyDOT.Settings.FloatOffset);
*/
	
	NameWmDOT();
	local HQTown = BuildWmHQ();
	
	MyOpDOT.Settings.HQTown = HQTown;
	while (true) {
		MyOpDOT.Run();
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