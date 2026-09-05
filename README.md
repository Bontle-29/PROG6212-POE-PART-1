# PROG6212-POE-PART-1
Project overview

RaceDay is a web-based event management system designed for South African running, walking, and cycling events. The system is intended to help event organisers manage events, categories, participant enrolments, routes, weather information, and race results. Participants can browse events, enter event categories, and view their performance history.

This repository contains the planning and database work for Part 1 of the Portfolio of Evidence. No C# API implementation is included in this part. The API will be implemented in a later part using the endpoint plan prepared here.

Part 1 sections

Section A — Entity Relationship Diagram

Section A contains the RaceDay ERD. The diagram shows the database entities, attributes, primary keys, foreign keys, and relationships between the entities.

The main entities are:

•
Users

•
Events

•
Categories

•
Enrolments

•
Results

•
Routes

•
WeatherForecasts

Files:

•
View the Section A ERD

•
View the editable ERD source

The Enrolments entity resolves the many-to-many relationship between participants and event categories. An organiser can create many events, an event can have many categories, and an enrolment can have zero or one result.

Section B — API Endpoint Plan

Section B contains the REST API endpoint plan. Each endpoint includes the HTTP method, route, description, required role, request body, and expected response.

The endpoint plan covers:

•
Authentication and registration.

•
User profiles.

•
Events.

•
Event categories.

•
Participant enrolments.

•
Race results.

•
Route information.

•
Weather forecasts.

File:

•
View the Section B API endpoint plan

The endpoint plan is a design document only. API code is not required for Section B of Part 1.

Section C — SQL Database Script

Section C contains the SQL Server database script. The script creates the RaceDayDb database, creates the tables represented in the ERD, applies constraints, and inserts sample data.

