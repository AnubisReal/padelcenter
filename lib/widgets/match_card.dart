import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/match_service.dart';
import 'confetti_animation.dart';

class MatchCard extends StatefulWidget {
  final String? matchId;
  final String courtNumber;
  final String skillLevel;
  final String startTime;
  final String status;

  const MatchCard({
    super.key,
    this.matchId,
    required this.courtNumber,
    required this.skillLevel,
    required this.startTime,
    this.status = 'abierto',
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  List<Map<String, dynamic>?> players = [
    null,
    null,
    null,
    null,
  ]; // 4 player slots
  String? currentUserId;
  String? actualMatchId;
  bool isLoading = true;
  late String currentSkillLevel;
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentSkillLevel = widget.skillLevel;
    currentStatus = widget.status;
    _initializeMatch();
  }

  Future<void> _initializeMatch() async {
    try {
      // Get current user profile to set currentUserId
      final userProfile = await ProfileService.getUserProfile();
      if (userProfile != null) {
        currentUserId = userProfile['id'];
      }

      print(
        'MatchCard: Initializing match with widget.matchId: ${widget.matchId}',
      );
      print(
        'MatchCard: Court: ${widget.courtNumber}, Time: ${widget.startTime}',
      );

      // Create match if it doesn't exist, or load existing match
      if (widget.matchId == null) {
        // Create new match
        print('MatchCard: Creating new match');
        final matchId = await MatchService.createMatch(
          courtNumber: widget.courtNumber,
          skillLevel: widget.skillLevel,
          startTime: widget.startTime,
          status: widget.status,
        );
        actualMatchId = matchId;
        print('MatchCard: Created new match with ID: $actualMatchId');
      } else {
        actualMatchId = widget.matchId;
        print('MatchCard: Using existing match ID: $actualMatchId');
      }

      // Load existing players
      if (actualMatchId != null) {
        await _loadMatchPlayers();
        // Also load the current skill level from the database
        final matchData = await MatchService.getMatch(actualMatchId!);
        if (matchData != null) {
          setState(() {
            currentSkillLevel = matchData['skill_level'] ?? widget.skillLevel;
          });
        }

        // Check if match is empty and reset level if needed (on initialization)
        await _checkAndResetLevelIfEmpty();
      }
    } catch (e) {
      print('Error initializing match: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMatchPlayers() async {
    if (actualMatchId == null) {
      print('MatchCard: actualMatchId is null, cannot load players');
      return;
    }

    try {
      print('MatchCard: Loading players for match ID: $actualMatchId');
      final matchPlayers = await MatchService.getMatchPlayers(actualMatchId!);

      print(
        'MatchCard: Loading ${matchPlayers.length} players from database for match $actualMatchId',
      );
      for (var player in matchPlayers) {
        print(
          'MatchCard: Player: ${player['player_name']} at position ${player['position']}',
        );
      }

      // Reset players array
      players = [null, null, null, null];

      // Fill players array with data from database
      for (var playerData in matchPlayers) {
        final position = playerData['position'];
        print(
          'MatchCard: Assigning player ${playerData['player_name']} to position $position',
        );
        if (position >= 0 && position < 4) {
          players[position] = {
            'userId': playerData['user_id'],
            'name': playerData['player_name'],
            'avatarUrl': playerData['avatar_url'],
          };
        }
      }

      print(
        'MatchCard: Final players array: ${players.map((p) => p?['name']).toList()}',
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('MatchCard: Error loading match players: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Top row: Date and Time | Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$today | ${widget.startTime}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currentStatus,
                style: TextStyle(
                  color: currentStatus == 'cerrado' ? Colors.red : Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Center: Player circles and VS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left team (2 players)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_buildPlayerCircle(0), _buildPlayerCircle(1)],
                ),
              ),

              // VS in center
              Expanded(
                flex: 1,
                child: Center(
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // Right team (2 players)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_buildPlayerCircle(2), _buildPlayerCircle(3)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bottom row: Court and Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.courtNumber,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currentSkillLevel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Count how many times current user is already in the match
  Future<int> _countCurrentUserInMatch() async {
    if (currentUserId == null || actualMatchId == null) return 0;
    return await MatchService.countUserInMatch(actualMatchId!, currentUserId!);
  }

  Future<bool> _isMatchEmpty() async {
    if (actualMatchId == null) return true;

    // Check if there are any players in the database for this match
    final matchPlayers = await MatchService.getMatchPlayers(actualMatchId!);
    print(
      'MatchCard: _isMatchEmpty check - found ${matchPlayers.length} players in database',
    );
    return matchPlayers.isEmpty;
  }

  Future<void> _checkAndResetLevelIfEmpty() async {
    print('MatchCard: Checking if match is empty for level reset...');
    if (await _isMatchEmpty()) {
      print(
        'MatchCard: Match is empty, resetting level from $currentSkillLevel to nivel',
      );
      // Reset skill level to 'nivel' (always)
      final success = await MatchService.updateMatchLevel(
        actualMatchId!,
        'nivel',
      );
      if (success) {
        setState(() {
          currentSkillLevel = 'nivel';
        });
        print(
          'MatchCard: Successfully reset level to nivel in database - match is empty',
        );
      } else {
        print('MatchCard: Failed to reset level in database');
      }
    } else {
      print(
        'MatchCard: Match is not empty, keeping current level: $currentSkillLevel',
      );
    }
  }

  Future<void> _updateMatchStatus() async {
    print(
      'MatchCard: _updateMatchStatus called, actualMatchId: $actualMatchId',
    );

    if (actualMatchId == null) {
      print('MatchCard: actualMatchId is null, cannot update status');
      return;
    }

    try {
      // Count filled player slots
      int filledSlots = 0;
      for (var player in players) {
        if (player != null) filledSlots++;
      }

      String newStatus = filledSlots == 4 ? 'cerrado' : 'abierto';
      String previousStatus = currentStatus;

      print(
        'MatchCard: Updating match $actualMatchId status to $newStatus ($filledSlots/4 players)',
      );

      final success = await MatchService.updateMatchStatus(
        actualMatchId!,
        newStatus,
      );
      if (success) {
        setState(() {
          currentStatus = newStatus;
        });
        print('MatchCard: Successfully updated match status to $newStatus');

        // Show confetti animation when match becomes closed
        if (previousStatus != 'cerrado' && newStatus == 'cerrado') {
          _showMatchClosedAnimation();
        }
      } else {
        print('MatchCard: Failed to update match status');
      }
    } catch (e) {
      print('MatchCard: Error updating match status: $e');
    }
  }

  void _showMatchClosedAnimation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ConfettiAnimation(
            onAnimationComplete: () {
              Navigator.of(context).pop();
            },
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showLevelSelector(int playerIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e202e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Selecciona el nivel del partido',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLevelOption('bajo', playerIndex),
              _buildLevelOption('medio', playerIndex),
              _buildLevelOption('medio alto', playerIndex),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelOption(String level, int playerIndex) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          _joinMatchWithLevel(playerIndex, level); // Use the selected position
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            level,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _joinMatch(int playerIndex) async {
    // If match is empty (first player joining), show level selector regardless of position
    if (await _isMatchEmpty()) {
      _showLevelSelector(playerIndex);
      return;
    }

    // Otherwise, join normally
    _joinMatchWithLevel(playerIndex, null);
  }

  void _joinMatchWithLevel(int playerIndex, String? selectedLevel) async {
    if (actualMatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Partido no inicializado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userProfile = await ProfileService.getUserProfile();
      if (userProfile != null) {
        // Set current user ID if not set
        if (currentUserId == null) {
          currentUserId = userProfile['id'];
        }

        // Check how many times user is already added
        int userCount = await _countCurrentUserInMatch();

        if (userCount >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ya estás añadido 2 veces en este partido (máximo permitido)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Determine name based on how many times user is already added
        String displayName;
        if (userCount == 0) {
          // First time: use real name
          displayName =
              userProfile['display_name'] ??
              userProfile['full_name'] ??
              userProfile['email'] ??
              'Usuario';
        } else {
          // Second time: use "compi"
          displayName = 'compi';
        }

        // If this is the first player and a level was selected, update the match level
        if (selectedLevel != null) {
          await MatchService.updateMatchLevel(actualMatchId!, selectedLevel);
          // Update local state to show the new level
          setState(() {
            currentSkillLevel = selectedLevel;
          });
        }

        // Save to database
        print(
          'Attempting to save player: $displayName at position $playerIndex for user $currentUserId',
        );
        final success = await MatchService.addPlayerToMatch(
          matchId: actualMatchId!,
          userId: currentUserId!,
          position: playerIndex,
          playerName: displayName,
          avatarUrl: userProfile['avatar_url'],
        );

        print('Save result: $success');

        if (success) {
          // Update local state
          final currentUser = {
            'userId': userProfile['id'],
            'name': displayName,
            'avatarUrl': userProfile['avatar_url'],
          };

          setState(() {
            players[playerIndex] = currentUser;
          });

          // Update match status after player joins
          await _updateMatchStatus();

          print(
            'Player added successfully: $displayName at position $playerIndex',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar en la base de datos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Fallback if no profile found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo obtener el perfil del usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse al partido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  void _leaveMatch(int playerIndex) async {
    if (actualMatchId == null) return;

    try {
      // Remove from database
      final success = await MatchService.removePlayerFromMatch(
        matchId: actualMatchId!,
        position: playerIndex,
      );

      if (success) {
        // Update local state
        setState(() {
          players[playerIndex] = null;
        });

        // Update match status after player leaves
        await _updateMatchStatus();

        // Check if match is now empty and reset level if needed
        await _checkAndResetLevelIfEmpty();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has desapuntado del partido'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al desapuntarse del partido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showLeaveConfirmation(int playerIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e202e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '¿Desapuntarse?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro de que quieres desapuntarte de este partido?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _leaveMatch(playerIndex);
              },
              child: const Text(
                'Desapuntarse',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isCurrentUser(Map<String, dynamic>? player) {
    if (player == null || currentUserId == null) return false;
    return player['userId'] == currentUserId;
  }

  Widget _buildPlayerCircle(int playerIndex) {
    final player = players[playerIndex];
    final isCurrentUser = _isCurrentUser(player);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (player == null) {
              _joinMatch(playerIndex);
            } else if (isCurrentUser) {
              _showLeaveConfirmation(playerIndex);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
              color: player != null
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: player == null
                ? const Icon(Icons.add, color: Colors.white70, size: 20)
                : player['avatarUrl'] != null
                ? ClipOval(
                    child: Image.network(
                      player['avatarUrl']!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar(player['name']!);
                      },
                    ),
                  )
                : _buildInitialsAvatar(player['name']!),
          ),
        ),
        const SizedBox(height: 4),
        if (player != null)
          Text(
            _getFirstName(player['name']!),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF1e202e),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
