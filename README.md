Project: zadostno - A Remote Learning Management System

A web-based application designed to facilitate remote learning for a school environment. This project provides a centralized platform for administrators, teachers, and students to manage courses, share learning materials, and handle assignment submissions and grading.


Table of Contents

Project Vision
Key Features
Technology Stack
Getting Started
File Structure
Project Team
License


Project Vision

The primary goal of zadostno is to create a streamlined and intuitive online environment for education. The system addresses the core needs of three user roles: Administrators who require tools to manage the entire user and course structure; Teachers who need an efficient way to distribute materials and assess student work; and Students who need a single, reliable place to access course content, submit assignments, and track their academic progress. The application is built from the ground up using PHP and PostgreSQL, focusing on security, maintainability, and a clean user experience.


Key Features

The application's functionality is segregated based on user roles to ensure a secure and relevant experience for everyone.

For Students
Secure Self-Registration: Students can create their own accounts through a public registration form.
Profile Management: Ability to view and update personal information, including name, email, and password.
Course Catalog & Enrollment: Students can browse a list of all available courses and enroll or un-enroll with a single click.

Dashboard: A personalized dashboard showing all currently enrolled courses for quick access.
View Learning Materials: Access and download files or view links posted by teachers for each course.
Assignment Submission: A simple interface to upload files for course assignments. The system handles file renaming and overwriting previous submissions upon confirmation.

Grade Tracking: A dedicated "My Grades" page to view grades and feedback from teachers for all submitted assignments.


For Teachers

Course Dashboard: A central hub displaying all courses assigned to the teacher.

Material Management: Easily upload course materials (PDFs, documents, etc.) or post relevant links for students.

Assignment Creation: Create, update, and delete assignments with titles, detailed descriptions, and due dates.

Submission Review: View a list of all enrolled students for an assignment, see who has submitted, and download their work.

Grading System: An intuitive interface to assign grades and provide written feedback for each student's submission.


For Administrators

Full User Management: Create, read, update, and delete both Teacher and Student accounts.

Course (Subject) Management: Full control to create, read, update, and delete all courses in the system.

Enrollment Control: Manually enroll students in courses and assign teachers to the courses they will instruct.

System Oversight: A comprehensive view of the entire system's structure, users, and curriculum.
Technology Stack


This project is built with a focus on robust, widely-supported, and open-source technologies.
Backend: PHP 8+, the core server-side language for all application logic.

Database: PostgreSQL 14+, a powerful, object-relational database for all data persistence.

Web Server: Apache or Nginx, a high-performance web server to handle HTTP requests.

Frontend: HTML5, CSS3, and JavaScript, the standard technologies for building the user interface.

UI Framework: Bootstrap 5, a CSS framework used to ensure a responsive and professional design.

Versioning: Git & GitHub, for source code management and collaborative development.


Getting Started
Follow these instructions to set up a local development environment for the project.
Prerequisites

Ensure you have the following software installed on your machine: a web server stack (like XAMPP or a manual installation of Apache/Nginx), PHP (version 8.0 or newer), PostgreSQL (version 14 or newer), and Git.
Installation Guide
Clone the Repository
First, clone the repository to your local machine using the command git clone https://github.com/your-username/zadostno.git, then navigate into the new directory.
Database Setup
Next, you will need to set up the database. Using a tool like psql or pgAdmin, create a new database (e.g., zadostno_db) and a new user with a password. Grant all privileges on the new database to this new user. Finally, import the provided schema from the database.sql file.
Configure the Application
Locate the config.php file in the project's root directory. You may need to copy it from config.example.php. Open this file and update the database constants (DB_HOST, DB_NAME, DB_USER, DB_PASS) to match the credentials you just created.
Configure Your Web Server
This is a critical security step. You must configure the "Document Root" (or "web root") of your local server environment to point directly to the /public directory inside the project folder. This prevents anyone from accessing your core application files through a browser.
Run the Application
Start your web server. Open your web browser and navigate to your local server's address (such as http://localhost). If everything is configured correctly, you should see the login page for the application.
File Structure
The project uses a structured layout to separate concerns and enhance security.
public/ - This is the web server root, and all browser requests are directed here.
css/ - For all stylesheets.
js/ - For all JavaScript files.
index.php - The front controller, which acts as the single entry point for the application.
src/ - This folder contains the core application logic and is not publicly accessible.
pages/ - Holds the content for individual pages like the dashboard or profile.
includes/ - For core functions, database connections, and authentication checks.
templates/ - For reusable HTML parts like the site-wide header and footer.
uploads/ - A directory for storing files uploaded by users, such as assignment submissions.
config.php - The main configuration file for database credentials and other settings.
README.md - This documentation file.
.gitignore - A file that tells Git which files and folders to ignore from version control.
Project Team
System Maintainer: [Filip Zavrnik]
Developer: [Gašper Vodišek]
Developer: [Beni Planko]
Mentor: [Mentor's Name]


License
This project is licensed under the MIT License. See the LICENSE file for more details.
