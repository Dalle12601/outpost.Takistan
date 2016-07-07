//Entry function - calls function to spawn composition and handles composition references

private[ "_objects", "_index", "_compReference" ];
params[ "_compName" ];

if ( isNil "LARs_spawnedCompositions" ) then {
	LARs_spawnedCompositions = [];
};

_objects = _this call LARs_fnc_createComp;

{
	if !( isNil "_x" ) then {
		_objects set [ _forEachIndex, [ _forEachIndex, _x ] ];
	}else{
		_objects set [ _forEachIndex, objNull ];
	};
}forEach _objects;

_objects = _objects - [ objNull ];

_index = {
	if ( isNil "_x" ) exitWith { _forEachIndex };
}forEach LARs_spawnedCompositions;

if ( isNil "_index" ) then {
	_compReference = format[ "%1_%2", _compName, count LARs_spawnedCompositions ];
	_nul = LARs_spawnedCompositions pushBack [ _compReference, _objects ];
}else{
	_compReference = format[ "%1_%2", _compName, _index ];
	LARs_spawnedCompositions set [ _index, [ _compReference, _objects ] ];
};

_compReference