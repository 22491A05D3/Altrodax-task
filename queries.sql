-- Create colleges table
CREATE TABLE colleges (
    college_id SERIAL PRIMARY KEY,
    college_name VARCHAR(100)
);

-- Create students table
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(100),
    college_id INT,
    join_date DATE,
    FOREIGN KEY (college_id)
    REFERENCES colleges(college_id)
);

-- Create skill modules table
CREATE TABLE skill_modules (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100)
);

-- Create student progress table
CREATE TABLE student_progress (
    progress_id SERIAL PRIMARY KEY,
    student_id INT,
    skill_id INT,
    level_reached INT,
    completed BOOLEAN,
    failed BOOLEAN,
    completion_date DATE,
    FOREIGN KEY (student_id)
    REFERENCES students(student_id),
    FOREIGN KEY (skill_id)
    REFERENCES skill_modules(skill_id)
);

-- Create daily activity table
CREATE TABLE daily_activity (
    activity_id SERIAL PRIMARY KEY,
    student_id INT,
    activity_date DATE,
    FOREIGN KEY(student_id)
    REFERENCES students(student_id)
);

-- Create placements table
CREATE TABLE placements (
    placement_id SERIAL PRIMARY KEY,
    student_id INT,
    placed BOOLEAN,
    FOREIGN KEY(student_id)
    REFERENCES students(student_id)
);
-- Colleges
INSERT INTO colleges (college_name)
VALUES
('QIS College of Engineering and technology'),
('pace Engineering College'),
('vignan university'),
('Rise engineering college');

-- Students
INSERT INTO students
(student_name,college_id,join_date)
VALUES
('naga',1,'2025-01-01'),
('Ram',1,'2025-01-10'),
('Sruthi',2,'2025-01-12'),
('Anju',2,'2025-01-15'),
('Arun',3,'2025-01-20'),
('Kiran',4,'2025-01-22');

-- Skill modules
INSERT INTO skill_modules (skill_name)
VALUES
('Aptitude'),
('Machine Learning'),
('Python'),
('java');

-- Student Progress
INSERT INTO student_progress
(student_id,skill_id,level_reached,
completed,failed,completion_date)
VALUES
(1,1,55,TRUE,FALSE,'2025-02-20'),
(2,1,35,FALSE,TRUE,'2025-02-22'),
(3,1,60,TRUE,FALSE,'2025-02-15'),
(4,2,70,TRUE,FALSE,'2025-03-01'),
(5,3,40,FALSE,TRUE,'2025-03-03'),
(6,4,80,TRUE,FALSE,'2025-03-05');

-- Daily activity
INSERT INTO daily_activity
(student_id,activity_date)
VALUES
(1,'2025-04-01'),
(1,'2025-04-02'),
(1,'2025-04-03'),
(1,'2025-04-04'),
(1,'2025-04-05'),
(1,'2025-04-06'),
(1,'2025-04-07'),
(2,'2025-04-01'),
(2,'2025-04-03');

-- Placements
INSERT INTO placements(student_id,placed)
VALUES
(1,TRUE),
(2,FALSE),
(3,TRUE),
(4,TRUE),
(5,FALSE),
(6,TRUE);



-- Q1: Average time taken to reach Level 50 in Aptitude by college

SELECT 
    c.college_name,
    ROUND(
        AVG(sp.completion_date - s.join_date),
        2
    ) AS avg_days_to_reach_level50
FROM student_progress sp
JOIN students s
    ON sp.student_id = s.student_id
JOIN colleges c
    ON s.college_id = c.college_id
JOIN skill_modules sm
    ON sp.skill_id = sm.skill_id
WHERE sm.skill_name = 'Aptitude'
AND sp.level_reached >= 50
GROUP BY c.college_name
ORDER BY avg_days_to_reach_level50;

-- Q2: Structural tracks with fail rate > 40%

SELECT
    sm.skill_name,
    COUNT(*) AS total_students,
    SUM(CASE WHEN sp.failed = TRUE THEN 1 ELSE 0 END) AS failed_students,
    ROUND(
        (
            SUM(CASE WHEN sp.failed = TRUE THEN 1 ELSE 0 END)::DECIMAL
            / COUNT(*)
        ) * 100,
        2
    ) AS fail_rate_percentage
FROM student_progress sp
JOIN skill_modules sm
ON sp.skill_id = sm.skill_id
GROUP BY sm.skill_name
HAVING (
    SUM(CASE WHEN sp.failed = TRUE THEN 1 ELSE 0 END)::DECIMAL
    / COUNT(*)
) > 0.40
ORDER BY fail_rate_percentage DESC;
-- Q3: Count unique students with 7+ day active streak

WITH streaks AS (
    SELECT
        student_id,
        activity_date,
        activity_date
        - ROW_NUMBER() OVER (
            PARTITION BY student_id
            ORDER BY activity_date
        )::INT AS streak_group
    FROM daily_activity
)

SELECT
    COUNT(DISTINCT student_id)
    AS students_with_7plus_day_streak
FROM (
    SELECT
        student_id,
        COUNT(*) AS streak_length
    FROM streaks
    GROUP BY student_id, streak_group
    HAVING COUNT(*) >= 7
) s;
-- Q4: Skill completion rate per skill module

SELECT
    sm.skill_name,
    COUNT(DISTINCT sp.student_id) AS total_students,
    
    COUNT(DISTINCT CASE 
        WHEN sp.completed = TRUE THEN sp.student_id 
    END) AS completed_students,

    ROUND(
        COUNT(DISTINCT CASE 
            WHEN sp.completed = TRUE THEN sp.student_id 
        END) * 100.0
        / COUNT(DISTINCT sp.student_id),
        2
    ) AS completion_rate_percentage

FROM student_progress sp
JOIN skill_modules sm
    ON sp.skill_id = sm.skill_id

GROUP BY sm.skill_name
ORDER BY completion_rate_percentage DESC;

-- Q5: Top 10 colleges ranked by historical student placement rate

SELECT
    c.college_name,
    COUNT(DISTINCT p.student_id) AS total_students,
    SUM(CASE WHEN p.placed = TRUE THEN 1 ELSE 0 END) AS placed_students,
    ROUND(
        SUM(CASE WHEN p.placed = TRUE THEN 1 ELSE 0 END)::DECIMAL
        / COUNT(DISTINCT p.student_id) * 100,
        2
    ) AS placement_rate_percentage
FROM placements p
JOIN students s
    ON p.student_id = s.student_id
JOIN colleges c
    ON s.college_id = c.college_id
GROUP BY c.college_name
ORDER BY placement_rate_percentage DESC
LIMIT 10;