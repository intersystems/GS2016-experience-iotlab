Class IoT.Data.StoredProcedures
{

ClassMethod GetIntervalNoFromTimestamp(ts As %TimeStamp, tsmax As %TimeStamp, IntervalLength As %Integer) As %Integer [ SqlName = SP_GetIntervalNo, SqlProc ]
{
	quit $System.SQL.DATEDIFF("mi",ts,tsmax)\IntervalLength
}

/// Returns <NumberOfIntervals> timestamps, starting with <EndTS>, going backwards in steps of <IntervalLength> minutes
/// Usage: select to_char(TS,'HH24MI'),* from IoT_Data.SP_Intervals('2016-02-22 13:32:28',3,21)
Query Intervals(EndTS As %TimeStamp, IntervalLength As %Integer = 4, NumberOfIntervals As %Integer = 30) As %Query(ROWSPEC = "IntervalStartTS:%TimeStamp,IntervalNo:%Integer,HHMM:%String") [ SqlName = SP_Intervals, SqlProc ]
{
}

ClassMethod IntervalsExecute(ByRef qHandle As %Binary, EndTS As %TimeStamp, IntervalLength As %Integer, NumberOfIntervals As %Integer) As %Status
{

	set qHandle=$LB(0,IntervalLength,NumberOfIntervals,$zdth(EndTS,3))
	
	Quit $$$OK
}

ClassMethod IntervalsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = IntervalsExecute ]
{
	Quit $$$OK
}

ClassMethod IntervalsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = IntervalsExecute ]
{
	set q=$lg(qHandle,1)
	
	set result= $System.SQL.DATEADD("mi",-q*$lg(qHandle,2),$lg(qHandle,4))
	
	set hhmm=$System.SQL.TOCHAR(result,"HH24MI")
	
	set Row=$LB(result,q,hhmm)	
	
	set q=q+1
	set qHandle= $listupdate(qHandle,1,q)
	
	if q>($lg(qHandle,3)) {
		set AtEnd=1
		set Row=""
	} else {
		set AtEnd=0
	}	
	
	Quit $$$OK
}

}
