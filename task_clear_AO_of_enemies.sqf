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

params ["_tskTitle", "_tskDescL", "_tskDest", "_enemySpawn1[]"];		// Getting the passed parameters

// Variable for storing the squads spawned
private ["_enemySquads", "_enemySpawnMarkers"];
_enemySquads = [];


// Now we need to rename the parameters to variables we can use
_taskTitle 		= _this select 0;
_taskDescL		= _this select 1;
_taskDest		= _this select 2;
_enemySpawn 	= _this select 3;

_taskState		= "ASSIGNED";

// Make an array with the squad types:
_squadTypes = [	(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Support_section"),
				(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Rifle_squad"),
				(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_AT_section"),
				(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Patrol_section")];
				
			
/* FOR DEBUGGING
for "i" from 1 to count _enemySpawn do
{
	systemChat str(_enemySpawn select i);
};
*/

// Setting up the local task var
_task = "task_" + str(tasksDone);
stratMap removeAction actionID;

// Make sure the task can't be startet 2 times
doWeHaveATask = true;
publicVariable "doWeHaveATask";

// Converting Markers to coordinates
_zoneToDefend 	= getMarkerPos _taskDest;



// Creating the task
_taskVar = [west, [_task], [_taskDescL, _taskTitle], _zoneToDefend, _taskState, 1] call bis_fnc_taskCreate;



// Spawn enemies
_spawnedSquads = [nrOfEnemySquadsAtAO, _enemySpawn, _squadTypes, 100, false] call compile preprocessFileLineNumbers "Basic_Functions\spawnEnemies.sqf";



// Assign the global variable to task ID
currentAssignedTask = _task;


// Create a trigger to check if task completed
_trig = createTrigger ["EmptyDetector", _zoneToDefend];
_trig setTriggerType "NONE";
_trig setTriggerActivation ["WEST SEIZED", "PRESENT", false];
_trig setTriggerArea [200, 200, 0, false];
_trig setTriggerTimeout [80, 80, 80, false];
_trig setTriggerStatements ["this", "", ""];

while {!(triggerActivated _trig)} do 
{ 	
	// Now we wait for the trigger to fire
	sleep(10);
};


stratMap addAction ['Open strategic map','openStrategicMap.sqf']; 
doWeHaveATask = false; publicVariable 'doWeHaveATask'; 
tasksDone = tasksDone + 1; 
[currentAssignedTask, 'Succeeded', true] spawn BIS_fnc_taskSetState; 



// Wait for ppl to leave the zone
sleep(600);
[_spawnedSquads] call compile preprocessFileLineNumbers "Basic_Functions\deSpawnEnemies.sqf";









/* GAMMEL KODE!

_objectToTransport = 0;





_switchVal = floor random 2;
switch(_switchVal) do
{
	// Spawning the object
	case 0: 
	{
		_objectToTransport = "rhsusf_rg33_d" createVehicle getMarkerPos _posOfCar;
		_objectToTransport setHit [getText(configFile >> "cfgVehicles" >> "rhsusf_rg33_d" >> "HitPoints" >> "HitEngine" >> "name") , 1];
		_objectToTransport setHit [getText(configFile >> "cfgVehicles" >> "rhsusf_rg33_d" >> "HitPoints" >> "HitFuel" >> "name") , 0.5];
		_objectToTransport setFuel 0;
		hint "it works!";
	};

	case 1:
	{
		_objectToTransport = "rhsusf_m1025_d_s" createVehicle getMarkerPos _posOfCar;
		_objectToTransport setHit [getText(configFile >> "cfgVehicles" >> "rhsusf_m1025_d_s" >> "HitPoints" >> "HitEngine" >> "name") , 1];
		_objectToTransport setHit [getText(configFile >> "cfgVehicles" >> "rhsusf_m1025_d_s" >> "HitPoints" >> "HitFuel" >> "name") , 0.5];
		_objectToTransport setFuel 0;		
		hint "it works!";
	};

	case 2:
	{
		_objectToTransport = "CargoNet_01_barrels_F" createVehicle getMarkerPos _posOfCar;
		_objectToTransport setHit ["motor" , 1];
		_objectToTransport setFuel 0;
		hint "it works!";
	};

	case 3:
	{
		_objectToTransport = "CargoNet_01_box_F" createVehicle getMarkerPos _posOfCar;
		_objectToTransport setHit ["motor" , 1];
		_objectToTransport setFuel 0;
		hint "it works!";
	};

	case 4:
	{
		_objectToTransport = "B_Slingload_01_Fuel_F" createVehicle getMarkerPos _posOfCar;
		_objectToTransport setHit ["motor" , 1];
		_objectToTransport setFuel 0;
		hint "it works!";
	};

	default
	{
	hint "it does not work";
	}
};
*/


	// Control structure
	// This checks if the task is completed
	
	// CHANGE THE STATEMENTS, TO REFLECT THE NEW TASK!
/*	
	_shallWeStillCheck = true;
	while {_shallWeStillCheck} do {
		if(position _objectToTransport distance2D _taskEndPos < 10) then {
			[_task, "Succeeded", true] spawn BIS_fnc_taskSetState;
			_shallWeStillCheck = false;
			doWeHaveATask = false;
			publicVariable "doWeHaveATask";
			tasksDone = tasksDone + 1;
			stratMap addAction ["Open strategic map","openStrategicMap.sqf"];
		};
		
		
		sleep(20);
		
	};


*/

































