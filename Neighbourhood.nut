/*	Neighbourhood Class, v.1-GS, r.163 [2011-12-17], part of
 *		Town Registrar v.1, part of 
 *		WmDOT v.5  r.114 [2011-04-26]
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
class NeighbourhoodInfo {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 163; }
	function GetDate()          { return "2011-12-17"; }
	function GetName()          { return "Neighbourhood Library"; }
}

class Neighbourhood {
	_index = null;
	_townlist = null;	//	townlist needs to be an array
	_size = null;
	_FloatOffset = null;
	
	_Info = null;
	Log = null;
	
	constructor ()
	{
		this._size = 0;
		this._townlist = [];
		this._FloatOffset = 0.001;
		
		this._Info = NeighbourhoodInfo();
		this.Log = WmDOT.Log;
	}
	
	constructor (Index, Towns)
	{
		this._index = Index;
		this._townlist = Towns;
		this._size = this._townlist.len();
		this._FloatOffset = 0.001;
		
		this._Info = NeighbourhoodInfo();
		this.Log = WmDOT.Log;
	}
	
	function GetSize()			{ return this._size; }
	function GetTowns()			{ return this._townlist }
	function GetIndex()			{ return this._index; }
	
	function GetVersion()       { return this._Info.GetVersion(); }
	function GetRevision()		{ return this._Info.GetRevision(); }
	function GetDate()          { return this._Info.GetDate(); }
	function GetName()          { return this._Info.GetName(); }
}

/* function Neighbourhood::GetSize()
{
	return this._size;
} */

function Neighbourhood::SplitNeighbourhood()
{
	//	Spliting the Neighbourhood takes the exisitng neighbourhood, finds the
	//		two biggest towns, and then creates two neighbourhoods by spliting
	//		the old neighbourhood by drawing a line between the two capitals
	//	Returns 2 element array, containing to arrays of the town ID's that
	//		fall into the two neighbourhoods
	
	local CapitalA = this.GetHighestPopulation();
	local CapitalB = this.GetHighestPopulation([CapitalA]);
	Log.Note("New capitals are " + GSTown.GetName(CapitalA) + " and " + GSTown.GetName(CapitalB) + ".",4);
	local xA = GSMap.GetTileX(GSTown.GetLocation(CapitalA));
	local yA = GSMap.GetTileY(GSTown.GetLocation(CapitalA));
	local xB = GSMap.GetTileX(GSTown.GetLocation(CapitalB));
	local yB = GSMap.GetTileY(GSTown.GetLocation(CapitalB));
	local dx = xA - xB;
	local dy = yA - yB;
	local avex = (xA + xB) / 2;
	local avey = (yA + yB) / 2;
	
	//	Solve a linear system:  ƒ(x) = y = mx + b
	local m = (dx + this._FloatOffset) / (dy + this._FloatOffset);		// slope
		//	FloatOffset is to avoid divide by zero problems
//	local b = yA - m * xA;												// y-intercept
	
	//	But we actually want the line that is perpenticular to and bisects the
	//		line between the two towns
	m = -m;
	local b = avey - m * avex;
	
	local NA = [];
	local NB = [];
	
	local xtest, ytest, ydivide;
	
	for (local i = 0; i  < this._townlist.len(); i++) {
		xtest = GSMap.GetTileX(GSTown.GetLocation(this._townlist[i]));
		ytest = GSMap.GetTileY(GSTown.GetLocation(this._townlist[i]));
		ydivide = m * xtest + b;
		if (ytest < ydivide) {
			NA.push(this._townlist[i]);
		} else {
			NB.push(this._townlist[i]);
		}
	}
	
	Log.Note("NA is: " + Array.ToString1D(NA),4);
	Log.Note("NB is: " + Array.ToString1D(NB),4);
	
	
	return [NA,NB];
}

function Neighbourhood::GetHighestPopulation(IgnoreList = [-1])
{
//	Returns the town with the highest population
//	TownID's on the Ignore list will not be returned
	local HighPop = 0;
	local KeepIndex = -1;
	
	for (local i = 0; i  < this._townlist.len(); i++) {
		if ((Array.ContainedIn1D(IgnoreList, this._townlist[i]) != true) && GSTown.GetPopulation(this._townlist[i]) > HighPop) {
			KeepIndex = this._townlist[i];
			HighPop = GSTown.GetPopulation(this._townlist[i]);
		}
	}
	
	return KeepIndex;
}

function Neighbourhood::UpdateTownList(NewTowns)
{
//	Bulk updates the town list (this completely replaces it! use with caution)
	this._townlist = NewTowns;
	this._size = this._townlist.len();
}

function MapTownsToNeighbourhoods(WorldSize, ListOfNeighbourhoods)
{
//	Returns an array where the index corresponds to the townID and the value at
//		that index corresponds to the Neighbourhood it's in
	local LookUpList = [];
	LookUpList.resize(WorldSize);
	
	for (local i = 0; i  < ListOfNeighbourhoods.len(); i++) {
		for (local j = 0; j < ListOfNeighbourhoods[i]._townlist.len(); j++) {
			LookUpList[ListOfNeighbourhoods[i]._townlist[j]] = i;
		}
	}
	
	//	Remove exisiting signs
	SuperLib.Helper.ClearAllSigns();	//	I don't like this really, but I
										//	don't put signs elsewhere, so this
										//	isn't a problem (yet...)
	
	return LookUpList;
}

function Neighbourhood::MarkOut(DebugLevel = 5)
{
//	When called, posts signs at the town centre of each town in the
//		neighbourhood with the neighbourhood's index number. The capital is
//		noted with stars **

	//	Now place
	SuperLib.Helper.SetSign(GSTown.GetLocation(this._townlist[0]), "** " + this._index + " **", true);
	if (DebugLevel >= 5) {
		for (local i = 1; i < this._townlist.len(); i++) {
			local text = this._index;
			SuperLib.Helper.SetSign(GSTown.GetLocation(this._townlist[i]), text, true);
		}
	}
}