-- Create Database using default location
USE master

GO

IF DB_ID ('EventManagementSystemDB') IS NOT NULL
DROP DATABASE EventManagementSystemDB;

DECLARE @data_path nvarchar(256);
SET @data_path = ( SELECT SUBSTRING(physical_name,1, CHARINDEX(N'master.mdf', LOWER(physical_name))-1)
	FROM master.sys.master_files
	WHERE database_id=1 AND file_id=1
);


EXECUTE ('CREATE DATABASE EventManagementSystemDB
ON PRIMARY (NAME=EventManagementSystemDB_data, FILENAME='''+@data_path+'EventManagementSystemDB_data.mdf'', SIZE=20MB, MAXSIZE=Unlimited, FILEGROWTH=5%)
LOG ON (NAME=EventManagementSystemDB_log, FILENAME='''+@data_path+'EventManagementSystemDB_log.ldf'', SIZE=10MB, MAXSIZE=100MB, FILEGROWTH=2MB)
');

GO

USE EventManagementSystemDB

GO

-- Alter Database to Modify size

ALTER DATABASE EventManagementSystemDB

MODIFY FILE (Name=EventManagementSystemDB_data, SIZE= 25MB);

GO

 -- Schema Creation
CREATE SCHEMA ems

GO

-- Create Multiple Tables 

USE EventManagementSystemDB

CREATE TABLE ems.Users (
     UserID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    --UserID int IDENTITY,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Email nvarchar(100) UNIQUE NOT NULL,
    MobileNo varchar(15), 
    UserType varchar(20) NOT NULL DEFAULT 'Attendee', 
    RegistrationDate datetime2 NOT NULL DEFAULT GETDATE(), 
    LastLogin datetime2, 
    IsActive bit NOT NULL DEFAULT 1, 
    CONSTRAINT CHK_UserType CHECK (UserType IN ('Organizer', 'Attendee')), 
    CONSTRAINT CHK_MobileNoFormat CHECK (MobileNo IS NULL OR MobileNo LIKE '[0][1][0-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]') 
);

GO

USE EventManagementSystemDB

CREATE TABLE ems.Events (
    EventID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EventName nvarchar(100) NOT NULL,
    EventDescription nvarchar(MAX), 
    StartDate datetime2 NOT NULL DEFAULT GETDATE(),
    EndDate datetime2 NOT NULL,
    Venue nvarchar(255) NOT NULL, 
    UserID int FOREIGN KEY REFERENCES ems.Users(UserID),
    
    CONSTRAINT CHK_StartDateBeforeEndDate CHECK (StartDate < EndDate), 
    CONSTRAINT CHK_EventNameLength CHECK (LEN(EventName) <= 100), 
    CONSTRAINT CHK_VenueNotEmpty CHECK (LEN(Venue) > 0), 
    CONSTRAINT CHK_EventDescriptionLength CHECK (LEN(ISNULL(EventDescription, '')) <= 200) 
);

GO

USE EventManagementSystemDB


CREATE TABLE ems.Tickets (
    TicketID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EventID int FOREIGN KEY REFERENCES ems.Events(EventID),
    TicketType varchar(30) NOT NULL,  
    Price decimal(10, 2) NOT NULL, 
    AvailableQuantity int NOT NULL DEFAULT 0, 
    SoldQuantity int NOT NULL DEFAULT 0, 
    CONSTRAINT CHK_PricePositive CHECK (Price >= 0), 
    CONSTRAINT CHK_AvailableQuantityNonNegative CHECK (AvailableQuantity >= 0), 
    CONSTRAINT CHK_SoldQuantityNonNegative CHECK (SoldQuantity >= 0) 
);

GO

USE EventManagementSystemDB

CREATE TABLE ems.Registrations (
    RegistrationID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EventID int FOREIGN KEY REFERENCES ems.Events(EventID),
    UserID int FOREIGN KEY REFERENCES ems.Users(UserID),
    TicketID int FOREIGN KEY REFERENCES ems.Tickets(TicketID),
    RegistrationDate datetime2 NOT NULL DEFAULT SYSUTCDATETIME(), 
    CONSTRAINT CHK_RegistrationDate CHECK (RegistrationDate <= SYSUTCDATETIME()), -- 
    CONSTRAINT UQ_UserEventRegistration UNIQUE (EventID, UserID), 
    CONSTRAINT CHK_RegistrationTicketConsistency CHECK (EventID IS NOT NULL AND UserID IS NOT NULL AND TicketID IS NOT NULL) 
);

GO

USE EventManagementSystemDB

CREATE TABLE ems.Speakers (
    SpeakerID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SpeakerName nvarchar(100) NOT NULL, 
    SpeakerBio nvarchar(MAX), 
    SpeakerPhoto varbinary(MAX), 
    IsActive bit NOT NULL DEFAULT 1, 
    CreatedDate datetime2 NOT NULL DEFAULT SYSUTCDATETIME(), 
    CONSTRAINT CHK_SpeakerNameLength CHECK (LEN(SpeakerName) <= 100), 
    CONSTRAINT CHK_SpeakerBioLength CHECK (LEN(ISNULL(SpeakerBio, '')) <= 200) 
);

GO

USE EventManagementSystemDB


CREATE TABLE ems.EventSpeakers (
    EventID int,
    SpeakerID int,
    CONSTRAINT FK_EventSpeakers_EventID FOREIGN KEY (EventID) REFERENCES ems.Events(EventID),
    CONSTRAINT FK_EventSpeakers_SpeakerID FOREIGN KEY (SpeakerID) REFERENCES ems.Speakers(SpeakerID),
    CONSTRAINT PK_EventSpeakers PRIMARY KEY (EventID, SpeakerID)
);

GO

USE EventManagementSystemDB

CREATE TABLE ems.Sponsors (
    SponsorID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SponsorName nvarchar(100) NOT NULL,
    WebsiteURL nvarchar(200),
    CONSTRAINT CHK_WebsiteURLFormat CHECK (WebsiteURL IS NULL OR WebsiteURL LIKE 'http://%') 
);

GO

USE EventManagementSystemDB

CREATE TABLE ems.EventSponsors (
    EventID int,
    SponsorID int,
    CONSTRAINT FK_EventSponsors_EventID FOREIGN KEY (EventID) REFERENCES ems.Events(EventID),
    CONSTRAINT FK_EventSponsors_SponsorID FOREIGN KEY (SponsorID) REFERENCES ems.Sponsors(SponsorID),
    CONSTRAINT PK_EventSponsors PRIMARY KEY (EventID, SponsorID)
);

GO

USE EventManagementSystemDB

CREATE TABLE ems.Payments (
    PaymentID int IDENTITY,
    UserID int NOT NULL,
    Amount money NOT NULL,
    PaymentDate datetime NOT NULL DEFAULT GETDATE(),
    PaymentMethod nvarchar(50) NOT NULL,
    TransactionID nvarchar(100) NULL,
    CONSTRAINT FK_UserID FOREIGN KEY (UserID) REFERENCES ems.Users(UserID),
    CONSTRAINT CHK_AmountPositive CHECK (Amount > 0),
    CONSTRAINT CHK_PaymentMethod CHECK (PaymentMethod IN ('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash')),
    CONSTRAINT CHK_TransactionID_Length CHECK (LEN(TransactionID) <= 100)
);

GO

-- Create Local & Global temporary tables

CREATE TABLE #EventWaitlist (
    WaitlistID int IDENTITY(1,1) PRIMARY KEY,
    UserID int NOT NULL,
    EventID int NOT NULL,
    WaitlistEntryTime datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(),   
    CONSTRAINT CHK_WaitlistEntryTime CHECK (WaitlistEntryTime <= SYSUTCDATETIME()) -- 
);

GO

CREATE TABLE ##EventSessionFeedback (
    FeedbackID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EventID int NOT NULL,
    SessionID int NOT NULL, 
    UserID int NOT NULL,
    Rating int CHECK (Rating >= 1 AND Rating <= 5),  
    FeedbackText nvarchar(MAX),  
    FeedbackTime datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(), 
       
);

GO

-- Drop Local Temporary table
DROP TABLE #EventWaitlist

-- Drop Global Temporary table
DROP TABLE ##EventSessionFeedback

GO

-- Alter table: adding and dropping column

ALTER TABLE ems.Events
ADD EventCategory varchar(50) NULL; 

ALTER TABLE ems.Events
DROP COLUMN EventCategory; 

GO

-- Created Clustered Index and NonClustered Index

CREATE CLUSTERED INDEX IX_Payments_PaymentID ON ems.Payments (PaymentID);

CREATE NONCLUSTERED INDEX IX_Registrations_EventID ON ems.Registrations (EventID);

GO

USE EventManagementSystemDB

-- Create a sequence

-- Created on Tickets Table
CREATE SEQUENCE TicketIDSequence
    START WITH 1000  
    INCREMENT BY 1   
    MINVALUE 1       
    MAXVALUE 999999  
    CYCLE;           

GO

-- Create View 

CREATE VIEW vwEventDetails
AS
SELECT 
    E.EventID,
    E.EventName,
    E.EventDescription,
    E.StartDate,
    E.EndDate,
    E.Venue,
    S.SpeakerID,
    S.SpeakerName,
    SP.SponsorID,
    SP.SponsorName,
    T.TicketID,
    T.TicketType,
    T.Price,
    T.AvailableQuantity
FROM 
    ems.Events E
LEFT JOIN 
    ems.EventSpeakers ES ON E.EventID = ES.EventID
LEFT JOIN 
    ems.Speakers S ON ES.SpeakerID = S.SpeakerID
LEFT JOIN 
    ems.EventSponsors ESp ON E.EventID = ESp.EventID
LEFT JOIN 
    ems.Sponsors SP ON ESp.SponsorID = SP.SponsorID
LEFT JOIN 
    ems.Tickets T ON E.EventID = T.EventID;


GO

-- Create a View With Encryption

CREATE VIEW EncryptedPaymentDetails
WITH ENCRYPTION
AS
SELECT 
  p.PaymentID,
  u.FirstName + ' ' + u.LastName AS UserName,
  e.EventName,
  p.Amount AS Amount,
  p.PaymentDate,
  p.PaymentMethod,
  p.TransactionID
FROM ems.Payments p
INNER JOIN ems.Users u ON p.UserID = u.UserID
INNER JOIN ems.Registrations r ON p.PaymentID = r.RegistrationID  
INNER JOIN ems.Events e ON r.EventID = e.EventID

GO

--Create a Transaction (Commit, Rollback, Try, Catch) with Stored-Procedure

CREATE PROCEDURE RegisterUserForEvent 
(
  @UserID int,
  @EventID int
)
AS
BEGIN
  
  BEGIN TRANSACTION;

  
  BEGIN TRY
   
    IF NOT EXISTS (SELECT * FROM ems.Users u JOIN ems.Events e ON u.UserID = @UserID AND e.EventID = @EventID)
      BEGIN
        RAISERROR ('User or Event does not exist.', 16, 1)
        RETURN; -- Exit procedure on error
      END;

    
    INSERT INTO ems.Registrations (EventID, UserID)
    VALUES (@EventID, @UserID);

    
    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH 
    ROLLBACK TRANSACTION; 
    RAISERROR ('Registration failed. This is a CUSTOMIZED ERROR from the Developer for Testing purpose', 16, 1); 
  END CATCH
END;


GO

-- Create After Trigger

CREATE TRIGGER UpdateTicketSoldQuantity
ON ems.Registrations
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    
    UPDATE ems.Tickets
    SET SoldQuantity = SoldQuantity + 1
    WHERE EventID IN (SELECT EventID FROM inserted)
END

GO

-- Create Instead Of Trigger For Setting Limit of 1 Row Update and Delete at a time

CREATE TRIGGER PreventDuplicateRegistrations
ON ems.Registrations
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

   
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE EXISTS (
            SELECT 1
            FROM ems.Registrations r
            WHERE r.UserID = i.UserID
            AND EXISTS (
                SELECT 1
                FROM ems.Events e
                WHERE e.EventID = r.EventID
                AND e.StartDate = (SELECT StartDate FROM ems.Events WHERE EventID = i.EventID)
                AND e.EndDate = (SELECT EndDate FROM ems.Events WHERE EventID = i.EventID)
            )
        )
    )
    BEGIN
        RAISERROR('Cannot register for another event happening at the same time.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    
    INSERT INTO ems.Registrations (EventID, UserID, TicketID, RegistrationDate)
    SELECT EventID, UserID, TicketID, RegistrationDate
    FROM inserted;
END

GO

-- Create Tabular Function

CREATE FUNCTION GetUserUpcomingRegistrations (@UserID INT)
RETURNS TABLE
AS
RETURN (
  SELECT 
    r.RegistrationID,
    e.EventName,
    e.EventDescription,
    e.StartDate,
    t.TicketType
  FROM ems.Registrations r
  INNER JOIN ems.Events e ON r.EventID = e.EventID
  INNER JOIN ems.Tickets t ON r.EventID = t.EventID
  WHERE r.UserID = @UserID
  AND e.StartDate >= GETDATE()  
);

GO

-- Create Scalar Function

CREATE FUNCTION CalculateUserTotalSpent
(
    @UserID INT
)
RETURNS MONEY
AS
BEGIN
    DECLARE @TotalSpent MONEY;

    SELECT @TotalSpent = SUM(P.Amount)
    FROM ems.Payments P
    INNER JOIN ems.Registrations R ON P.UserID = R.UserID
    WHERE R.UserID = @UserID;

    IF @TotalSpent IS NULL
    BEGIN
        SET @TotalSpent = 0;
    END

    RETURN @TotalSpent;
END
