-- Problem statement 1- Get Ideas of travel insights 
--  -> Between two pairs of airport
--  -> Most frequent route, No of passengers based on that

Select origin_airport,destination_airport,sum(Passengers) as Total_passengers
from airports group by origin_airport,destination_airport
order by Total_passengers DESC;

-- Outcome - The top 3 frequent route are PDX to RDM having passenger count 1033561
-- SEA to RDM having passenger count 366728
-- SFO to RDM having passenger count 108356
-- Most frequent destination Airport is RDM

-- Problem statement 2 - Identify highest and lowest Seat occupancy
-- Optimize flight capacity
-- Improving operational efficiency

select Origin_airport,destination_airport,round(AVG(CAST(passengers as FLOAT)/NULLIF(seats,0))*100,2)
as Avg_Seat_Utilization from airports group by Origin_airport,destination_airport
order by Avg_Seat_Utilization;

-- Outcome- Most utilized flights are in the region between BIL-RDM,FBK-RDM,FAT-RDM
-- Least  utilized flights are in the region between RDM-RDM,DFW-RDM,BIF-RDM

-- Problem statement 3- Finding out the most Active city on the basis of flights and passengers
-- It helps to optimize capacity Management

select origin_city,COUNT(Flights) as Total_flights,SUM(Passengers) as Total_passengers from 
airports group by Origin_city order by Total_passengers DESC LIMIT 3;

-- Outcome- The Most Active cities are Portland(OR),San Francisco(CA), Seattle(WA)

-- Problem statement 4- Look into Travel patterns and Future route Planning

Select Origin_airport,Sum(Distance) as Total_Distance from airports
group by Origin_airport order by Total_Distance DESC;

-- Outcome - From above we found that Airports having highest travelling Distance.

-- Problem Statement 5- Find out Seasonal Trends

select YEAR(fly_date) as Year,MONTH(fly_date) as Month,count(flights) as Total_Flights,SUM(Passengers) as Total_Passengers,round(avg(distance),2) as
Avg_Distance from airports group by Year,Month order by Total_Passengers DESC;

-- Outcome - From above we found that most running month of year when large no of passengers travel

-- Problem Statement 6- Identify unutilized seats by calculatiing passenger seat ratio
-- unutilized seats are those whose ratio is less than 0.5

select origin_airport,destination_airport,SUM(Passengers) as Total_Passengers,SUM(Seats) as Total_seats,
(SUM(Passengers)*1.0/NULLIF(SUM(Seats),0)) as Passenger_Seat_Ratio from airports
group by origin_airport,destination_airport having Passenger_Seat_Ratio < 0.5
order by Total_Passengers;

-- Outcome - From above analysis we get the unutilized seats between two source

-- Problem Statement 7- Identifying most active airport based on origin aiport

select Origin_airport,Count(flights) as Total_flights from airports group by Origin_airport
order by Total_flights DESC LIMIT 3;

-- Outcome - The stakeholders and Airline companies can provide Quality of Services in these airports

-- Problem Statement 8- Finding top 3 most active origin city with distinct cities

select origin_city,Count(flights) as Total_Flights,Sum(passengers) as Total_passengers from airports
group by origin_city order by Total_Flights DESC limit 3;

-- Outcome - From above query we found that top 3 Most active cities.

-- Problem Statement 9- Finding Longest distance Flights

select origin_airport,destination_airport,MAX(Distance) as Longest_Dist from airports group by origin_airport,destination_airport
order by Longest_Dist DESC Limit 3;

-- Outcome - From above query we found Longest route flights.

-- Problem Statement 10- Finding most busiest and least busiest month based on flights

With Monthly_Flights AS(
Select Month(fly_date) as MONTH,
Count(flights) as Total_flights from airports
group by MONTH(fly_date)
)
select MONTH,Total_flights,
CASE
WHEN Total_flights=(select max(Total_flights) from Monthly_Flights) then "Most Busy"
WHEN Total_flights=(select min(Total_flights) from Monthly_Flights) then "Least Busy"
ELSE NULL
end as Status from Monthly_Flights
where Total_flights=(select max(Total_flights) from Monthly_Flights) OR
Total_flights=(select min(Total_flights) from Monthly_Flights);


-- Problem Statement 11 - Analyzing year by year passenger growth 

WITH Passenger_Summary AS(Select origin_airport,Destination_airport,YEAR(fly_date) as YEAR,Sum(passengers) as Total_passengers
from airports group by origin_airport,Destination_airport,YEAR(fly_date)),

Passenger_growth AS (Select origin_airport,Destination_airport,YEAR,Total_passengers,
LAG(Total_passengers) over(partition by origin_airport,Destination_airport order by YEAR) as Previous_year_passenger
from passenger_Summary)

select origin_airport,Destination_airport,YEAR,Total_passengers,
CASE 
WHEN Previous_year_passenger IS NOT NULL THEN
round(((Total_passengers-Previous_year_passenger)*100.0/NULLIF(Previous_year_passenger,0)),0)
ELSE 0
End as Growth_Percentage
from Passenger_growth
group by origin_airport,Destination_airport,YEAR;

-- Outcome -->
-- This analysis will help identify trends in passenger traffic over time,
-- providing valuable insights for airlines to make informed decisions about route development 
-- and capacity management based on demand fluctuations.

-- Problem Statement 12 - Analyzing year by year flight growth between two sources

WITH Flight_Summary AS(select origin_airport,destination_airport,Year(fly_date) as YEAR,Count(flights) as Total_Flights
from airports group by origin_airport,destination_airport,Year(fly_date)),

Flight_Growth AS (select origin_airport,destination_airport,YEAR,Total_Flights,
LAG(Total_Flights) over(partition by origin_airport,destination_airport order by YEAR) as Previous_year_flights
from Flight_Summary),

Growth_Rates AS(select origin_airport,destination_airport,YEAR,Total_Flights,
CASE 
WHEN Previous_year_flights is not null and Previous_year_flights>0 THEN
((Total_Flights-Previous_year_flights)*100.0/Previous_year_flights)
ELSE null
end as Growth_rate,
CASE
WHEN Previous_year_flights is not null and Total_Flights>Previous_year_flights THEN 1
ELSE 0
End as Growth_Indicator
from Flight_Growth)

Select origin_airport,destination_airport,
MIN(Growth_rate) as Minimum_Growth_Rate,
MAX(Growth_rate) as Maximum_Growth_Rate
from Growth_Rates
where Growth_indicator=1
group by origin_airport,destination_airport
having MIN(Growth_Indicator)=1 order by origin_airport,destination_airport;

-- Outcome - This Analysis found the total growth of flights per year

-- Problem Statement 13- Determine the top 3 origin airports with the highest weighted passenger-to-seats utilization ratio

WITH Utilization_Ratio AS (Select origin_airport,SUM(Passengers) as Total_Passengers,
SUM(Seats) as Total_seats,count(Flights) as Total_flights,
(SUM(Passengers)*1.0/SUM(Seats)) as Passenger_Seat_Ratio
from airports group by origin_airport),

Weighted_Utilization AS(Select origin_airport,Total_Passengers,Total_seats,Total_flights,Passenger_Seat_Ratio,
(Passenger_Seat_Ratio*Total_flights)/SUM(Total_flights) OVER() as Weighted_utilization
from Utilization_Ratio)

Select origin_airport,Total_Passengers,Total_seats,Total_flights,Passenger_Seat_Ratio,Weighted_utilization
from Weighted_utilization order by Weighted_utilization DESC LIMIT 3;

-- Problem Statement 14- Identify the peak traffic month for each origin city based on the highest number of passengers

WITH Monthly_Passenger_Count AS (Select origin_city,Year(fly_date) as Year,Month(fly_date) as Month,sum(Passengers) as Total_Passengers
from airports group by origin_city,Year(fly_date),Month(fly_date)),

Max_Passenger_perCity as (Select origin_city,MAX(Total_Passengers) as Peak_Passengers from Monthly_Passenger_Count
group by origin_city)

Select mpc.origin_city,mpc.Year,mpc.Month,mpc.Total_Passengers from Monthly_Passenger_Count mpc
join Max_Passenger_perCity mp ON mpc.origin_city=mp.origin_city and
mpc.total_Passengers=mp.peak_passengers
order by mpc.origin_city,mpc.Year,mpc.Month; 

-- Outcome - This analysis will help to reveal seasonal travel patterns specific to each city,
-- enabling airlines to tailor their services and marketing strategies to meet demand effectively.

-- Problem Statement 15- Identify the routes which experienced large yearly decline in passengers

WITH Yearly_Passenger_count AS (Select Origin_airport,Destination_airport,Year(fly_date) as Year,SUM(passengers) as Total_Passengers
from airports group by Origin_airport,Destination_airport,Year(fly_date)),

Yearly_decline AS (Select y1.origin_airport,y1.destination_airport,y1.YEAR as Year1,y1.Total_passengers as Passengers_Year1,y2.Year as Year2,
y2.Total_passengers as Passengers_Year2,((y2.Total_passengers-y1.Total_passengers)/NULLIF(y1.Total_passengers,0))*100 as Percentage_Change
from Yearly_Passenger_count y1 join Yearly_Passenger_count y2 on
y1.origin_airport=y2.origin_airport and y1.destination_airport=y2.destination_airport
and y1.year=y2.year+1)
Select Origin_airport,Destination_airport,Year1,Year2,Passengers_Year1,Passengers_Year2,Percentage_Change from Yearly_decline
where Percentage_Change<0 order by Percentage_Change ASC Limit 5;

-- Outcome - This analysis will help airlines pinpoint routes facing reduced demand,
-- allowing for strategic adjustments in operations, marketing, and service offerings to address the decline effectively.

-- Problem Statement 16 - Identify all origin and destination airports that had at least 10 flights
-- but maintained an average seat utilization (passengers/seats) of less than 50%.

WITH Flight_Stats AS (Select origin_airport,Destination_airport,Count(Flights) as Total_flights,Sum(Passengers) as Total_Passengers,
Sum(Seats) as Total_Seats,
(Sum(Passengers)/Nullif(Sum(Seats),0)) as Avg_Seat_Utilization from airports
group by origin_airport,Destination_airport)
Select origin_airport,Destination_airport,Total_flights,Total_Passengers,Total_Seats,
Avg_Seat_Utilization,round(Avg_Seat_Utilization*100,2)as Avg_Seat_Utilization_Percentage
from Flight_Stats where Total_flights>=10 and round(Avg_Seat_Utilization*100,2) < 50 
order by Avg_Seat_Utilization_Percentage ASC;

-- Outcome - This analysis will highlight underperforming routes, allowing airlines to reassess their capacity management strategies
-- and make informed decisions regarding potential service adjustments to optimize seat utilization and improve profitability.

-- Problem Statement 17- Calculate the average flight distance for each unique city-to-city pair (origin and destination) 
-- and identify the routes with the longest average distance

WITH Distance_Stats AS (Select Origin_airport,Destination_airport,AVG(Distance) as Avg_Flight_Distance from airports
group by Origin_airport,Destination_airport)
select Origin_airport,Destination_airport,round(Avg_Flight_Distance,2) as Avg_flight_Distance from 
Distance_Stats order by Avg_flight_Distance DESC;

-- Outcome - This analysis will provide insights into long-haul travel patterns,helping airlines assess operational considerations
-- and potential market opportunities for extended routes.

-- Problem Statement 18- The objective is to calculate the total number of flights and passengers for each year, 
-- along with the percentage growth in both flights and passengers compared to the previous year

WITH Yearly_Summary AS (Select Year(fly_date) as Year,Count(passengers) as Total_Passengers,Sum(Flights) as Total_Flights
from airports group by Year),

Year_Growth AS (select Year,Total_Passengers,Total_Flights,LAG(Total_Passengers) over(order by Year) as Prev_Passengers,
LAG(Total_Flights) over(order by Year) as Prev_flights from Yearly_Summary)

Select Year,Total_Passengers,Total_Flights,
round(((Total_Passengers-Prev_Passengers)/nullif(Prev_Passengers,0)*100),2) as Passenger_Growth_percentage,
round(((Total_Flights-Prev_flights)/nullif(Prev_flights,0)*100),2) as Flight_Growth_Percentage
from Year_Growth order by Year;

-- Outcome - This analysis will provide a comprehensive overview of annual trends in air travel,enabling airlines and stakeholders to assess growth patterns and 
-- make informed strategic decisions for future operations.

-- Problem Statement 19- identify the top 3 busiest routes (origin-destination pairs) based on the total distance flown,
--  weighted by the number of flights. 

With Flight_Route As (Select Origin_airport,Destination_airport,SUM(Flights) as Total_Flights,
SUM(Distance) as Total_Distances from airports
group by Origin_airport,Destination_airport),

Weighted_Distance AS(Select Origin_airport,Destination_airport,Total_Flights,Total_Distances,
Total_Flights*Total_Distances as Weighted_Distance from Flight_Route)

Select Origin_airport,Destination_airport,Total_Flights,Total_Distances,Weighted_Distance
from Weighted_Distance order by Weighted_Distance DESC LIMIT 3;

-- Outcome - This analysis will highlight the most significant routes in terms of distance and operational activity, 
-- providing valuable insights for airlines to optimize their scheduling and resource allocation strategies.