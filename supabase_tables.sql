-- Crear tabla para almacenar partidos
CREATE TABLE matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    court_number TEXT NOT NULL,
    skill_level TEXT NOT NULL,
    start_time TEXT NOT NULL,
    status TEXT DEFAULT 'abierto',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla para almacenar jugadores por partido
CREATE TABLE match_players (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    position INTEGER NOT NULL CHECK (position >= 0 AND position <= 3),
    player_name TEXT NOT NULL,
    avatar_url TEXT,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(match_id, position) -- Solo un jugador por posición en cada partido
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_matches_created_at ON matches(created_at);
CREATE INDEX idx_match_players_match_id ON match_players(match_id);
CREATE INDEX idx_match_players_user_id ON match_players(user_id);

-- Habilitar RLS (Row Level Security)
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_players ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para matches (todos pueden ver y crear partidos)
CREATE POLICY "Anyone can view matches" ON matches FOR SELECT USING (true);
CREATE POLICY "Anyone can create matches" ON matches FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update matches" ON matches FOR UPDATE USING (true);

-- Políticas RLS para match_players (todos pueden ver, solo el usuario puede modificar sus propias entradas)
CREATE POLICY "Anyone can view match players" ON match_players FOR SELECT USING (true);
CREATE POLICY "Users can add themselves to matches" ON match_players FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove themselves from matches" ON match_players FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own match entries" ON match_players FOR UPDATE USING (auth.uid() = user_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at en matches
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
