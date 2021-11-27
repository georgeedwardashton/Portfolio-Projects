-- The purpose of this project is to showcase my ability to clean datasets using SQL code. The dataset I will be using today
-- is data related to licensed auctioneers within the state of Texas. It is quite a strange choice I know but out of the trades listed
-- on the website I was browsing, I thought it would be quite interesting to look into (and Bargain Hunt was on TV in the background).

-- First of all, I'm checking that the spreadsheet has been loaded into Microsoft SQL Server correctly. 
SELECT * FROM auction;

-- From first inspection, I can see multiple options for data cleaning. The first column 'license_type' just contains the word
-- 'Auctioneer' in each row and is therefore redundant. I acknowledge that the deletion of entire columns of data is not commonly done
-- in the workplace without good reason but in this project I will be doing so.

ALTER TABLE auction
DROP COLUMN license_type;

SELECT * FROM auction;

-- First column has been successfully deleted. In fact, there are multiple other columns that can be deleted which contain null fields.
-- Due to the columns containing sensitive info, they are now blank and therefore no longer serve a purpose.

ALTER TABLE auction
DROP COLUMN address_line_1,
			address_line_2,
			city_state,
			phone_number,
			business_address_line_1,
			business_address_line_2,
			business_city_state_zip,
			business_zip,
			business_phone,
			license_subtype;

SELECT * FROM auction;

-- Columns deleted successfully. We could possibly make the license_number column a primary key if all of the numbers are unique.
-- Let's check if they are.

SELECT COUNT(DISTINCT license_number) FROM auction;

-- The number of unique license numbers = the number of total rows. We can now set it as a primary key without worrying
-- Let's alter the column constraints so the values can't be null before we set the primary key.

ALTER TABLE auction
ALTER COLUMN license_number float not null;

-- Having the data type for the license number being a float is a bit pointless considering the numbers are always integers, so let's
-- change that.

ALTER TABLE auction
ALTER COLUMN license_number int;

-- Now let's set the primary key.

ALTER TABLE auction
ADD CONSTRAINT PK_license_number
PRIMARY KEY (license_number);

SELECT * FROM auction;

-- Let's now change the data type for the license expiry date from a string to a date. This will make the data more useful to use in
-- data visualisation software such as Tableau or Power BI.

ALTER TABLE auction
ALTER COLUMN license_exp_date date;

-- Lets make all of the letters in the County column lowercase.
UPDATE auction
SET county = LOWER(county);

SELECT county FROM auction;

-- All lowercase. Lets change it back.

UPDATE auction
set county = UPPER(county);
SELECT * FROM auction;

-- Now I want to change N to NO and Y to YES in the continuing_education column.

UPDATE auction
SET continuing_education =
	CASE WHEN continuing_education = 'N' THEN 'NO'
		 WHEN continuing_education = 'Y' THEN 'YES'
		 ELSE continuing_education
END

-- full_name and business_name are duplicate columns so lets delete business_name

ALTER TABLE auction
DROP COLUMN business_name;

-- Now let's split up the full names of the auctioneer licensees into first names and surnames, create new columns and add the values
-- into them.

SELECT full_name FROM auction;

SELECT SUBSTRING(full_name, 1,(CHARINDEX(',',full_name)-1)) AS surname FROM auction;

-- Let's talk about these string mainupaltion functions for a second. The substring function is being used to extract the surname
-- of the license holder from the full name. The charindex function is nested within the substring function in order to determine the
-- end position of the substring (which will change from name to name due to the variance in length). The charindex function returns the
-- position of the comma within the string so -1 is put next to it in order to go one character back from the comma and just return the
-- surnames.

-- We will now add a new column for the surnames and add them into it.

ALTER TABLE auction
ADD surname nvarchar(50);

-- Column added.

UPDATE auction
SET surname = SUBSTRING(full_name, 1,(CHARINDEX(',',full_name)-1));

-- Surnames added. I want to extract just the columns for license number, surname, license expiry date and business county
-- code with aliased names. I also want to order the data by license expiry date in order to see which .
SELECT license_number AS "License Number",
	   surname AS "Surname",
	   license_exp_date AS "License Expiry Date",
	   business_county AS "Business County"
	   FROM auction
	   ORDER BY [License Expiry Date];

-- We can use this query as a CTE by using a with statement before it, and run further queries upon it as if it was a table within the
-- database. This can be a useful trick to use when you may not have permission to create new tables within a database. Let's set the
-- query as a CTE, extract all columns within and 

WITH cte AS(
	   SELECT license_number AS "License Number",
	   surname AS "Surname",
	   license_exp_date AS "License Expiry Date",
	   business_county AS "Business County"
	   FROM auction)
SELECT * FROM cte WHERE "License Number" BETWEEN 7000 AND 10000;

-- To demonstrate how to use joins, I am going to create a temporary table which only contains columns for license number and a micellaneous
-- column. Let's call the new temp table "bargain" this new column "hunt" and insert the phrase "SOLD" in each row.

CREATE TABLE #bargain (
         license_number int NOT NULL,
		 hunt nvarchar(10));

INSERT INTO #bargain (license_number)
SELECT license_number FROM auction;

UPDATE #bargain
SET hunt = 'SOLD';

SELECT * FROM #bargain;

-- With the temporary table created and columns now filled, lets join the cte created earlier with the new table. We will perform an
-- inner join and join on the license number column.

WITH cte AS(
	   SELECT license_number,
	   surname,
	   license_exp_date,
	   business_county
	   FROM auction)
SELECT cte.license_number, cte.surname, #bargain.hunt
FROM cte
JOIN #bargain ON #bargain.license_number= cte.license_number;

-- If you are wondering, this was just an elaborate way to see Bargain Hunt within the code. Thanks for reading.