/*
 *
 *	THIS FUNCTION IS FOR
 *		Spawning squads in AO at markernames
 *		Some squads will fortify buildings, others will patrol the area
 *
 *
 *	PARAMETERS:
 *		0:		_squadsToDespawn - The squads of which to despawn all units
 *
 *
 *	RETURNS:
 *		Array of squads created
 */


// Get parameters
params ["_squadsToDespawn"];

{ 
	{
		deleteVehicle _x;
	} forEach units _x;
	
} forEach _squadsToDespawn;





