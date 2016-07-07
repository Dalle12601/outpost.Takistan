//Main function resposible for spawning compositions

//[ COMP_NAME, POS_ATL, OFFSET, DIR, ALIGN_TERRAIN ] call LARs_fnc_spawnComp;

//COMP_NAME - Classname given to composition in missionConfigFile CfgCompositions

//POS_ATL( optional ) - Position to spawn composition
//	If not given or empty array passed then original saved composition position is used
//	Also accepts OBJECT, MARKER, LOCATION

//OFFSET( optional ) - ARRAY [ x, y, z ] ammount to offset composition, as a compositions base pos can vary from what you want when its saved

//DIR( optional ) - Direction to face composition in, If POS_ATL is of type OBJECT, MARKER, LOCATION passing TRUE for direction will use objects direction

//ALIGN_TERRAIN( optional ) - BOOL, Whether composition objects should align themselves to their positions surface normal

#define DEBUG_DEV getNumber( missionConfigFile >> "LARs_spawnComp_debug" ) isEqualTo 2
#define DEBUG getNumber( missionConfigFile >> "LARs_spawnComp_debug" ) isEqualTo 1 || DEBUG_DEV
#define DEBUG_MSG( COND, MSG ) if ( COND ) then { diag_log MSG }

private [ "_groupCfgs", "_itemCfgs", "_deferedIDs", "_deferedItems", "_deferedGrps", "_deferedTrgs", "_crewLinks", "_objects", "_priority", "_ids", "_inits", "_nul" ];

params[
	"_compName",
	[ "_compPos", [] ],
	[ "_compOffset", [0,0,0] ],
	[ "_compRot", 0 ],
	[ "_compAlign", true ],
	[ "_compWater", true ]
];

_msg = format[ "COMP - Name: %1, Pos:%2, Offset: %3, Rot: %4, Align: %5", _compName, _compPos, _compOffset, _compRot, _compAlign ];
DEBUG_MSG( DEBUG, _msg );

_asPlaced = false;

switch ( true ) do {
	//Get original composition position
	case ( _compPos isEqualType [] && { count _compPos isEqualTo 0 } ) : {
		_compPos = getArray( missionConfigFile >> "CfgCompositions" >> _compName >> "center" );
		_compPos = [ _compPos select 0, _compPos select 2, _compPos select 1 ];
		_asPlaced = true;
	};
	//Get position of a specified OBJECT
	case ( _compPos isEqualType objNull ) : {
		if ( _compRot isEqualType true ) then {
			_compRot = getDirVisual _compPos;
		};
		_compPos = getPosASLVisual _compPos;
	};
	//Get position of a MARKER
	case ( _compPos isEqualType "" && { getMarkerPos _compPos != [0,0,0] } ) : {
		if ( _compRot isEqualType true ) then {
			_compRot = markerDir _compPos;
		};
		_compPos = ATLToASL getMarkerPos _compPos;
	};
	//Get position of a LOCATION
	case ( _compPos isEqualType locationNull ) : {
		if ( _compRot isEqualType true ) then {
			_compRot = direction _compPos;
		};
		_compPos = ATLToASL locationPosition _compPos;
	};
	default {
		_compPos = ATLToASL _compPos;
	};
};

if ( DEBUG_DEV ) then {
	createVehicle [ "Sign_Arrow_Large_Green_F", _compPos, [], 0, "CAN_COLLIDE" ];
	_arrow = createVehicle [ "Sign_Arrow_Direction_Green_F", _compPos vectorAdd [ 0, 0, 3 ], [], 0, "CAN_COLLIDE" ];
	_arrow setDir _compRot;
};

_groupCfgs = [];
_itemCfgs = [];

_deferedIDs = [];
_deferedItems = [];
_deferedGrps = [];
_deferedTrgs = [];

_crewLinks = [];

_objects = [];

_priority = [ "Marker", "Object", "Group", "Waypoint", "Trigger", "Logic" ];

private _fnc_sortCfgItems = {
	private[ "_dataType" ];
	params[ "_cfg", [ "_groupID", -1 ], [ "_groupCfg", configNull ], [ "_toDefer", false ] ];

	{
		_dataType = getText( _x >> "dataType" );
		
		_id = getNumber( _x >> "id" );
		if ( count _objects <= _id ) then {
			_objects resize _id;
		};

		_nul = _objects set [ _id, [ _id, _x, _dataType, _groupID, _groupCfg ] ];

		switch ( _dataType ) do {
			case "Layer" : {
				[ ( _x >> "Entities" ) ] call _fnc_sortCfgItems;
			};
			case "Group" : {
				if !( isClass( _x >> "crewLinks" ) ) then {
					_nul = _groupCfgs pushBack _x;
				}else{
					_nul = _deferedIDs pushBackUnique _id;
					_nul = _deferedGrps pushBack _x;
					[ ( _x >> "Entities" ), _id, _x, true ] call _fnc_sortCfgItems;
					//[ ( _x >> "CrewLinks" ) ] call _fnc_deferLinks;
				};
			};
			default {
				if !( _toDefer ) then {
					_nul = _itemCfgs pushBack _x;
				}else{
					_nul = _deferedIDs pushBackUnique _id; 
					//_nul = _deferedItems pushBack _x;
				};
			};
		};
	}forEach ( "true" configClasses _cfg );

};

[ ( missionConfigFile >> "CfgCompositions" >> _compName >> "items" ) ] call _fnc_sortCfgItems;

private _fnc_deferLinks = {
	private[ "_item0ID", "_item1ID", "_item0Info", "_item1Info", "_linkType" ];
	params[ "_cfg" ];

	{
		
		//Connections
		//RandomStartPos = Man and Marker
		//WaypointActivation = Waypoint and Waypoint OR Waypoint and Trigger
		//Sync
		//[ "marker", "object", "group", "waypoint", "trigger", "logic" ]
		
		_item0ID = getNumber( _x >> "item0" );
		_item1ID = getNumber( _x >> "item1" );

		//[ _id, _cfg, _dataType, _groupID, _groupCfg ]
		_item0Info = _objects select _item0ID;
		_item1Info = _objects select _item1ID;

		if ( !isNil "_item0Info" && !isNil "_item1Info" ) then {
		
			switch ( toUpper ( configName _cfg ) ) do {
				case ( "CONNECTIONS" ) : {
					_linkType = getText( _x >> "customData" >> "type" );
					switch ( _linkType ) do {
						
						case "WaypointActivation" : {
							if ( { ( _x select 2 ) isEqualTo "Trigger" }count[ _item0Info, _item1Info ] > 0 ) then {
								{
									_x params[ "_id", "_cfg", "_type" ];
									if ( _type isEqualTo "Trigger" ) exitWith {
										_itemCfgs = _itemCfgs - [ _cfg ];
										_nul = _deferedIDs pushBackUnique _id;
										_nul = _deferedItems pushBackUnique _cfg;
									};
								}forEach [ _item0Info, _item1Info ];
							}else{
								_nul = _deferedIDs pushBackUnique _item0ID;
								_nul = _deferedItems pushBackUnique ( _item0Info select 1 ); 
							};
						};
						
						case "RandomStart" : {
							{
								_x params[ "_id", "_cfg", "_type", "_groupID", "_groupCfg" ];
								if ( _type isEqualTo "Object" ) exitWith {
									if !( isNull _groupCfg ) then {
										_groupCfgs = _groupCfgs - [ _groupCfg ];
										_nul = _deferedIDs pushBackUnique _groupID;
										_nul = _deferedGrps pushBackUnique _groupCfg;
									}else{
										_itemCfgs = _itemCfgs - [ _cfg ];
										_nul = _deferedIDs pushBackUnique _id;
										_nul = _deferedItems pushBackUnique _cfg;
									};
								};
							}forEach [ _item0Info, _item1Info ];
						};
						
						case "Sync" : {
							private[ "_item" ];
							_itemPriority = [ 0, 0 ];
							{
								_x params[ "_id", "_cfg", "_type" ];
								_itemPriority set [ _forEachIndex, _priority find _type ];
							}forEach [ _item0Info, _item1Info ];
							_item = [ _item0Info, _item1Info ] select ( _itemPriority select 1 < ( _itemPriority select 0 ) );
							_item params[ "_id", "_cfg", "_type", "_groupID", "_groupCfg" ];
							if ( _groupID > -1 ) then {
								_groupCfgs = _groupCfgs - [ _groupCfg ];
								_nul = _deferedIDs pushBackUnique _groupID;
								_nul = _deferedGrps pushBackUnique _groupCfg;
							}else{
								_itemCfgs = _itemCfgs - [ _cfg ];
								_nul = _deferedIDs pushBackUnique _id;
								_nul = _deferedItems pushBackUnique _cfg;
							};
						};
						
						case "TriggerOwner" : {
							private[ "_owner" ];
							//FIXME: triggerOwner is currently broken in stable branch
							//TODO: attached trigger types activationByOwner and its variants - needs proper testing hopefully handled by connections
							{
								_x params[ "_id", "_cfg", "_type", "_groupID", "_groupCfg" ];
								if ( _type isEqualTo "Trigger" ) exitWith {
									_owner = [ _item0Info, _item1Info ] - ( [ _item0Info, _item1Info ] select _forEachIndex );
									_itemCfgs = _itemCfgs - [ _cfg ];
									_nul = _deferedIDs pushBackUnique _id;
									_nul = _deferedTrgs pushBackUnique _cfg;
								};
							}forEach [ _item0Info, _item1Info ];
						};
						
					};
				};
				
//				case ( "CREWLINKS" ) :{
//					//If a Group has crewLinks then it and its units are defered
					//so will not spawn until after vehicle is done see connections
//				};
			};
		};
		

	}forEach ( "true" configClasses ( _cfg >> "Links" ));

};

//add connections to deferedIDs
if ( isClass( missionConfigFile >> "CfgCompositions" >> _compName >> "connections" ) ) then {
	[ ( missionConfigFile >> "CfgCompositions" >> _compName >> "connections" ) ] call _fnc_deferLinks;
};


private _fnc_setPositionAndRotation = {
	private[ "_pos", "_newPosX", "_newPosY", "_newPosASL", "_newPosZ", "_rotation", "_mkrPos" ];
	params[
		[ "_obj", objNull ],
		[ "_cfgOffset", [0,0,0] ],
		[ "_cfgRot", [0,0,0] ],
		[ "_ATLOffset", 0 ],
		[ "_randomStartPos", [] ],
		[ "_needsSurfaceUp", false ],
		[ "_placementRadius", 0 ]
	];
	
	//TESTING
//	if ( DEBUG_DEV ) then {
//		if !( canSuspend ) exitWith {
//			_this spawn _fnc_setPositionAndRotation;
//		};
//	};	
		
	_cfgOffset = [ _cfgOffset select 0, _cfgOffset select 2 , _cfgOffset select 1 ];
	_cfgOffset = [ _cfgOffset, 360 - _compRot ] call BIS_fnc_rotateVector2D;
	_cfgOffset = _cfgOffset vectorAdd ( [ _compOffset, 360 - _compRot ] call BIS_fnc_rotateVector2D ) ;
	
	if ( _compAlign && !_asPlaced ) then {
		_newPosX = ( _compPos select 0 ) + ( _cfgOffset select 0 );
		_newPosY = ( _compPos select 1 ) + ( _cfgOffset select 1 );
		_newPosASL = getTerrainHeightASL [ _newPosX, _newPosY ];
		_newPosZ = _newPosASL + ( _cfgOffset select 2 );
//		if ( _asPlaced ) then {
//			_pos = [ _newPosX, _newPosY, _newPosZ + _ATLOffset ];
//		}else{
			_pos = [ _newPosX, _newPosY, _newPosZ ];
//		};
	}else{
		_pos = ( _compPos vectorAdd _cfgOffset ) vectorAdd [ 0, 0, _ATLOffset ];
	};
	
	if ( count _randomStartPos > 0 ) then {
		_randomStartPos = _randomStartPos  apply { 
			_mkrPos = ATLToASL getMarkerPos _x;
			_mkrPos = _mkrPos vectorAdd [ 0, 0, abs( boundingBoxReal _obj select 0 select 2 ) ];
			_mkrPos
		};
		_pos = selectRandom ( [ _pos ] + _randomStartPos );
	};
	
	if ( _placementRadius > 0 ) then {
		_pos = AGLToASL ( _pos getPos [ random _placementRadius, random 360 ] );
		_pos = _pos vectorAdd [ 0, 0, abs( boundingBoxReal _obj select 0 select 2 ) ];
	};
	
	if ( surfaceIsWater _pos && _compWater && !_asPlaced ) then {
		_pos = [ _pos select 0, _pos select 1, 0 + ( _cfgOffset select 2 ) + ( _compOffset select 2 ) ];
	};
	
	if ( DEBUG_DEV ) then {
		//OBJECT composition pos + offset + atl offset
		createVehicle [ "Sign_Arrow_Yellow_F", ASLToATL ( ( _compPos vectorAdd _cfgOffset ) vectorAdd [ 0, 0, _ATLOffset ] ), [], 0, "CAN_COLLIDE" ];
		//OBJECT calculated final position
		createVehicle [ "Sign_Arrow_Green_F", ASLToATL _pos, [], 0, "CAN_COLLIDE" ];
	};
	
		
	if !( isNull _obj ) then {
		
		//Move object to its world position
		_obj setPosWorld _pos;

		//Turn composition angles to degrees
		_CfgRot params[ "_P", "_Y", "_R" ];
		
		_Y = ( deg _Y ) + _compRot;
		_P = deg _P;
		_R = 360 - deg _R;
		
		//If Aliging composition or its a vehicle that needs surface up
		_pb = if ( ( _compAlign || _needsSurfaceUP ) && !( surfaceIsWater _pos && _compWater ) && !_asPlaced ) then {
			//Face it in the right direction
			_obj setDir _Y;
			//Get positions surface up
			_up = surfaceNormal _pos;
						
			//Get bound corner surface ups
			_bounds = boundingBoxReal _obj;
			_bounds params[ "_mins", "_maxs" ];
			_mins params[ "_minX", "_minY", "_minZ" ];
			_maxs params[ "_maxX", "_maxY" ];
			
			//Calculate up based on corner surface normals
			_newUp = _up;
			{
				_cornerPos = _obj modelToWorldVisual _x;
				_cornerUp = surfaceNormal _cornerPos;
				_weight = _pos distance _cornerPos; 
				_diff = ( _up vectorDiff _cornerUp ) vectorMultiply _weight;
				_newUp = _newUp vectorAdd _diff;
			}forEach [
				[ _minX, _minY, _minZ ],
				[ _minX, _maxY, _minZ ],
				[ _maxX, _maxY, _minZ ],
				[ _maxX, _minY, _minZ ]
			];
			
			_obj setVectorUp vectorNormalized _up;
			
			_obj call BIS_fnc_getPitchBank
		}else{
			[ 0, 0 ]
		};
		
		//Add any surface offset to composition rotations
		_pb params[ "_pbP", "_pbR" ];

		_P = _P + _pbP;
		_R = _R + _pbR;

		//Make sure rotations are in 0 - 360 range
		{
			_deg = call compile format [ "%1 mod 360", _x ];
			if ( _deg < 0 ) then {
				_deg = linearConversion[ -0, -360, _deg, 360, 0 ];
			};
			call compile format[ "%1 = _deg", _x ];
		}forEach [ "_P", "_R", "_Y" ];

		//Calculate Dir and Up
		_dir = [ sin _Y * cos _P, cos _Y * cos _P, sin _P];
		_up = [ [ sin _R, -sin _P, cos _R * cos _P ], -_Y ] call BIS_fnc_rotateVector2D;
		
		//Set Object rotation
		_obj setVectorDirAndUp [ _dir, _up ];

		//enable simulation		
		if !( simulationEnabled _obj ) then {
			_obj enableSimulationGlobal true;
		};

	};
	
	_pos
};

//private _fnc_getRotation = {
//	params[ "_CfgRot", "_obj" ];
//
//	
//	_CfgRot params[ "_P", "_Y", "_R" ];
//	_Y = ( ( deg _Y ) + _compRot );
//	_P = ( deg _P );
//	_R = ( deg _R );
//	
//	_cfgDir = [ sin _Y * cos _P, cos _Y * cos _P, sin _P];
//	_cfgUp = [ [ sin _R, -sin _P, cos _R * cos _P ], -_Y ] call BIS_fnc_rotateVector2D;
//	
//	_obj setVectorDirAndUp [ _cfgDir, _cfgUp ];
//	
//};

private _fnc_CustomAttributes = {
	private[ "_property", "_expression", "_split", "_valueType", "_value", "_header" ];
	params[ "_obj", "_cfg" ];
	
	{
		_property = getText( _x >> 'property' );
		_expression = getText( _x >> 'expression' );
		if ( _expression find "%s" > -1 ) then {
			_split = _expression splitString "%s";
			_expression = format[ "%1%2%3", _split select 0, _property, _split select 2 ]; //TODO: does property need passing as STRING? dont think so
		};
		_valueType = getArray( _x >> 'Value' >> 'data' >> 'type' >> 'type' );
		switch ( _valueType select 0 ) do {
			case 'STRING' : {
				_value = getText( _x >> 'Value' >> 'data' >> 'value' );
			};
			case 'SCALAR' : {
				_value = getNumber( _x >> 'Value' >> 'data' >> 'value' );
			};
			case 'BOOL' : {
				_value = [ false, true ] select getNumber( _x >> 'Value' >> 'data' >> 'value' );
			};
			case 'ARRAY' : {
				_value = getArray( _x >> 'Value' >> 'data' >> 'value' );
			};
		};
		_header = "params[ '_this', '_value' ];";
		[ _obj, _value ] call compile format[ "%1%2", _header, _expression ];
	}forEach ( "true" configClasses ( _cfg >> 'CustomAttributes' ) );
};

_ids = [];
_inits = [];

private _fnc_getCfgValue = {
	private[ "_value" ];
	params[ "_cfg", "_type", "_default" ];
	
	switch ( toUpper _type ) do {
		case "NUM" : {
			_value = if ( isNumber( _cfg ) ) then {
				getNumber( _cfg )
			}else{
				if !( isNil "_default" ) then {
					_default
				}else{
					0
				};
			};
		};
		case "BOOL" : {
			_value = if ( isNumber( _cfg ) ) then {
				[ false, true ] select ( getNumber( _cfg ) ) 
			}else{
				if !( isNil "_default" ) then {
					_default
				}else{
					true
				};
			};
		};
		case "TXT" : {
			_value = if ( isText( _cfg ) ) then {
				getText ( _cfg ) 
			}else{
				if !( isNil "_default" ) then {
					_default
				}else{
					""
				};
			};
		};
		case "ARRAY" : {
			_value = if ( isArray( _cfg ) ) then {
				getArray ( _cfg ) 
			}else{
				if !( isNil "_default" ) then {
					_default
				}else{
					[]
				};
			};
		};
	};
	
	_value
};

private _fnc_getUnitInventory = {
	private[ "_invCfg", "_loadout" ];
	params[ "_invCfg", "_unit" ];
		
	_loadout = [];
	
	//Weapons
	private _fnc_getWeaponDetails = {
		private[ "_weaponCfg" ];
		params[ "_weapon" ];
		
		_weaponCfg = _invCfg >> _weapon;
		
		[
			getText( _weaponCfg >> "name" ),
			getText( _weaponCfg >> "muzzle" ),
			getText( _weaponCfg >> "flashlight" ),
			getText( _weaponCfg >> "optics" ),
			[
				getText( _weaponCfg >> "primaryMuzzleMag" >> "name" ),
				getNumber( _weaponCfg >> "primaryMuzzleMag" >> "ammoLeft" )
			],
			[
				getText( _weaponCfg >> "secondaryMuzzleMag" >> "muzzle" ),
				getNumber( _weaponCfg >> "secondaryMuzzleMag" >> "ammoLeft" )
			],
			getText( _weaponCfg >> "underBarrel" )
		]
	
	};
	
	{
		_nul = _loadout pushBack ( _x call _fnc_getWeaponDetails );
	}forEach [ "primaryWeapon", "secondaryWeapon", "handgun" ];

	
	//Containers
	private _fnc_getContainerDetails = {
		params[ "_container" ];
		
		_containerCfg = _invCfg >> _container;
		
		_containerType = getText( _containerCfg >> "typeName" );
		_items = [];
		{
			_cargoType = _x;
			{
				if ( _cargoType isEqualTo "MagazineCargo" ) then {
					_nul = _items pushBack [ getText( _x >> "name" ), getNumber( _x >> "ammoLeft" ), getNumber( _x >> "count" ) ];
				}else{
					_nul = _items pushBack [ getText( _x >> "name" ), getNumber( _x >> "count" ) ];
				};
			}forEach ( "true" configClasses ( _containerCfg >> _cargoType ));
		}forEach [ "MagazineCargo", "ItemCargo" ];
		
		[ _containerType, _items ]
	};
	
	{
		_nul = _loadout pushBack ( _x call _fnc_getContainerDetails );
	}forEach [ "uniform", "vest", "backpack" ];
		
	_nul = _loadout pushBack getText( _invCfg >> "headgear" );
	_nul = _loadout pushBack getText( _invCfg >> "goggles" );
	_nul = _loadout pushBack ( "binocular" call _fnc_getWeaponDetails );
	
	//linked Items
	_nul = _loadout pushBack [
		getText( _invCfg >> "map" ),
		getText( _invCfg >> "gps" ),
		getText( _invCfg >> "radio" ),
		getText( _invCfg >> "compass" ),
		getText( _invCfg >> "watch" ),
		getText( _invCfg >> "hmd" )
	];
	
	_unit setUnitLoadout _loadout;
};

//******
// OBJECT TYPES
//******

private _fnc_spawnGroup = {
	private[ "_side", "_group", "_combatMode", "_behaviour", "_speedMode", "_formation" ];
	params[ "_cfg" ];
	
	_side = getText( _cfg >> "Side" );
	_group = call compile format[ "createGroup %1", _side ];
	
	_combatMode = getText( _cfg >> "Attributes" >> "combatMode" );
	_behaviour = getText( _cfg >> "Attributes" >> "behaviour" );
	_speedMode = getText( _cfg >> "Attributes" >> "speedMode" );
	_formation = getText( _cfg >> "Attributes" >> "formation" );
	_group setCombatMode _combatMode;
	_group setBehaviour _behaviour;
	_group setSpeedMode _speedMode;
	_group setFormation _formation;
	
	{
		[ _x, _group ] call _fnc_spawnItems;
	}forEach ( "true" configClasses ( _cfg >> "Entities" ) );
	
	//DO we want to fix placement spawning of whole groups ????
//	{
//		_x setPosATL formationPosition _x;
//	}forEach units _group;
	
	//Save crewLinks until everything is spawned
	if ( isClass( _cfg >> "crewLinks" ) ) then {
		private[ "_unitID", "_vehID", "_role", "_turret", "_cargoIndex" ];
		{
			
			_unitID = getNumber( _x >> 'item0' );
			_vehID = getNumber( _x >> 'item1' );
			_role = getNumber( _x >> 'customData' >> 'role' );
			_turret = getArray( _x >> 'customData' >> 'turretPath' );
			_cargoIndex = [ ( _x >> 'customData' >> 'cargoIndex' ), 'NUM', -1 ] call _fnc_getCfgValue;
			
			_nul = _crewLinks pushBack [ _unitID, _vehID, _role, _turret, _cargoIndex ];
		
		}forEach ( "true" configClasses ( _cfg >> "crewLinks" >> "Links" ));
	};
	
	_group
};

private _fnc_spawnObject = {
	private [ "_veh", "_isFlying", "_presence", "_preCondition", "_needsSurfaceUP" ];
	params[ "_cfg", "_group" ];
	
	_veh = objNull;
	_isFlying = false;
	_needsSurfaceUP = false;
	
	_presence = [ ( _cfg >> "Attributes" >> "presence" ), "NUM", 1 ] call _fnc_getCfgValue;
	_preCondition = [ ( _cfg >> "Attributes" >> "presenceCondition" ), "TXT", "true" ] call _fnc_getCfgValue; //TODO: does this need defering
	
	if ( random 1 <= _presence && { call compile _preCondition } ) then {
		private[ "_type", "_ATLOffset" ];
		
		_type = getText( _cfg >> "type" );
		
		_ATLOffset = getNumber( _cfg >> "atlOffset" );
				
		switch ( true ) do {
			
			case ( _type isKindOf "Man" ) : {
				private[ "_skill", "_rank" ];
				
				_veh = _group createUnit [ _type, [0,0,500], [], 0, "FORM" ];
				_veh enableSimulationGlobal false;
			
				_skill = [ ( _cfg >> "Attributes" >> "skill" ), "NUM", -1 ] call _fnc_getCfgValue;
				if ( _skill > -1 ) then {
					_veh setSkill _skill;
				};
				
				_rank = getText( _cfg >> "Attributes" >> "rank" );
				if !( _rank isEqualTo "" ) then {
					_veh setRank _rank;
				};
				
				if ( isClass( _cfg >> "Attributes" >> "Inventory" ) ) then {
					[ _cfg >> "Attributes" >> "Inventory", _veh ] call _fnc_getUnitInventory;
				};

			};
		
			case ( _type isKindOf "LandVehicle" ) : {
				private[ "_lock", "_fuel" ];
				
				_veh = createVehicle [ _type, [0,0,500], [], 0, "CAN_COLLIDE" ];
				_veh enableSimulationGlobal false;
				
				_lock = getText( _cfg >> "Attributes" >> "lock" );
				if !( _lock isEqualTo "" ) then {
					_veh setVehicleLock _lock
				};
				
				_fuel = [ ( _cfg >> "Attributes" >> "fuel" ), "NUM", 1 ] call _fnc_getCfgValue;
				_veh setFuel _fuel;
				
				_needsSurfaceUP = true;
			};
			
			case ( _type isKindOf "Air" ) : {
				private[ "_lock", "_fuel" ];
				
				_isFlying = _ATLOffset > 18;
				
				_veh = createVehicle [ _type, [0,0,500], [], 0, [ "NONE", "FLY" ] select _isFlying ];
				_veh enableSimulationGlobal false;
				
				_lock = getText( _cfg >> "Attributes" >> "lock" );
				if !( _lock isEqualTo "" ) then {
					_veh setVehicleLock _lock
				};
				
				_fuel = [ ( _cfg >> "Attributes" >> "fuel" ), "NUM", 1 ] call _fnc_getCfgValue;
				_veh setFuel _fuel;
				
				if ( _isFlying ) then {
					_veh engineOn true;
				}else{
					_needsSurfaceUP = true;
				};
				
			};
			
			default {
				_veh = createVehicle [ _type, [0,0,500], [], 0, "CAN_COLLIDE" ];
				_veh enableSimulationGlobal false;
			};
		};
		
		if ( DEBUG_DEV ) then {
			[ _veh, [ 1, 0, 0, 1 ] ] call LARs_fnc_drawBounds;
		};
		
		private[ "_health", "_ammo", "_name", "_texture" ];
		
		_health = [ ( _cfg >> "Attributes" >> "health" ), "NUM", 1 ] call _fnc_getCfgValue;
		_veh setDamage ( 1 - _health );
		
		_ammo = [ ( _cfg >> "Attributes" >> "ammo" ), "NUM", 1 ] call _fnc_getCfgValue;
		_veh setVehicleAmmo _ammo;
		
		_name = getText( _cfg >> "Attributes" >> "name" );
		if !( _name isEqualTo "" ) then {
			_veh setVehicleVarName _name;
			missionNamespace setVariable [ _name, _veh ];
		};
		
		
		_texture = getText( _cfg >> "Attributes" >> "textures" );
		if !( _texture isEqualTo "" ) then {
			_veh setObjectTextureGlobal [ 0, _texture ];
		};
		
		private[ "_randomStartPos", "_position", "_rotation", "_placementRadius", "_init" ];
		
		_position = getArray( _cfg >> "PositionInfo" >> "position" );
		_rotation = [ ( _cfg >> "PositionInfo" >> "angles" ), "ARRAY", [0,0,0] ] call _fnc_getCfgValue;
		_randomStartPos = getArray( _cfg >> "randomStartPositions" );
		_placementRadius = getNumber( _cfg >> "Attributes" >> "placementRadius" );
		
		_position = [ _veh, _position, _rotation, _ATLOffset, _randomStartPos, _needsSurfaceUP, _placementRadius ] call _fnc_setPositionAndRotation;

		
		if ( typeOf _veh isKindOf "Man" ) then {
			( waypoints ( group _veh )) select 0 setWaypointPosition [ getPos _veh, 0 ];
		}; 
		
		_init = getText( _cfg >> "Attributes" >> "init" );
		if !( _init isEqualTo "" ) then {
			_nul = _inits pushBack [ _veh, format[ "this = _this; %1", _init ] ];
		};
						
	};
	
	_veh
	
};

private _fnc_spawnTrigger = {
	private[ "_type", "_position", "_ATLOffset", "_rotation", "_varName", "_description", "_condition",
	"_onActivation", "_onDeactivation", "_sizeA", "_sizeB", "_sizeC", "_timeout", "_interuptable", "_repeatable" ];
	params[ "_cfg", [ "_defered", false ] ];
	
	//FIX for default grpNull passed from spawnItems
	if ( _defered isEqualType grpNull ) then { _defered = false };
	
	_type = getText( _cfg >> "type" );
	_position = getArray( _cfg >> "position" );
	_rotation = getNumber( _cfg >> "angle" );
	_ATLOffset = getNumber( _cfg >> "atlOffset" );
			
	_varName = getText( _cfg >> "Attributes" >> "name" );
	_description = getText( _cfg >> "Attributes" >> "text" );
	_condition = if !( _defered ) then {
		[ ( _cfg >> "Attributes" >> "condition" ), "TXT", "this" ] call _fnc_getCfgValue
	}else{
		//If trigger is defered due to connections TriggerOwner
		//set its condition to false until after connections are made
		"false"
	};
	_onActivation = getText( _cfg >> "Attributes" >> "onActivation" );
	_onDeactivation = getText( _cfg >> "Attributes" >> "onDeactivation" );
	_sizeA = getNumber( _cfg >> "Attributes" >> "sizeA" );
	_sizeB = getNumber( _cfg >> "Attributes" >> "sizeB" );
	_sizeC = getNumber( _cfg >> "Attributes" >> "sizeC" ); 
	_timeout = [ ( _cfg >> "Attributes" >> "timeout" ), "ARRAY", [ 0, 0, 0 ] ] call _fnc_getCfgValue;
	_interuptable = [false, true] select getNumber( _cfg >> "Attributes" >> "interuptable" );
	_repeatable = [false, true] select getNumber( _cfg >> "Attributes" >> "repeatable" );
	
	private[ "_activationBy", "_trig_type", "_isRectangle", "_effectCondition", "_effectSound", "_effectVoice", "_effectSoundEnvironment", "_effectSoundTrigger", "_effectMusic", "_effectTitle", "_trg" ];

//TODO: Hopefully done see connections TriggerOwner
	//Default to NONE if not defined it could possibly be waiting on a connection TriggerOwner
	_activationBy = [ ( _cfg >> "Attributes" >> "activationBy" ), "TXT", "NONE" ] call _fnc_getCfgValue;
	
	_trig_type = [ ( _cfg >> "Attributes" >> "type" ), "TXT", "PRESENT" ] call _fnc_getCfgValue;
	_isRectangle = [false, true] select getNumber( _cfg >> "Attributes" >> "isRectangle" );
	
	_effectCondition = getText( _cfg >> "Attributes" >> "effectCondition" );
	_effectSound = getText( _cfg >> "Attributes" >> "effectSound" );
	_effectVoice = getText( _cfg >> "Attributes" >> "effectVoice" );
	_effectSoundEnvironment = getText( _cfg >> "Attributes" >> "effectSoundEnvironment" );
	_effectSoundTrigger = getText( _cfg >> "Attributes" >> "effectSoundTrigger" );
	_effectMusic = getText( _cfg >> "Attributes" >> "effectMusic" );
	_effectTitle = getText( _cfg >> "Attributes" >> "effectTitle" );
	

	_trg = createTrigger[ _type, [0,0,0], true ];
	//_trg setPosWorld _position;
	//_position = [ _position, _ATLOffset ] call _fnc_getPosition;
	_position = [ _trg, _position, [0,0,0], _ATLOffset ] call _fnc_setPositionandRotation;
	_trg setTriggerArea [ _sizeA, _sizeB, _rotation, _isRectangle, _sizeC ];
	if !( _varName isEqualTo "" ) then {
		_trg setVehicleVarName _varname;
		missionNamespace setVariable [ _varName, _trg, true ];
	};
	_trg setTriggerText _description;
	_trg setTriggerStatements [ _condition, _onActivation, _onDeactivation ];
	_trg setTriggerActivation [ _activationBy, _trig_type, _repeatable ];
	_trg setTriggerTimeout ( _timeout + [ _interuptable ] );

	//TODO: Needs testing
	_trg setEffectCondition _effectCondition;
	_trg setSoundEffect [ _effectSound, _effectVoice, _effectSoundEnvironment, _effectSoundTrigger ];
	_trg setMusicEffect _effectMusic;
	switch ( true ) do {
		case ( isClass( missionConfigFile >> "RscTitles" >> _effectTitle ) ) : {
			_trg setTitleEffect [ "RES", "", _effectTitle ];
		};
		case ( isClass( configFile >> "CfgTitles" >> _effectTitle ) ) : {
			_trg setTitleEffect [ "OBJECT", "", _effectTitle ];
		};
		default {
			if ( _effectTitle != "" ) then {
				_trg setTitleEffect [ "TEXT", "PLAIN", _effectTitle ];
			};
		};
	};

	_trg
};

private _fnc_spawnLogic = {
	private[ "_presence", "_preCondition" ];
	private _logic = objNull;
	params[ "_cfg" ];
	
	_presence = [ ( _cfg >> "presence" ), "NUM", 1 ] call _fnc_getCfgValue;
	_preCondition = [ ( _cfg >> "presenceCondition" ), "TXT", "true" ] call _fnc_getCfgValue; //TODO: does this need defering 
	
	if ( random 1 <= _presence && { call compile _preCondition } ) then { 
		private [ "_type", "_position", "_ATLOffset", "_rotation", "_varName", "_group", "_init" ];
		
		_type = getText( _cfg >> "type" );
		_position = [ ( _cfg >> "PositionInfo" >> "position" ), "ARRAY", [0,0,0] ] call _fnc_getCfgValue;
		_ATLOffset = getNumber( _cfg >> "atlOffset" );
		_rotation = [ ( _cfg >> "PositionInfo" >> "angles" ), "ARRAY", [0,0,0] ] call _fnc_getCfgValue;
		_varName = getText( _cfg >> "name" );
			
		//FIX: Seems to not to be saved in the composition ??
		//_placementRadius = getNumber( _cfg >> "Attributes" >> "placementRadius" );
		
		//TODO: Split logics into proper module grps
		_group = group bis_functions_mainscope;
		_logic = _group createUnit [ _type, [0,0,0], [], 0, "CAN_COLLIDE" ]; //No randomStart for logics
		
		_position = [ _logic, _position, _rotation, _ATLOffset ] call _fnc_setPositionandRotation;
		
		if !( _varName isEqualTo "" ) then {
			_logic setVehicleVarName _varName;
			missionNamespace setVariable [ _varName, _logic, true ];
		};
		
		_init = getText( _cfg >> "init" );
		_nul = _inits pushBack [ _logic, format[ "this = _this; %1", _init ] ];
		
	};
	
	_logic
};

private _fnc_spawnMarker = {
	private [ "_position", "_name", "_text", "_markerType", "_type", "_colorName", "_alpha", "_fill", "_sizeA", "_sizeB", "_angle", "_id", "_mrk" ];
	params[ "_cfg" ];
	
	_position = getArray( _cfg >> "position" );
	//_position = [ _position ] call _fnc_getPosition;
	_position = [ objNull, _position ] call _fnc_setPositionandRotation;
	_name = getText( _cfg >> "name" );
	_text = getText( _cfg >> "text" );
	_markerType = getText( _cfg >> "markerType" );
	_type = getText( _cfg >> "type" );
	_colorName = getText( _cfg >> "colorName" );
	_alpha = [ ( _cfg >> "alpha" ), "NUM", 1 ] call _fnc_getCfgValue;
	
	_fill = getText( _cfg >> "fillName" );
	_sizeA = getNumber( _cfg >> "a" );
	_sizeB = getNumber( _cfg >> "b" );
	_angle = getNumber( _cfg >> "angle" );
	_id = getNumber( _cfg >> "id" );
	

	_mrk = createMarker[ _name, _position ];
	_mrk setMarkerDir _angle;
	_mrk setMarkerText _text;
	_mrk setMarkerSize [ _sizeA, _sizeB ];
	if !( _markerType isEqualTo "" ) then {
		_mrk setMarkerShape _markerType;
		if !( _fill isEqualTo "" ) then {
			_mrk setMarkerBrush _fill;
		};
	}else{
		_mrk setMarkerShape "ICON";
		_mrk setMarkerType _type;
	};
	if !( _colorName isEqualTo "" ) then {
		_mrk setMarkerColor _colorName;
	};
	_mrk setMarkerAlpha _alpha;
	
	_mrk
};

private _fnc_spawnWaypoint = {
	private [ "_position", "_ATLOffset", "_placement", "_compRadius", "_mode", "_formation", "_speed", "_behaviour", "_description", "_condition" ];
	params[ "_cfg", "_group" ];
	
	_position = getArray( _cfg >> "position" );
	_ATLOffset = getNumber( _cfg >> "atlOffset" );
	//_position = [ _position, _ATLOffset ] call _fnc_getPosition;
	_position = [ objNull, _position, [0,0,0], _ATLOffset ] call _fnc_setPositionandRotation;
	_placement = getNumber( _cfg >> "placement" );
	_compRadius = getNumber( _cfg >> "completitionRadius" );
	_mode = getText( _cfg >> "combatMode" );
	_formation = getText( _cfg >> "formation" );
	_speed = getText( _cfg >> "speed" );
	_behaviour = getText( _cfg >> "combat" );
	_description = getText( _cfg >> "description" );
	_condition = [ ( _cfg >> "expCond" ), "TXT", "true" ] call _fnc_getCfgValue; //TODO: does this need defering
	
	private [ "_onAct", "_name", "_script", "_timeout", "_show", "_type" ];
	
	_onAct = getText( _cfg >> "expActiv" );
	_name = getText( _cfg >> "name" );
	_script = getText( _cfg >> "script" );
	_timeout = [ getNumber( _cfg >> "timeoutMin" ), getNumber( _cfg >> "timeoutMid" ), getNumber( _cfg >> "timeoutMax" ) ];
	_show = getText( _cfg >> "showWP" );
	_type = getText( _cfg >> "type" );
	
	private [ "_effectCondition", "_effectSound", "_effectVoice", "_effectSoundEnvironment", "_effectMusic", "_effectTitle", "_wp" ];
	
	_effectCondition = getText( _cfg >> "Effects" >> "condition" ); //TODO: does this need defering
	_effectSound = getText( _cfg >> "Effects" >> "sound" );
	_effectVoice = getText( _cfg >> "Effects" >> "voice" );
	_effectSoundEnvironment = getText( _cfg >> "Effects" >> "soundEnv" );
	_effectMusic = getText( _cfg >> "Effects" >> "track" );
	_effectTitle = getText( _cfg >> "Effects" >> "title" );

	_wp = _group addWaypoint[ ASLToATL _position, _placement, count waypoints _group, _name];
	_wp setWaypointType _type;
	_wp setWaypointCompletionRadius _compRadius;
	_wp setWaypointCombatMode _mode;
	_wp setWaypointFormation _formation;
	_wp setWaypointSpeed _speed;
	_wp setWaypointBehaviour _behaviour;
	_wp setWaypointDescription _description;
	_wp setWaypointStatements[ _condition, _onAct ];
	_wp setWaypointTimeout _timeout;
	_wp showWaypoint _show;
	_wp setWaypointScript _script;
	
	//TODO: Effects need testing
	_wp setEffectCondition _effectCondition;
	_wp setSoundEffect [ _effectSound, _effectVoice, _effectSoundEnvironment, "" ];
	_wp setMusicEffect _effectMusic;
	switch ( true ) do {
		case ( isClass( missionConfigFile >> "RscTitles" >> _effectTitle ) ) : {
			_wp setTitleEffect [ "RES", "", _effectTitle ];
		};
		case ( isClass( configFile >> "CfgTitles" >> _effectTitle ) ) : {
			_wp setTitleEffect [ "OBJECT", "", _effectTitle ];
		};
		default {
			if ( _effectTitle != "" ) then {
				_wp setTitleEffect [ "TEXT", "PLAIN", _effectTitle ];
			};
		};
	};
	
	_wp
};

//*****
//Main
//*****

private _fnc_spawnItems = {
	private[ "_id", "_dataType", "_msg", "_obj" ];
	params[ "_cfg", [ "_info", grpNull ] ]; //INFO is usually a group but is also used by triggers as a defered boolean flag

	_id = getNumber( _cfg >> 'id' );
	
	if ( count _ids <= _id ) then {
		_ids resize _id;
	};
	
	_dataType = getText( _cfg >> "dataType" );
	
	_msg = format[ "spawning - %1 %2 - ID: %3", _dataType, getText( _cfg >> "type" ), _id ];
	
	switch ( _dataType ) do {

		case "Group" : {
			_obj = [ _cfg ] call _fnc_spawnGroup;
			_msg = format[ "%1, GroupID %2", _msg, groupID _obj ];
		};
		
		case "Object" : {
			_obj = [ _cfg, _info ] call _fnc_spawnObject;
			if !( vehicleVarName _obj isEqualTo "" ) then {
				_msg = format[ "%1, VarName %2", _msg, vehicleVarName _obj ];
			};
		};
		
		case "Trigger" : {
			_obj = [ _cfg, _info ] call _fnc_spawnTrigger;
			if !( vehicleVarName _obj isEqualTo "" ) then {
				_msg = format[ "%1, VarName %2", _msg, vehicleVarName _obj ];
			};
		};
		
		case "Logic" : {
			_obj = [ _cfg ] call _fnc_spawnLogic;
			if !( vehicleVarName _obj isEqualTo "" ) then {
				_msg = format[ "%1, VarName %2", _msg, vehicleVarName _obj ];
			};
		};
		
		case "Marker" : {
			_obj = [ _cfg ] call _fnc_spawnMarker;
			_msg = format[ "%1, Name %2", _msg, str _obj ];
		};
		
		case "Waypoint" : {
			_obj = [ _cfg, _group ] call _fnc_spawnWaypoint;
			if !( waypointName _obj isEqualTo "" ) then {
				_msg = format[ "%1, WaypointID %2", _msg, waypointName _obj ];
			};
		};
		
		case "Layer" : {
			[ ( _cfg >> "Entities" ) ] call _fnc_spawnItems;
		};
	};
	
	if !( isNil	"_obj" ) then {
		_ids set [ _id, _obj ];
		if ( ( _obj isEqualType objNull ) && { !isNull _obj } ) then {
			[ _obj, _cfg ] call _fnc_CustomAttributes;
		};
	};
	
	DEBUG_MSG( DEBUG, _msg );
	
};


DEBUG_MSG( DEBUG, "ITEMS" );
private [ "_pType", "_dataType" ];
{
	_pType = _x;
	{
		_dataType = getText( _x >> "dataType" );
		if ( _dataType == _pType ) then {
			[ _x ] call _fnc_spawnItems;
		};
	}forEach _itemCfgs;
}forEach _priority;


DEBUG_MSG( DEBUG, "GROUPS" );
{
	[ _x ] call _fnc_spawnItems;
}forEach _groupCfgs;


//Items are defered if their id is in a connection or they belong to a defered group
DEBUG_MSG( DEBUG, "DEFERED ITEMS" );
{
	_pType = _x;
	{
		_dataType = getText( _x >> "dataType" );
		if ( _dataType == _pType ) then {
			[ _x ] call _fnc_spawnItems;
		};
	}forEach _deferedItems;
}forEach _priority;


//Groups are defered if they have crewLinks or a unit of the group has a random start pos
DEBUG_MSG( DEBUG, "DEFERED GROUPS" );
{
	[ _x ] call _fnc_spawnItems;
}forEach _deferedGrps;


//Triggers are defered if they are in connections of type TriggerOwner
DEBUG_MSG( DEBUG, "DEFERED TRIGGERS" );
{
	[ _x, true ] call _fnc_spawnItems;
}forEach _deferedTrgs;


DEBUG_MSG( DEBUG, "CREW LINKS" );
private [ "_unit", "_veh" ];
{
	_x params[ "_unitID", "_vehID", "_role", "_turret", "_cargoIndex" ];

	_unit = _ids select _unitID;
	_veh = _ids select _vehID;

	switch ( true ) do {
		case ( count _turret > 0 ) : {
			_unit moveInTurret [ _veh, _turret ];
		};
		case ( _cargoIndex > -1 ) : {
			_unit moveInCargo [ _veh, _cargoIndex ];
		};
		default {
			_unit moveInDriver _veh;
		};
	};
}forEach _crewLinks;


DEBUG_MSG( DEBUG, "CONNECTIONS" );
if ( isClass( missionConfigFile >> "CfgCompositions" >> _compName >> "connections" ) ) then {
	private [ "_connectionType", "_fromID", "_toID", "_from", "_to" ];
	
	{
		_connectionType = getText ( _x >> "CustomData" >> "type" );
		_fromID = getNumber( _x >> "item0" );
		_toID = getNumber( _x >> "item1" );
		_from = _ids select _fromID;
		_to = _ids select _toID;

		if ( !isNil "_from" && !isNil "_to" ) then {

			switch ( _connectionType ) do {
				
				case 'WaypointActivation' : {
					private [ "_trg", "_wp" ];
					
					if ( { !( _x isEqualType [] ) }count[ _from, _to ] > 0 ) then {
						_trg = {
							if !( _x isEqualType [] ) exitWith { _x };
						}forEach [ _from, _to ];
						_wp = ( [ _from, _to ] - [ _trg ] ) select 0;
						_trg synchronizeTrigger [ _wp ];
					}else{
						_from synchronizeWaypoint [ _to ];
					};
				};
				
				case 'Sync' : {
					_from synchronizeObjectsAdd [ _to ];
				};
				
				case "RandomStart" : {
					
				};
				
				case "TriggerOwner" : {
					private [ "_info", "_trg", "_owner", "_type", "_act", "_condition", "_cond" ];
					
					_info = {
						if ( typeOf _x isEqualTo "EmptyDetector" ) exitWith { [ _x, _forEachIndex ] };
					}forEach [ _from, _to ];
					_trg = _info select 0;
					_owner = ( [ _from, _to ] - [ _trg ] ) select 0;
					( _objects select ( [ _toID, _fromID ] select ( _info select 1 )))params[ "_id", "_cfg" ];
					_type = [ ( _cfg >> "Attributes" >> "activationByOwner" ), "TXT", "VEHICLE" ] call _fnc_getCfgValue;
					_act = triggerActivation _trg;
					_act set [ 0, _type ];
					_condition = [ ( _cfg >> "Attributes" >> "condition" ), "TXT", "this" ] call _fnc_getCfgValue;
					_cond = triggerStatements _trg;
					_cond set [ 0, _condition ];
					if ( _type isEqualTo "STATIC" ) then {
						_trg triggerAttachObject [ _owner ];
					}else{
						_trg triggerAttachVehicle [ _owner ];
					};
					_trg setTriggerActivation _act;
					_trg setTriggerStatements _cond;
				};
			};
		}else{
			//diag_log format[ "connection object missing - Fid: %1, F: %2, Tid: %3, T: %4", _fromID, _from, _toID, _to ];
		};
	}forEach ( "true" configClasses ( missionConfigFile >> "CfgCompositions" >> _compName >> "connections" >> "Links" ) );
};


DEBUG_MSG( DEBUG, "INITS" );
{
	_x params [ "_obj", "_code" ];
	_obj call compile _code;
}forEach _inits;

_msg = format[ "Composition %1 Done!!", str _compName ];
DEBUG_MSG( DEBUG, _msg );

_ids