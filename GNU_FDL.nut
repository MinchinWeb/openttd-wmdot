/*	Road building code, part of
 *	WmDOT v.3  r.40  [2011-03-25]
 *	Copyright © 2011 by William Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	This is code used by WmDOT copied from elsewhere
 *		That said, it has been updated and changed from the original.
 *	This code is under the GNU Free Documentation License
 */

function OpDOT::BuildRoad(ConnectPairs)
//function BuildRoad(ConnectPairs)
{
	//	builds a road, given the path
	//	copied from	http://wiki.openttd.org/AI:RoadPathfinder on 2010-02-10
	//		under GNU Free Documentation License.

	AILog.Info("     Connecting " + AITown.GetName(ConnectPairs[0]) + " and " + AITown.GetName(ConnectPairs[1]) + "...");
	
	local tick;
	tick = WmDOT.GetTick();	
	
	/* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  
  /* Create an instance of the pathfinder. */
  local pathfinder = RoadPathfinder();
  
	//	Set Parameters
	pathfinder.cost.max_bridge_length = this._MaxBridge;
	pathfinder.cost.max_tunnel_length = this._MaxTunnel;
	pathfinder.cost.no_existing_road = 100;		//	default = 40
	pathfinder.cost.slope = 400;				//	default = 200
	pathfinder.cost.bridge_per_tile = 250;		//	default = 150
												//	the hope is that random bridges on flat ground won't
												//		show up, but they will for the little dips  \_/
	pathfinder.cost.turn = 50;					//	default = 100
	
  /* Give the source and goal tiles to the pathfinder. */
  pathfinder.InitializePath([AITown.GetLocation(ConnectPairs[0])], [AITown.GetLocation(ConnectPairs[1])]);

  /* Try to find a path. */
	AILog.Info("          Pathfinding...");
  local path = false;
  local CycleCounter = 0;
  while (path == false) {
    path = pathfinder.FindPath(100);
 //   this.Sleep(1);
	CycleCounter+=this._PathFinderCycles;
	if (CycleCounter > 2000) {
		//	A safety to make sure that the AI doesn't run out
		//		of money while pathfinding...
		SLMoney.MakeSureToHaveAmount(100);
		CycleCounter = 0;
	}
  }

  if (path == null) {
    /* No path was found. */
    AILog.Error("pathfinder.FindPath return null");
  }
  
	/* If a path was found, build a road over it. */
	AILog.Info("          Path found. Took " + (WmDOT.GetTick() - tick) + " ticks. Building route...");
	tick = WmDOT.GetTick();
	
	// Clean out the bank
	SLMoney.MaxLoan();
	
  while (path != null) {
    local par = path.GetParent();
    if (par != null) {
      local last_node = path.GetTile();
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          /* An error occured while building a piece of road. TODO: handle it. 
           * Note that is can also be the case that the road was already build. */
        }
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
              /* An error occured while building a tunnel. TODO: handle it. */
            }
          } else {
            local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
            bridge_list.Valuate(AIBridge.GetMaxSpeed);
            bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
            if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
              /* An error occured while building a bridge. TODO: handle it. */
            }
          }
        }
      }
    }
    path = par;
  }
  
	// Pay the loan back
	SLMoney.MakeMaximumPayback();
	SLMoney.MakeSureToHaveAmount(100);
	
	AILog.Info("          Route complete. (MD = " + AIMap.DistanceManhattan(AITown.GetLocation(ConnectPairs[0]), AITown.GetLocation(ConnectPairs[1])) + ") Took " + (WmDOT.GetTick() - tick) + " tick(s)."); 
 }