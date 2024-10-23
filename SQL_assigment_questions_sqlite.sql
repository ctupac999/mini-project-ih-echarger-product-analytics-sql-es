-- LEVEL 1

-- Question 1: Number of users with sessions
SELECT COUNT(DISTINCT user_id) AS numero_usuarios_con_sesiones
FROM sessions;

-- Question 2: Number of chargers used by user with id 1
SELECT COUNT(DISTINCT charger_id) AS numero_cargadores_utilizados
FROM sessions
WHERE user_id = 1;

-- LEVEL 2

-- Question 3: Number of sessions per charger type (AC/DC)
SELECT 
    c.type AS tipo_cargador,
    COUNT(s.id) AS numero_sesiones
FROM 
    sessions s
JOIN 
    chargers c ON s.charger_id = c.id
GROUP BY 
    c.type;

-- Question 4: Chargers being used by more than one user
SELECT 
    s.charger_id,
    COUNT(DISTINCT s.user_id) AS numero_usuarios
FROM 
    sessions s
GROUP BY 
    s.charger_id
HAVING 
    COUNT(DISTINCT s.user_id) > 1;

-- Question 5: Average session time per charger (not completed, please clarify if you need a specific calculation)
SELECT 
    s.charger_id,
    AVG(TIMESTAMPDIFF(SECOND, s.start_time, s.end_time)) AS average_session_time
FROM 
    sessions s
GROUP BY 
    s.charger_id;

-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS nombre_completo
FROM 
    sessions s
JOIN 
    users u ON s.user_id = u.user_id
GROUP BY 
    u.first_name, u.last_name, DATE(s.start_time) 
HAVING 
    COUNT(DISTINCT s.charger_id) > 1;

-- Question 7: Top 3 chargers with longer sessions
SELECT 
    c.id AS charger_id,
    c.label AS charger_label,
    SUM(TIMESTAMPDIFF(SECOND, s.start_time, s.end_time)) AS total_duration
FROM 
    sessions s
JOIN 
    chargers c ON s.charger_id = c.id
GROUP BY 
    c.id, c.label
ORDER BY 
    total_duration DESC
LIMIT 3;

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)
SELECT 
    AVG(user_count) AS average_users_per_charger
FROM (
    SELECT 
        COUNT(DISTINCT s.user_id) AS user_count
    FROM 
        sessions s
    GROUP BY 
        s.charger_id
) AS charger_user_counts;

-- Question 9: Top 3 users with more chargers being used
SELECT 
    u.user_id AS user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    COUNT(DISTINCT s.charger_id) AS charger_count
FROM 
    users u
JOIN 
    sessions s ON u.user_id = s.user_id
GROUP BY 
    u.user_id, u.first_name, u.last_name
ORDER BY 
    charger_count DESC
LIMIT 3;

-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both

SELECT 
    COUNT(DISTINCT u.user_id) AS user_count
FROM 
    users u
JOIN 
    sessions s ON u.user_id = s.user_id
JOIN 
    chargers c ON s.charger_id = c.id
WHERE 
    c.type IN ('AC', 'DC')
GROUP BY 
    u.user_id
HAVING 
    COUNT(DISTINCT c.type) = 2;  SELECT
    SUM(CASE WHEN ac_count > 0 AND dc_count = 0 THEN 1 ELSE 0 END) AS only_ac,
    SUM(CASE WHEN dc_count > 0 AND ac_count = 0 THEN 1 ELSE 0 END) AS only_dc,
    SUM(CASE WHEN ac_count > 0 AND dc_count > 0 THEN 1 ELSE 0 END) AS both
FROM (
    SELECT
        s.USER_ID,
        COUNT(DISTINCT CASE WHEN c.TYPE = 'AC' THEN s.CHARGER_ID END) AS ac_count,
        COUNT(DISTINCT CASE WHEN c.TYPE = 'DC' THEN s.CHARGER_ID END) AS dc_count
    FROM SESSIONS s
    JOIN CHARGERS c ON s.CHARGER_ID = c.ID
    GROUP BY s.USER_ID
) AS UserChargerCounts;

-- Question 11: Monthly average number of users per charger

SELECT 
    c.id AS charger_id,
    c.label AS charger_label,
    COUNT(DISTINCT s.user_id) / COUNT(DISTINCT DATE_TRUNC('MONTH', s.start_time)) AS average_users_per_month
FROM 
    sessions s
JOIN 
    chargers c ON s.charger_id = c.id
GROUP BY 
    c.id, c.label;

-- Question 12: Top 3 users per charger (for each charger, number of sessions)

WITH ranked_users AS (
    SELECT 
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name) AS user_name,
        s.charger_id,
        COUNT(s.id) AS session_count,
        ROW_NUMBER() OVER (PARTITION BY s.charger_id ORDER BY COUNT(s.id) DESC) AS rank
    FROM 
        sessions s
    JOIN 
        users u ON s.user_id = u.user_id
    GROUP BY 
        u.user_id, u.first_name, u.last_name, s.charger_id
)

SELECT 
    charger_id,
    user_id,
    user_name,
    session_count
FROM 
    ranked_users
WHERE 
    rank <= 3
ORDER BY 
    charger_id, rank;


-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)

WITH monthly_sessions AS (
    SELECT 
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name) AS user_name,
        DATE_TRUNC('MONTH', s.start_time) AS session_month,
        SUM(TIMESTAMPDIFF(SECOND, s.start_time, s.end_time)) AS total_duration
    FROM 
        sessions s
    JOIN 
        users u ON s.user_id = u.user_id
    GROUP BY 
        u.user_id, u.first_name, u.last_name, session_month
),

ranked_sessions AS (
    SELECT 
        user_id,
        user_name,
        session_month,
        total_duration,
        ROW_NUMBER() OVER (PARTITION BY session_month ORDER BY total_duration DESC) AS rank
    FROM 
        monthly_sessions
)

SELECT 
    session_month,
    user_id,
    user_name,
    total_duration
FROM 
    ranked_sessions
WHERE 
    rank <= 3
ORDER BY 
    session_month, rank;

-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)

WITH session_times AS (
    SELECT 
        s.charger_id,
        DATE_TRUNC('MONTH', s.start_time) AS session_month,
        s.start_time,
        LEAD(s.start_time) OVER (PARTITION BY s.charger_id ORDER BY s.start_time) AS next_session_time
    FROM 
        sessions s
),

time_differences AS (
    SELECT 
        charger_id,
        session_month,
        TIMESTAMPDIFF(SECOND, start_time, next_session_time) AS time_diff
    FROM 
        session_times
    WHERE 
        next_session_time IS NOT NULL
)

SELECT 
    charger_id,
    session_month,
    AVG(time_diff) AS average_time_between_sessions
FROM 
    time_differences
GROUP BY 
    charger_id, session_month
ORDER BY 
    session_month, charger_id;