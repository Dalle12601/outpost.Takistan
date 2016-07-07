/*
 *
 *	THIS FUNCTION IS FOR
 *	
 *
 *
 *	PARAMETERS:
 *		0:		COMMANDER-object	
 *		1:		_caller
 *		2:		_addActionID
 *		3:  
 *		4:	
 *
 */
 
 
 
 
 _compReference = [ "iedDalle_1"] call LARs_fnc_spawnComp;

 
 while {(getDammage ied1 < 0.9)} do 
 {
	sleep(2);
};

 sleep(15);

 
 [_compReference] call LARs_fnc_deleteComp;