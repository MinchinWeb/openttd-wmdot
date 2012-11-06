/*	Operation Hibernia v.3, r.230, [2012-03-17]
 *		part of WmDOT v.9
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	Operation Hibernia
 *		Hibernia refers to the oil field and production platform in the North
 *		Atlantic Ocean, about 300km ESE from St. John's, Newfoundland, Canada.
 *		Hibernia is the world's largest oil platform.
 *
 *		Operation Hibernia seeks out oil platforms, and then transports oil to
 *		Oil Refinaries.
 */
 
//	Requires MinchinWeb's MetaLibrary v.4
//	Requires Zuu's SuperLib v.21

//	TO-DO
//		- if the cargo is passengers (or, I assume, mail), the recieving
//			industries do not include towns but they probably should...

 class OpHibernia {
	function GetVersion()       { return 3; }
	function GetRevision()		{ return 230; }
	function GetDate()          { return "2012-03-17"; }
	function GetName()          { return "Operation Hibernia"; }
	
	
	_NextRun = null;
//	_ROI = null;
//	_Cost = null;
	
	_SleepLength = null;	//	as measured in days
	_TransportedCutOff = null;	//	maximum percentage of transported cargo for an industry still to be considered.
	_CapacityDays = null;		//	this is the (max) numbers of days production a ship will be built to transport
	_Atlas = null;
	_AtlasModel = null;
	_Serviced = null;		//	Industries that have already been serviced
	
	Log = null;
	Money = null;
	
	constructor()
	{
		this._NextRun = 0;
		this._SleepLength = 90;
		this._TransportedCutOff = 50;	// Turn this into an AI setting??
		this._CapacityDays = 60;
		
		this._Atlas = Atlas();
		this._AtlasModel = ModelType.DISTANCE_SHIP;
		this._Atlas.SetModel(this._AtlasModel);
		this._Serviced = [];
		
		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
	}
}

class OpHibernia.Settings {

	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "SleepLength":			this._main._SleepLength = val; break;
			case "TransportedCutOff":	this._main._TransportedCutOff = val; break;
			case "AtlasModel":			this._main._AtlasModel = val; break;
			case "CapacityDays":		this._main._CapacityDays = val; break;
/*			case "HQTown":				this._main._HQTown = val; break;
*/			case "Atlas":				this._main._Atlas = val; break;
/*			case "TownArray":			this._main._TownArray = val; break;
			case "PairsToConnect":		this._main._PairsToConnect = val; break;
			case "ConnectedPairs":		this._main._ConnectedPairs = val; break;
			case "SomeoneElseConnected":	this._main._SomeoneElseConnected = val; break;
			case "DebugLevel":			this._main._DebugLevel = val; break;
			case "RoadType":			this._main._RoadType = val; break;
*/			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx)
	{
		switch (idx) {
			case "SleepLength":			return this._main._SleepLength; break;
			case "TransportedCutOff":	return this._main._TransportedCutOff; break;
			case "AtlasModel":			return this._main._AtlasModel; break;
			case "CapacityDays":		return this._main._CapacityDays; break;
/*			case "HQTown":				return this._main._HQTown; break;
*/			case "Atlas":				return this._main._Atlas; break;
/*			case "TownArray":			return this._main._TownArray; break;
			case "PairsToConnect":		return this._main._PairsToConnect; break;
			case "ConnectedPairs":		return this._main._ConnectedPairs; break;
			case "SomeoneElseConnected":	return this._main._SomeoneElseConnected; break;
			case "DebugLevel":			return this._main._DebugLevel; break;
			case "RoadType":			return this._main._RoadType; break;
*/			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}
 
class OpHibernia.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
//			case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._NextRun; break;
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

function OpHibernia::LinkUp() 
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
//	ship manager...
	Log.Note(this.GetName() + " linked up!",3);
}
 
function OpHibernia::Run() {

	local tick = WmDOT.GetTick();
	Log.Note("OpHibernia running at tick " + tick + ".",1);
	
	if ((WmDOT.GetSetting("OpHibernia") != 1) || (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_WATER) == true)) {
		this._NextRun = AIController.GetTick() + 13001;			//	6500 ticks is about a year
		Log.Note("** OpHibernia has been disabled. **",0);
		return;
	}
	
	///	Check that there is oil on the map; put to sleep if not
	//	Actually this checks for industries that include docks
	local MyIndustries = AIIndustryList();
	MyIndustries.Valuate(AIIndustry.HasDock);
	MyIndustries.KeepValue(true.tointeger());
	
	Log.Note("Keep " + MyIndustries.Count() + " industries.", 2);

	if (MyIndustries.Count() > 0) {
		//	Cycle through MyIndustries and come up with the list of cargos they produce
		local Produced;
		local MyCargos = [];
		MyIndustries.Valuate(Helper.ItemValuator);
		foreach (IndustryNo in MyIndustries) {
			Produced = AICargoList_IndustryProducing(IndustryNo);
			Produced.Valuate(Helper.ItemValuator);
			Log.Note("Industry " + IndustryNo + " produces " + Produced.Count() + " cargos.   (" + AIIndustry.GetName(IndustryNo) + ")",4);
			foreach (CargoNo in Produced) {
				if (Array.ContainedIn1D(MyCargos, CargoNo) == false) {
					MyCargos.push(CargoNo);
					Log.Note("Adding Cargo № " + CargoNo + " (" + AICargo.GetCargoLabel(CargoNo) + ")", 2);
				}
			}
		}
		
		foreach (CargoNo in MyCargos) {
			//	TO-DO: Add a check here to see if we can actually transport the cargo in question!
			//				SuperLib.Engine.DoesEngineExistForCargo(cargo_id, vehicle_type = -1, no_trams = true, no_articulated = true, only_small_aircrafts = false)
			
			///	Get a list of Oil Rigs, and add those without our ships to the sources list;
			//	Keep only those that are underserviced (less than 25%, typically)
			MyIndustries = AIIndustryList();
			MyIndustries.Valuate(AIIndustry.HasDock);
			MyIndustries.KeepValue(true.tointeger());
			MyIndustries.Valuate(AIIndustry.GetLastMonthTransportedPercentage, CargoNo);
			MyIndustries.KeepBelowValue(this._TransportedCutOff);
			MyIndustries.Valuate(AIIndustry.GetLastMonthProduction, CargoNo);
			MyIndustries.KeepAboveValue(1);
			Log.Note("On Cargo: " + AICargo.GetCargoLabel(CargoNo) + ", " + MyIndustries.Count() + " input Industry kept.", 2);
			
			MyIndustries.Valuate(Helper.ItemValuator);
			this._Atlas.Reset();
			foreach (Location in MyIndustries) {
				///		Priority is the production level
				this._Atlas.AddSource(AIIndustry.GetLocation(Location), ( AIIndustry.GetLastMonthProduction(Location, CargoNo) * ( 100 - AIIndustry.GetLastMonthTransportedPercentage(Location, CargoNo) ) ) / 100);
				Log.Note("Atlas.AddSource([" + AIMap.GetTileX(AIIndustry.GetLocation(Location)) + ", " + AIMap.GetTileY(AIIndustry.GetLocation(Location)) + "], " + (AIIndustry.GetLastMonthProduction(Location, CargoNo) * (( 100 - AIIndustry.GetLastMonthTransportedPercentage(Location, CargoNo) ) ) / 100) + ")   (" + AIIndustry.GetName(Location) + ")", 5);
			}	//	end of  foreach (Location in MyIndustries)

			///	Get a list of Oil Refinaries and add to the attraction list; Priority is the goods production level
			//	Actually, this is for industries that accept CargoNo
			local InIndustries = AIIndustryList_CargoAccepting(CargoNo);
			InIndustries.Valuate(Helper.ItemValuator);
			foreach (Location in InIndustries) {
				local Produced = AICargoList_IndustryProducing(Location);
				Produced.Valuate(Helper.ItemValuator);
				local ProductionLevel = 0;
				foreach (CargoNoNo in Produced) {
					ProductionLevel += AIIndustry.GetLastMonthProduction(Location, CargoNoNo);
				}
				this._Atlas.AddAttraction(AIIndustry.GetLocation(Location), ProductionLevel);
				Log.Note("Atlas.AddAttaction([" + AIMap.GetTileX(AIIndustry.GetLocation(Location)) + ", " + AIMap.GetTileY(AIIndustry.GetLocation(Location)) + "], " + ProductionLevel + ")   (" + AIIndustry.GetName(Location) + ")", 5);
			}	// end of  foreach (Location in InIndustries)	

			///	Apply Traffic Model, and select best pair
			local tick2 = WmDOT.GetTick();
			this._Atlas.SetModel(this._AtlasModel);
			this._Atlas.RunModel();
			Log.Note("Atlas.RunModel() took " + (WmDOT.GetTick() - tick2) + " ticks.", 2);
			//	TO-DO:	Apply maximum distance, based on ship travel speeds
			
			local KeepTrying = true;
			while (KeepTrying == true) {
				local BuildPair = this._Atlas.Pop();
				if (BuildPair == null) {
					Log.Note("No Build Pairs.", 3);
					KeepTrying = false;
				} else {
					Log.Note("BuildPair is" + Array.ToStringTiles1D(BuildPair) + "  (" + MetaLib.Industry.GetIndustryID(BuildPair[0]) + ", " + MetaLib.Industry.GetIndustryID(BuildPair[1]) + ")", 3);
					///	Get build location for dock at Oil Refinary
					//	At this point, we know that the first industry has a dock; now we have to figure out what to do about the second industry
					local DockLocation = _MinchinWeb_C_.InvalidTile();
					
					if (AIIndustry.HasDock(MetaLib.Industry.GetIndustryID(BuildPair[1])) == true) {
					//	1. Test if the Industry has a built in dock
						DockLocation = AIIndustry.GetDockLocation(MetaLib.Industry.GetIndustryID(BuildPair[1]));	
					} else {
					//	2. Test if we have a dock built that would work
						Log.Note("Max Station Spread is : " + MetaLib.Constants.MaxStationSpread(), 5);
						local MyStations = AIStationList(AIStation.STATION_DOCK);
						Log.Note("Start with " + MyStations.Count() + " stations.", 5);
						//	Test stations based on distance to industry
						MyStations.Valuate(AIStation.GetDistanceManhattanToTile, BuildPair[1]);
						MyStations.KeepBelowValue((MetaLib.Constants.MaxStationSpread() + MetaLib.Constants.IndustrySize() + AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) * 2);
						Log.Note("Kept " + MyStations.Count() + " stations (close enough).", 5);
						//	Test stations to see if they accept cargo in question
						MyStations.Valuate(MetaLib.Station.IsCargoAccepted, CargoNo);
						MyStations.KeepValue(true.tointeger());
						Log.Note("Kept " + MyStations.Count() + " stations.", 3);
						
						if (MyStations.Count() > 0) {
							//	If more than one station, use the closest to other industry
							MyStations.Valuate(AIStation.GetDistanceManhattanToTile, BuildPair[0]);
							MyStations.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
							local templist = AITileList_StationType(MyStations.Begin(), AIStation.STATION_DOCK);
							DockLocation = templist.Begin();
						} else {
						//	3. Build a dock
							//	TO-DO: consider using station spread to get a spot (i.e. build a
							//				truck stop to reach the refinery)
							//	TO-DO: wait to build the dock until we are ready to start the route
							//	TO-DO: only build the dock (or pass on it's location) if it is in
							//				the same waterbody as BuildPair[0]
							
							local PossibilitesList = Marine.GetPossibleDockTiles(MetaLib.Industry.GetIndustryID(BuildPair[1]));
							Log.Note("Build Possibilites: " + Array.ToStringTiles1D(PossibilitesList, true), 5);
							if (PossibilitesList.len() == 0) {
								Log.Note("     No dock possible near" + Array.ToStringTiles1D([BuildPair[1]]) + ".", 3);
								//	Let the routine come up with another pair from the Atlas
							} else {
								Money.FundsRequest((AIMarine.GetBuildCost(AIMarine.BT_DOCK) + AITile.GetBuildCost(AITile.BT_CLEAR_GRASS)) * 1.1);
								
								local PossibilitiesAIList = AITileList();
								for (local i = 0; i < PossibilitesList.len(); i++) {
									PossibilitiesAIList.AddItem(PossibilitesList[i], AIMap.DistanceManhattan(PossibilitesList[i], BuildPair[0]));
								}
								PossibilitiesAIList.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
								
								local KeepTrying3 = true;
								DockLocation = PossibilitiesAIList.Begin();
								while (KeepTrying3) {
									Log.Note("Trying DockLocation =" + Array.ToStringTiles1D([DockLocation]), 5);
//									DockLocation = PossibilitiesAIList.Next();
									if ((AITile.GetCargoAcceptance(DockLocation, CargoNo, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_DOCK)) >= 8) && (AIMarine.BuildDock(DockLocation, AIStation.STATION_NEW))) {
										// it worked! We have a dock! Nothing more...
										Log.Note("Built Dock at" + Array.ToStringTiles1D([DockLocation]), 3);
										KeepTrying3 = false;
									} else {
										if (PossibilitiesAIList.IsEnd()) {
											DockLocation = MetaLib.Constants.InvalidTile()
											KeepTrying3 = false;
										} else {
											DockLocation = PossibilitiesAIList.Next();
										}
									}
								}	
							}
						}
					}
					
					if (DockLocation == MetaLib.Constants.InvalidTile()) {
						Log.Note("No valid dock location.", 3);
						//	probably keep KeepTrying = ture
					} else {
						Log.Note("DockLocation is" + Array.ToStringTiles1D([DockLocation]) + ".", 3);
						///	Run Waterbody Check to see if Oil Refinary dock and Oil Rig are connected
						local WBC = MetaLib.WaterbodyCheck();
						local Starts = Marine.GetDockFrontTiles(BuildPair[0]);
						local Ends = Marine.GetDockFrontTiles(DockLocation);
						Log.Note("starts: " + Array.ToStringTiles1D(Starts) + "  -> ends: " + Array.ToStringTiles1D(Ends), 5);
						
						//	The Ship Pathfinder can only have one start and one end tile
						local KeepTrying2 = true;
						local start;
						local end;
						local Starts2 = Helper.SquirrelListToAIList(Starts);
						local Ends2 = Helper.SquirrelListToAIList(Ends);
						Starts2.Valuate(Marine.DistanceShip, BuildPair[1]);
						Ends2.Valuate(Marine.DistanceShip, BuildPair[0]);
						Starts2.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
						Ends2.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
						local OldStarts2 = Starts2;
						start = Starts2.Begin();
						end = Ends2.Begin();
						tick2 = WmDOT.GetTick();
						local WBCTries = 0;
						local WBCResults;
							
						while (KeepTrying2 == true) {
							Log.Note("WBC:: start: " + Array.ToStringTiles1D([start]) + "  -> end: " + Array.ToStringTiles1D([end]), 5);
							WBC.InitializePath([start], [end]);
							WBC.PresetSafety(start, end);
							WBCResults = WBC.FindPath(-1);
							WBCTries ++;
							if (WBCResults != null) {
								Log.Note("Waterbody Check returns positive. Took " + WBCTries + " tries and " + (WmDOT.GetTick() - tick2) + " ticks.",3);
								KeepTrying2 = false;
							} else if (Starts2.IsEnd()) {
							//	this tree will test all pairs of starts and ends
								if (Ends2.IsEnd()) {
									Log.Note("Waterbody Check returns negative. Took " + WBCTries + " tries and " + (WmDOT.GetTick() - tick2) + " ticks.",3);
									KeepTrying2 = false;
								} else {
									Starts2 = OldStarts2;
									start = Starts2.Begin();
									end = Ends2.Next();
								}
							} else {
								start = Starts2.Next();
							}
						}

						if (WBCResults != null) {
							///	Run Ship Pathfinder, and build buoys
							tick2 = WmDOT.GetTick();
							local Pathfinder = MetaLib.ShipPathfinder();
							Pathfinder.InitializePath([start], [end]);
							//	Ship Pathfinder must be given a single start tile and a
							//		single end tile
							//	Tell the pathfinder to skip Waterbody Check
							Pathfinder.OverrideWBC()
							local SPFResults = Pathfinder.FindPath(-1);
							
							if (SPFResults != null) {
								Log.Note("Ship Pathfinder returns positive. Took " + (WmDOT.GetTick() - tick2) + " ticks.",3);
								
								//	Build Buoys
								local NumberOfBuoys = Pathfinder.CountPathBuoys();
								Log.Note(NumberOfBuoys + " buoys may be needed.", 5);
								
								//	request funds for Buoys
								//	request funds for Depots
								Money.FundsRequest((AIMarine.GetBuildCost(AIMarine.BT_BUOY) * NumberOfBuoys) + (AIMarine.GetBuildCost(AIMarine.BT_DEPOT) * 2));
								Pathfinder.BuildPathBuoys();
								SPFResults = Pathfinder.GetPath();
								
								//	Build Depots						
								local Depot1 = Marine.BuildDepot(start, MetaLib.Extras.NextCardinalTile(BuildPair[0], BuildPair[1]));
								local Depot2 = Marine.BuildDepot(end, MetaLib.Extras.NextCardinalTile(BuildPair[1], BuildPair[0]));
								Log.Note("Depots at" + Array.ToStringTiles1D([Depot1, Depot2]), 4);
								
								//	TO-DO:	Do something if neither depot could be built
								//	TO-DO:	Build Depots in the middle if the path is extra long
								if ((Depot1 == null) && (Depot2 != null)) {
									Depot1 = Depot2;
								}
								
								//	Pick an engine (ship)
								//	TO-DO: More sophisicated engine selection; weight all the factors at once
								local Engines = AIEngineList(AIVehicle.VT_WATER);
								Log.Note("Start with " + Engines.Count() + " engines.", 5);
								
								//	Keep only buildable engines
								Engines.Valuate(AIEngine.IsBuildable);
								Engines.KeepValue(true.tointeger());
								Log.Note("Only " + Engines.Count() + " are buildable.", 5);
								
								//	TO-DO:	Keep only engines we can afford  -  AIEngine.GetPrice(EngineID)
								
								//	Keep only ships for this cargo
								Engines.Valuate(AIEngine.CanRefitCargo, CargoNo);
								Engines.KeepValue(true.tointeger());
								Log.Note("Only " + Engines.Count() + " can carry " + AICargo.GetCargoLabel(CargoNo) + ".", 5);
								
								//	Keep only ships under max capacity
								//		"In case it can transport multiple cargoes, it returns the first/main."
								local MaxCargo = (AIIndustry.GetLastMonthProduction(MetaLib.Industry.GetIndustryID(BuildPair[0]), CargoNo) * this._CapacityDays)/30;
								Engines.Valuate(AIEngine.GetCapacity);
								Engines.RemoveAboveValue(MaxCargo);
								Log.Note("Only " + Engines.Count() + " have capacity below " + MaxCargo + ". (" + AIIndustry.GetLastMonthProduction(MetaLib.Industry.GetIndustryID(BuildPair[0]), CargoNo) + " * " + this._CapacityDays + " / 30)", 5);
								
								//	Pick the fastest one
								Engines.Valuate(AIEngine.GetMaxSpeed);
								Engines.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
								
								if (Engines.Count() > 0) {
									local PickedEngine = Engines.Begin();
									Log.Note("Picked engine: " + PickedEngine + " : " + AIEngine.GetName(PickedEngine), 3);
									
									//	Build Ship and give it orders
									//	request funds for Ship
									local CostShip = AIEngine.GetPrice(PickedEngine);								
									//	TO-DO: Provide for retrofit costs
									local KeepTrying4 = true;
									local UnfilledCapacity = MaxCargo;
									local MyVehicle;
									local FirstVehicle = null;
									while (KeepTrying4) {
										Money.FundsRequest(CostShip * 1.1);
										MyVehicle = AIVehicle.BuildVehicle(Depot1, PickedEngine);
										if (AIVehicle.IsValidVehicle(MyVehicle)) {
											AIVehicle.RefitVehicle(MyVehicle, CargoNo);
											UnfilledCapacity -= AIVehicle.GetCapacity(MyVehicle, CargoNo);
											Log.Note("Added Vehicle № " + MyVehicle + "; remaining capacity = " + UnfilledCapacity + ".", 4);
											
											///	Give Orders!
											if (FirstVehicle == null) {
												FirstVehicle = MyVehicle;
												//	start station; full load here
												AIOrder.AppendOrder(MyVehicle, AIIndustry.GetDockLocation(MetaLib.Industry.GetIndustryID(BuildPair[0])), AIOrder.OF_FULL_LOAD);
												Log.Note("Order (Start): " + MyVehicle + " : " + Array.ToStringTiles1D([AIIndustry.GetDockLocation(MetaLib.Industry.GetIndustryID(BuildPair[0]))]) + ".", 5);
												//	buoys
												for (local i = 0; i < SPFResults.len(); i++) {
													AIOrder.AppendOrder(MyVehicle, SPFResults[i], AIOrder.OF_NONE);
													Log.Note("Order: " + MyVehicle + " : " + Array.ToStringTiles1D([SPFResults[i]]) + ".", 5);
												}
												//	end station
												AIOrder.AppendOrder(MyVehicle, DockLocation, AIOrder.OF_NONE);
												Log.Note("Order (End): " + MyVehicle + " : " + Array.ToStringTiles1D([DockLocation]) + ".", 5);
												//	buoys, but backwards
												for (local i = SPFResults.len() - 1; i >= 0; i--) {
													AIOrder.AppendOrder(MyVehicle, SPFResults[i], AIOrder.OF_NONE);
													Log.Note("Order: " + MyVehicle + " : " + Array.ToStringTiles1D([SPFResults[i]]) + ".", 5);
												}
												
												// send it on it's merry way!!!
												AIVehicle.StartStopVehicle(MyVehicle);
												
											} else {
												AIOrder.ShareOrders(MyVehicle, FirstVehicle);
												Log.Note("Order: Shared from " + FirstVehicle + " to " + MyVehicle + ".", 5);
												AIVehicle.StartStopVehicle(MyVehicle);
											}
											
											if (UnfilledCapacity < AIVehicle.GetCapacity(MyVehicle, CargoNo)) {
												KeepTrying4 = false;
											}
										} else {
											Log.Note("Vehicle Building failed!!", 4);
											KeepTrying4 = false;
										}
									}

								} else {
									Log.Note("No engine matches criteria.", 3);
								}
								
							} else {
								Log.Note("Ship Pathfinder returns negative. Took " + (WmDOT.GetTick() - tick2) + " ticks.",3);
							}
							///	Build one ship on path, and turn over to Ship Route Manager
							
							KeepTrying = false;
						} else {
							Log.Note("Waterbody Check returns negative. Took " + (WmDOT.GetTick() - tick2) + " ticks.",3);
							// try another path
							KeepTrying = true;
						}
					}
				}
			}
		}	// end of foreach(CargoNo in MyCargos)
	} else {
		Log.Warning("No Industries to work with.");
	}
	
//	Sleep for three months after last OpHibernia run, or a month after the last
//		ship was added, or ignore if we have no debt
	this._NextRun = WmDOT.GetTick() + 6500*this._SleepLength/365;	//	Approx. three months
	Log.Note("OpHibernia finished. Took " + (WmDOT.GetTick() - tick) + " ticks.",2);
	
	return;
}