/*	WmDOT v.3  r.40  [2011-03-25]
 *	Copyright © 2011 by William Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

class WmDOT extends AIInfo 
{
	function GetAuthor()        { return "William Minchin"; }
	function GetName()          { return "WmDOT"; }
	function GetDescription()   { return "An AI that doesn't compete with you but rather builds out the highway network. We're still looking for a revenue stream. v.3 (r.38) CC-BY 3.0"; }
	function GetVersion()       { return 3; }
	function MinVersionToLoad() { return 1; }
	function GetDate()          { return "2011-03-25"; }
	function GetShortName()     { return "}}mW"; }	//	576D7D7D
	function CreateInstance()   { return "WmDOT"; }
	function GetAPIVersion()    { return "1.0"; }

	function GetSettings() {
		AddSetting({name = "MinTownSize", description = "The minimal size of towns to connect", min_value = 100, max_value = 10000, easy_value = 100, medium_value = 500, hard_value = 1000, custom_value = 300, flags = AICONFIG_INGAME, step_size=50});
		AddSetting({name = "DOT_name1", description = "DOT State (first letter)", min_value = 0, max_value = 26, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("DOT_name1", {_0 = "Default", _1 = "A", _2 = "B", _3 = "C", _4 = "D", _5 = "E", _6 = "F", _7 = "G", _8 = "H", _9 = "I", _10 = "J", _11 = "K", _12 = "L", _13 = "M", _14 = "N", _15 = "O", _16 = "P", _17 = "Q", _18 = "R", _19 = "S", _20 = "T", _21 = "U", _22 = "V", _23 = "W", _24 = "X", _25 = "Y", _26 = "Z"});
		AddSetting({name = "DOT_name2", description = "DOT State (second letter)", min_value = 0, max_value = 26, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("DOT_name2", {_0 = "none", _1 = "A", _2 = "B", _3 = "C", _4 = "D", _5 = "E", _6 = "F", _7 = "G", _8 = "H", _9 = "I", _10 = "J", _11 = "K", _12 = "L", _13 = "M", _14 = "N", _15 = "O", _16 = "P", _17 = "Q", _18 = "R", _19 = "S", _20 = "T", _21 = "U", _22 = "V", _23 = "W", _24 = "X", _25 = "Y", _26 = "Z"});
//		AddSetting({name = "Grid_Spacing", description = "Grid Spacing", min_value = 6, max_value = 30, easy_value = 14, medium_value = 14, hard_value = 14, custom_value = 12, step_size=2, flags = 0});
//		AddLabels("Grid_Spacing", {_12 = "12 (default)", _14 = "14 (min. for full-sized airports)"});
//		AddSetting({name = "Hwy_Prefix", description = "Highway Prefix", min_value = 0, max_value = 4, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
//		AddLabels("Hwy_Prefix", {_0 = "Match DOT name", _1 = "Hwy", _2 = "I-", _3 = "US", _4 = "RN"});
	}
}

/* Tell the core we are an AI */
RegisterAI(WmDOT());