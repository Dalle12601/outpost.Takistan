/*
 *
 *	THIS FUNCTION IS FOR
 *	CREATING A TASK TO THE LEADER OF UNITS GROUP
 *
 *
 *
 *	NOTES:
 *		7: TASK-STATE needs some work. At this moment (23/4 2016) is only defaults to ASSIGNED no matter what you set in parameter.
 *
 *
 *
 *
 *	PARAMETERS:
 *		1:	TASK-TITLE 			- The name of the task
 *		2:	TASK-DECRIPTION_L	- Set the LONG description
 *		3:	TASK-DECRIPTION_S	- THIS IS THE TITLE! The SHORT description
 *		4:	TASK-DECRIPTION_H	- Set the HUD description				Default is nil
 *		5:	TASK_DESTINATION	- Marker name @ the DESTINATION
 *		6:  UNIT				- Unit of the group to give the task to
 *		7:	TASK-STATE			- Set the state of the created task. 	Default is ASSIGNED
 *
 *
 *	EXAMPLE CALL
 *		_someVariable = [TITLE_STRING, "DeskL", AC_TITLE_STRING, "DeskH", COORDINATES, UNIT, "ASSIGNED"] execVM "createTask.sqf";
 *			Where:
 *				COORDINATES:		[0, 0, 0] form. It only uses 0 and 1 (like coordinates for markers)
 *				UNIT				Some unit whose groupleader gets the task.
 *				TITLE_STRING		Should not have been used. It does not seem to do anything
 *				AC_TITLE_STRING		!USE THIS FOR THE TITLE! This is the actual title string.
 *
 *			[_unit,_taskid,[_tskDescL, _tskTitle],_tskDest,_tskState, 1,true] call bis_fnc_taskCreate;
 *			[_owner,_taskid,_texts,_destination,_state,_priority,_showNotification,_taskType,_alwaysVisible] call bis_fnc_taskCreate;
 *
 *
 *			EXAMPLE CALL:
 *				_nah = ["Title", "DeskL", "DeskS", "HER ER MAD!", [0, 0, 0], this, "ASSIGNED"] execVM "createTask.sqf";
 */
 
params ["_tskTitle", "_tskDescL", "_tskDest", "_tskState", "_enemySpawn1", "_enemySpawn2"];		// Getting the passed parameters


// Now we need to rename the parameters to variables we can use
_taskTitle 		= _this select 0;	// DO NOT USE THIS. USE _taskDescS instead.
_taskDescL		= _this select 1;
_taskDest		= _this select 2;
_taskState		= _this select 3;
_enemySpawn1 	= _this select 4;
_enemySpawn2	= _this select 5;


_task = "task_";


// Make sure the task can't be startet 2 times
doWeHaveATask = true;
publicVariable "doWeHaveATask";


// Create the task
_actualTaskPos = getMarkerPos _taskDest;
_taskVar = [west, [_task], [_taskDescL, _taskTitle],   _actualTaskPos, _taskState, 1] call bis_fnc_taskCreate;
 
 // Spawn our units
 _InfSquad1 = [(getMarkerPos _taskDest), west, (configFile >> "CfgGroups" >> "West" >> "rhs_faction_usmc_d" >> "rhs_group_nato_usmc_d_infantry" >> "rhs_group_nato_usmc_d_infantry_team")] Call BIS_fnc_spawnGroup;
 // rhs_group_nato_usmc_d_infantry_team
 

 
 
// Spawn the enemy units!
if(nrOfEnemySquadsForAssist > 0) then {
	// Spawn enemies, if parameter says so
	for "i" from 1 to nrOfEnemySquadsForAssist do
	{
		if (i % 2 == 0) then {
			_InfSquad2 = [(getMarkerPos _enemySpawn1), resistance, (configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Support_section")] Call BIS_fnc_spawnGroup;
		
			_wp = _InfSquad2 addWaypoint [[getMarkerPos _taskDest select 0, getMarkerPos _taskDest select 1], 0];
			_wp setWaypointType "MOVE";
			_wp setWaypointStatements ["True", ""];
			
		} else {
			_InfSquad2 = [(getMarkerPos _enemySpawn1), resistance, (configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Rifle_squad")] Call BIS_fnc_spawnGroup;
		
			_wp = _InfSquad2 addWaypoint [[getMarkerPos _taskDest select 0, getMarkerPos _taskDest select 1], 0];
			_wp setWaypointType "MOVE";
			_wp setWaypointStatements ["True", ""];
		}
	};
};
 
 
 
 /* OUTDATED!
 // Spawn the enemy group
 _InfSquad2 = [(getMarkerPos _enemySpawn1), resistance, (configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Support_section")] Call BIS_fnc_spawnGroup;
	// LOP_AM_Support_section
	// LOP_AM_Rifle_squad
	// LOP_AM_AT_section
	// LOP_AM_Patrol_section

	// Make waypoints for the groups
	_wp = _InfSquad2 addWaypoint [[getMarkerPos _taskDest select 0, getMarkerPos _taskDest select 1], 0];
	_wp setWaypointType "MOVE";
	_wp setWaypointStatements ["True", ""];

*/	
	
	// Control structure
	// This checks if the task is completed0
	_shallWeStillCheck = true;
	while {_shallWeStillCheck} do {
		
		if(({alive _x} count units _InfSquad2) < 1) then {
			[_task, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
			_shallWeStillCheck = false;
			doWeHaveATask = false;
			publicVariable "doWeHaveATask";
			tasksDone = tasksDone + 1;
		};
		
		if(({alive _x} count units _InfSquad1) < 1) then {
			[_task, "Failed", true] spawn BIS_fnc_taskSetState;
			_shallWeStillCheck = false;
			doWeHaveATask = false;
			publicVariable "doWeHaveATask";
			tasksDone = tasksDone + 1;
		};
		
		
		sleep(20);
		
	}; 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 /*		NOT USED
 
 // GAME-LOGIC GROUPING
 _temp_group1	= createGroup west;
 _temp_group2	= createGroup west;
 
 
 // INIT-fields for units
 gut_1_init = "[this, 'STAND'] call BIS_fnc_ambientAnim; this setDir 94.088; gut_1 = this; this addAction ['Talk', 'gut_1_talk.sqf'];";
 gut_2_init = "[this,'SIT_LOW_U','ASIS'] call BIS_fnc_ambientAnim; this setDir 210.692; gut_2 = this; this setVehiclePosition [gut_2_pos, [],0, 'CAN_COLLIDE']; this addAction ['Talk', 'gut_2_talk.sqf']";
 
 
 
 // CIVILIANS
 "CAF_AG_ME_CIV_03"	createUnit [gut_1_pos, _temp_group1, gut_1_init]; // GUT 1
 "CAF_AG_ME_CIV_03"	createUnit [[0,0,0], _temp_group2, gut_2_init]; // GUT 2


 
 // STATIC OBJECTS		EXAMPLE CODE		_veh_1		= "C_offroad_01_F" 	createVehicle position player;		EXAMPLE CODE
 
 
 
 // ENEMY UNITS
 
 
 */ 
 
 
 
 
 
  
 
  // TESTS
//  [group _this select 1, ["task_0"], ["We have reason to believe one of the locals know something about our enemies positions. Locate the guy and speak with him.", "Speak to the local"],    _dest_1, "ASSIGNED", 1] call bis_fnc_taskCreate;

	// hint "Dillermis!";
 
 // --END OF TESTS
 
 // HELPER FUNCTIONS
 /*
 KK_fnc_setPosAGLS = {
	params ["_obj", "_pos", "_offset"];
	_offset = _pos select 2;
	if (isNil "_offset") then {_offset = 0};
	_pos set [2, worldSize]; 
	_obj setPosASL _pos;
	_pos set [2, vectorMagnitude (_pos vectorDiff getPosVisual _obj) + _offset];
	_obj setPosASL _pos;
};
*/







































