
/*
CS-A1150 project part 2

@Authors: Paul Juillard, Tanguy Rocher

*/


/*
Tu peux sommer les dates avec des jours comme ca
On part donc du principe que nos durations sont toujours sous la forme 'x days', des TEXT
SELECT date('now','6 days')
FROM SubProject;

*/

-- USE CASES ----------------------

-- ### USE CASE : A Subproject needs a machine ###

-- Adding the machine needed into needed
INSERT INTO Needed
VALUES
('3',4,3,date('2020-04-13'),'10 days',1);
-- Finding an item of the corresponding machine that is available during the period

-- Take all items that have the same model as requested
SELECT Item.*
FROM Item
WHERE model = '3'
EXCEPT
-- Except the ones that will already be used by another subproject
SELECT model, itemID
FROM Assigned
WHERE NOT (date('2020-04-13','10 days') < start OR date('2020-04-13') > date(start,duration))
EXCEPT 
-- Except the ones that are in maintenance during the same period
SELECT model, itemID
FROM Maintenance
WHERE NOT (date('2020-04-13','10 days') < start OR date('2020-04-13') > date(start,duration));

-- We can finally insert one of the item returned by this query to the Assigned table
INSERT INTO Needed
VALUES
('3',4,3,date('2020-04-13'),'10 days',1);

-- ### USE CASE : INFORMATIONS ABOUT PROJECT X ###
-- subprojects of project
SELECT *
FROM Subproject
WHERE projectID = X
;
-- employees working on project now
SELECT socialSecurityNo
FROM IsAppointedTo
WHERE 
    projectID = X 
    AND subprojectID IN -- subprojects of X
         ( SELECT *
         FROM Subproject
         WHERE projectID = X
         )
;
-- Scheduled finish time
SELECT MAX(finish)
FROM SubprojectsByTime
WHERE projectID = X
;

-- ### USE CASE : COMPANY STATISTICS ###
-- Need to fire... look at employees ordered by sick leave durations this year
SELECT socialSecurityNo, SUM(duration)
FROM Absence
WHERE 
    (start + duration) >= date('year')
    AND reason = 'sickness'
ORDER BY SUM(duration) DESC
;

-- promotion time! which employee never takes hollidays past 3 years
SELECT socialSecurityNo, SUM(duration)
FROM Absence
WHERE 
    (start + duration) >= date('3 years ago')
    AND reason = 'hollydays'
ORDER BY SUM(duration) ASC
;

-- projects finished this year
SELECT COUNT(projectID)
FROM Project
WHERE projectID IN (
    SELECT projectID
    FROM Subproject
    WHERE
        finish >= date('year')
        AND finish <= date('now') 
    GROUP BY projectID
    )
;
-- More equipment budget, what should we buy? most used machines
SELECT model, SUM(duration)
FROM Assigned
ORDER BY SUM(duration) DESC
;
-- 4


-- ### USE CASE : CREATE A PROJECT ###

-- in which location is there less projects?
-- let l be the location of the result of this query
SELECT location, SUM(1)
    FROM ProjectsByLocation
    ORDER BY SUM(1) ASC
    LIMIT 1
;
INSERT INTO Project VALUES (new_uid(), date('now'), l);
-- 1


-- ### USE CASE : AN EMPLOYEE IS SICK TODAY ###

SELECT CurrentSubprojects.*
FROM IsAppointedTo, CurrentSubprojects
WHERE IsAppointedTo.socialSecurityNo = 12 AND 
    IsAppointedTo.projectID = CurrentSubprojects.projectID AND 
    isAppointedTo.subprojectID = CurrentSubprojects.subprojectID AND
    NOT (date('2020-05-11','4 days') < start OR date('2020-05-11') > finish);


-- All the employee with the same qualification
SELECT Employee.*
FROM Employee INNER JOIN HasTheQualification ON Employee.socialSecurityNo = HasTheQualification.socialSecurityNo
WHERE type IN (SELECT type FROM HasTheQualification WHERE socialSecurityNo = 12) AND Employee.socialSecurityNo != 12
EXCEPT
-- Except the ones that are working during the period were the guy is sick
SELECT Employee.*
FROM Employee INNER JOIN IsAppointedTo ON Employee.socialSecurityNo = IsAppointedTo.socialSecurityNo, SubProject
WHERE IsAppointedTo.subprojectID = SubProject.subprojectID AND 
    IsAppointedTo.projectID = SubProject.projectID AND
    NOT (date('2020-05-11','4 days') < start OR date('2020-05-11') > finish)
EXCEPT
-- Except the ones that are also absent during the period
SELECT Employee.*
FROM Employee INNER JOIN Absence ON Employee.socialSecurityNo = Absence.socialSecurityNo
WHERE NOT (date('2020-05-11','4 days') < start OR date('2020-05-11') > date(start,duration))
EXCEPT
-- Except the ones that are already substituing someone during the period
SELECT Employee.*
FROM Employee INNER JOIN Substitute ON Employee.socialSecurityNo = Substitute.socialSecurityNoSubstitute,Absence
WHERE Substitute.socialSecurityNoAbsent = Absence.socialSecurityNo AND NOT (date('2020-05-11','4 days') < Absence.start OR date('2020-05-11') > date(Absence.start,Absence.duration));

INSERT INTO Absence
VALUES
(12,date('2020-05-11'),'4 days','sick');

INSERT INTO Substitute
VALUES
(12,date('2020-05-11'),20);


-- ### USE CASE : AN ITEM IS BROKEN ###

-- drill 3 IS ASSIGNED TO PROJECT 1 AND JUST BROKE,
-- ASSIGN ANOTHER ONE FOR THE REMAINING 3 DAYS AND PUT  IT IN MAINTENANCE
-- find assignment and delete it
DELETE 
FROM Assigned
WHERE 
    modelID = 'drill'
    AND itemID = 3
    AND start + duration > date('now')
;

-- find another available item
SELECT model, itemID
FROM Item
WHERE NOT (model, itemID) IN (
    SELECT model, itemID
    FROM Assigned
    WHERE 
        start+duration > date('now')
        AND start < date('now') + date('3 days')
    )
LIMIT 1;
-- (drill 4) is available

-- assign this new item to subproject
INSERT INTO Assigned
VALUES
('drill', 4, date('now'), date('3 days'), );

-- put drill 3 in maintenance for a days
INSERT INTO Maintenance
VALUES
('drill', 3, date('now'), date('1 day'));


-- ### USE CASE : HIRING PEOPLE ###
SELECT type, COUNT(socialSecurityNo)
FROM HasTheQualification
GROUP BY type;

SELECT qualificationType, SUM(count)
FROM Requires
GROUP BY qualificationType;
