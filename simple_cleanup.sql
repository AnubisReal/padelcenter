-- Opción 1: Limpiar TODO (más simple y rápido)
-- Elimina todos los partidos y jugadores, empezar desde cero

-- Eliminar todos los jugadores
DELETE FROM match_players;

-- Eliminar todos los partidos
DELETE FROM matches;

-- Verificar que las tablas están vacías
SELECT 'matches' as table_name, COUNT(*) as remaining_records FROM matches
UNION ALL
SELECT 'match_players' as table_name, COUNT(*) as remaining_records FROM match_players;
