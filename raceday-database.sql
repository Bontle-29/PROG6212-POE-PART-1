/*
    RaceDay Part 1 - SQL Server database script
    Run on a clean SQL Server database in SSMS.
*/

IF DB_ID(N'RaceDayDb') IS NULL
BEGIN
    CREATE DATABASE RaceDayDb;
END;
GO

USE RaceDayDb;
GO

/* Drop objects in dependency order so the script can be rerun during testing. */
DROP TABLE IF EXISTS dbo.WeatherForecasts;
DROP TABLE IF EXISTS dbo.Routes;
DROP TABLE IF EXISTS dbo.Results;
DROP TABLE IF EXISTS dbo.Enrolments;
DROP TABLE IF EXISTS dbo.Categories;
DROP TABLE IF EXISTS dbo.Events;
DROP TABLE IF EXISTS dbo.Users;
GO

CREATE TABLE dbo.Users
(
    UserId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    FirstName NVARCHAR(80) NOT NULL,
    LastName NVARCHAR(80) NOT NULL,
    Email NVARCHAR(255) NOT NULL CONSTRAINT UQ_Users_Email UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL CONSTRAINT CK_Users_Role CHECK (Role IN (N'Organiser', N'Participant', N'Admin')),
    PhoneNumber NVARCHAR(30) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.Events
(
    EventId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Events PRIMARY KEY,
    OrganiserId INT NOT NULL,
    Name NVARCHAR(160) NOT NULL,
    Description NVARCHAR(2000) NULL,
    EventType NVARCHAR(20) NOT NULL CONSTRAINT CK_Events_EventType CHECK (EventType IN (N'Running', N'Walking', N'Cycling')),
    Venue NVARCHAR(200) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    Province NVARCHAR(100) NOT NULL,
    EventDate DATE NOT NULL,
    RegistrationOpen DATETIME2(0) NOT NULL,
    RegistrationClose DATETIME2(0) NOT NULL,
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Events_Status DEFAULT N'Published' CONSTRAINT CK_Events_Status CHECK (Status IN (N'Draft', N'Published', N'Closed', N'Completed', N'Cancelled')),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Events_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT CK_Events_RegistrationDates CHECK (RegistrationClose >= RegistrationOpen),
    CONSTRAINT CK_Events_EventDate CHECK (EventDate >= CAST(RegistrationOpen AS DATE))
);
GO

CREATE TABLE dbo.Categories
(
    CategoryId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categories PRIMARY KEY,
    EventId INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL CONSTRAINT DF_Categories_EntryFee DEFAULT 0,
    MaximumEntries INT NULL,
    CONSTRAINT FK_Categories_Event FOREIGN KEY (EventId) REFERENCES dbo.Events(EventId) ON DELETE CASCADE,
    CONSTRAINT UQ_Categories_Event_Name UNIQUE (EventId, Name),
    CONSTRAINT CK_Categories_Distance CHECK (DistanceKm > 0),
    CONSTRAINT CK_Categories_EntryFee CHECK (EntryFee >= 0),
    CONSTRAINT CK_Categories_MaximumEntries CHECK (MaximumEntries IS NULL OR MaximumEntries > 0)
);
GO

CREATE TABLE dbo.Enrolments
(
    EnrolmentId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Enrolments PRIMARY KEY,
    CategoryId INT NOT NULL,
    ParticipantId INT NOT NULL,
    EnrolledAt DATETIME2(0) NOT NULL CONSTRAINT DF_Enrolments_EnrolledAt DEFAULT SYSUTCDATETIME(),
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Enrolments_Status DEFAULT N'Confirmed' CONSTRAINT CK_Enrolments_Status CHECK (Status IN (N'Pending', N'Confirmed', N'Cancelled')),
    RaceNumber NVARCHAR(30) NOT NULL CONSTRAINT UQ_Enrolments_RaceNumber UNIQUE,
    CONSTRAINT FK_Enrolments_Category FOREIGN KEY (CategoryId) REFERENCES dbo.Categories(CategoryId) ON DELETE CASCADE,
    CONSTRAINT FK_Enrolments_Participant FOREIGN KEY (ParticipantId) REFERENCES dbo.Users(UserId),
    CONSTRAINT UQ_Enrolments_Participant_Category UNIQUE (ParticipantId, CategoryId)
);
GO

CREATE TABLE dbo.Results
(
    ResultId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Results PRIMARY KEY,
    EnrolmentId INT NOT NULL CONSTRAINT UQ_Results_Enrolment UNIQUE,
    FinishPosition INT NULL,
    FinishTimeSeconds INT NULL,
    ResultStatus NVARCHAR(20) NOT NULL CONSTRAINT DF_Results_Status DEFAULT N'Finished' CONSTRAINT CK_Results_Status CHECK (ResultStatus IN (N'Finished', N'DNF', N'DNS', N'DSQ')),
    RecordedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Results_RecordedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Results_Enrolment FOREIGN KEY (EnrolmentId) REFERENCES dbo.Enrolments(EnrolmentId) ON DELETE CASCADE,
    CONSTRAINT CK_Results_Position CHECK (FinishPosition IS NULL OR FinishPosition > 0),
    CONSTRAINT CK_Results_Time CHECK (FinishTimeSeconds IS NULL OR FinishTimeSeconds > 0)
);
GO

CREATE TABLE dbo.Routes
(
    RouteId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Routes PRIMARY KEY,
    EventId INT NOT NULL CONSTRAINT UQ_Routes_Event UNIQUE,
    StartLocation NVARCHAR(200) NOT NULL,
    FinishLocation NVARCHAR(200) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    RouteDescription NVARCHAR(2000) NULL,
    MapUrl NVARCHAR(500) NULL,
    CONSTRAINT FK_Routes_Event FOREIGN KEY (EventId) REFERENCES dbo.Events(EventId) ON DELETE CASCADE,
    CONSTRAINT CK_Routes_Distance CHECK (DistanceKm > 0)
);
GO

CREATE TABLE dbo.WeatherForecasts
(
    WeatherForecastId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_WeatherForecasts PRIMARY KEY,
    EventId INT NOT NULL,
    ForecastDate DATE NOT NULL,
    TemperatureC DECIMAL(5,2) NOT NULL,
    Conditions NVARCHAR(100) NOT NULL,
    WindSpeedKmh DECIMAL(6,2) NOT NULL CONSTRAINT DF_Weather_Wind DEFAULT 0,
    RainChancePercent INT NOT NULL CONSTRAINT DF_Weather_Rain DEFAULT 0,
    RetrievedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Weather_RetrievedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Weather_Event FOREIGN KEY (EventId) REFERENCES dbo.Events(EventId) ON DELETE CASCADE,
    CONSTRAINT UQ_Weather_Event_Date UNIQUE (EventId, ForecastDate),
    CONSTRAINT CK_Weather_Wind CHECK (WindSpeedKmh >= 0),
    CONSTRAINT CK_Weather_Rain CHECK (RainChancePercent BETWEEN 0 AND 100)
);
GO

/* Minimum seed data: two organisers, two participants, three events,
   categories for every event, and sample enrolments. */
INSERT INTO dbo.Users (FirstName, LastName, Email, PasswordHash, Role, PhoneNumber)
VALUES
(N'Lerato', N'Mokoena', N'lerato.organiser@raceday.co.za', N'REPLACE_WITH_HASH_1', N'Organiser', N'+27820000001'),
(N'Johan', N'van der Merwe', N'johan.organiser@raceday.co.za', N'REPLACE_WITH_HASH_2', N'Organiser', N'+27820000002'),
(N'Ayesha', N'Naidoo', N'ayesha.participant@raceday.co.za', N'REPLACE_WITH_HASH_3', N'Participant', N'+27820000003'),
(N'Thabo', N'Dlamini', N'thabo.participant@raceday.co.za', N'REPLACE_WITH_HASH_4', N'Participant', N'+27820000004');
GO

INSERT INTO dbo.Events (OrganiserId, Name, Description, EventType, Venue, City, Province, EventDate, RegistrationOpen, RegistrationClose, Status)
VALUES
(1, N'Gauteng Sunrise Run', N'A community road-running event for all abilities.', N'Running', N'Union Buildings', N'Pretoria', N'Gauteng', '2027-02-14', '2026-10-01T08:00:00', '2027-02-07T23:59:00', N'Published'),
(1, N'Cape Coastal Cycle', N'A scenic cycling event along the Cape Peninsula.', N'Cycling', N'Green Point Stadium', N'Cape Town', N'Western Cape', '2027-03-21', '2026-11-01T08:00:00', '2027-03-14T23:59:00', N'Published'),
(2, N'Durban Charity Walk', N'A family-friendly charity walk supporting local schools.', N'Walking', N'Moses Mabhida Stadium', N'Durban', N'KwaZulu-Natal', '2027-04-10', '2026-12-01T08:00:00', '2027-04-03T23:59:00', N'Published');
GO

INSERT INTO dbo.Categories (EventId, Name, DistanceKm, EntryFee, MaximumEntries)
VALUES
(1, N'5 km Fun Run', 5.00, 80.00, 1000),
(1, N'10 km Road Race', 10.00, 150.00, 1500),
(2, N'40 km Cycle', 40.00, 250.00, 800),
(2, N'80 km Cycle', 80.00, 400.00, 600),
(3, N'5 km Family Walk', 5.00, 60.00, 1200),
(3, N'10 km Charity Walk', 10.00, 100.00, 800);
GO

INSERT INTO dbo.Routes (EventId, StartLocation, FinishLocation, DistanceKm, RouteDescription, MapUrl)
VALUES
(1, N'Union Buildings', N'Union Buildings', 10.00, N'City route through central Pretoria and surrounding suburbs.', N'https://maps.example.com/gauteng-sunrise'),
(2, N'Green Point', N'Green Point', 80.00, N'Coastal route through Hout Bay and Chapman''s Peak.', N'https://maps.example.com/cape-coastal'),
(3, N'Moses Mabhida Stadium', N'Moses Mabhida Stadium', 10.00, N'Flat beachfront route suitable for families and charity teams.', N'https://maps.example.com/durban-walk');
GO

INSERT INTO dbo.WeatherForecasts (EventId, ForecastDate, TemperatureC, Conditions, WindSpeedKmh, RainChancePercent)
VALUES
(1, '2027-02-14', 23.50, N'Partly cloudy', 12.00, 20),
(2, '2027-03-21', 20.00, N'Sunny', 18.00, 10),
(3, '2027-04-10', 25.00, N'Clear', 9.00, 15);
GO

INSERT INTO dbo.Enrolments (CategoryId, ParticipantId, EnrolledAt, Status, RaceNumber)
VALUES
(1, 3, '2026-11-12T09:30:00', N'Confirmed', N'GSR-0001'),
(2, 4, '2026-11-14T10:15:00', N'Confirmed', N'GSR-0002'),
(3, 3, '2026-12-01T11:00:00', N'Confirmed', N'CCC-0001'),
(5, 4, '2026-12-05T12:45:00', N'Confirmed', N'DCW-0001');
GO

INSERT INTO dbo.Results (EnrolmentId, FinishPosition, FinishTimeSeconds, ResultStatus)
VALUES
(1, 18, 1685, N'Finished'),
(2, 42, 3220, N'Finished');
GO
