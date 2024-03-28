USE EventManagementSystemDB
GO

INSERT INTO ems.Users (FirstName, LastName, Email, MobileNo, UserType, RegistrationDate, LastLogin, IsActive)
VALUES
('Md. Rahman', 'Hossain', 'rahman.hossain@example.com', '01711 223 344', 'Organizer', GETDATE(), '2024-03-27 10:30:00', 0),
('Fatema', 'Akter', 'fatema.akter@example.com', '01822 334 455', 'Attendee', GETDATE(), NULL, 1),
('Shakil', 'Ahmed', 'shakil.ahmed@example.com', NULL, 'Attendee', GETDATE(), NULL, 1),
('Tasnim', 'Khan', 'tasnim.khan@example.com', '01633 445 566', 'Attendee', GETDATE(), NULL, 0),
('Farhan', 'Islam', 'farhan.islam@example.com', '01544 556 677', 'Organizer', GETDATE(), '2024-03-26 15:45:00', 1),
('Tasnim2', 'Khan2', 'abcsj.ugf@example.com', '01666 445 566', 'Attendee', GETDATE(), NULL, 0);

GO

SELECT * FROM ems.Users

GO

-- Insert sample event data rows 
INSERT INTO ems.Events (EventName, EventDescription, StartDate, EndDate, Venue, UserID)
VALUES ('Software Development Conference', 'A gathering of developers to share knowledge and experiences.', GETDATE(), DATEADD(day, 2, GETDATE()), 'Grand Convention Center', 1);  

INSERT INTO ems.Events (EventName, EventDescription, StartDate, EndDate, Venue, UserID)
VALUES ('Marketing Workshop', NULL, '2024-04-10 09:00:00', '2024-04-10 17:00:00', 'Company Auditorium', 2);  

INSERT INTO ems.Events (EventName, EventDescription, StartDate, EndDate, Venue, UserID)
VALUES ('Networking Event for Entrepreneurs', 'Connect with fellow entrepreneurs and explore potential collaborations.', 
       DATEADD(day, 7, GETDATE()), DATEADD(day, 9, GETDATE()), 'The Sky Lounge', 3);

INSERT INTO ems.Events (EventName, EventDescription, StartDate, EndDate, Venue, UserID)
VALUES ('Data Science Hackathon', 'A weekend-long challenge to solve real-world data problems.', '2024-05-17 18:00:00', '2024-05-19 12:00:00', 'Innovation Hub', 1);  

INSERT INTO ems.Events (EventName, EventDescription, StartDate, EndDate, Venue, UserID)
VALUES ('Business Summit 2024', 'Annual business summit bringing together industry leaders and entrepreneurs.', '2024-11-12 08:30:00', '2024-11-14 17:00:00', 'Radisson Blu Dhaka Water Garden', 4);

GO

SELECT * FROM ems.Events

GO

-- Insert Values Into Tickets table using TicketIDSequence 

INSERT INTO ems.Tickets (EventID, TicketType, Price, AvailableQuantity, SoldQuantity)
VALUES
(1, 'General Admission', 50.00, 100, 0),
(2, 'VIP', 100.00, 50, 0),
(3, 'Regular', 30.00, 200, 0),
(4, 'Premium', 50.00, 100, 0),
(5, 'Standard', 25.00, 150, 0);

GO

INSERT INTO ems.Registrations (EventID, UserID, TicketID, RegistrationDate)
VALUES
(1, 1, 1, SYSUTCDATETIME()), 
(2, 2, 2, SYSUTCDATETIME()); 

GO

INSERT INTO ems.Speakers (SpeakerName, SpeakerBio, SpeakerPhoto, IsActive, CreatedDate)
VALUES
('Md. Rahman Hossain', 'Md. Rahman Hossain is a renowned Bangladeshi entrepreneur and motivational speaker.', 0x, 1, SYSUTCDATETIME()), 
('Fatema Akter', 'Fatema Akter is an accomplished Bangladeshi scientist and educator.', 0x, 1, SYSUTCDATETIME()); 

GO

INSERT INTO ems.EventSpeakers (EventID, SpeakerID)
VALUES
(1, 1), 
(2, 2); 

GO

INSERT INTO ems.Sponsors (SponsorName, WebsiteURL)
VALUES
('ABC Corporation', 'http://www.abccorporation.com'), 
('XYZ Group', NULL); 

GO

INSERT INTO ems.EventSponsors (EventID, SponsorID)
VALUES
(1, 1), 
(2, 2); 

GO

INSERT INTO ems.Payments (UserID, Amount, PaymentDate, PaymentMethod, TransactionID)
VALUES
(1, 500.00, GETDATE(), 'Credit Card', 'CC1234567890'), 
(2, 300.00, GETDATE(), 'Bank Transfer', 'BT987654321'); 

GO

--Update

UPDATE [EventManagementSystemDB].[ems].[Users]
SET Email = 'newemail@example.com',
    MobileNo = '01987 654 321'
WHERE UserID = 1;

GO

--Delete

DELETE FROM [EventManagementSystemDB].[ems].[Users]
WHERE UserID = 6;

GO

SELECT DISTINCT FirstName, LastName
FROM [EventManagementSystemDB].[ems].[Users];

GO

--Insert Into Copy Data From Another Table
SELECT * 
INTO #tempPayment
FROM ems.Payments

GO

SELECT * FROM #tempPayment

GO

--Truncate table
TRUNCATE TABLE #tempPayment

GO

SELECT *
FROM ems.Users
CROSS JOIN ems.Events;

GO

SELECT u1.UserID AS UserID1, u1.FirstName AS FirstName1, u1.LastName AS LastName1,
       u2.UserID AS UserID2, u2.FirstName AS FirstName2, u2.LastName AS LastName2
FROM ems.Users u1
JOIN ems.Users u2 ON u1.UserID <> u2.UserID;

GO

SELECT UserType, COUNT(UserID) AS UserCount
FROM ems.Users
WHERE RegistrationDate > '2024-01-01'
GROUP BY UserType
HAVING COUNT(UserID) > 1;

GO

SELECT PaymentID, UserID, Amount, PaymentDate, PaymentMethod, TransactionID
FROM ems.Payments
WHERE UserID IN (SELECT UserID FROM ems.Users WHERE UserType = 'Organizer');

GO

SELECT UserID, NULL AS FirstName, NULL AS LastName, Email, NULL AS MobileNo
FROM ems.Users
UNION
SELECT UserID, Amount, PaymentDate, PaymentMethod, TransactionID
FROM ems.Payments;

GO

SELECT UserID, NULL AS FirstName, NULL AS LastName, Email, NULL AS MobileNo
FROM ems.Users
UNION ALL
SELECT UserID, Amount, PaymentDate, PaymentMethod, TransactionID
FROM ems.Payments;

GO

WITH UpcomingRegistrations AS (
  SELECT  
    r.RegistrationID,
    e.EventName,
    e.StartDate,
    e.Venue,
    u.FirstName,
    u.LastName,
    u.Email
  FROM ems.Registrations r
  INNER JOIN ems.Events e ON r.EventID = e.EventID
  INNER JOIN ems.Users u ON r.UserID = u.UserID
  WHERE e.EndDate >= GETDATE()  
)

SELECT *
FROM UpcomingRegistrations;

GO

EXEC RegisterUserForEvent @UserID = 1, @EventID = 1;

GO


SELECT * FROM dbo.GetUserUpcomingRegistrations(2);

GO

DECLARE @UserID INT = 1; 
DECLARE @TotalSpent MONEY;

SELECT @TotalSpent = dbo.CalculateUserTotalSpent(@UserID);

-- Display the total amount spent by the user
SELECT @TotalSpent AS TotalSpent;

GO

--Mathematical Operator
SELECT 10+2 as [Sum]
GO
SELECT 10-2 as [Substraction]
GO
SELECT 10*3 as [Multiplication]
GO
SELECT 10/2 as [Divide]
GO
SELECT 10%3 as [Remainder]
GO

--Cast, Convert, Concatenation
SELECT 'Today : ' + CAST(GETDATE() as varchar)
Go

SELECT 'Today : ' + CONVERT(varchar,GETDATE(),1)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),2)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),3)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),4)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),5)
SELECT 'Today : ' + CONVERT(varchar,GETDATE(),6)
GO

--Isdate
SELECT ISDATE('2030-05-21')
--Datepart
SELECT DATEPART(MONTH,'2030-05-21')
--Datename
SELECT DATENAME(MONTH,'2030-05-21')
--Sysdatetime
SELECT Sysdatetime()
--UTC
SELECT GETUTCDATE()

GO

SELECT UserID, FirstName, LastName, 
  DATEDIFF(day, RegistrationDate, GETUTCDATE()) AS DaysSinceRegistered
FROM ems.Users
WHERE UserType = 'Attendee';

GO

SELECT YEAR(RegistrationDate), MONTH(RegistrationDate) AS Month, COUNT(*) AS RegistrationsPerMonth
FROM ems.Registrations
GROUP BY YEAR(RegistrationDate), MONTH(RegistrationDate) WITH ROLLUP;

GO

SELECT UserType, RegistrationDate, COUNT(*) AS RegistrationsByTypeAndDate
FROM ems.Users
GROUP BY GROUPING SETS ((UserType), (RegistrationDate), (UserType, RegistrationDate));

GO

SELECT UserID, FirstName, LastName,
  CASE UserType WHEN 'Organizer' THEN 'Event Organizer' ELSE 'Attendee' END AS UserTypeName
FROM ems.Users;

GO

SELECT EventName, StartDate, EndDate
FROM ems.Events
WHERE StartDate BETWEEN '2024-04-01' AND '2024-04-30';

GO

SELECT UserID, FirstName, LastName, Email
FROM ems.Users
WHERE UserType = 'Attendee' AND RegistrationDate > '2024-03-01';

GO

SELECT EventName, SpeakerName
FROM ems.Events e
INNER JOIN ems.EventSpeakers es ON e.EventID = es.EventID
INNER JOIN ems.Speakers s ON es.SpeakerID = s.SpeakerID
WHERE SpeakerName LIKE '%Fatema Akter%' OR SpeakerName LIKE '%Machine Learning%';

GO

SELECT EventName, TicketType, SUM(SoldQuantity) AS TicketsSold
FROM ems.Tickets t
INNER JOIN ems.Events e ON t.EventID = e.EventID
GROUP BY EventName, ROLLUP(TicketType);

GO

SELECT u.UserType, r.RegistrationDate, COUNT(*) AS RegistrationsByTypeAndDate
FROM ems.Registrations r
INNER JOIN ems.Users u ON r.UserID = u.UserID
GROUP BY u.UserType, r.RegistrationDate;

GO

SELECT *
FROM ems.Events
WHERE EventID NOT IN (
    SELECT EventID
    FROM ems.EventSpeakers ES
    JOIN ems.Speakers S ON ES.SpeakerID = S.SpeakerID
    WHERE S.SpeakerName IN ('John', 'Jane')
);


GO

SELECT TOP 5 *
FROM ems.Events E
JOIN ems.Tickets T ON E.EventID = T.EventID
ORDER BY T.Price DESC;

GO

SELECT *
FROM ems.Events
WHERE EventName LIKE 'Market%';

GO

DECLARE @Counter INT = 1;
WHILE @Counter <= 10
BEGIN
    PRINT 'UserID: ' + CAST(@Counter AS NVARCHAR(10));
    SET @Counter = @Counter + 1;
END;

GO

SELECT EventName,
       StartDate,
       IIF(CONVERT(DATE, StartDate) = CONVERT(DATE, GETDATE()), 'Today', 'Not Today') AS StartDateStatus
FROM ems.Events;

GO

SELECT EventName,
       EndDate,
       CHOOSE(MONTH(EndDate), 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December') AS EndMonth
FROM ems.Events;

GO

SELECT EventName,
       ISNULL(EventDescription, 'No Description Available') AS EventDescription
FROM ems.Events;

GO

SELECT 
    E.EventName,
    E.Venue,
    S.SponsorName
FROM 
    ems.Events E
JOIN 
    ems.EventSponsors ES ON E.EventID = ES.EventID
JOIN 
    ems.Sponsors S ON ES.SponsorID = S.SponsorID
WHERE 
    S.SponsorName IN ('ABC Corporation', 'Company B', 'Company C');


GO

SELECT 
    UserID, 
    COALESCE(Email, 'Email not provided') AS UserEmail
FROM 
    ems.Users;

GO

SELECT 
    UserID,
    RegistrationDate,
    RANK() OVER (ORDER BY RegistrationDate ASC) AS RegistrationRank,
    DENSE_RANK() OVER (ORDER BY RegistrationDate ASC) AS DenseRegistrationRank,
    ROW_NUMBER() OVER (ORDER BY RegistrationDate ASC) AS RowNumberRegistrationRank
FROM 
    ems.Users;


GO

SELECT 
    UserID,
    Amount,
    SUM(Amount) OVER(PARTITION BY UserID) AS TotalAmountPaid,
    AVG(Amount) OVER(PARTITION BY UserID) AS AverageAmountPaid,
    MAX(Amount) OVER(PARTITION BY UserID) AS MaxAmountPaid,
    MIN(Amount) OVER(PARTITION BY UserID) AS MinAmountPaid
FROM 
    ems.Payments;

GO

SELECT 
    TicketType,
    Price,
    CEILING(Price) AS RoundedUpPrice,
    FLOOR(Price) AS RoundedDownPrice,
    ROUND(Price, 2) AS RoundedPrice
FROM 
    ems.Tickets;

GO

SELECT 
    EventID,
    COUNT(RegistrationID) AS TotalRegistrations
FROM 
    ems.Registrations
GROUP BY 
    EventID;


GO

-- Show events where the organizer is an active user
SELECT EventName, e.UserID
FROM ems.Events e
WHERE EXISTS (
  SELECT 1 FROM ems.Users u
  WHERE u.UserID = e.UserID AND u.IsActive = 1
);

GO

SELECT 
    SponsorID,
    SponsorName,
    WebsiteURL,
    PARSENAME(REPLACE(REPLACE(WebsiteURL, 'https://', ''), 'http://', ''), 2) AS Domain
FROM 
    ems.Sponsors;


GO

