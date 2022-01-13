Select *
From PortfolioProject.dbo.NashvilleHousing

-- Standardize Date Format
Select SaleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
Set SaleDate = Convert(Date, SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
Set SaleDateConverted = Convert(Date, SaleDate)




--Populate Property Address Data can be done with a refference point to base it off.
SELECT PropertyAddress, ParcelID
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress is null

SELECT one.ParcelID, one.PropertyAddress, two.ParcelID, two.PropertyAddress, ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing one
JOIN PortfolioProject.dbo.NashvilleHousing two
	on one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]
Where one.PropertyAddress is null

UPDATE one
SET PropertyAddress = ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing one
JOIN PortfolioProject.dbo.NashvilleHousing two
	on one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]
Where one.PropertyAddress is null

--Breaking Down Address into Individual Columns (Address, City, State) using SUBSTRING
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX (',', PropertyAddress)+1 , LEN(PropertyAddress)) as Address
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar (255);

Update NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar (255);

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX (',', PropertyAddress)+1 , LEN(PropertyAddress))




--Breaking Down Address into Individual Columns (Address, City, State) using PARSENAME
Select OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
	Add OwnerSplitAddress Nvarchar (255);
ALTER TABLE NashvilleHousing
	Add OwnerSplitCity Nvarchar (255);
ALTER TABLE NashvilleHousing
	Add OwnerSplitState Nvarchar (255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
Update NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



--Change Y and N to "Yes" and "No" in "Sold as Vacant" field
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing)
DELETE
From RowNumCTE
Where row_num > 1


--Delete Unused Columns

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN TaxDistrict, SaleDate

