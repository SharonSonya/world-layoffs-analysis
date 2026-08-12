-- ==========================================
-- WORLD LAYOFFS DATA ANALYSIS PROJECT
-- Global Layoffs Dataset
-- Author: Sharon Kam'mambala
-- ==========================================

-- Objective:
-- Analyze global layoffs trends, identify companies and
-- industries most affected, examine layoffs over time,
-- and uncover patterns by country, location, and funding stage.
-- The analysis aims to provide business insights that
-- support workforce planning and risk management.
-- ==========================================


-- =====================================================
-- STEP 1: DATABASE SETUP
-- =====================================================

CREATE DATABASE world_layoffs;

USE world_layoffs;


-- =====================================================
-- STEP 2: CREATE RAW TABLE
-- =====================================================

CREATE TABLE layoffs (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT
);


-- =====================================================
-- STEP 3: DATA IMPORT
-- =====================================================

LOAD DATA LOCAL INFILE
'C:\Users\A\Desktop\Sharon folder\CSV. Datasets\World Layoffs\layoffs.csv'
INTO TABLE layoffs
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    country,
    funds_raised_millions
);


-- =====================================================
-- STEP 4: INITIAL DATA QUALITY ASSESSMENT
-- =====================================================

-- Total number of records

SELECT COUNT(*) AS total_rows
FROM layoffs;

-- Preview the dataset

SELECT *
FROM layoffs
LIMIT 10;


-- =====================================================
-- STEP 5: DATA CLEANING
-- =====================================================

-- Create staging table to preserve the raw dataset

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;


-- =====================================================
-- STEP 5.1: REMOVE DUPLICATES
-- =====================================================

CREATE TABLE layoffs_staging2
LIKE layoffs_staging;

ALTER TABLE layoffs_staging2
ADD COLUMN row_num INT;

INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY
               company,
               location,
               industry,
               total_laid_off,
               percentage_laid_off,
               `date`,
               stage,
               country,
               funds_raised_millions
       ) AS row_num
FROM layoffs_staging;


-- Check for duplicate records

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;


-- Remove duplicates

DELETE FROM layoffs_staging2
WHERE row_num > 1;


-- Verify cleaned record count

SELECT COUNT(*) AS total_records
FROM layoffs_staging2;


-- =====================================================
-- STEP 5.2: STANDARDIZE TEXT VALUES
-- =====================================================

UPDATE layoffs_staging2
SET company = TRIM(company);

UPDATE layoffs_staging2
SET industry = TRIM(industry);

UPDATE layoffs_staging2
SET location = TRIM(location);

UPDATE layoffs_staging2
SET country = TRIM(country);

UPDATE layoffs_staging2
SET stage = TRIM(stage);


-- =====================================================
-- STEP 5.3: HANDLE MISSING INDUSTRIES
-- =====================================================

-- Replace missing industry values with Unknown

UPDATE layoffs_staging2
SET industry = 'Unknown'
WHERE industry IS NULL;


-- Create final cleaned staging table

CREATE TABLE layoffs_staging3 AS
SELECT *
FROM layoffs_staging2;


-- Correct known missing industry values

UPDATE layoffs_staging3
SET industry = CASE
    WHEN company = 'Airbnb' THEN 'Travel'
    WHEN company = 'Carvana' THEN 'Transportation'
    WHEN company = 'Juul' THEN 'Consumer'
END
WHERE company IN ('Airbnb', 'Carvana', 'Juul')
AND (industry IS NULL OR industry = '');


-- Verify corrections

SELECT
    company,
    industry
FROM layoffs_staging3
WHERE company IN ('Airbnb', 'Carvana', 'Juul');


-- =====================================================
-- STEP 5.4: HANDLE MISSING FUNDING STAGE VALUES
-- =====================================================

UPDATE layoffs_staging3
SET stage = 'Unknown'
WHERE stage IS NULL
OR TRIM(stage) = '';


-- Verify

SELECT COUNT(*) AS missing_stage
FROM layoffs_staging3
WHERE stage IS NULL
OR TRIM(stage) = '';


-- =====================================================
-- STEP 5.5: STANDARDIZE COUNTRY VALUES
-- =====================================================

-- Remove the incorrect trailing period from United States.

UPDATE layoffs_staging3
SET country = TRIM(TRAILING '.' FROM country)
WHERE country = 'United States.';


-- =====================================================
-- STEP 6: DATA QUALITY VERIFICATION
-- =====================================================

SELECT
    COUNT(*) AS total_rows,
    SUM(company IS NULL OR company = '') AS missing_company,
    SUM(location IS NULL OR location = '') AS missing_location,
    SUM(industry IS NULL OR industry = '') AS missing_industry,
    SUM(total_laid_off IS NULL) AS missing_laid_off,
    SUM(
        percentage_laid_off IS NULL
        OR percentage_laid_off = ''
    ) AS missing_percentage,
    SUM(date IS NULL OR date = '') AS missing_date,
    SUM(stage IS NULL OR stage = '') AS missing_stage,
    SUM(country IS NULL OR country = '') AS missing_country,
    SUM(
        funds_raised_millions IS NULL
        OR funds_raised_millions = ''
    ) AS missing_funding
FROM layoffs_staging3;


-- =====================================================
-- STEP 6.1: MISSING LAYOFF VALUES
-- =====================================================

SELECT
    COUNT(*) AS total_missing_layoffs,

    SUM(
        CASE
            WHEN percentage_laid_off IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS has_percentage,

    SUM(
        CASE
            WHEN percentage_laid_off IS NULL
            THEN 1
            ELSE 0
        END
    ) AS no_percentage

FROM layoffs_staging3
WHERE total_laid_off IS NULL;


-- Results:
-- Total missing layoffs: 739
-- Records with percentage information: 378
-- Records without percentage information: 361


-- =====================================================
-- STEP 7: EXPLORATORY DATA ANALYSIS
-- =====================================================
-- The following business questions examine the major
-- patterns and trends within the layoffs dataset.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 1
-- =====================================================
-- How many people were laid off in total?

SELECT
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging3;

-- Result:
-- Total layoffs: 383,659

-- Business Insight:
-- The dataset records more than 383,000 reported layoffs,
-- highlighting the significant scale of workforce reductions
-- across companies and industries.

-- Recommendation:
-- Businesses should maintain stronger workforce planning,
-- financial reserves, and scenario analysis to prepare for
-- periods of economic uncertainty.


-- =====================================================
-- BUSINESS QUESTION 2
-- =====================================================
-- Which companies recorded the highest number of layoffs?

SELECT
    company,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging3
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 10;

-- Key Results:
-- Amazon: 18,150
-- Google: 12,000
-- Meta: 11,000
-- Salesforce: 10,090
-- Philips: 10,000
-- Microsoft: 10,000
-- Ericsson: 8,500
-- Uber: 7,585
-- Dell: 6,650
-- Booking.com: 4,601

-- Business Insight:
-- Large technology and multinational companies accounted
-- for some of the largest individual workforce reductions.

-- Recommendation:
-- Large organizations should monitor workforce costs,
-- demand forecasts, and operational efficiency before
-- implementing large-scale workforce reductions.


-- =====================================================
-- BUSINESS QUESTION 3
-- =====================================================
-- Which industries experienced the highest layoffs?

SELECT
    industry,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging3
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC;

-- Key Results:
-- Consumer: 45,182
-- Retail: 43,613
-- Other: 36,289
-- Transportation: 33,748
-- Finance: 28,344
-- Healthcare: 25,953
-- Food: 22,855
-- Real Estate: 17,565
-- Travel: 17,159

-- Business Insight:
-- Consumer and retail industries experienced the largest
-- reported workforce reductions, followed by transportation,
-- finance, and healthcare.

-- Recommendation:
-- Companies operating in highly affected industries should
-- closely monitor demand, operating costs, and market changes
-- to identify workforce risks early.


-- =====================================================
-- BUSINESS QUESTION 4
-- =====================================================
-- Which years recorded the highest layoffs?

SELECT
    YEAR(STR_TO_DATE(date, '%m/%d/%Y')) AS year,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging3
WHERE date IS NOT NULL
GROUP BY year
ORDER BY total_layoffs DESC;

-- Results:
-- 2022: 160,661
-- 2023: 125,677
-- 2020: 80,998
-- 2021: 15,823

-- Business Insight:
-- Layoffs increased substantially in 2022 and remained high
-- in 2023, making these the most affected years in the dataset.

-- Recommendation:
-- Businesses should use historical workforce trends to
-- strengthen forecasting and prepare for future economic
-- downturns.


-- =====================================================
-- BUSINESS QUESTION 5
-- =====================================================
-- Which countries recorded the highest layoffs?

SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging3
GROUP BY country
ORDER BY total_laid_off DESC;

-- Key Results:
-- United States: 256,559
-- India: 35,993
-- Netherlands: 17,220
-- Sweden: 11,264
-- Brazil: 10,391
-- Germany: 8,701
-- United Kingdom: 6,398
-- Canada: 6,319
-- Singapore: 5,995
-- China: 5,905

-- Business Insight:
-- The United States recorded by far the largest number of
-- reported layoffs, followed by India and the Netherlands.

-- Recommendation:
-- Multinational companies should consider regional economic
-- conditions when developing workforce and resource plans.


-- =====================================================
-- BUSINESS QUESTION 6
-- =====================================================
-- Which funding stages experienced the highest layoffs?

SELECT
    stage,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging3
WHERE total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY total_laid_off DESC;

-- Key Results:
-- Post-IPO: 204,132
-- Unknown: 41,038
-- Acquired: 27,576
-- Series C: 20,017
-- Series D: 19,225
-- Series B: 15,311
-- Series E: 12,697

-- Business Insight:
-- Post-IPO companies recorded the highest total layoffs,
-- suggesting that workforce reductions were not limited to
-- early-stage startups.

-- Recommendation:
-- Companies should continue monitoring profitability,
-- investor expectations, and operating efficiency after
-- reaching later funding or public-market stages.


-- =====================================================
-- BUSINESS QUESTION 7
-- =====================================================
-- Which months recorded the highest layoffs?

SELECT
    DATE_FORMAT(
        STR_TO_DATE(date, '%m/%d/%Y'),
        '%Y-%m'
    ) AS month,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging3
WHERE total_laid_off IS NOT NULL
GROUP BY month
ORDER BY total_laid_off DESC
LIMIT 10;

-- Key Results:
-- 2023-01: 84,714
-- 2022-11: 53,451
-- 2023-02: 36,493
-- 2020-04: 26,710
-- 2020-05: 25,804
-- 2022-10: 17,406
-- 2022-06: 17,394
-- 2022-07: 16,223
-- 2022-08: 13,055
-- 2022-05: 12,885

-- Business Insight:
-- January 2023 recorded the highest monthly layoffs in the
-- dataset, followed by November 2022.

-- Recommendation:
-- Organizations should closely monitor workforce indicators
-- during periods of rapidly increasing layoffs and prepare
-- contingency plans before major cost-cutting periods.


-- =====================================================
-- BUSINESS QUESTION 8
-- =====================================================
-- Which companies had the most layoff events?

SELECT
    company,
    COUNT(*) AS layoff_events
FROM layoffs_staging3
WHERE company IS NOT NULL
GROUP BY company
ORDER BY layoff_events DESC
LIMIT 10;

-- Business Insight:
-- Repeated layoff events indicate that some companies
-- implemented workforce reductions over multiple periods
-- rather than through a single event.

-- Recommendation:
-- Companies experiencing repeated layoffs should evaluate
-- the underlying causes and consider longer-term workforce
-- and financial restructuring strategies.


-- =====================================================
-- BUSINESS QUESTION 9
-- =====================================================
-- Which companies recorded the highest average percentage
-- of their workforce laid off?

SELECT
    company,
    ROUND(
        AVG(
            CAST(percentage_laid_off AS DECIMAL(10,4))
        ) * 100,
        2
    ) AS avg_percentage_laid_off
FROM layoffs_staging3
WHERE percentage_laid_off IS NOT NULL
GROUP BY company
ORDER BY avg_percentage_laid_off DESC
LIMIT 10;

-- Key Results:
-- Several companies recorded 100% average workforce reductions.

-- Business Insight:
-- Some smaller companies experienced extremely severe
-- workforce reductions, with some reporting the elimination
-- of their entire workforce.

-- Recommendation:
-- Investors and management teams should monitor workforce
-- reduction percentages alongside absolute employee counts
-- to distinguish between large-company restructuring and
-- business shutdowns.


-- =====================================================
-- BUSINESS QUESTION 10
-- =====================================================
-- Which locations recorded the highest layoffs?

SELECT
    location,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging3
WHERE total_laid_off IS NOT NULL
GROUP BY location
ORDER BY total_laid_off DESC
LIMIT 10;

-- Key Results:
-- SF Bay Area: 125,631
-- Seattle: 34,743
-- New York City: 29,364
-- Bengaluru: 21,787
-- Amsterdam: 17,140
-- Stockholm: 11,217
-- Boston: 10,785
-- Sao Paulo: 9,081
-- Austin: 8,980
-- Chicago: 6,419

-- Business Insight:
-- Major technology and business hubs accounted for a large
-- share of reported layoffs.

-- Recommendation:
-- Organizations should consider geographic concentration
-- when assessing workforce risk and operational resilience.


-- =====================================================
-- STEP 8: DATASET SUMMARY
-- =====================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT company) AS companies,
    COUNT(DISTINCT country) AS countries,
    COUNT(DISTINCT industry) AS industries,
    COUNT(DISTINCT stage) AS funding_stages
FROM layoffs_staging3;


-- =====================================================
-- STEP 9: KEY FINDINGS
-- =====================================================

-- Key Finding 1:
-- The dataset contains 2,356 cleaned records representing
-- 383,659 reported layoffs.

-- Key Finding 2:
-- 2022 recorded the highest annual layoffs with 160,661,
-- followed by 2023 with 125,677.

-- Key Finding 3:
-- January 2023 recorded the highest monthly layoffs
-- with 84,714 reported layoffs.

-- Key Finding 4:
-- The United States recorded the highest number of layoffs
-- with 256,559, significantly higher than other countries.

-- Key Finding 5:
-- Consumer and Retail were the industries with the highest
-- reported layoffs.

-- Key Finding 6:
-- Post-IPO companies recorded the highest layoffs by
-- funding stage, with 204,132 reported layoffs.

-- Key Finding 7:
-- Amazon recorded the highest company-level layoffs
-- with 18,150 employees affected.

-- Key Finding 8:
-- The SF Bay Area recorded the highest location-level
-- layoffs with 125,631.


-- =====================================================
-- STEP 10: BUSINESS RECOMMENDATIONS
-- =====================================================

-- Recommendation 1:
-- Strengthen workforce forecasting and scenario planning
-- during periods of economic uncertainty.

-- Recommendation 2:
-- Companies in highly affected industries such as Consumer,
-- Retail, Transportation, and Finance should closely
-- monitor demand and operating costs.

-- Recommendation 3:
-- Organizations should monitor workforce trends across
-- major business hubs to identify geographic concentration
-- risks.

-- Recommendation 4:
-- Companies should evaluate profitability and workforce
-- efficiency before and after major funding or IPO events.

-- Recommendation 5:
-- Repeated layoffs should trigger deeper analysis of
-- long-term financial and operational sustainability.

-- Recommendation 6:
-- Workforce reduction percentages should be analyzed
-- alongside absolute layoffs to identify companies facing
-- severe operational distress.


-- =====================================================
-- STEP 11: FINAL CONCLUSION
-- =====================================================

-- The analysis shows that global layoffs were concentrated
-- in 2022 and early 2023, with the United States accounting
-- for the largest share of reported workforce reductions.
--
-- Consumer, Retail, Transportation, and Finance were among
-- the most affected industries, while large post-IPO companies
-- accounted for a substantial share of total layoffs.
--
-- The findings demonstrate how SQL can be used to identify
-- workforce trends across companies, industries, countries,
-- locations, and funding stages.
--
-- Businesses can use these insights to strengthen workforce
-- planning, monitor financial risk, improve forecasting,
-- and prepare for periods of economic uncertainty.


-- =====================================================
-- END OF WORLD LAYOFFS DATA ANALYSIS PROJECT
-- Author: Sharon Kam'mambala
-- =====================================================