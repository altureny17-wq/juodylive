// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:juodylive/helpers/quick_actions.dart';
import 'package:juodylive/helpers/quick_help.dart';
import 'package:juodylive/models/LiveStreamingModel.dart';
import 'package:juodylive/models/UserModel.dart';
import 'package:juodylive/ui/container_with_corner.dart';
import 'package:juodylive/ui/text_with_tap.dart';
import 'package:juodylive/utils/colors.dart';
import 'game_live_screen.dart';

/// ─────────────────────────────────────────────────────────────
/// GameLiveBanner  – زر الدخول السريع لبث الألعاب من الهوم
/// الاستخدام:
///   GameLiveBanner(currentUser: currentUser)
/// ─────────────────────────────────────────────────────────────
class GameLiveBanner extends StatelessWidget {
  final UserModel currentUser;
  const GameLiveBanner({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        QuickHelp.goToNavigatorScreen(
          context,
          // ignore: prefer_const_constructors
          GameLivePreviewLaunch(currentUser: currentUser),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A0A2E)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.4)),
              ),
              child: const Center(
                  child: Text("🎮", style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "بث الألعاب",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "PUBG • Free Fire • COD • وأكثر",
                    style: TextStyle(
                        color: Color(0xFFA78BFA), fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "ابدأ الآن",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// GameLivesGrid – يعرض البثوث الحية من نوع game
/// الاستخدام:
///   GameLivesGrid(currentUser: currentUser)
/// ─────────────────────────────────────────────────────────────
class GameLivesGrid extends StatefulWidget {
  final UserModel currentUser;
  const GameLivesGrid({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<GameLivesGrid> createState() => _GameLivesGridState();
}

class _GameLivesGridState extends State<GameLivesGrid> {
  List<LiveStreamingModel> gameLives = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGameLives();
  }

  Future<void> _loadGameLives() async {
    final q = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    q.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    q.whereEqualTo(LiveStreamingModel.keyLiveSubType, LiveStreamingModel.liveSubGame);
    q.includeObject([LiveStreamingModel.keyAuthor]);
    q.setLimit(20);
    q.orderByDescending(LiveStreamingModel.keyViewersCountLive);
    final r = await q.query();
    if (mounted && r.success) {
      setState(() {
        gameLives = (r.results ?? []).cast<LiveStreamingModel>();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }
    if (gameLives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎮", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text("لا يوجد بثوث ألعاب الآن",
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            const SizedBox(height: 4),
            const Text("كن أول من يبث!",
                style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _loadGameLives(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("تحديث",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGameLives,
      color: const Color(0xFF7C3AED),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: gameLives.length,
        itemBuilder: (context, i) => _GameLiveCard(
          live: gameLives[i],
          currentUser: widget.currentUser,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// _GameLiveCard – كرت بث لعبة واحد
/// ─────────────────────────────────────────────────────────────
class _GameLiveCard extends StatelessWidget {
  final LiveStreamingModel live;
  final UserModel currentUser;
  const _GameLiveCard({required this.live, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final author = live.getAuthor;
    final viewers = live.getViewersCount ?? 0;

    return GestureDetector(
      onTap: () {
        QuickHelp.goToNavigatorScreen(
          context,
          GameLiveScreen(
            currentUser: currentUser,
            liveStreaming: live,
            liveID: live.getStreamingChannel!,
            isHost: false,
            selectedGame: live.getLiveTitle ?? "لعبة",
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail / background
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: author?.getAvatar != null
                ? Image.network(
                    author!.getAvatar!.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gameBg(),
                  )
                : _gameBg(),
          ),

          // Dark overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // LIVE badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 6),
                  SizedBox(width: 4),
                  Text("LIVE",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Game icon top right
          const Positioned(
            top: 8,
            right: 8,
            child: Text("🎮", style: TextStyle(fontSize: 16)),
          ),

          // Bottom info
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  live.getLiveTitle ?? "بث لعبة",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Avatar + name
                Row(
                  children: [
                    if (author != null)
                      ClipOval(
                        child: QuickActions.avatarWidget(author,
                            width: 18, height: 18),
                      ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        author?.getFullName ?? "",
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB), fontSize: 9),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Viewers
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        color: Color(0xFF9CA3AF), size: 11),
                    const SizedBox(width: 3),
                    Text(
                      QuickHelp.convertToK(viewers),
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF1A0A2E)],
        ),
      ),
      child: const Center(
          child: Text("🎮", style: TextStyle(fontSize: 40))),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// GameLivePreviewLaunch – wrapper بسيط للانتقال للـ preview
/// ─────────────────────────────────────────────────────────────
class GameLivePreviewLaunch extends StatelessWidget {
  final UserModel currentUser;
  const GameLivePreviewLaunch({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ننتقل مباشرة لصفحة الإعداد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameLiveScreen(
            currentUser: currentUser,
            liveID: "",
            isHost: false,
          ),
        ),
      );
    });
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A1A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      ),
    );
  }
}
