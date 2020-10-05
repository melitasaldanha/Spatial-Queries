-- -- To Calculate StartTime
-- DELETE FROM cse532.querytime WHERE sql_name='noerzips.sql' AND index_present = TRUE;
-- DELETE FROM cse532.querytime WHERE sql_name='noerzips.sql' AND index_present = FALSE;
-- INSERT INTO cse532.querytime VALUES('noerzips.sql', TRUE, current timestamp, null, null);

-- Query
WITH 
	-- Find zip codes which have an ER and reduce zip codes to length of 5
	ER_zips AS  																					-- 172
	(
		SELECT
			distinct(SUBSTRING(F.ZipCode, 0, 6)) as ZipCode
		FROM
			cse532.facility F, 
			cse532.facilitycertification C
		WHERE
			F.FacilityID = C.FacilityID AND
			C.AttributeValue = 'Emergency Department'
	),				
	
	-- Zip codes without ER = (Total Zip Codes in facility table with shape in uszip) - (ER Zip codes) 
	NER_zips AS 																				-- 624
	(
		SELECT N.ZipCode as ZipCode
		FROM
			(
				SELECT distinct(SUBSTRING(F.ZipCode, 0, 6)) as ZipCode  									-- 796
				FROM cse532.facility F, cse532.facilitycertification C
				WHERE F.FacilityID = C.FacilityID
				MINUS
				SELECT ZipCode FROM ER_zips
			) N,
			cse532.uszip U 
		WHERE N.ZipCode = U.ZCTA5CE10
	),

	-- Cross Join: NER x ER
	cross_uszips AS
	(
		SELECT 
			NER.ZipCode as ZipCode1,
			NER.Shape as Shape1, 
			ER.ZipCode as ZipCode2, 
			ER.Shape as Shape2
		FROM 
			(
				SELECT
					Z.ZipCode AS ZipCode, 
					U.Shape AS Shape
				FROM
					NER_zips Z, 
					cse532.uszip U
				WHERE 
					Z.ZipCode = U.ZCTA5CE10
			) NER 
			CROSS JOIN 
			(
				SELECT 
					Z.ZipCode AS ZipCode, 
					U.Shape AS Shape
				FROM
					ER_zips Z, 
					cse532.uszip U
				WHERE
					Z.ZipCode = U.ZCTA5CE10
			) ER
	)


-- From All NER_ZipCodes, remove the zip codes which intersect with ER_ZipCodes (i.e. remove the NER which intersect with any ER)
SELECT ZipCode FROM NER_zips
MINUS
SELECT distinct(ZipCode1) FROM cross_uszips WHERE DB2GSE.ST_INTERSECTS(Shape1, Shape2) = 1;


-- -- To Calculate End Time
-- UPDATE cse532.querytime
-- SET end_time = current timestamp
-- WHERE sql_name = 'noerzips.sql' AND index_present = TRUE;

-- -- Calculate Total Time
-- UPDATE cse532.querytime
-- SET total_time = TIMESTAMPDIFF(1, (end_time - start_time))
-- WHERE sql_name = 'noerzips.sql' AND index_present = TRUE;

-- -- Display Total Time
-- SELECT total_time AS Time_Taken
-- FROM cse532.querytime
-- WHERE sql_name = 'noerzips.sql' AND index_present = TRUE;