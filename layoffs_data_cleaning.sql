-- To see what data we will be working with.
SELECT * 
FROM layoffs;

-- 1. Remove any duplicates (if any).
-- 2. Standardize the data (fix any mistakes)
-- 3. Fix NULL or blank values.
-- 4. Remove any rows or columns that are not required.

-- Creating a new table with the same data. It is important to not tamper with the raw one.
CREATE TABLE layoffs_2
LIKE layoffs;

SELECT *
FROM layoffs_2;

-- Copying the data from the original table to the one we will be working with
INSERT layoffs_2
SELECT * 
	FROM layoffs;

-- Using ROW_NUMBER() to identify them as there's no identifying factor
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_2;

-- Using a CTE to find exact duplicates
WITH duplicates_CTE AS
(SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_2)
SELECT *
FROM duplicates_CTE
WHERE row_num > 1;

-- Creating a new table to remove the duplicates
CREATE TABLE `layoffs_3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Copying values from layoffs_2 to layoffs_3
INSERT layoffs_3
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_2;

-- Removing the duplicates
DELETE
FROM layoffs_3
WHERE row_num > 1;

-- Removing extra spaces
UPDATE layoffs_3
SET company = TRIM(company);

-- Standardizing the data
UPDATE layoffs_3
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_3
SET country = 'United States'
WHERE country LIKE 'United States%';

SELECT date, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_3;

UPDATE layoffs_3
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Converting date into a DATE format
ALTER TABLE layoffs_3
MODIFY `date` DATE;

-- Finding out the blank Industry data
SELECT r1.company, r1.industry, r2.company, r2.industry
FROM layoffs_3 r1
JOIN layoffs_3 r2
	ON r1.company = r2.company
WHERE r1.industry IS NULL OR r1.industry = ''
	AND r2.industry IS NOT NULL;

-- Filling the missing information
-- Need to make the Blank values NULL.

UPDATE layoffs_3
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_3 r1
JOIN layoffs_3 r2 
	ON r1.company = r2.company
SET r1.industry = r2.industry
WHERE r1.industry IS NULL
	AND r2.industry IS NOT NULL;

-- Removing the rows that don't have any data
SELECT *
FROM layoffs_3
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_3
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

-- Removing the row_num column
ALTER TABLE layoffs_3
DROP column row_num;

-- Data cleaning complete. layoffs_4 will be used for exploratory analysis