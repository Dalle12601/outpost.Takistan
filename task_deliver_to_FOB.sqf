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

params ["_tskTitle", "_tskDescL", "_tskDest", "_tskState","_tskStart", "_enemySpawn1", "_enemySpawn2"];		// Getting the passed parameters


// Now we need to rename the parameters to variables we can use
_taskTitle 		= _this select 0;
_taskDescL		= _this select 1;
_taskDest		= _this select 2;
_taskState		= _this select 3;
_taskStart		= _this select 4;
_enemySpawn1 	= _this select 5;
_enemySpawn2	= _this select 6;

// Setting up the local task var
_task = "task_" + str(tasksDone);
stratMap removeAction actionID;


// Make sure the task can't be startet 2 times
doWeHaveATask = true;
publicVariable "doWeHaveATask";

// Creating the task
_actualTaskPos = getMarkerPos _taskDest;
_taskVar = [west, [_task], [_taskDescL, _taskTitle],   _actualTaskPos, _taskState, 1] call bis_fnc_taskCreate;

_objectToTransport = 0;

_switchVal = floor random 5;
switch(_switchVal) do
{
	// Spawning the object
	case 0: 
	{
		_objectToTransport = "B_Slingload_01_Cargo_F" createVehicle getMarkerPos _taskStart;
		hint "it works!";
	};

	case 1:
	{
		_objectToTransport = "rhsusf_m1025_d_s" createVehicle getMarkerPos _taskStart;
		hint "it works!";
	};

	case 2:
	{
		_objectToTransport = "CargoNet_01_barrels_F" createVehicle getMarkerPos _taskStart;
		hint "it works!";
	};

	case 3:
	{
		_objectToTransport = "CargoNet_01_box_F" createVehicle getMarkerPos _taskStart;
		hint "it works!";
	};

	case 4:
	{
		_objectToTransport = "B_Slingload_01_Fuel_F" createVehicle getMarkerPos _taskStart;
		hint "it works!";
	};
	
	default
	{
	hint "it does not work";
	}
};



// _nrOfSquads = paramsArray select 2;
// Spawn the enemy units!
if(nrOfEnemySquadsForTransport > 0) then {
	// Spawn enemies, if parameter says so
	for "i" from 1 to nrOfEnemySquadsForTransport do
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
		};
	};
};





	// Control structure
	// This checks if the task is completed
	
	// CHANGE THE STATEMENTS, TO REFLECT THE NEW TASK!
	
	_shallWeStillCheck = true;
	while {_shallWeStillCheck} do {
		if(position _objectToTransport distance2D _actualTaskPos < 10) then {
			[_task, "Succeeded", true] spawn BIS_fnc_taskSetState;
			_shallWeStillCheck = false;
			doWeHaveATask = false;
			publicVariable "doWeHaveATask";
			tasksDone = tasksDone + 1;
			stratMap addAction ["Open strategic map","openStrategicMap.sqf"];
		};
		
		
		sleep(20);
		
	};




































