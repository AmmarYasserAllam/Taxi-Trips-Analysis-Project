/*  Transform and Cleaning the Data */

-- Cleaning and Deleting duplicates rows in the (id column)so that I can make it a primary key in trips table.
With id_duplicates as(
-- Select rows with duplicate 'id' values using ROW_NUMBER().
  Select* 
  From (
      Select 
       *,ROW_NUMBER() Over(Partition by id Order by id) as RN
      From
       Trips ) as temp 
  Where
    RN > 1
  )
-- Delete rows from the temporary table that indicate duplicate 'id' values.
Delete From id_duplicates

--------------------------------------------------

-- Cleaning and Deleting duplicates rows in the (id column) so that I can make it a primary key in Zones table
With id_duplicates as(
-- Select rows with duplicate 'id' values using ROW_NUMBER().
  Select* 
  From(
     	 Select 
      		 *,ROW_NUMBER() Over(Partition by id Order by id) as RN
     	 From
      		 Zones ) as temp 
  Where
   		 RN > 1 )
-- Delete rows from the temporary table that indicate duplicate 'id' values.
Delete 
From id_duplicates

----------------------------------------------------

-- Delete rows from the 'Zones' table where the 'id' column is null so that I can make it a primary key.
Delete from Zones
where       id is null
-----------------------------------------------------
/* 
Select distinct 'pickup_location_id' values from the 'Trips' table 
where they are not found in the 'id' column of the 'Zones' table. 
And insert it into 'id' column of the 'Zones' table
so that i can make it a foreign key referencing the 'id' column in the 'Zones' table. 
*/
Insert into 
       [dbo].[Zones] (id)
Select 
   	distinct pickup_location_id
From 
      Trips 
Where 
      pickup_location_id not in ( 
                                  Select id  
                                  From  [dbo].[Zones]  )
---------------------------------------------------

--Correcting the negative values in specific columns in the 'Trips' table to ensure positive values.
UPDATE 
  Trips 
SET 
  fare_amount = ABS(fare_amount) ,
  extra = ABS(extra) ,
  mta_tax = ABS(mta_tax) ,
  tip_amount = ABS(tip_amount),
  tolls_amount = ABS(tolls_amount),
  airport_fee = ABS(airport_fee),
  total_amount = ABS(total_amount)
WHERE 
  fare_amount < 0 and  extra < 0 and mta_tax < 0 and tip_amount < 0 and 
  tolls_amount < 0 and airport_fee < 0 and total_amount < 0;
 --------------------------------------------
 
--Detect the null values in airport_fee column and make it zeros
update Trips
set    airport_fee = 0
where  airport_fee is null

----------------------------------------------

-- Update the 'Trips' table:
-- Set payment type to 5 where payment type is 0 which refers to Unknown Payment way.
update Trips
  set 
   	 payment_type = 5
  where 
   	 payment_type =0
----------------------------------------------
-- Create a new table named 'Payment' to store payment information.
Create table Payment (
 				 id           varchar(5)  primary key, 
 				 payment_type varchar(50)
);
-----------------------------------------------

-- Insert values for payment types into payment table
INSERT INTO Payment (id, payment_type)
VALUES 		 ('1', 'Credit card'),
      			 ('2', 'Cash'),
      			 ('3', 'No charge'),
     			 ('4', 'Dispute'),
      			 ('5', 'Unknown'),
       		 ('6', 'Voided trip');

----------------------------------------------------


-- Rename the column 'payment_type' in the 'Trips' table to 'payment_id'.
exec sp_rename
@objname = 'Trips.payment_type',
@newname = 'payment_id',
@objtype = 'COLUMN'

-------------------------------------------------------------------------------
/* 
1)	Write a query to get the average trip distance,average trip fare and
   total revenue overall provided data and per zone pair.
*/
------------------------------------------------------------------------------
-------------------------------------------------------
--This is the  Avg_Trip_Distance, Avg_Trip_Fare and Avg_Trip_Fare
Select (SUM (T.trip_distance) / COUNT(T.id)) as Avg_trip_distance,
       (SUM (T.fare_amount)   / COUNT(T.id)) as Avg_trip_fare,
       (Sum (T.total_amount))                as Reveneu,
        Z.zone_name                          as Zone

from    Trips T join Zones Z
     on T.dropoff_location_id = Z.id
group by 
  Z.zone_name
order by 
  Avg_trip_distance desc;
-------------------------------------
--------------------------------------------------









/* 
2) Write a Query to get what hour of the day that has the highest number of trips 
   and average trip price per hour.
*/
-------------------------------------------------------------------------------

--Extract the hour form the pickup_datetime column
SELECT 
  	SUBSTRING(pickup_datetime, 12 , 2) AS Trip_hour 
FROM 
      Trips;
------------------------------------
--Create a new column named Trip_hour in the Trips Table
ALTER TABLE 
     Trips
ADD        
     Trip_hour  VARCHAR(5);

--------------------
--Insert the extracted hours in Trip_hour column
update 
Trips
set 
Trip_hour = SUBSTRING(pickup_datetime, 12 , 2); 

--------------------

--The hour that has the highest number of trips  and the average trip price per hour.
Select 
 	 trip_hour as Trip_Hour, count(trip_hour) as Num_Trips,(sum(total_amount)/ count(id)) as Avg_Trip_Price
from 
 	 Trips 
group by 
 	 trip_hour
order by 
 Num_Trips desc;
-------------------------------------------
--------------------------------------------------
/*
3) What is the most Pickup and Dropoff pair with the highest number of trips? 
*/
---------------------------------------------------------------------------

--The most Pickup and Dropoff pair with the highest number of trips
Select  top(1)* 
from 
  (
    Select * , 
      		Row_number() over(partition by pickup_location_id, dropoff_location_id 
                        		order by pickup_location_id, dropoff_location_id desc ) as RN 
    from 
      		Trips ) as newtable 
order by 
 	      RN desc
------------------------------------------------------------------------------
--------------------------------------------------------------
/*
What did you notice in that doesn't make sense?
--------------------------------------------------------
1)	We notice that the average trip distance column has negative values and that because of the outliers and
are going to handel it in powerBI.

 /*
2)	We notice that in the most (Pickup and Dropoff) pair with the highest number of trips,
 	the values of the 'pickup_location_id'column and the 'dropoff_location_id'column are equal
 	At first look, you might feel that there is an error and it's illogical for the values to be equal
 	However, there is no mistake the two columns represent the same location however 
 	this location includes a variety of different and numerous coordinates.
 */

