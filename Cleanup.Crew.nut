/*	Cleanup Crew v.2-GS, [2011-12-17], part of
 *		part of WmDOT v.6-GS,
 *		adapted from WmDOT v.6  r.118 [2011-04-28]
 *	Copyright � 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	Cleanup Crew
 *		The Cleanup Crew is a sort of 'unbuilder.' Operation DOT, particularly
 *		in Mode 6, has a tendency to make a mess of the map by building roads
 *		every which way. Cleanup Crew fixes that being fed a list of tile pair
 *		connections that are built and being provided the 'Golden Path' (the
 *		last, and assumedly best, path built). Road tile pairs that were built
 *		but are not part of the 'Golden Path' are then 'unbuild' (deleted).
 */ 
 
//	Requires
//		Queue.Fibonacci_Heap v.2

class OpCleanupCrew {
	function GetVersion()       { return 2; }
	function GetRevision()		{ return 163; }
	function GetDate()          { return "2011-12-17"; }
	function GetName()          { return "Cleanup Crew"; }

	_heap_class = import("Queue.Fibonacci_Heap", "", 2);
	_built_tiles = null;
	_golden_path = null;
	_heap = null;
	_next_run = null;
	_road_type = null;
	
	Log = null;
	
	State = null;
	
	constructor() {
		this.Log = OpLog();
		this.State = this.State(this);
		this._heap = this._heap_class();
		this._next_run = 10000;
		this._road_type = GSRoad.ROADTYPE_ROAD;
	}

}

class OpCleanupCrew.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
//			case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._next_run; break;
//			case "ROI":				return this._main._ROI; break;
//			case "Cost":			return this._main._Cost; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function OpCleanupCrew::LinkUp() 
{
	this.Log = WmDOT.Log;
	Log.Note(this.GetName() + " linked up!",3);
}

function OpCleanupCrew::Reset()
{
//	Clears the internal heap and the Golden Path
//	Can be invoked externally, but is invoked internally at the end of Run()
	this._built_tiles = null;
	this._golden_path = null;
	this._heap = null;
	this._heap = this._heap_class();
	this._next_run = GSController.GetTick() + 10000;
}


function OpCleanupCrew::AcceptBuiltTiles(TilePairArray)
{
//	Takes in a Array of Tile Pairs and adds them to an internal heap to be
//		dealt with later
//	TO-DO: Add an error check on the supplied array
	
//	Note: Tiles are added with a random priority. This is so that they get
//		pulled off the map in a 'random' order, which I thought would look cool :)

	Log.Note("Running CleanupCrew.AcceptBuildTiles...", 3);
	for (local i = 0; i < TilePairArray.len(); i++ ) {
//		Log.Note("Inserting " + Array.ToStringTiles1D(TilePairArray[i]) + " : " + i + ".", 4);
		this._heap.Insert(TilePairArray[i], GSBase.RandRange(255) );
	}
}

function OpCleanupCrew::AcceptGoldenPath(TilePairArray)
{
//	Takes in an Array of Tile Pairs that represents the 'Golden Path' or
//		perfect routing. Tile Pairs appearing on this list will not be un-built
//	TO-DO: Add an error check on the supplied array

	this._golden_path = TilePairArray;
	return this._golden_path;
}

function OpCleanupCrew::SetToRun()
{
//	Involved OpDOT to have Cleanup Crew run on the next pass in the main loop

//	Note:	This is set to run at the current moment. However, the main loop
//			compares run times to the time when the loop started. Therefore,
//			put CleanupCrew above OpDOT in the loop lists to be sure that
//			CleanupCrew runs before OpDOT does again.

	this._next_run = GSController.GetTick();
	return this._next_run;
}

function OpCleanupCrew::Run()
{
//	This is where the real action is!
	local tick = GSController.GetTick();
	if (this._golden_path == null) {
		Log.Note("Cleanup Crew: At tick " + tick + ".",1);
		Log.Note("          There has been no 'Golden Path' set so, yum, yeah...we're still unemployed...", 1);
		this._next_run = tick + 10000;
		return;
	}
	
	Log.Note("Cleanup Crew is employed at tick " + tick + ".",1);
	
	GSRoad.SetCurrentRoadType(this._road_type);
	local TestPair;
	local i = 0;
	while (this._heap.Count() > 0) {
		local count = this._heap.Count();	// For debugging
		TestPair = this._heap.Pop();
		if (!Array.ContainedInPairs(this._golden_path, TestPair[0], TestPair[1])) {
			if (GSMap.DistanceManhattan(TestPair[0], TestPair[1]) == 1) {
				GSRoad.RemoveRoadFull(TestPair[0], TestPair[1]);
				i++;
				Log.Note(i +". Testpair at " + Array.ToStringTiles1D(TestPair) + " removed.", 4);
			} else {
			// we're either a tunnel or a bridge, remove both!
				i++;
				Log.Note(i +". Testpair at " + Array.ToStringTiles1D(TestPair) + " removed. (Bridge or Tunnel)", 4);
				GSBridge.RemoveBridge(TestPair[0]);
				GSTunnel.RemoveTunnel(TestPair[0]);
			}
		} else {
			Log.Note(i +". Testpair at " + Array.ToStringTiles1D(TestPair) + " NOT removed.", 4);
		}
	}

	this.Reset();
	
	Log.Note("Cleanup Crew's work is complete, took " + (GSController.GetTick() - tick) + " ticks, " + i + " tiles removed.", 2);
}

function OpCleanupCrew::SetRoadType(ARoadType)
{
//	Changes the road type Cleanup Crew is operating in
//	TO-DO: Add an error check on the supplied value

	this._road_type = ARoadType;
	return this._road_type;
}