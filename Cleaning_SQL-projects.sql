SELECT*
FROM Project.dbo.housing

--At first glance, I realize that we need to do next: 
--1.Standarize sales date format
--2.Populate Property Address data
--3.Break Address into individual columns (Address, City, State)
--4.Change Y and N to YES and No in Column 'SoldAsVacant'
--5.Remove Duplicates
--6.Delete Unused Columns

--1. Standarize sales date format
SELECT SaleDate, CONVERT (Date, SaleDate)
FROM Project.dbo.housing

ALTER TABLE Project.dbo.housing
ADD SaleDate2 Date

UPDATE Project.dbo.housing
SET SaleDate2 = CONVERT (Date, SaleDate)

SELECT SaleDate, SaleDate2
FROM Project..housing

--2.Populate Property Address data
SELECT ParcelID, PropertyAddress
FROM Project..housing
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Project..housing a
JOIN Project..housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Project..housing a
JOIN Project..housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--3.Break Address into individual columns (Address, City, State)

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM Project..housing

ALTER TABLE Project..housing
ADD PropertyAddressClean Nvarchar (250)

UPDATE Project..housing
SET PropertyAddressClean = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE Project..housing
ADD Property_city Nvarchar (250);

UPDATE Project..housing
SET Property_city = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

--We need to do the same wth the owner address
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3) as Address,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) as City,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) as State
FROM Project..housing

ALTER TABLE Project..housing
ADD OwnerAddressClean NVARCHAR(250)

ALTER TABLE Project..housing
ADD OwnerCity NVARCHAR(250)

ALTER TABLE Project..housing
ADD OwnerState NVARCHAR(250)

UPDATE Project..housing
SET OwnerAddressClean = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE Project..housing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE Project..housing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),+1)

--4.Change Y and N to YES and No in Column 'SoldAsVacant'
SELECT Distinct( SoldAsVacant), COUNT(SoldAsVacant) 
FROM Project..housing
Group by SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM Project..housing


UPDATE Project..housing
SET SoldAsVacant=CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

--5.Remove duplicates
--First, we need to identify the duplicates
with RowNumCTE as(
Select *,
	ROW_NUMBER () over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order BY
				 UniqueID
				 ) as row_num
From Project..housing
)
Select*
FROM RowNumCTE
WHERE row_num>1

--Let's delete them
with RowNumCTE as(
SELECT *,
	ROW_NUMBER () over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order BY
				 UniqueID
				 ) as row_num
From Project..housing
)
DELETE
FROM RowNumCTE
WHERE row_num>1

--Delete unused columns

Select *
FROM Project..housing

Alter Table Project..housing
DROP Column ownerAddress, PropertyAddress, SaleDate



