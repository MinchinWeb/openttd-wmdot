/* $Id: library.nut 15091 2009-01-15 15:56:10Z truebrain $ */

class Road extends AILibrary {
	function GetAuthor()      { return "OpenTTD NoAI Developers Team"; }
	function GetName()        { return "Road"; }
	function GetShortName()   { return "PFRO"; }
	function GetDescription() { return "An implementation of a road pathfinder, edited by WM and CR"; }
	function GetVersion()     { return 4; }
	function GetDate()        { return "2011-02-25"; }
	function CreateInstance() { return "Road"; }
	function GetCategory()    { return "Pathfinder"; }
}

RegisterLibrary(Road());
