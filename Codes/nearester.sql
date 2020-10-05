-- -- To Calculate Start Time
-- DELETE FROM cse532.querytime WHERE sql_name='nearester.sql' AND index_present = TRUE;
-- DELETE FROM cse532.querytime WHERE sql_name='nearester.sql' AND index_present = FALSE;
-- INSERT INTO cse532.querytime VALUES('nearester.sql', TRUE, current timestamp, null, null);


-- Query
SELECT 
	C.FacilityID AS FacilityID,
	C.FacilityName AS FacilityName,
	CAST(DB2GSE.ST_ASTEXT(F.Geolocation) AS VARCHAR(32)) AS Geolocation,
	CAST((DB2GSE.ST_DISTANCE(Geolocation, DB2GSE.ST_POINT(-72.993983, 40.824369, 1), 'STATUTE MILE')) AS Decimal(8, 4)) AS Distance_in_Statute_Mile
FROM 
	cse532.facility F, 
	cse532.facilitycertification C
WHERE 
	C.AttributeValue = 'Emergency Department' AND 
	F.FacilityID = C.FacilityID AND
	DB2GSE.ST_WITHIN(F.Geolocation, DB2GSE.ST_BUFFER(DB2GSE.ST_Point(-72.993983, 40.824369, 1), 0.25)) = 1
ORDER BY Distance_in_Statute_Mile
LIMIT 1;


-- -- To Calculate End Time
-- UPDATE cse532.querytime
-- SET end_time = current timestamp
-- WHERE sql_name = 'nearester.sql' AND index_present = TRUE;

-- -- Calculate Total Time
-- UPDATE cse532.querytime
-- SET total_time = TIMESTAMPDIFF(1, (end_time - start_time))
-- WHERE sql_name = 'nearester.sql' AND index_present = TRUE;

-- -- Display Total Time
-- SELECT total_time AS Time_Taken
-- FROM cse532.querytime
-- WHERE sql_name = 'nearester.sql' AND index_present = TRUE;