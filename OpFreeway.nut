/*	Operation Freeway v.1, [2012-12-28],  
 *		part of WmDOT v.11
 *	Copyright © 2012 by W. Minchin. For more info,
 *		please visit https://github.com/MinchinWeb/openttd-wmdot
 *
 *	Permission is granted to you to use, copy, modify, merge, publish, 
 *	distribute, sublincense, and/or sell this software, and provide these 
 *	rights to others, provided:
 *
 *	+ The above copyright notice and this permission notice shall be included
 *		in all copies or substantial portions of the software.
 *	+ Attribution is provided in the normal place for recognition of 3rd party
 *		contributions.
 *	+ You accept that this software is provided to you "as is", without warranty.
 */
 
/*	Operation Freeways
 *		Operation Freeways builds off of OpDOT and the Dominion Land System
 *		(grid roads in MetaLibrary) to build 'rural' freeways. It does this by
 *		turning straight stretches of roads between grid points into two
 *		one-way roads running side by side.
 */

class OpFreeway {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 121228; }
	function GetDate()          { return "2012-12-28"; }
	function GetName()          { return "Operation Freeway"; }

	_NextRun = null;
	_RoadType = null;
	_tiles = null;

	Log = null;
	Money = null;

	constructor()
	{
		this._NextRun = 13001;
		this._RoadType = AIRoad.ROADTYPE_ROAD;
		
//		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
	}

}

class OpFreeway.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
			case "NextRun":			return this._main._NextRun; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	function _set(idx, val)
	{
		switch (idx) {
			case "NextRun":				this._main._NextRun = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function OpFreeway::LinkUp() 
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
	Log.Note(this.GetName() + " linked up!",3);
}
 
function OpFreeway::AcceptPath(PathToTiles) {
	//	TO-DO: add safety check to input here
	this._tiles = PathToTiles;
	return;
}

function OpFreeway::SetToRun() {
	//	sets OpFreeway to run on next pass
	this._NextRun = AIController.GetTick();
	return this._NextRun;
}

function OpFreeway::Run() {
	//	runs over the list of tiles in the tiles array.
	//	when it reaches a grid point, it goes until it reaches another grid
	//	point, or the path changes direction
	//	if it goes from grid point to grid point without changing direction, it
	//	will add a second road parallel to the first and turn the two of them
	//	into a couplet of one-way roads, one in each direction
	Log.Note("OpFreeway running at tick " + AIController.GetTick() + ".",1);

	//	check to see if we have tiles to work with
	if (this._tiles == null) {
		Log.Note("No tile array for OpFreeway... skipping!", 2);
		this._NextRun = AIController.GetTick() + 13001;
		return;
	}

	//	We're here if we have tiles
	for (local i=0; i < this._tiles.len() - 2; i++) {
		//	loop over tiles
		local StartTile = this._tiles[i];
		local NextTile;
		local EndTile = null;
		if (DLS.IsGridPoint(StartTile)) {
			//	is tile a grid point? if not, skip
			local BeforeTile = StartTile;
			local myDirection = Direction.GetDirectionToTile(this._tiles[i], this._tiles[i+1]);
			local oldDirection;
			do {
				oldDirection = myDirection;
				i++;
				NextTile = this._tiles[i];
				myDirection = Direction.GetDirectionToTile(BeforeTile, NextTile);
				if (DLS.IsGridPoint(NextTile) && (oldDirection == myDirection)) {
					//	if we get to the next grid point and haven't changed
					//	direction, Build couplet!

					//	Which way do we shift?
					local Shift;
					if ((myDirection == Direction.DIR_N) || (myDirection == Direction.DIR_S)) {
						Shift = Direction.DIR_W;
					} else if ((myDirection == Direction.DIR_E) || (myDirection == Direction.DIR_W)) {
						Shift = Direction.DIR_S;
					} else {
						Log.Warning ("OpFreeway.Run without direction shift!!");
					}
					// Get shifted endpoints
					local End1 = Direction.GetAdjacentTileInDirection(StartTile, Shift);
					local End2 = Direction.GetAdjacentTileInDirection(NextTile, Shift);

					//	test to see if we can build from End1 to End2
					//	this won't work if we need a bridge or a tunnel
					AIRoad.SetCurrentRoadType(this._RoadType);
					local BuildingMode = AITestMode();
					local BeanCounter = AIAccounting();	//	To figure out costs	
					if (AIRoad.BuildRoad(End1, End2) && AIRoad.BuildRoad(End1, StartTile) && AIRoad.BuildRoad(End2, NextTile)) {
						BuildingMode = AIExecMode();
						Money.FundsRequest(BeanCounter.GetCosts() * 1.2);	//	Get the money we need
						AIRoad.BuildRoad(End1, StartTile);			//	Build it!
						AIRoad.BuildRoad(End2, NextTile);
						AIRoad.BuildRoad(End1, End2);
						//	Build one way arrows
						//	To-Do: check for exiting one-way road so we don't make the road no-entry or remove the one-way-ness
						local OneWay11 = Direction.GetAdjacentTileInDirection(StartTile, Direction.GetDirectionToTile(StartTile, NextTile));
						local OneWay12 = Direction.GetAdjacentTileInDirection(OneWay11, Direction.GetDirectionToTile(StartTile, NextTile));
						local OneWay21 = Direction.GetAdjacentTileInDirection(End1, Direction.GetDirectionToTile(End1, End2));
						local OneWay22 = Direction.GetAdjacentTileInDirection(OneWay21, Direction.GetDirectionToTile(End1, End2));
						AIRoad.BuildOneWayRoad(OneWay11, OneWay12);
						AIRoad.BuildOneWayRoad(OneWay22, OneWay21);
					}
					i--;
				}
				BeforeTile = NextTile;

				if (oldDirection != myDirection) {
					//	if direction changes, break while loop
					break;
				}
			} while (i < this._tiles.len() - 1)
			EndTile = null;
		}
	}

	this._tiles = null;
	this._NextRun = AIController.GetTick() + 13001;
	return;
}