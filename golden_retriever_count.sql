
use seattle_pet_licenses


----------------------------------------------------------------------
--QUESTION 1
--What zip code has the most Golden Retrievers?
----------------------------------------------------------------------

--Take a look at the data that was retrieved in Python
select top 1000 * from [Ingest_pet_license_raw_data_999999_20190909_1810]

--Make sure it's all there
select count(*) from [Ingest_pet_license_raw_data_999999_20190909_1810]
--51,754 rows, looks good.

--Look for Golden Retrievers
select distinct primary_breed, secondary_breed
from [Ingest_pet_license_raw_data_999999_20190909_1810]
where primary_breed like '%golden%'
or secondary_breed like '%golden%'
--The only format for Golden Retrievers is, "Retriever, Golden", so we can create our where clauses to match exactly that.

--Take a look at zip code data cleanliness
select distinct zip_code
from [Ingest_pet_license_raw_data_999999_20190909_1810]
--There are both 5-digit and 9-digit zip codes present, so let's be careful of that later.

--Find the zip code with the most Golden Retrievers
select zip_code
,count(*) as count_animals
from [Ingest_pet_license_raw_data_999999_20190909_1810]
where primary_breed = 'Retriever, Golden'
or secondary_breed = 'Retriever, Golden'
group by zip_code
order by count(*) desc
--We see that there are only 3 results with a 9-digit zip-code, so it won't impact our outcome, but just for posterity, let's clean that up in the next query.

--Find the zip code with the most Golden Retrievers  -  5-digit zip code only
select left(zip_code,5) as zip_code
,count(*) as count_animals
from [Ingest_pet_license_raw_data_999999_20190909_1810]
where primary_breed = 'Retriever, Golden'
or secondary_breed = 'Retriever, Golden'
group by left(zip_code,5)
order by count(*) desc
--There are also 6 Golden Retrievers with NULL zip code.

--And just to make sure we're not crazy...
select *
from [Ingest_pet_license_raw_data_999999_20190909_1810]
where (primary_breed = 'Retriever, Golden'
or secondary_breed = 'Retriever, Golden')
and species <> 'dog'
--0 rows, good.


--ANSWER:  Zip code 98115 has the most Golden Retrievers with 224 dogs.  (Possibly up to 230, given the 6 dogs with unknown zip code.)





----------------------------------------------------------------------
--QUESTION 2
--Via a visualization method of your choosing,
--make a chart showing the number of licenses per year per species.
----------------------------------------------------------------------

--My current end users expect visualization output in a consistent Excel format, so I currently have the most experience with Excel.
--First, we'll prep the data for output to Excel.  The ideal scenario is for the data to be easily consumed in Excel
--so that we can later automate additional pieces of the process, for example by using an Excel data connection directly
--to the SQL database, or by generating the Excel file itself from Python code.

--Number of licenses per year per species
select year(license_issue_date) as issue_year
,species
,count(*) as count_animals
from [Ingest_pet_license_raw_data_999999_20190909_1810]
group by year(license_issue_date), species
order by year(license_issue_date), species
--This result would be better formatted if we pivot the species across columns.
--However, SQL syntax for pivoting is fussy, so when possible, I prefer to write more readable, more maintainable SQL code
--to pivot with CASE statements as follows.

--Pivot species to columns
select year(license_issue_date) as issue_year
,count(CASE
		WHEN species = 'Cat' THEN 1
		ELSE NULL
	   END) as 'cat'
,count(CASE
		WHEN species = 'Dog' THEN 1
		ELSE NULL
	   END) as 'dog'
,count(CASE
		WHEN species = 'Goat' THEN 1
		ELSE NULL
	   END) as 'goat'
,count(CASE
		WHEN species = 'Pig' THEN 1
		ELSE NULL
	   END) as 'pig'
from [Ingest_pet_license_raw_data_999999_20190909_1810]
group by year(license_issue_date)
order by year(license_issue_date)
--Sidenote:  it looks like we have some outliers for data prior to 2015.  TODO:  Investigate further.

--There are some years that don't have data.  We may want to include zero values for these years,
--so one quick way to do so is to join to a calendar lookup table.  I'll keep this one simple.

	create table year_lookup ([year] int NOT NULL)

	declare @i int = 2003
	while @i <= 2019
	begin
		INSERT INTO [dbo].[year_lookup]
			   ([year])
		VALUES
			   (@i)
		set @i = @i + 1
	end
	

--Pivot species to columns, now joining to the calendar_lookup table to fill in empty years
select years.year as issue_year
,count(CASE
		WHEN species = 'Cat' THEN 1
		ELSE NULL
	   END) as 'cat'
,count(CASE
		WHEN species = 'Dog' THEN 1
		ELSE NULL
	   END) as 'dog'
,count(CASE
		WHEN species = 'Goat' THEN 1
		ELSE NULL
	   END) as 'goat'
,count(CASE
		WHEN species = 'Pig' THEN 1
		ELSE NULL
	   END) as 'pig'
from [Ingest_pet_license_raw_data_999999_20190909_1810] dat
right join year_lookup as years
on year(dat.license_issue_date) = years.year
group by years.year
order by years.year

--At this point, we can pipe this data into Excel for charting.  (See Excel file, "licenses_by_species_visualization.xlsx")
--If we were looking to automate this visualization component while still using Excel,
--I would run the above SQL from within Python and use openpyxl to manipulate Excel files,
--or I would use a saved SQL query within the Excel file, which can query the database directly.
--Otherwise, if we are looking to fully automate the visualization component,
--I would investigate the best delivery mechanism for the end user, such as matplotlib, Tableau, etc.





----------------------------------------------------------------------
--QUESTION 3
--How would you extend this job to continuously capture pet license data?
--A description of your thoughts here are sufficient, you do not need to write this code.
----------------------------------------------------------------------

/*

To continuously capture pet data, we would need to keep track of what data we have already received.
The license_issue_date and license_number columns together should hopefully form a composite key that uniquely
identifies a single pet license record.  license_number by itself may also be a unique identifier for each record,
but it could be that a renewed pet license keeps the same license_number and has an updated date,
so we will want to use both together to identify unique records.

A regularly-scheduled job would run to pull data from the data source, in this case using the Seattle data website's API.
Depending on the update frequency of the data source, a scheduled job could run on the scale of minutes or months.
It looks like we can specify date filters in the API that would allow us to pull only the new data.
Alternatively, we can also pull the full data set on a regular basis and then later determine which rows are new.
This second approach could be important in cases where existing data changes, for example.

To manage the data ingest, I would create what I call a "load control" table, which is used to track data received and loaded.
When the data-fetching job runs and pulls data from the source, it adds an entry into load control,
including various metadata like fetch-date, number of rows, filepath, filename, etc.
A separate job or a separate step can load the data into the database and update the load control status.

I'm happy to go into more detail on these next steps to continuously capture pet data.

*/







