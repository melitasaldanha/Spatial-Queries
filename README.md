## Question 2
**Run Query:** `db2 -tf nearester.sql`

## Question 3

**Assumptions:**   
1. Zip codes from facility table which are not in uszip table are ignored and hence, not a part of the result. (No information about shape, hence, cannot say anything about its neighbors)
2. Zip codes with more than 5 digits are truncated to 5 digits.   

**Run Query:** `db2 -tf noerzips.sql`

## Question 4
To query time for the questions 2 and 3, first create table which stores time by:
```
CREATE TABLE cse532.querytime (   
  sql_name VARCHAR (15),   
  index_present BOOLEAN,   
  start_time TIMESTAMP,   
  end_time TIMESTAMP,   
  total_time INTEGER   
);
```

After running both scripts with and without index, compare time by:   
`db2 SELECT sql_name, index_present, total_time FROM cse532.querytime;`

**OUTPUT:**  
|SQL_NAME       |       INDEX_PRESENT  |     TOTAL_TIME  |
|---------------|----------------------|-----------------|   
|nearester.sql  |             0        |       485000    |
|noerzips.sql   |             0        |       1070000   |
|nearester.sql  |             1        |       369000    |
|noerzips.sql   |             1        |       985000    |

## Question 5

**Assumptions:**  
1. Zips having population less than or equal to average are merged to get zips with population greater than average.
2. Considered limited number of zips from cse532.zippop table in ascending order of zips since running query for 33,120 takes very long. Limit can be entered by user while calling stored procedure (Command given in instructions).
3. Since all zips are not considered, there will be some zips remaining which have no neighbors, and hence are not merged. Such zips are not included in the final result.

**Instructions to run:** 
1. **Run Script:** `db2 -td@ -f mergezip.sql`  
This gives Zip, Pop of all zips after merging with population greater than average  
_NOTE:_ The third last line (Line no: 185) of the code has the call to the stored procedure, where user can enter limit on the number of zip codes to be fetched from cse532.zippop  
**Syntax:** `CALL mergezips(<limit on number of rows>, ?, ?)`  
**Current Value = 1000 rows:** `CALL mergezips(1000, ?, ?)`  
2. To get zips which do not have any neighbors considered subset and hence aren’t merged:   
`db2 SELECT Zip, Pop FROM cse532.A;`  

**For Reference:**
Schema of table cse532.A and table cse532.B
|Column Name | Data Type      | Length |
|------------|----------------|--------|
|ZIP         | VARCHAR        |200     |
|POP         | BIGINT         | 8      |
|SHAPE       |ST_MULTIPOLYGON | 0      |

(Need to increase Zip VARCHAR length if more number of rows to be considered and hence too many zips needed to be merged)
