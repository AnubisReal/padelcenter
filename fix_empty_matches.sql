-- Script para resetear el nivel de partidos vacíos que quedaron con nivel incorrecto
-- Actualiza todos los partidos que no tienen jugadores para que tengan skill_level = 'nivel'

UPDATE matches 
SET skill_level = 'nivel'
WHERE id NOT IN (
  SELECT DISTINCT match_id 
  FROM match_players
)
AND skill_level != 'nivel';

-- Verificar los cambios
SELECT 
  court_number,
  start_time,
  skill_level,
  (SELECT COUNT(*) FROM match_players WHERE match_id = matches.id) as player_count
FROM matches 
ORDER BY court_number, start_time;
