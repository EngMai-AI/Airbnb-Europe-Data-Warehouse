USE master;
GO

CREATE DATABASE AirbnbDW;
GO

USE AirbnbDW;
GO

CREATE SCHEMA bronze;
GO
USE AirbnbDW;
GO

SELECT SUM(p.rows) AS total_rows
FROM sys.tables t
JOIN sys.schemas s    ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE s.name = 'bronze';

SELECT TOP 5 *
FROM [bronze].[amsterdam_weekdays]



SELECT TOP 5 *
FROM [bronze].[london_weekends]

