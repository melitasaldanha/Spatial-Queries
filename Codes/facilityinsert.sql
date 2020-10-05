INSERT INTO cse532.facility
SELECT 
	FacilityID, 
	FacilityName, 
	Description, 
	Address1, 
	Address2, 
	City, 
	State, 
	ZipCode, 
	CountyCode, 
	County, 
	DB2GSE.ST_Point(Longitude, Latitude, 1) AS Geolocation
FROM cse532.facilityoriginal;