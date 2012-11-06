/*	WmDOT v.6-GS, r.163 [2011-12-17]
 *		adapted from WmDOT v.6  r.118 [2011-04-28]
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 *		OR  http://www.tt-forums.net/viewtopic.php?f=65&t=53698
 */

class WmDOT extends GSInfo 
{
	function GetAuthor()        { return "W. Minchin"; }
	function GetName()          { return "WmDOT-GS"; }
	function GetDescription()   { return "An GameScript that builds out the highway network. We're still looking for a revenue stream. v.6-GS (r.163)"; }
	function GetVersion()       { return 6; }
	function MinVersionToLoad() { return 6; }
	function GetDate()          { return "2011-12-17"; }
	function GetShortName()     { return "~}mW"; }	//	0x576D7D7E
	function CreateInstance()   { return "WmDOT"; }
	function GetAPIVersion()    { return "1.2"; }
	function UseAsRandomGS()	{ return false; }
	function GetURL()			{ return "http://www.tt-forums.net/viewtopic.php?f=65&t=53698"; }
//	function GetURL()			{ return "http://code.google.com/p/openttd-noai-wmdot/issues/"; }
	function GetEmail()			{ return "w_minchin@hotmail.com"}

	function GetSettings() {
		AddSetting({name = "Debug_Level", description = "Debug Level ", min_value = 0, max_value = 5, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = CONFIG_INGAME});
		AddSetting({name = "OpDOT", description = "--  Operation DOT  --  is a ", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, min_value = 0, max_value = 1, flags = 0});
		AddLabels("OpDOT", {_0 = "no go ----------------------- :,-(", _1 = "GO!  ------------------------ :-)"});
		AddSetting({name = "OpDOT_MinTownSize", description = "     The minimal size of towns to connect", min_value = 0, max_value = 10000, easy_value = 100, medium_value = 500, hard_value = 1000, custom_value = 300, flags = CONFIG_INGAME, step_size=50});
		AddSetting({name = "TownRegistrar_AtlasSize", description = "     Max Atlas Size", min_value = 20, max_value = 150, easy_value = 50, medium_value = 50, hard_value = 50, custom_value = 50, step_size = 5, flags = 0});
		AddSetting({name = "OpDOT_RebuildAttempts", description = "     Build Attemps", min_value = 1, max_value = 20, easy_value = 10, medium_value = 10, hard_value = 10, custom_value = 10, flags = CONFIG_INGAME});
//		AddLabels("Grid_Spacing", {_12 = "12 (default)", _14 = "14 (min. for full-sized airports)"});
//		AddSetting({name = "Hwy_Prefix", description = "Highway Prefix", min_value = 0, max_value = 4, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
//		AddLabels("Hwy_Prefix", {_0 = "Match DOT name", _1 = "Hwy", _2 = "I-", _3 = "US", _4 = "RN"});
		AddSetting({name = "info0", description = "----------------------------------------------------- ", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("info0", {_0 = "", _1 = ""});
		AddSetting({name = "info1", description = "     For more information on WmDOT and its settings, visit                ", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("info1", {_0 = "", _1 = ""});
		AddSetting({name = "info2", description = "                http://www.tt-forums.net/viewtopic.php?f=65&t=53698  ", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("info2", {_0 = "", _1 = ""});
	}
}

/* Tell the core we are an GS */
RegisterGS(WmDOT());

//	Requires:
//		SuperLib, v.16
//		MinchinWeb's MetaLib, v.1
//		Queue.Fibonacci_Heap v.2
//		Queue.Binary_Heap v.1
//		Graph.AyStar v.6