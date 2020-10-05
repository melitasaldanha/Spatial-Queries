-- Create temporary tables to store result
DROP TABLE cse532.A @
DROP TABLE cse532.B @
DROP TABLE cse532.C @

-- For zips with population less than equal too avg
CREATE TABLE cse532.A (
	Zip VARCHAR(200) NOT NULL PRIMARY KEY,
	Pop BIGINT,
	Shape DB2GSE.ST_MULTIPOLYGON
) @

-- For zips with population greater than avg
CREATE TABLE cse532.B (
	Zip VARCHAR(200) NOT NULL PRIMARY KEY,
	Pop BIGINT,
	Shape DB2GSE.ST_MULTIPOLYGON
) @

-- Temporary table
CREATE TABLE cse532.C (
	Zip VARCHAR(200) NOT NULL PRIMARY KEY,
	Pop BIGINT,
	Shape DB2GSE.ST_MULTIPOLYGON
) @


-- Define procedure to merge zips
CREATE OR REPLACE PROCEDURE mergezips(IN lim INTEGER, OUT original_avg INTEGER, OUT avg_after_merge INTEGER)
LANGUAGE SQL 

BEGIN
	-- Declare variables
	DECLARE zip1 VARCHAR(500);
	DECLARE pop1 BIGINT;
	DECLARE zip2 VARCHAR(500);
	DECLARE pop2 BIGINT;

	-- Initialize value of variables
	SET zip1 = NULL;
	SET pop1 = 0;
	SET zip2 = NULL;
	SET pop2 = 0;

	-- Find average
	SET original_avg = (
		SELECT AVG(Pop) 
		FROM (
			SELECT Zip, Pop, Shape
			FROM (
				SELECT Zip, AVG(Zpop) as Pop
				FROM cse532.zippop 
				GROUP BY Zip
				ORDER BY Zip
				LIMIT lim
			), cse532.uszip
			WHERE Zip = ZCTA5CE10
		)
	);

	-- Find zips less than or equal to avg
	INSERT INTO cse532.A 
	(
		SELECT ZCTA5CE10 as Zip, Pop, Shape
		FROM (
			SELECT Zip, AVG(Zpop) as Pop
			FROM cse532.zippop 
			GROUP BY Zip
			ORDER BY Zip
			LIMIT lim
		), cse532.uszip
		WHERE Zip = ZCTA5CE10 AND Pop<=original_avg
	);

	-- Find zips greater than avg
	INSERT INTO cse532.B 
	(
		SELECT ZCTA5CE10 as Zip, Pop, Shape
		FROM (
			SELECT Zip, AVG(Zpop) as Pop
			FROM cse532.zippop 
			GROUP BY Zip
			ORDER BY Zip
			LIMIT lim
		), cse532.uszip
		WHERE Zip = ZCTA5CE10 AND Pop>original_avg
	);

	-- Traverse through table with population less than avg
	WHILE (SELECT COUNT(*) FROM cse532.A) != 0 DO 
		SET zip2 = NULL;

		SELECT Zip, Pop INTO zip1, pop1 FROM cse532.A ORDER BY Pop ASC LIMIT 1;
		SELECT Zip, Pop INTO zip2, pop2 FROM cse532.A WHERE Zip != zip1 AND DB2GSE.ST_INTERSECTS(Shape, (SELECT Shape FROM cse532.A WHERE Zip=zip1))=1 ORDER BY Pop DESC LIMIT 1;
		
		IF zip2 IS NOT NULL THEN

			-- If merge than population > avg then merge and put it in B
			IF (pop1 + pop2) > original_avg THEN
				INSERT INTO cse532.B VALUES 
				(
					(zip1 || ',' || zip2), 
					(pop1 + pop2),
					(
						SELECT DB2GSE.ST_TOMULTIPOLYGON(DB2GSE.ST_UNION(S1.Shape, S2.Shape)) 
						FROM 
							(SELECT Shape FROM cse532.A WHERE Zip=zip1) S1, 
							(SELECT Shape FROM cse532.A WHERE Zip=zip2) S2
					)
				);
				DELETE FROM cse532.A WHERE Zip = zip2;

			-- If merge has population <= avg, then merge shape, add population and keep it in A
			ELSE
				UPDATE cse532.A SET Zip = (zip1 || ',' || zip2), Pop = (pop1 + pop2), Shape = DB2GSE.ST_TOMULTIPOLYGON(DB2GSE.ST_UNION((SELECT Shape FROM cse532.A WHERE Zip=zip1),(SELECT Shape FROM cse532.A WHERE Zip=zip2))) WHERE Zip = zip2;
			
			END IF;
		
		-- Zip1 does not intersect with any other zip in A
		ELSE			
			
			-- INSERT INTO C
			INSERT INTO cse532.C VALUES 
			(
				zip1, 
				pop1, 
				(SELECT Shape FROM cse532.A WHERE Zip=zip1)
			);

		END IF;

		DELETE FROM cse532.A WHERE Zip = zip1;
	END WHILE;

	-- Traverse remaining zips which did not intersect back in A
	INSERT INTO cse532.A (
		SELECT * FROM cse532.C
	);

	-- Clear temp table C
	DELETE FROM CSE532.C;


	-- Traverse through zips that didnt intersect with zips in less than avg table (Try intersecting with zips in greater than avg table)
	WHILE (SELECT COUNT(*) FROM cse532.A) != 0 DO 
		SET zip2 = NULL;

		SELECT Zip, Pop INTO zip1, pop1 FROM cse532.A ORDER BY Pop ASC LIMIT 1;
		SELECT Zip, Pop INTO zip2, pop2 FROM cse532.B WHERE DB2GSE.ST_INTERSECTS(Shape, (SELECT Shape FROM cse532.A WHERE Zip=zip1))=1 ORDER BY Pop ASC LIMIT 1;

		IF zip2 IS NOT NULL THEN
			-- Merge and put it in B
			UPDATE cse532.B SET Zip = (zip1 || ',' || zip2), Pop = (pop1 + pop2), Shape = DB2GSE.ST_TOMULTIPOLYGON(DB2GSE.ST_UNION((SELECT Shape FROM cse532.A WHERE Zip=zip1),(SELECT Shape FROM cse532.B WHERE Zip=zip2))) WHERE Zip = zip2;
		
		-- Zip1 does not intersect with any other zip in B
		ELSE

			-- INSERT INTO C (These zips do not have any neighbors)
			INSERT INTO cse532.C VALUES 
			(
				zip1, 
				pop1,
				(SELECT Shape FROM cse532.A WHERE Zip=zip1)
			);

		END IF;

		DELETE FROM cse532.A WHERE Zip = zip1;
	END WHILE;

	-- Save zips which have pop<=avg and have no neighbors in A
	INSERT INTO cse532.A (
		SELECT * FROM cse532.C
	);

	-- Find new average
	SET avg_after_merge = (
		SELECT AVG(Pop) 
		FROM CSE532.B
	);

END@

-- Call prodecure
CALL mergezips(1000, ?, ?) @

-- View resultant merged zips and population
SELECT Zip, Pop FROM cse532.B @