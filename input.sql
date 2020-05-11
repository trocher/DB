
/*
CS-A1150 project part 2

@Authors: Paul Juillard, Tanguy Rocher

*/

/*
-> unique is ensured by primary key statements
-> reference key for primary key requires uniqueness
-> MODIFIED : removing location from subproject
-> MODIFIED : added :FOREIGN KEY(socialSecurityNoAbsent, start) REFERENCES Absence(socialSecurityNoAbsent, start)
             to the substitute table
TODO LIST:
-> FINISH TO CREATE AND INPUT DATA FOR THE MACHINES

*
*/

-- CREATE DATABASE Project2DB;

-- PRAGMA foreign_keys;
-- PRAGMA foreign_keys = ON;

CREATE TABLE Project(
    projectID INT PRIMARY KEY,
    start DATE, 
    location TEXT
);

CREATE TABLE SubProject(
    projectID INT,
    subprojectID INT,
    start DATE,
    finish DATE,
    PRIMARY KEY (projectID, subprojectID),
    FOREIGN KEY (projectID) REFERENCES Project(projectID)
);

CREATE TABLE Employee(
    socialSecurityNo INT PRIMARY KEY,
    name TEXT,
    address TEXT
);

CREATE TABLE Absence(
    socialSecurityNo INT,
    start DATE,
    duration TEXT,
    reason TEXT,
    PRIMARY KEY(socialSecurityNo, start),
    FOREIGN KEY(socialSecurityNo) REFERENCES Employee(socialSecurityNo)
);

CREATE TABLE Qualification (
    type TEXT PRIMARY KEY
);

CREATE TABLE Machine (
    model TEXT PRIMARY KEY, 
    description TEXT, 
    manufacturer TEXT, 
    size INT, 
    fuel INT
);

CREATE TABLE Item (
    model TEXT,
    itemID INT,
    PRIMARY KEY (model, itemID),
    FOREIGN KEY (model) REFERENCES Machine(model)
);

CREATE TABLE Maintenance (
    model TEXT, 
    itemID INT, 
    start DATE, 
    reason TEXT, 
    duration TEXT,
    PRIMARY KEY (model, itemID, start),
    FOREIGN KEY (model, itemID) REFERENCES Item(model, itemID)
);

CREATE TABLE HappensBefore(
    beforeProjectID INT,
    beforeSubprojectID INT,
    afterProjectID INT,
    afterSubprojectID INT,
    PRIMARY KEY (beforeProjectID, beforeSubprojectID, afterProjectID, afterSubprojectID),
    FOREIGN KEY (beforeProjectID, beforeSubprojectID) REFERENCES Subproject(projectID, subprojectID),
    FOREIGN KEY (afterProjectID,  afterSubprojectID ) REFERENCES Subproject(projectID, subprojectID)
);

CREATE TABLE Needed(
    model TEXT,
    projectID INT,
    subprojectID INT,
    start DATE,
    duration TEXT,
    count INT,
    PRIMARY KEY(model, projectID, subprojectID, start),
    FOREIGN KEY(model) REFERENCES Machine(model),
    FOREIGN KEY(projectID, subprojectID) REFERENCES Subproject(projectID, subprojectID)
);

CREATE TABLE Assigned(
    model TEXT,
    itemID INT,
    projectID INT,
    subprojectID INT,
    start DATE,
    duration TEXT,
    PRIMARY KEY(model, itemId, projectID, subprojectID, start),
    FOREIGN KEY(model, itemID) REFERENCES Item(model, itemID),
    FOREIGN KEY(projectID, subprojectID) REFERENCES Subproject(projectID, subprojectID)
);

CREATE TABLE Requires(
    projectID INT,
    subprojectID INT,
    qualificationType TEXT,
    count INT,
    PRIMARY KEY(projectID, subprojectID, qualificationType)
    FOREIGN KEY(projectID, subprojectID) REFERENCES Subproject(projectID, subprojectID),
    FOREIGN KEY(qualificationType) REFERENCES Qualification(type)
);

CREATE TABLE IsAppointedTo ( 
    projectID INT,
    subprojectID INT,
    socialSecurityNo INT,
    PRIMARY KEY(projectID, subprojectID, socialSecurityNo),
    FOREIGN KEY(projectID, subprojectID) REFERENCES Subproject(projectID, subprojectID),
    FOREIGN KEY(socialSecurityNo) REFERENCES Employee(socialSecurityNo)
);

CREATE TABLE HasTheQualification ( 
    socialSecurityNo INT,
    type TEXT,
    PRIMARY KEY(socialSecurityNo, type),
    FOREIGN KEY(socialSecurityNo) REFERENCES Employee(socialSecurityNo),
    FOREIGN KEY(type) REFERENCES Qualification(type)
);

CREATE TABLE Substitute ( 
    socialSecurityNoAbsent INT,
    start DATE,
    socialSecurityNoSubstitute INT, 
    PRIMARY KEY(socialSecurityNoAbsent,start),
    FOREIGN KEY(socialSecurityNoAbsent, start) REFERENCES Absence(socialSecurityNoAbsent, start),
    FOREIGN KEY(socialSecurityNoAbsent) REFERENCES Employee(socialSecurityNo),
    FOREIGN KEY(socialSecurityNoSubstitute) REFERENCES Employee(socialSecurityNo)
);

-- A FEW USEFUL INDEXES

CREATE INDEX EmployeesByName ON Employee(name);

CREATE INDEX ProjectsByLocation ON Project(location);

CREATE INDEX SubstitutionsBySubstitute ON Substitute(socialSecurityNoSubstitute);

CREATE INDEX SubprojectsByTime ON Subproject(start, finish);

-- A FEW USEFUL VIEWS

CREATE VIEW CurrentSubprojects
AS 
SELECT *
FROM SubProject
WHERE date('now') BETWEEN start AND finish;

CREATE VIEW AvailableEmployees
AS
SELECT *
FROM Employee
EXCEPT 
SELECT Employee.*
FROM Employee INNER JOIN IsAppointedTo ON Employee.socialSecurityNo = IsAppointedTo.socialSecurityNo, CurrentSubprojects
WHERE IsAppointedTo.subprojectID = CurrentSubprojects.subprojectID and IsAppointedTo.projectID = CurrentSubprojects.projectID
EXCEPT
SELECT Employee.*
FROM Employee INNER JOIN Absence ON Employee.socialSecurityNo = Absence.socialSecurityNo
WHERE date('now') BETWEEN start AND date(start,duration)
EXCEPT
SELECT Employee.*
FROM Employee INNER JOIN Substitute ON Employee.socialSecurityNo = Substitute.socialSecurityNoSubstitute,Absence
WHERE Substitute.socialSecurityNoAbsent = Absence.socialSecurityNo AND date('now') BETWEEN Absence.start AND date(Absence.start,duration);

-- INSERTING DATA IN THE DATABASE

INSERT INTO Project
VALUES
(1, date('2020-01-19'), 'ESPOO'),
(2, date('2020-04-10'), 'HELSINKI'),
(3, date('2021-04-14'), 'HELSINKI'),
(4, date('2020-02-13'), 'VANTAA');


INSERT INTO SubProject
VALUES
(1,1,date('2020-01-19'),date('2020-02-19')),
(1,2,date('2020-02-20'),date('2020-03-05')),
(1,3,date('2020-03-06'),date('2020-05-21')),
(2,1,date('2019-04-10'),date('2020-05-25')),
(2,2,date('2020-05-26'),date('2020-09-11')),
(3,1,date('2021-04-14'),date('2021-07-15')),
(4,1,date('2020-02-13'),date('2020-03-12')),
(4,2,date('2020-03-13'),date('2020-04-12')),
(4,3,date('2020-04-13'),date('2020-05-21'));

INSERT INTO HappensBefore
VALUES
(1,1,1,2),
(1,2,1,3),
(2,1,2,2),
(4,1,4,2),
(4,2,4,3);

INSERT INTO Employee
VALUES
(1,'James','Pohjoisesplanadi 90, 00240 HELSINKI'),
(2,'John','Rauhankatu 10, 00760 HELSINKI'),
(3,'Robert','Suometsäntie 26, 00640 HELSINKI'),
(4,'Michael','Suometsäntie 53, 00620 HELSINKI'),
(5,'William','Puolakantie 4, 00500 HELSINKI'),
(6,'David','Suometsäntie 36, 00700 HELSINKI'),
(7,'Richard','Norra Esplanaden 28, 00290 HELSINKI'),
(8,'Joseph','Koskikatu 83, 02240 ESPOO'),
(9,'Thomas','Itätuulenkuja 88, 02970 ESPOO'),
(10,'Charles','Kajaaninkatu 84, 02100 ESPOO'),
(11,'Christopher','Kajaaninkatu 38, 02007 ESPOO'),
(12,'Daniel','Itätuulenkuja 29, 02980 ESPOO'),
(13,'Matthew','Linnankatu 70, 02380 ESPOO'),
(14,'Anthony','Kluuvikatu 26, 01510 VANTAA'),
(15,'Donald','Kajaaninkatu 26, 01760 VANTAA'),
(16,'Mark','Puutarhakatu 21, 01620 VANTAA'),
(17,'Paul','Kluuvikatu 31, 01460 VANTAA'),
(18,'Steven','Puutarhakatu 2, 01710 VANTAA'),
(19,'Andrew','Kluuvikatu 84, 01370 VANTAA'),
(20,'Kenneth','Puutarhakatu 16, VANTAA');

INSERT INTO Absence
VALUES
(1,date('2021-04-14'),'10 days','holidays'),
(2,date('2020-05-27'),'21 days','holidays'),
(3,date('2019-04-10'),'3 days','sick'),
(13,date('2019-05-06'),'60 days','holidays');

INSERT INTO Substitute
VALUES
(1,date('2021-04-14'),9),
(2,date('2020-05-27'),10),
(3,date('2019-04-10'),11),
(13,date('2019-05-06'),5);


INSERT INTO Qualification
VALUES
('carpenter'),
('electrician'),
('plumber'),
('mason');

INSERT INTO HasTheQualification
VALUES
(1,'carpenter'),
(2,'electrician'),
(3,'plumber'),
(4,'mason'),
(5,'carpenter'),
(6,'electrician'),
(7,'plumber'),
(8,'mason'),
(9,'carpenter'),
(10,'electrician'),
(11,'plumber'),
(12,'mason'),
(13,'carpenter'),
(14,'electrician'),
(15,'plumber'),
(16,'mason'),
(17,'carpenter'),
(18,'electrician'),
(19,'plumber'),
(20,'mason');

INSERT INTO Requires
VALUES
(1,1,'mason',2),
(1,2,'plumber',1),
(1,3,'electrician',2),
(1,3,'carpenter',1),

(2,1,'mason',1),
(2,1,'plumber',1),
(2,2,'electrician',2),

(3,1,'mason',2),
(3,1,'carpenter',1),
(3,1,'plumber',1),

(4,1,'mason',1),
(4,2,'plumber',1),
(4,3,'electrician',1);

INSERT INTO IsAppointedTo
VALUES
(1,1,4),
(1,1,8),
(1,2,15),
(1,3,14),
(1,3,18),
(1,3,17),

(2,1,12),
(2,1,3),
(2,2,2),
(2,2,6),

(3,1,16),
(3,1,20),
(3,1,1),
(3,1,11),

(4,1,20),
(4,2,19),
(4,3,10);

INSERT INTO Machine
VALUES
('1', 'Electric Drill','Bosh',30,15),
('2', 'Concrete mixer','Banggood',200,32),
('3', 'Jigsaw','Bosh',42,22),
('4', 'Electric Drill','Panasonic',41,12);

INSERT INTO Item
VALUES
('1',1),
('1',2),
('2',1),
('2',2),
('2',3),
('3',1),
('3',2),
('4',1);

