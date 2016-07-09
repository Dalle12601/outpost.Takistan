/*
 *
 *	THIS FUNCTION IS FOR
 *	
 *
 *
 *	PARAMETERS:
 *		0:			
 *		1:		
 *		2:		
 *		3:  
 *		4:	
 *
 */ 
 
 
 // Getting the parameters
 params ["_tskTitle", "_tskDescL"];
 
 // Now we need to rename the parameters to variables we can use
_taskTitle 		= _this select 0;
_taskDescL		= _this select 1;


_taskState		= "ASSIGNED";

_squadTypes = [	(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Support_section"),
				(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Rifle_squad"),
				(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_AT_section"),
				(configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Patrol_section")];
 
 
 // Setting up the local task var
_task = "task_" + str(tasksDone);
stratMap removeAction actionID;

// Make sure the task can't be startet 2 times
doWeHaveATask = true;
publicVariable "doWeHaveATask";

 
// Spawn the objects
_compReference = ["iedDalle_1"] call LARs_fnc_spawnComp;
 
// Getting the place to blow up
_placeToDestroy 	= getPos ied1;

// Spawn enemies
_spawnedSquads = [nrOfEnemySquadsAtIED, _placeToDestroy, _squadTypes, 100, true] call compile preprocessFileLineNumbers "Basic_Functions\spawnEnemies.sqf";

 // Creating the task
_taskVar = [west, [_task], [_taskDescL, _taskTitle], _placeToDestroy, _taskState, 1] call bis_fnc_taskCreate;



 // Wait for the IED to be destroyed
while {(alive ied1)} do 
{
	sleep(2);
};


// Wait some time before completing the task
sleep(10);

// Complete the task
[_task, 'Succeeded', true] spawn BIS_fnc_taskSetState;

// Do the stuff we have to do
doWeHaveATask = false;
publicVariable "doWeHaveATask";
tasksDone = tasksDone + 1;
stratMap addAction ["Open strategic map","openStrategicMap.sqf"];

// Wait some time before deleting the site again
sleep(15);	
// Delete the factory 
[_compReference] call LARs_fnc_deleteComp;
// Delete remaining units, if any
[_spawnedSquads] call compile preprocessFileLineNumbers "Basic_Functions\deSpawnEnemies.sqf";