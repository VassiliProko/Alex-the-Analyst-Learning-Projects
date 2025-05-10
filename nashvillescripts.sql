
-- IMPORTING DATA VIA TERMINAL:

-- USE nashvillehousing;

-- TRUNCATE TABLE nashvillehousing;

-- LOAD DATA LOCAL INFILE '/Users/vassi/Documents/Projects/Nashville Housing/Nashville Housing Data for Data Cleaning.csv'
-- INTO TABLE nashvillehousing
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;


USE nashvillehousing;


SELECT * FROM nashvillehousing;

-- Standardize Sale Date

SET SQL_SAFE_UPDATES = 0;

UPDATE nashvillehousing
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y')
WHERE SaleDate IS NOT NULL;




-- Populate Property Address data

SELECT *
FROM nashvillehousing
-- WHERE PropertyAddress IS NULL OR TRIM(PropertyAddress) = '';
ORDER BY ParcelID;


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
IFNULL(NULLIF(TRIM(a.PropertyAddress), ''), b.PropertyAddress) AS FilledAddress
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL OR TRIM(a.PropertyAddress) = '';
    

UPDATE nashvillehousing a
JOIN nashvillehousing b 
  ON a.ParcelID = b.ParcelID 
  AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL OR TRIM(a.PropertyAddress) = '';

SET SQL_SAFE_UPDATES = 1;


-- Breaking Address into individual columns (address, city, state)

Select PropertyAddress
FROM nashvillehousing;


SELECT
SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS Address,
SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1) AS City
FROM nashvillehousing;


ALTER TABLE nashvillehousing
ADD PropertySplitAddress nvarchar(255);

UPDATE nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1);

ALTER TABLE nashvillehousing
ADD PropertySplitCity nvarchar(255);

UPDATE nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1);


-- Splitting Owner Address

SELECT OwnerAddress
FROM nashvillehousing;

SELECT
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS Street,
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS City,
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS State
FROM nashvillehousing;



ALTER TABLE nashvillehousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE nashvillehousing
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));

ALTER TABLE nashvillehousing
ADD OwnerSplitCity nvarchar(255);

UPDATE nashvillehousing
SET OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1));

ALTER TABLE nashvillehousing
ADD OwnerSplitState nvarchar(255);

UPDATE nashvillehousing
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

-- Cleaning SoldAsVacant field

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant;



SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END
FROM nashvillehousing;

UPDATE nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END;

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    ORDER BY UniqueID
    ) row_num
FROM nashvillehousing
-- ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;


DELETE FROM nashvillehousing
WHERE UniqueID IN (
  SELECT UniqueID
  FROM (
    SELECT UniqueID,
           ROW_NUMBER() OVER (
             PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
             ORDER BY UniqueID
           ) AS row_num
    FROM nashvillehousing
  ) sub
  WHERE row_num > 1
);


-- Delete unused columns

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;



