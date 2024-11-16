import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionRecordsScreen extends StatelessWidget {
  Future<Map<String, int>> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('sessions');
    if (storedData == null) return {};
    return Map<String, int>.from(jsonDecode(storedData));
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Session Records')),
      body: FutureBuilder<Map<String, int>>(
        future: _loadSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No session data found.'));
          }

          Map<String, int> sessions = snapshot.data!;
          List<String> sortedDates = sessions.keys.toList()..sort();

          return ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              String date = sortedDates[index];
              int seconds = sessions[date]!;
              return ListTile(
                title: Text(date),
                subtitle: Text('Total: ${_formatTime(seconds)}'),
              );
            },
          );
        },
      ),
    );
  }
}
