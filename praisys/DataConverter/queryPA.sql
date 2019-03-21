Use PA;
/*Written by dePaul Miller using SQL Server 17
  This method is intended to be easily replicatable with
  HAZUS mdf files. After attaching the file to a SQL Server
  do a similar query.
*/


DECLARE @g geometry;
DECLARE @h geometry;
DECLARE @j geometry;
DECLARE @k nvarchar(MAX);
DECLARE @Road1 varchar(255);
DECLARE @Road2 varchar(255);
DECLARE @length int;
DECLARE @outercount int;
DECLARE @incount int;


SET @outercount = 1;
SET @incount = 2;
SET @Road1 = ' ';
SET @Road2 = ' ';
SET @k = ' ';

DROP TABLE IF EXISTS dbo.praisystable;
DROP TABLE IF EXISTS dbo.praisysHighwaySegment;
DROP TABLE IF EXISTS dbo.praisysAllPoints;

SELECT * INTO praisysHighwaySegment FROM hzHighwaySegment WHERE CountyFips = 42077 OR CountyFips = 42095;

CREATE TABLE praisystable (
	Road1 varchar(255),
	Road2 varchar(255),
	Point nvarchar(MAX),
	PointObject geometry
);

CREATE TABLE praisysAllPoints (
	Road varchar(255),
	Point nvarchar(MAX),
	ID int
);

ALTER TABLE praisysHighwaySegment DROP COLUMN OBJECTID;
ALTER TABLE praisysHighwaySegment ADD OBJECTID INT IDENTITY(1,1);
SET @length = (SELECT COUNT(OBJECTID) FROM praisysHighwaySegment);


WHILE @outercount <= (@length - 1)
BEGIN
	WHILE @incount <= @length
	BEGIN
		SET @g = (SELECT Shape FROM praisysHighwaySegment WHERE OBJECTID = @outercount);
		SET @h = (SELECT Shape FROM praisysHighwaySegment WHERE OBJECTID = @incount);
		SET @j = @g.STIntersection(@h);
		SET @k = @j.ToString();
		SET @Road1 = (SELECT [Name] FROM praisysHighwaySegment WHERE OBJECTID = @outercount);
		SET @Road2 = (SELECT [Name] FROM praisysHighwaySegment WHERE OBJECTID = @incount);
		INSERT INTO praisystable (Road1, Road2, Point, PointObject) SELECT @Road1 AS Road1, @Road2 AS Road2, @k AS Point, @j AS PointObject;
		SET @incount = @incount + 1;
	END
	SET @outercount = @outercount + 1;
	SET @incount = @outercount + 1;
END

SET @outercount = 1;

WHILE @outercount <= @length
BEGIN
	SET @g = (SELECT Shape FROM praisysHighwaySegment WHERE OBJECTID = @outercount);
	SET @h = @g.STStartPoint();
	SET @k = @h.ToString();
	SET @Road1 = (SELECT [Name] FROM praisysHighwaySegment WHERE OBJECTID = @outercount);
	INSERT INTO praisystable (Road1, Point, PointObject) SELECT @Road1 AS Road1, @k AS Point, @h AS PointObject;
	SET @h = @g.STEndPoint();
	SET @k = @h.ToString();
	INSERT INTO praisystable (Road1, Point, PointObject) SELECT @Road1 AS Road1, @k AS Point, @h AS PointObject;
	SET @outercount = @outercount + 1;
END

SELECT * FROM praisystable WHERE Point != 'GEOMETRYCOLLECTION EMPTY';

SET @outercount = 1;

WHILE @outercount <= @length
BEGIN
	SET @Road1 = (SELECT [Name] FROM praisysHighwaySegment WHERE OBJECTID = @outercount);
	SET @g = (SELECT Shape FROM praisysHighwaySegment WHERE OBJECTID = @outercount);
	SET @incount = 1;
	WHILE @incount <= @g.STNumPoints()
	BEGIN
		SET @h = @g.STPointN(@incount);
		SET @k = @h.ToString();
		INSERT INTO praisysAllPoints (Road, Point,ID) SELECT @Road1 AS Road, @k AS Point, @incount AS ID;
		SET @incount = @incount + 1;
	END
	SET @outercount = @outercount + 1;
END

SELECT * FROM praisysAllPoints;
