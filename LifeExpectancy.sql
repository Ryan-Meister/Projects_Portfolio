#World Life Expectancy


#Explore the table
SELECT *
FROM projects.WorldLifeExpectancy;



#PART 1: DATA CLEANING



#1.1 Removing Duplicates
#Set has data on the years 2007 to 2022 (16 years total)
SELECT Country, COUNT(Country) count
FROM WorldLifeExpectancy
GROUP BY Country
ORDER BY count DESC;
	#We see there are countries with 17, 16, 15 and 1 year(s) of data (most have 16)

#Identify all countries that do not have 16 years of data
SELECT Country, COUNT(Country) count
FROM WorldLifeExpectancy
GROUP BY Country
HAVING count <> 16
ORDER BY count DESC;

#Display records that do not have a count of 16
SELECT *
FROM WorldLifeExpectancy
WHERE Country IN (
    SELECT Country
    FROM WorldLifeExpectancy
    GROUP BY Country
    HAVING COUNT(*) <> 16
);
	#Notes
		#COUNT = 17
			#IRELAND: 2022 is duplicated (all values the same) -> DROP Row_ID = 1251
			#SENGAL: 2009 is duplicated (all values the same) -> DROP Row_ID = 2264
			#ZIMBABWE: 2019 is duplicated (all values the same) -> DROP Row_ID = 2928
		#COUNT = 15
			#AFGANISTAN: 2018 is missing -> Consider dropping
            #ALBANIA: 2018 is missing -> Consider dropping
		#COUNT = 1
			#Cook Islands, Dominica, Marshall Islands, Monaco, Nauru, Niue, Palau, Saint Kitts and Nevis, San Marino, Tuvalu
				#Only 2020 data available, has unreasonable values (Life expectancy = 0) -> DROP ALL countries

#Execute list above
#Drop duplicate years
DELETE FROM WorldLifeExpectancy
WHERE Row_ID IN (1251, 2264, 2928);

#Drop countries
DELETE FROM WorldLifeExpectancy
WHERE Country IN (
    SELECT Country
    FROM (
        SELECT Country
        FROM WorldLifeExpectancy
        GROUP BY Country
        HAVING COUNT(*) = 1
    ) AS sub
);

#Check to Ensure changes were made
	#Note, Albania and Afganistan are still <> 16
SELECT Country, COUNT(Country) count
FROM WorldLifeExpectancy
GROUP BY Country
ORDER BY count DESC;

#Display all data for quick look over
SELECT *
FROM WorldLifeExpectancy;





#1.2 STANDARDIZING
#Start with `Status`
	#These are repeat values, however some are missing 
SELECT Country, Status, COUNT(*) AS status_count
FROM WorldLifeExpectancy
GROUP BY Country, Status
ORDER BY Country, status_count DESC;

#Replace the empty values with the values of `Status` for all the other years
UPDATE WorldLifeExpectancy w
JOIN (
	SELECT Country, ANY_VALUE(Status) AS fill_status
	FROM WorldLifeExpectancy
	WHERE Status IS NOT NULL AND Status <> ''
	GROUP BY Country
    ) AS x
ON x.Country = w.Country
SET w.Status = x.fill_status
WHERE w.Status IS NULL or w.Status = '';

#Double check to ensure there's no null or empty values remaining
SELECT Country, Status, COUNT(*) AS status_count
FROM WorldLifeExpectancy
GROUP BY Country, Status
ORDER BY Country, status_count DESC;

#Display all data for quick look over
SELECT *
FROM WorldLifeExpectancy;





#1.3 Explore summary statistics - unreasonable values

#Build summary_stats table
DROP TABLE IF EXISTS summary_stats;
CREATE TABLE summary_stats
WITH
#1 Unpivot the numeric columns you want to summarize
numeric_data AS (
    SELECT 'life_expectancy' AS var, CAST(`Life expectancy` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'adult_mortality', CAST(`Adult Mortality` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'infant deaths', CAST(`infant deaths` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'percentage expenditure', CAST(`percentage expenditure` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'Measles', CAST(`Measles` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'BMI', CAST(`BMI` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'under-five deaths', CAST(`under-five deaths` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'Polio', CAST(`Polio` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'Diphtheria', CAST(`Diphtheria` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'HIV/AIDS', CAST(`HIV/AIDS` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'GDP', CAST(`GDP` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'thinness  1-19 years', CAST(`thinness  1-19 years` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'thinness 5-9 years', CAST(`thinness 5-9 years` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
    UNION ALL
    SELECT 'Schooling', CAST(`Schooling` AS DECIMAL(10,2)) AS val
    FROM WorldLifeExpectancy
),

#2 Aggregates
agg AS (
    SELECT
        var,
        COUNT(val)                 AS N,
        ROUND(AVG(val), 0)         AS Mean,
        ROUND(STDDEV_SAMP(val), 0) AS Stdev,
        ROUND(MIN(val), 0)         AS Minimum,
        ROUND(MAX(val), 0)         AS Maximum
    FROM numeric_data
    WHERE val IS NOT NULL
    GROUP BY var
),

#3 Median
med AS (
    SELECT var, ROUND(AVG(val), 0) AS Median
    FROM (
        SELECT
            var, val,
            ROW_NUMBER() OVER (PARTITION BY var ORDER BY val) AS rn,
            COUNT(*)    OVER (PARTITION BY var)               AS cnt
        FROM numeric_data
        WHERE val IS NOT NULL
    ) t
    WHERE rn IN (FLOOR((cnt + 1)/2), CEIL((cnt + 1)/2))
    GROUP BY var
),

#4 Mode (lowest value wins ties)
mode_calc AS (
    SELECT var, ROUND(val, 0) AS Mode
    FROM (
        SELECT
            var, val,
            ROW_NUMBER() OVER (PARTITION BY var ORDER BY cnt DESC, val ASC) AS rnk
        FROM (
            SELECT var, val, COUNT(*) AS cnt
            FROM numeric_data
            WHERE val IS NOT NULL
            GROUP BY var, val
        ) c
    ) d
    WHERE rnk = 1
)

#5 Final summary table
SELECT
    a.var       AS `Variable`,
    a.N,
    a.Mean,
    m.Median,
    mo.Mode,
    a.Stdev,
    a.Minimum,
    a.Maximum
FROM agg a
JOIN med      m  USING (var)
LEFT JOIN mode_calc mo USING (var);


#Display table to view
SELECT *
FROM summary_stats;


#Index for faster lookups by variable name
ALTER TABLE summary_stats ADD PRIMARY KEY (`Variable`);


#Delete outliers (any numeric column outside Mean ± 2.5*Stdev)
DELETE w
FROM WorldLifeExpectancy w
WHERE
  (CAST(`Life expectancy` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='life_expectancy') > 0
   AND (
     CAST(`Life expectancy` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='life_expectancy') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='life_expectancy')
     OR
     CAST(`Life expectancy` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='life_expectancy') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='life_expectancy')
   ))
  OR
  (CAST(`Adult Mortality` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='adult_mortality') > 0
   AND (
     CAST(`Adult Mortality` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='adult_mortality') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='adult_mortality')
     OR
     CAST(`Adult Mortality` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='adult_mortality') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='adult_mortality')
   ))
  OR
  (CAST(`infant deaths` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='infant deaths') > 0
   AND (
     CAST(`infant deaths` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='infant deaths') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='infant deaths')
     OR
     CAST(`infant deaths` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='infant deaths') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='infant deaths')
   ))
  OR
  (CAST(`percentage expenditure` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='percentage expenditure') > 0
   AND (
     CAST(`percentage expenditure` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='percentage expenditure') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='percentage expenditure')
     OR
     CAST(`percentage expenditure` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='percentage expenditure') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='percentage expenditure')
   ))
  OR
  (CAST(`Measles` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='Measles') > 0
   AND (
     CAST(`Measles` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='Measles') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Measles')
     OR
     CAST(`Measles` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='Measles') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Measles')
   ))
  OR
  (CAST(`BMI` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='BMI') > 0
   AND (
     CAST(`BMI` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='BMI') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='BMI')
     OR
     CAST(`BMI` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='BMI') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='BMI')
   ))
  OR
  (CAST(`under-five deaths` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='under-five deaths') > 0
   AND (
     CAST(`under-five deaths` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='under-five deaths') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='under-five deaths')
     OR
     CAST(`under-five deaths` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='under-five deaths') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='under-five deaths')
   ))
  OR
  (CAST(`Polio` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='Polio') > 0
   AND (
     CAST(`Polio` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='Polio') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Polio')
     OR
     CAST(`Polio` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='Polio') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Polio')
   ))
  OR
  (CAST(`Diphtheria` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='Diphtheria') > 0
   AND (
     CAST(`Diphtheria` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='Diphtheria') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Diphtheria')
     OR
     CAST(`Diphtheria` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='Diphtheria') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Diphtheria')
   ))
  OR
  (CAST(`HIV/AIDS` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='HIV/AIDS') > 0
   AND (
     CAST(`HIV/AIDS` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='HIV/AIDS') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='HIV/AIDS')
     OR
     CAST(`HIV/AIDS` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='HIV/AIDS') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='HIV/AIDS')
   ))
  OR
  (CAST(`GDP` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='GDP') > 0
   AND (
     CAST(`GDP` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='GDP') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='GDP')
     OR
     CAST(`GDP` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='GDP') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='GDP')
   ))
  OR
  (CAST(`thinness  1-19 years` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='thinness  1-19 years') > 0
   AND (
     CAST(`thinness  1-19 years` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='thinness  1-19 years') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='thinness  1-19 years')
     OR
     CAST(`thinness  1-19 years` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='thinness  1-19 years') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='thinness  1-19 years')
   ))
  OR
  (CAST(`thinness 5-9 years` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='thinness 5-9 years') > 0
   AND (
     CAST(`thinness 5-9 years` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='thinness 5-9 years') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='thinness 5-9 years')
     OR
     CAST(`thinness 5-9 years` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='thinness 5-9 years') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='thinness 5-9 years')
   ))
  OR
  (CAST(`Schooling` AS DECIMAL(10,2)) IS NOT NULL
   AND (SELECT Stdev FROM summary_stats WHERE Variable='Schooling') > 0
   AND (
     CAST(`Schooling` AS DECIMAL(10,2)) <
       (SELECT Mean FROM summary_stats WHERE Variable='Schooling') - 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Schooling')
     OR
     CAST(`Schooling` AS DECIMAL(10,2)) >
       (SELECT Mean FROM summary_stats WHERE Variable='Schooling') + 2.5*(SELECT Stdev FROM summary_stats WHERE Variable='Schooling')
   ));
   

#Display
SELECT *
FROM WorldLifeExpectancy;


#Perform another count
SELECT
	ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_num,
	Country,
    COUNT(*) AS count
FROM WorldLifeExpectancy
GROUP BY Country;


#Ony use the data for the past 10 years for each country (2021-2012)
	#percentage expenditure is 0 for 2022
DELETE FROM WorldLifeExpectancy
WHERE Year NOT IN (2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012);

#Drop countries that do not have data for all of these 10 years
DELETE FROM WorldLifeExpectancy
WHERE Country IN (
    SELECT Country
    FROM (
        SELECT Country
        FROM WorldLifeExpectancy
        GROUP BY Country
        HAVING COUNT(*) <> 10
    ) AS sub
);

#Display countries that made it to the final-cut
SELECT
	ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_num,
	Country,
    COUNT(*) AS count
FROM WorldLifeExpectancy
GROUP BY Country;

#Drop Row_ID
ALTER TABLE WorldLifeExpectancy
DROP COLUMN Row_ID;

#Display the final table of clean data
SELECT *
FROM WorldLifeExpectancy
ORDER BY Country ASC, Year DESC;





#PART 2: Exploratory Data Analysis

#1. Display Summary Statistics for each country
SELECT Country,
`Status`,
ROUND(AVG(`Life expectancy`), 1) AS avg_life_expectancy
FROM worldlifeexpectancy
GROUP BY Country, Status
ORDER BY avg_life_expectancy DESC;
	#Notes:
		#Here are the top 5 countries (in the sample) that have the highest average life expectancy (using 10 years of data in 2012-2021)
			#Spain		Developed		83.2
			#Greece		Developing		82.4
			#Italy		Developed		82.4
			#Israel		Developing		82
			#Portugal	Developed		81.3
				#Notice how there's 2 'Developing' countries in the top 5!
					#Which Status has a higher life expectancy? (prediction: Developed, but the margin may be closer than anticipated)

#Do 'Developed' or 'Developing' countries have a higher life expectancy?
SELECT `Status`,
ROUND(AVG(`Life expectancy`), 1) AS avg_life_expectancy
FROM worldlifeexpectancy
GROUP BY Status
ORDER BY avg_life_expectancy DESC;
	#Results:
		#Developed	77.5
		#Developing	71.4
			#Notes - Developed countries have an average life expectancy that is 5.9 years longer than developing, other factors held constant

#How many Developed vs Developing countries are there?
SELECT `Status`,
COUNT(DISTINCT Country) as country_count
FROM worldlifeexpectancy
GROUP BY `Status`;
	#Notes - Out of 68 countries, only 14 are Developed

#percent_expenditure is named wrongly - it is the amount of money (USD) spent on healthcare
ALTER TABLE WorldLifeExpectancy
CHANGE COLUMN `percentage expenditure` health_care_expenditure DECIMAL(12,2);


#How do the other variables compare to the average life expectancy?
SELECT `Status`,
ROUND(AVG(`Life expectancy`), 1) AS avg_life_expectancy,
ROUND(AVG(`Adult Mortality`), 1) AS avg_adult_mortality,
ROUND(AVG(`infant deaths`), 1) AS avg_infant_deaths,
ROUND(AVG(`health_care_expenditure`), 1) AS avg_health_care_expenditure,
ROUND(AVG(`Measles`), 1) AS avg_measles,
ROUND(AVG(`BMI`), 1) AS avg_bmi,
ROUND(AVG(`under-five deaths`), 1) AS avg_under_five_deaths,
ROUND(AVG(`Polio`), 1) AS avg_polio,
ROUND(AVG(`Diphtheria`), 1) AS avg_diphtheria,
ROUND(AVG(`HIV/AIDS`), 1) AS avg_hiv_aids,
ROUND(AVG(`GDP`), 1) AS avg_GDP,
ROUND(AVG(`thinness  1-19 years`), 1) AS avg_thinness_1_to_19_years,
ROUND(AVG(`thinness 5-9 years`), 1) AS avg_thinness_5_to_9_years,
ROUND(AVG(`Schooling`), 1) AS avg_schooling
FROM worldlifeexpectancy
GROUP BY Status
ORDER BY avg_life_expectancy DESC;
	#Notes
		#VARIABLE NAME					Predicticted Developed		Predicted Developing				Actual Developed		Actual Developing				Correct?		Difference (POV = Developing)
		#avg_adult_mortality			Lower						Higher								Lower					Higher							Yes				~4.1% higher adult mortality 
		#avg_infant_deaths				L							H									L  						H 								Y				6.9 more deaths		
		#avg_health_care_expenditure	H							L 									H						L 								Y				$464.2 less spending
		#avg_measles					L							H 									H 						L 								N				218.6 LESS cases
		#avg_bmi						H 							L									H						L								Y				11.4 point lower
		#avg_under_five_deaths			L							H 									L						H 								Y				8.5 more
		#avg_polio						H							L									H						L								Y				1.2% less vaccinated (94.3 vs 95.5)
		#avg_diphtheria					H							L									H 						L								Y				1.3 less vaccinated (94.4 vs 95.7)
		#avg_hiv_aids					L							H									L 						H								Y				0.3 more deaths 
		#avg_GDP						H							L									L						H								Y				$7,431.2 less
		#avg_thinness_1_to_19_years		L							H									L						H								Y				2.6 percentage points higher
		#avg_thinness_5_to_9_years		L							H									L						H								Y				2.6 percentage points higher
		#avg_schooling					H							L									H						L								Y				2.7 less years
        
			#Summary:
				#Over the course of the years od 2012 to 2021, developing countries - on the average:
					#Had a higher rate of adult mortality	(4.1%)
                    #Had more infants die	(6.9)
                    #Spent less on health care		($464.2)	
						#NOT REPORTED DUE TO LACK OF CONFIDENCE IN DATA AND MISREPRESENTATION
							#Had LESS cases of measles		(218.6)
					#Had lower BMIs		(11.4 points)
                    #Had more children under 5 die		(8.5)
                    #Had lower rates of vaccination for polio and diphtheria	(1.2 and 1.3 percentage points - Both Developed and Developing were > 94%)
                    #Had more HIV/AIDS related deaths	(0.3)
                    #Had a lower GDP per capita		($7,431.2)
                    #Had a higher rate of thinness in 1-19 and 5-9 year olds	(2.6 percentage points)
                    #AND
					#Had less education		(2.7 years)
				#Than those in developed countries

#Notes:
	#I would use a more trustworthy dataset in the future
		#Data was gathered from multiple sources and didn't supply a rock solid data dictionary (one had to be created using educated guesses)
		#Supports the claim that developed countries have MORE measles cases than developing
			#This could be true, however without population we can't calculate the rate - which is more comparable than sheer cases
			#There are a lot of zeros in the data - perhaps data wasn't collected properly for all countries leading to bias










