-- Script para limpiar partidos duplicados en Supabase
-- Mantiene solo los partidos que tienen jugadores, elimina los vacíos

-- 1. Primero, identificar partidos duplicados (misma pista y hora)
WITH duplicate_matches AS (
  SELECT 
    court_number,
    start_time,
    COUNT(*) as match_count,
    ARRAY_AGG(id ORDER BY created_at) as match_ids
  FROM matches 
  GROUP BY court_number, start_time 
  HAVING COUNT(*) > 1
),

-- 2. Para cada grupo de duplicados, encontrar cuáles tienen jugadores
matches_with_players AS (
  SELECT 
    m.id as match_id,
    m.court_number,
    m.start_time,
    COUNT(mp.id) as player_count
  FROM matches m
  LEFT JOIN match_players mp ON m.id = mp.match_id
  WHERE m.id IN (
    SELECT UNNEST(match_ids) 
    FROM duplicate_matches
  )
  GROUP BY m.id, m.court_number, m.start_time
),

-- 3. Identificar qué partidos eliminar (los que no tienen jugadores cuando hay duplicados)
matches_to_delete AS (
  SELECT DISTINCT mwp1.match_id
  FROM matches_with_players mwp1
  WHERE mwp1.player_count = 0
  AND EXISTS (
    SELECT 1 
    FROM matches_with_players mwp2 
    WHERE mwp2.court_number = mwp1.court_number 
    AND mwp2.start_time = mwp1.start_time 
    AND mwp2.player_count > 0
  )
)

-- 4. Eliminar los partidos vacíos duplicados
DELETE FROM matches 
WHERE id IN (SELECT match_id FROM matches_to_delete);

-- 5. Mostrar resumen de lo que queda
SELECT 
  court_number,
  start_time,
  skill_level,
  COUNT(*) as remaining_matches,
  SUM((SELECT COUNT(*) FROM match_players WHERE match_id = matches.id)) as total_players
FROM matches 
GROUP BY court_number, start_time, skill_level
ORDER BY court_number, start_time;
