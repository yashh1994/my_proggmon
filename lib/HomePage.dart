import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isSessionActive = false;
  late Stopwatch stopwatch;
  late SharedPreferences prefs;
  late Timer timer;
  late AnimationController _animationController;
  int elapsedToday = 0; // Total elapsed seconds for today.
  int lastSessionTime = 0; // Stores the time when app was last paused.

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    _initializeStorage();
    _loadSessionState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  // Initialize SharedPreferences
  Future<void> _initializeStorage() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Load session state and elapsed time from SharedPreferences
  Future<void> _loadSessionState() async {
    String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    Map<String, int> dailySessions = _getStoredSessions();
    setState(() {
      elapsedToday = dailySessions[today] ?? 0;
    });

    // Load the last session state
    int? storedSessionTime = prefs.getInt('lastSessionTime');
    bool? storedSessionStatus = prefs.getBool('isSessionActive');

    if (storedSessionStatus == true) {
      isSessionActive = true;
      lastSessionTime = storedSessionTime ?? 0;
      stopwatch.start();
      _startTimer();
    }
  }

  // Start or stop the session
  void _toggleSession() {
    setState(() {
      if (isSessionActive) {
        // Stop session
        stopwatch.stop();
        timer.cancel();
        _saveSessionIfValid();
        _animationController.stop();
      } else {
        // Start session
        stopwatch.start();
        _startTimer();
        _animationController.repeat();
      }
      isSessionActive = !isSessionActive;
    });

    _saveSessionState();
  }

  // Periodically update the UI while the stopwatch is running
  void _startTimer() {
    timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      setState(() {});
    });
  }

  // Save the session time to SharedPreferences if it's a valid session
  Future<void> _saveSessionIfValid() async {
    int durationInSeconds = stopwatch.elapsed.inSeconds;
    stopwatch.reset();

    if (durationInSeconds >= 10) {
      String today =
          DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      Map<String, int> dailySessions = _getStoredSessions();
      dailySessions[today] = (dailySessions[today] ?? 0) + durationInSeconds;

      await prefs.setString('sessions', jsonEncode(dailySessions));
      setState(() {
        elapsedToday = dailySessions[today]!;
      });
    }
  }

  // Save session state (whether it's active or not) to SharedPreferences
  Future<void> _saveSessionState() async {
    await prefs.setInt('lastSessionTime', stopwatch.elapsed.inSeconds);
    await prefs.setBool('isSessionActive', isSessionActive);
  }

  // Get stored session data from SharedPreferences
  Map<String, int> _getStoredSessions() {
    String? storedData = prefs.getString('sessions');
    if (storedData == null) return {};
    return Map<String, int>.from(jsonDecode(storedData));
  }

  // Format the time (hours:minutes:seconds)
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    seconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PreviousSessionsScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Progress Arc
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CircularProgressPainter(
                    progress: isSessionActive
                        ? stopwatch.elapsedMilliseconds /
                            (60 * 1000) // Map to a minute
                        : 0,
                    isRunning: isSessionActive,
                  ),
                  child: SizedBox(
                    width: 250,
                    height: 250,
                  ),
                );
              },
            ),
            // Timer Text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSessionActive
                      ? 'Active: ${_formatTime(stopwatch.elapsed.inSeconds)}'
                      : 'Start a session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Today: ${_formatTime(elapsedToday)}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            // Invisible Button
            GestureDetector(
              onTap: _toggleSession,
              child: Container(
                width: 250,
                height: 250,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isRunning;

  CircularProgressPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final Paint progressPaint = Paint()
      ..color = isRunning ? Colors.green : Colors.red
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    double angle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PreviousSessionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previous Sessions'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _loadSessions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          Map<String, int> sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return Center(child: Text('No sessions recorded.'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              String date = sessions.keys.elementAt(index);
              int duration = sessions[date]!;
              return ListTile(
                title: Text(date),
                subtitle: Text('Total: ${_formatTime(duration)}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _loadSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('sessions');
    if (storedData == null) return {};
    return Map<String, int>.from(jsonDecode(storedData));
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    seconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
