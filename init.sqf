



nrOfEnemySquadsForTransport		= paramsArray select 0;
nrOfEnemySquadsForAssist	 	= paramsArray select 1;
nrOfEnemySquadsForTowing 		= paramsArray select 2;
nrOfEnemySquadsAtAO				= paramsArray select 3;


// Variable for keeping track of completed tasks
tasksDone						= 0;
currentAssignedTask 			= 0;

// Variable to keep track of action ID for strategic map
actionID	= 0;

[] spawn {call compile preprocessFileLineNumbers "EPD\Ied_Init.sqf";};