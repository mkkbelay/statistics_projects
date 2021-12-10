/*maximal departure delay in minutes for each airline. */

select L_AIRLINE_ID.NAME, max(al_perf.DepDelayMinutes) as maximal_dep_delay
from L_AIRLINE_ID, al_perf
where L_AIRLINE_ID.ID=al_perf.DOT_ID_Reporting_Airline
group by L_AIRLINE_ID.ID
order by maximal_dep_delay;
#Output: 14 row(s) returned. 


/*maximal early departures in minutes for each airline. */

select L_AIRLINE_ID.NAME, min(DepDelay)as earliest_dep
from L_AIRLINE_ID, al_perf
where L_AIRLINE_ID.ID=al_perf.DOT_ID_Reporting_Airline 
group by L_AIRLINE_ID.ID
order by earliest_dep asc;
#Output: 14 row(s) returned.

 
/*Rank days of the week by the number of flights performed by all airlines on that day ( 1 is the 
busiest). */

select L_WEEKDAYS.Day, sum(Flights) as number_of_flights, rank() over (order by count(Flights) desc) as ranks
from al_perf, L_WEEKDAYS
where al_perf.DayOfWeek=L_WEEKDAYS.Code
group by L_WEEKDAYS.Day
order by ranks;
#Output: 7row(s) returned.
 
/* airport that has the highest average departure delay among all airports. */ 

with average_dep_delays as (select L_AIRPORT_ID.NAME as airport_name, L_AIRPORT.Code, avg(DepDelayMinutes) as average_delay
from L_AIRPORT_ID, al_perf, L_AIRPORT
where L_AIRPORT_ID.ID=al_perf.OriginAirportID and L_AIRPORT_ID.NAME=L_AIRPORT.NAME
group by L_AIRPORT_ID.ID)
select *
from average_dep_delays
where average_delay=(select max(average_delay) from average_dep_delays);
#Output: 1 row(s) returned.



/*find an airport where it has the highest average departure delay. */
with highest_delays as 
(select L_AIRLINE_ID.Name as airline_name, L_AIRPORT_ID.NAME as airport_name, avg(DepDelayMinutes) as avg_delay, rank() over (partition by L_AIRLINE_ID.ID order by avg(DepDelayMinutes) desc) as s_rank
from L_AIRPORT_ID, al_perf, L_AIRLINE_ID
where L_AIRPORT_ID.ID=al_perf.OriginAirportID and L_AIRLINE_ID.ID=al_perf.DOT_ID_Reporting_Airline
group by L_AIRLINE_ID.ID,L_AIRPORT_ID.ID)
select airline_name, airport_name, avg_delay
from highest_delays
where s_rank =1; 
#Output: 14 row(s) returned

 
/* canceled flights.*/

select sum(Flights) as num_cancelled_flights 
from al_perf
where Cancelled=1; /*There are 6,735 cancelled flights in the dataset.*/
#Output: 1 row(s) returned. 


/* most frequent reason for each departure airport. */

with frequent_reason as (
select L_AIRPORT_ID.ID,L_AIRPORT_ID.Name,L_CANCELATION.Reason, count(CancellationCode) as number_of_cancellations, rank() over (partition by L_AIRPORT_ID.ID order by count(CancellationCode) desc) as "Rank"
from L_AIRPORT_ID, al_perf, L_CANCELATION
where L_AIRPORT_ID.ID=al_perf.OriginAirportID and Cancelled=1 and L_CANCELATION.Code=CancellationCode
group by L_AIRPORT_ID.ID,L_AIRPORT_ID.Name, al_perf.CancellationCode)
select NAME, Reason as most_freq_reason, number_of_cancellations
from frequent_reason
where frequent_reason.Rank=1
order by Name;
#Output: 306 row(s) returned.
 
/*Build a report that for each day output average number of flights over the preceding 3 days.*/
with report as( 
select L_WEEKDAYS.Day, FlightDate, sum(Flights) as num_flights
from al_perf, L_WEEKDAYS
where al_perf.DayOfWeek=L_WEEKDAYS.Code 
group by L_WEEKDAYS.Day, FlightDate)
select Day, FlightDate, avg(num_flights)
	over(partition by Day order by FlightDate rows between 3 preceding and current row)
	as avg_num_flights
from report; 
# Output: 31 row(s) returned.

