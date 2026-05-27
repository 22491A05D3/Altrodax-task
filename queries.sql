DROP TABLE IF EXISTS activity_logs CASCADE;
DROP TABLE IF EXISTS skill_completions CASCADE;
DROP TABLE IF EXISTS aptitude_progress CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS skill_modules CASCADE;
DROP TABLE IF EXISTS learning_tracks CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS colleges CASCADE;

CREATE TABLE colleges (
    college_id SERIAL PRIMARY KEY,
    college_name VARCHAR(150) NOT NULL,
    placement_rate NUMERIC(5,4) NOT NULL
);
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    college_id INT REFERENCES colleges(college_id),
    enrollment_date DATE NOT NULL
);
CREATE TABLE aptitude_progress (
    progress_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    level_reached INT NOT NULL,
    date_started TIMESTAMP NOT NULL,
    date_completed TIMESTAMP
);
CREATE TABLE learning_tracks (
    track_id SERIAL PRIMARY KEY,
    track_name VARCHAR(100) NOT NULL,
    description TEXT
);
CREATE TABLE skill_modules (
    module_id SERIAL PRIMARY KEY,
    track_id INT REFERENCES learning_tracks(track_id),
    module_name VARCHAR(100) NOT NULL,
    difficulty_level VARCHAR(50)
);
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    track_id INT REFERENCES learning_tracks(track_id),
    enrollment_date DATE NOT NULL,
    status VARCHAR(30)
);
CREATE TABLE skill_completions (
    completion_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    module_id INT REFERENCES skill_modules(module_id),
    completion_date TIMESTAMP,
    score NUMERIC(5,2)
);

CREATE TABLE activity_logs (
    log_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    activity_type VARCHAR(100),
    activity_time TIMESTAMP,
    details TEXT
);

INSERT INTO colleges (college_name, placement_rate)
VALUES
('IIT Bombay',0.9200),
('IIT Delhi',0.9100),
('NIT Trichy',0.8500),
('BITS Pilani',0.8800),
('VIT Vellore',0.7800);

INSERT INTO students (college_id, enrollment_date)
VALUES
(1,'2023-01-10'),
(1,'2023-02-14'),
(2,'2023-01-15'),
(3,'2023-02-20'),
(4,'2023-03-05');

INSERT INTO learning_tracks (track_name, description)
VALUES
('Data Analytics','SQL,Python,Power BI'),
('Web Development','HTML,CSS,JavaScript'),
('AI & ML','Machine Learning Concepts');

INSERT INTO skill_modules (track_id, module_name, difficulty_level)
VALUES
(1,'SQL Basics','Beginner'),
(1,'Advanced SQL','Intermediate'),
(2,'JavaScript','Intermediate'),
(3,'Machine Learning','Advanced');

INSERT INTO enrollments
(student_id, track_id, enrollment_date, status)
VALUES
(1, 1,'2023-01-15','Completed'),
(2, 1,'2023-02-01','Active'),
(3, 2,'2023-02-10','Dropped'),
(4, 3,'2023-03-01','Completed'),
(5, 2,'2023-03-10','Dropped');

INSERT INTO aptitude_progress
(student_id, level_reached, date_started, date_completed)
VALUES
(1, 50,'2023-01-10 10:00:00','2023-02-01 12:00:00'),
(2, 45,'2023-02-01 09:00:00','2023-03-01 15:00:00'),
(3, 50,'2023-01-20 11:00:00','2023-02-25 17:00:00'),
(4, 60,'2023-03-05 08:00:00','2023-04-01 10:00:00');

INSERT INTO skill_completions
(student_id, module_id, completion_date, score)
VALUES
(1, 1,'2023-02-01 10:00:00',85.50),
(1, 2,'2023-02-15 11:00:00',88.00),
(2, 1,'2023-03-01 09:30:00',91.00),
(4, 4,'2023-04-10 14:00:00',95.00);

INSERT INTO activity_logs
(student_id, activity_type, activity_time, details)
VALUES
(1, 'Login','2023-02-01 09:00:00','Student Login'),
(1, 'Quiz','2023-02-02 09:00:00','SQL Quiz'),
(1, 'Assignment','2023-02-03 09:00:00','Assignment Submission'),
(1, 'Discussion','2023-02-04 09:00:00','Forum Discussion'),
(1, 'Project','2023-02-05 09:00:00','Project Work'),
(1, 'Quiz','2023-02-06 09:00:00','Advanced SQL Quiz'),
(1, 'Logout','2023-02-07 09:00:00','Student Logout');

SELECT
    c.college_name,
    COUNT(ap.progress_id) AS students_reached_level50,
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM
            (ap.date_completed - ap.date_started)
            ) / 86400
        ),
        2
    ) AS avg_days_to_level50
FROM aptitude_progress ap
JOIN students s
ON ap.student_id=s.student_id
JOIN colleges c
ON s.college_id=c.college_id
WHERE ap.level_reached>=50
AND ap.date_completed IS NOT NULL
GROUP BY c.college_name
ORDER BY avg_days_to_level50;

SELECT
    lt.track_name,
    COUNT(*) AS total_students,
    SUM(
        CASE
            WHEN e.status='Dropped'
            THEN 1
            ELSE 0
        END
    ) AS dropped_students,
    ROUND(
        (
            SUM(
                CASE
                    WHEN e.status='Dropped'
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
        ) / COUNT(*),
        2
    ) AS fail_rate
FROM enrollments e
JOIN learning_tracks lt
ON e.track_id=lt.track_id
GROUP BY lt.track_name
HAVING
(
    SUM(
        CASE
            WHEN e.status='Dropped'
            THEN 1
            ELSE 0
        END
    ) * 100.0
) / COUNT(*) > 40;

SELECT
COUNT(DISTINCT student_id)
AS active_students_7day_streak
FROM
(
    SELECT
        student_id,
        COUNT(DISTINCT DATE(activity_time))
        AS active_days
    FROM activity_logs
    GROUP BY student_id
    HAVING COUNT(DISTINCT DATE(activity_time)) >=7
) streak_students;

SELECT
    sm.module_name,
    COUNT(DISTINCT sc.student_id)
    AS students_completed,

    (SELECT COUNT(*) FROM students)
    AS total_students,

    ROUND(
        (
            COUNT(DISTINCT sc.student_id)
            * 100.0
        )
        /
        (
            SELECT COUNT(*)
            FROM students
        ),
        2
    ) AS completion_percentage

FROM skill_modules sm

LEFT JOIN skill_completions sc
ON sm.module_id=sc.module_id

GROUP BY sm.module_name
ORDER BY completion_percentage DESC;

SELECT
    college_name,
    placement_rate
FROM colleges
ORDER BY placement_rate DESC
LIMIT 10;
