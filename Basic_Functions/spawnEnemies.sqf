/*
 *
 *	THIS FUNCTION IS FOR
 *		Spawning squads in AO at markernames
 *		Some squads will fortify buildings, others will patrol the area
 *
 *
 *	PARAMETERS:
 *		0:		_nrOfEnemies	- How many enemies should be spawned?	
 *		1:		_enemySpawn		- Where should they be spawned? (array)
 *		2:		_squadTypes		- Types of squads to choose from (array)
 *
 *
 *	RETURNS:
 *		Array of squads created
 */


// Get parameters
params ["_nrOfEnemies", "_enemySpawn", "_squadTypes", "_distanceToSpawn"];

// Array to store the squads in
private "_spawnedSquads";
_spawnedSquads = [];
if(count _this isEqualTo 4) then
{
	_distanceToSpawn = _this select 3;
} else 
{
	_distanceToSpawn = 100;
};



// Spawn the enemy units!
if(nrOfEnemySquadsAtAO > 0) then {
	// Spawn enemies, if parameter says so
	for "i" from 0 to nrOfEnemySquadsAtAO - 1 do
	{
		_squadToSpawn = floor random 4;
		_placeToSpawn = floor random (count _enemySpawn);


		// _enemySquads pushBack [_enemySpawnMarkers select _placeToSpawn, resistance, (_squadTypes select 2) ] Call BIS_fnc_spawnGroup;
		// [getMarkerPos (_enemySpawn select _placeToSpawn), resistance, (configFile >> "CfgGroups" >> "Indep" >> "LOP_AM" >> "Infantry" >> "LOP_AM_Support_section")] Call BIS_fnc_spawnGroup;
		_tempGroup = [getMarkerPos (_enemySpawn select _placeToSpawn), resistance, _squadTypes select _squadToSpawn] Call BIS_fnc_spawnGroup;
		_spawnedSquads set [i, _tempGroup];
		
		// Creating tasks for the AI
		_grpTask = floor random 2;
		switch (_grpTask) do{
			// DEFEND waypoint
			case 0:
			{	
				_angle = random 360;
				_randomPlaceToSpawn = [(getMarkerPos (_enemySpawn select _placeToSpawn) select 0) + (_distanceToSpawn * cos _angle), (getMarkerPos (_enemySpawn select _placeToSpawn) select 1) + (_distanceToSpawn * sin _angle)];
				
				[_tempGroup, _randomPlaceToSpawn, 100, 2, true] call CBA_fnc_taskDefend;
			};
			
			// PATROL
			case 1:
			{
				_angle = random 360;
				_randomPlaceToSpawn = [(getMarkerPos (_enemySpawn select _placeToSpawn) select 0) + (_distanceToSpawn * cos _angle), (getMarkerPos (_enemySpawn select _placeToSpawn) select 1) + (_distanceToSpawn * sin _angle)];
				[_tempGroup, _randomPlaceToSpawn, 200, 15] call CBA_fnc_taskPatrol;
			};
			
		
		};
		
		
	};
	_spawnedSquads;
};	

