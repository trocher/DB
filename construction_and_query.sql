
/*
CS-A1150 project part 2

@Authors: Paul Juillard, Tanguy Rocher

*/

-- Tu peux sommer les dates avec des jours comme ca
-- On part donc du principe que nos durations sont toujours sous la forme 'x days', des TEXT
SELECT date('now','6 days')
FROM SubProject;

-- USE CASES

-- COMPANY STATISTICS
-- most sick employees
-- never takes holliday employees
-- projects finished this year
-- most used machine
-- 4

-- CREATE A PROJECT
-- in which location is there more space?
-- when can we start it? lets not have more then X projects at a time
-- 2

-- CREATE A NEW SUBPROJECTS WITH ALL ITS NEEDS FROM AVAILABILITY
-- create subproject to project X
-- add qualification requirements
-- add machine needs
-- 0

-- ANSWER PENDING NEEDS
-- find pending needs
-- find available items
-- assign item I to subproject X 
-- 2

-- ANSWER PENDING QUALIFICATION REQUIREMENTS
-- find employees that correspond to qualifications x
-- appoint them to subproject
-- 1

-- INFORMATIONS ABOUT PROJECT X
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



-- COMPANY STATISTICS
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

-- CREATE A PROJECT
-- in which location is there less projects?

-- let l be the location of the result of this query
SELECT location, SUM(1)
    FROM ProjectsByLocation
    ORDER BY SUM(1) ASC
    LIMIT 1
;
INSERT INTO Project VALUES (new_uid(), date('now'), l);
-- 1


-- USE CASE AN EMPLOYEE IS SICK TODAY
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
-- ITEM I IS BROKEN, ASSIGN ANOTHER ONE
-- delete assignment
-- find another available item
-- assign another item of the same model to subproject
-- put I in maintenance
-- 1

-- ITEM I IS DAMAGED, WHO DID IT?
-- last 10 uses of item I
-- uses of item I this year
-- last maintenance for item I
-- 3

-- USE CASE HIRING PEOPLE
SELECT type, COUNT(socialSecurityNo)
FROM HasTheQualification
GROUP BY type;

SELECT qualificationType, SUM(count)
FROM Requires
GROUP BY qualificationType;

-- USE CASE CREATE NEW PROJECT AND SUBPROJECT
INSERT INTO Project
VALUES
(5, date('2020-05-14'), 'HELSINKI');