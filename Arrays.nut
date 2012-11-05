
<!-- saved from url=(0070)https://openttd-noai-wmdot.googlecode.com/svn/tags/WmDOT-v3/Arrays.nut -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"></head><body class=" hasGoogleVoiceExt"><pre style="word-wrap: break-word; white-space: pre-wrap;">/*	WmDOT v.2  r.17		2011-02-28
 *	Array Functions
 *	Copyright � 2011 by William Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */


function Print1DArray(InArray)
{
	//	Move to Library
	//	Add error check that an array is provided
	
	local Length = InArray.len();
	local i = 0;
	local Temp = "";
	while (i &lt; InArray.len() ) {
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
	while (i &lt; InArray.len() ) {
		local InnerArray = [];
		InnerArray = InArray[i];
		local InnerLength = InnerArray.len();
		local j = 0;
		while (j &lt; InnerArray.len() ) {
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
	while (i &lt; InArray.len() ) {
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
	while (i &lt; InArray.len() ) {
		local InnerArray = [];
		InnerArray = InArray[i];
		local InnerLength = InnerArray.len();
		local j = 0;
		while (j &lt; InnerArray.len() ) {
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
	
	for (local i = 0; i &lt; InArray.len(); i++ ) {
		for (local j=0; j &lt; InArray[i].len(); j++ ) {
			if (InArray[i][j] == SearchValue) {
				return true;
			}
		}
	}

	return false;
}

function ContainedIn1DArray(InArray, SearchValue)
{
//	Searches the array for the given value. Returns 'TRUE' if found and
//		'FALSE' if not.
//	Accepts 1D Arrays
//
//	Move to Array library
	
	for (local i = 0; i &lt; InArray.len(); i++ ) {
			if (InArray[i] == SearchValue) {
				return true;
			}
	}

	return false;
}

</pre></body></html>