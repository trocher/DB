/*
CS-A1150 project part 2

@Authors: Paul Juillard, Tanguy Rocher

*/

/*
total queries : 14
total insert : 7
total delete : 1
TODO LIST:
*/

-- USE CASES FOR PROJECT2DB
-- this script assumes scripts 'constructino.sql' and 'input.sql' have been run prior

-- INFORMATIONS ABOUT PROJECT 3
-- subprojects of project
SELECT *
FROM Subproject
WHERE projectID = 3
;
-- employees working on project now
SELECT socialSecurityNo
FROM IsAppointedTo
WHERE 
    projectID = 3 
    AND subprojectID IN -- subprojects of X
         ( SELECT subprojectID
         FROM Subproject
         WHERE projectID = 3
         )
;
-- Scheduled finish time
SELECT MAX(finish)
FROM Subproject
WHERE projectID = 3
;

-- COMPANY STATISTICS
-- Need to fire... look at employees ordered by sick leave durations this year
SELECT socialSecurityNo, SUM(duration)
FROM Absence
WHERE 
    date(start,duration) >= date('2020-01-01')
    AND reason = 'sick'
ORDER BY SUM(duration) DESC
;

-- promotion time! which employee never takes holidays past 3 years
SELECT socialSecurityNo, SUM(duration)
FROM Absence
WHERE 
    date(start,duration) >= date('2017-01-01')
    AND reason = 'holidays'
ORDER BY SUM(duration) ASC
;

-- find machine of the year
SELECT model, SUM(duration)
FROM Assigned
ORDER BY SUM(duration) DESC
;

-- projects finished this year
SELECT COUNT(projectID)
FROM Project
WHERE projectID IN (
    SELECT projectID
    FROM Subproject
    WHERE
        finish >= date('2020-01-01')
        AND finish <= date('now') 
    GROUP BY projectID
    )
;

-- CREATE A PROJECT
-- where is there less projects?
SELECT location, SUM(1)
FROM Project
ORDER BY SUM(1) ASC
LIMIT 1
;
-- there is space in 'ESPOO'
INSERT INTO Project VALUES (88, date('now'), 'ESPOO');


-- AN EMPLOYEE IS SICK TODAY
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

-- AN ITEM BROKE
-- drill 3, assigned to project 1 subproject 1,  just broke.
-- assign another one for the remaining days and put it in maintenance

-- find assignment and delete it
DELETE 
FROM Assigned
WHERE 
    model = 'drill'
    AND itemID = 3
    AND date(start,duration) >= date('now')
;
-- find another available item
SELECT model, itemID
FROM Item
WHERE 
    model = 'drill'
    AND NOT (model, itemID) IN (
    SELECT model, itemID
    FROM Assigned
    WHERE 
        date(start,duration) > date('now')
        AND date(start) < date('now','3 days')
    )
    AND NOT (model, itemID) IN (
    SELECT model, itemID
    FROM Maintenance
    WHERE 
        date(start,duration) > date('now')
        AND date(start) < date('now','3 days')
    )
LIMIT 1;
-- (drill 4) is available

-- assign this new item of the same model to subproject
INSERT INTO Assigned
VALUES
('drill', 4, 1, 1, date('now'), date('3 days'));

-- put drill 3 in maintenance for a day
INSERT INTO Maintenance
VALUES
('drill', 3, date('now'), 'I made it fall', date('1 days'));

-- HIRING PEOPLE
SELECT type, COUNT(socialSecurityNo)
FROM HasTheQualification
GROUP BY type;

SELECT qualificationType, SUM(count)
FROM Requires
GROUP BY qualificationType;

--A SUBPROJECT NEEDS A MACHINE

-- Adding the machine needed into needed
INSERT INTO Needed
VALUES
('3D printer',1,3,date('2020-04-13'),'10 days',1);
-- Finding an item of the corresponding machine that is available during the period

-- Take all items that have the same model as requested
SELECT Item.*
FROM Item
WHERE model = '3D printer'
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
INSERT INTO Assigned
VALUES
('3D printer',1,1,3,date('2020-04-13'),'10 days');