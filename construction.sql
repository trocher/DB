
/*
CS-A1150 project part 2

@Authors: Paul Juillard, Tanguy Rocher

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
    start TEXT,
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
    PRIMARY KEY(model, itemID, projectID, subprojectID, start),
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
    FOREIGN KEY(socialSecurityNoAbsent, start) REFERENCES Absence(socialSecurityNo, start),
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
