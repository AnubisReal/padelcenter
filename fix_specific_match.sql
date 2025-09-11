-- Script para corregir el partido específico que se quedó con 'medio alto'
-- Encuentra partidos vacíos con skill_level incorrecto y los corrige

-- Ver el estado actual de todos los partidos
SELECT 
  id,
  court_number,
  start_time,
  skill_level,
  (SELECT COUNT(*) FROM match_players WHERE match_id = matches.id) as player_count
FROM matches 
ORDER BY court_number, start_time;

-- Corregir partidos vacíos que no tienen skill_level = 'nivel'
UPDATE matches 
SET skill_level = 'nivel'
WHERE id NOT IN (
  SELECT DISTINCT match_id 
  FROM match_players
)
AND skill_level != 'nivel';

-- Verificar los cambios
SELECT 
  id,
  court_number,
  start_time,
  skill_level,
  (SELECT COUNT(*) FROM match_players WHERE match_id = matches.id) as player_count
FROM matches 
WHERE (SELECT COUNT(*) FROM match_players WHERE match_id = matches.id) = 0
ORDER BY court_number, start_time;
