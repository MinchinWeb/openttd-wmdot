/*	WmDOT v.5  r.53d		2011-04-09
 *	Array Functions
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */


function Print1DArray(InArray)
{
	//	Move to Library
	//	Add error check that an array is provided
	
	local Length = InArray.len();
	local i = 0;
	local Temp = "";
	while (i < InArray.len() ) {
		Temp = Temp + "  " + InArray[i];
		i++;
	}
	AILog.Info("The array is " + Length + " long.  " + Temp + " ");
}

function Print2DArray(InArray)
{
	//	Move to Library
	//	Add error check that a 2D array is provided
	
	local Length = InArray.len();
	local i = 0;
	local Temp = "";
	while (i < InArray.len() ) {
		local InnerArray = [];
		InnerArray = InArray[i];
		local InnerLength = InnerArray.len();
		local j = 0;
		while (j < InnerArray.len() ) {
			Temp = Temp + "  " + InnerArray[j];
			j++;
		}
		Temp = Temp + "  /  ";
		i++;
	}
	AILog.Info("The array is " + Length + " long." + Temp + " ");
}

function ToSting1DArray(InArray)
{
	//	Move to Library
	//	Add error check that an array is provided
	
	local Length = InArray.len();
	local i = 0;
	local Temp = "";
	while (i < InArray.len() ) {
		Temp = Temp + "  " + InArray[i];
		i++;
	}
	return ("The array is " + Length + " long.  " + Temp + " ");
}

function ToSting2DArray(InArray)
{
	//	Move to Library
	//	Add error check that a 2D array is provided
	
	local Length = InArray.len();
	local i = 0;
	local Temp = "";
	while (i < InArray.len() ) {
		local InnerArray = [];
		InnerArray = InArray[i];
		local InnerLength = InnerArray.len();
		local j = 0;
		while (j < InnerArray.len() ) {
			Temp = Temp + "  " + InnerArray[j];
			j++;
		}
		Temp = Temp + "  /  ";
		i++;
	}
	return ("The array is " + Length + " long." + Temp + " ");
}

function ContainedIn2DArray(InArray, SearchValue)
{
//	Searches the array for the given value. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 2D Arrays
//
//	Move to Array library
	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
			for (local j=0; j < InArray[i].len(); j++ ) {
				if (InArray[i][j] == SearchValue) {
					return true;
				}
			}
		}

		return false;
	}
}

function ContainedIn1DArray(InArray, SearchValue)
{
//	Searches the array for the given value. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 1D Arrays
//
//	Move to Array library
	if (InArray == null) {
		return null;
	} else {
		for (local i = 0; i < InArray.len(); i++ ) {
				if (InArray[i] == SearchValue) {
					return true;
				}
		}

		return false;
	}
}

