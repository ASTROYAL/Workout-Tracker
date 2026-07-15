import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class HIITScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const HIITScreen({super.key, required this.onFinish});

  @override
  State<HIITScreen> createState() => _HIITScreenState();
}

class _HIITScreenState extends State<HIITScreen> {
  static const int totalRounds = 6;
  static const int workSeconds = 40;
  static const int restSeconds = 20;

  int _currentRound = 1;
  bool _isWorkPhase = true; // true = work, false = rest
  int _secondsRemaining = workSeconds;
  Timer? _timer;
  bool _isPaused = true;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (!_isPaused) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          if (_isWorkPhase) {
            _isWorkPhase = false;
            _secondsRemaining = restSeconds;
          } else {
            if (_currentRound < totalRounds) {
              _currentRound++;
              _isWorkPhase = true;
              _secondsRemaining = workSeconds;
            } else {
              _timer?.cancel();
              _isPaused = true;
            }
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isFinished = _currentRound == totalRounds && !_isWorkPhase && _secondsRemaining == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('HIIT Session')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFinished ? 'DONE!' : 'Round $_currentRound of $totalRounds',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            if (!isFinished)
              Text(
                _isWorkPhase ? 'WORK' : 'REST',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _isWorkPhase ? AppTheme.push : AppTheme.hiit,
                ),
              ),
            const SizedBox(height: 40),
            if (!isFinished)
              Text(
                '$_secondsRemaining',
                style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 40),
            if (!isFinished)
              ElevatedButton.icon(
                onPressed: _togglePause,
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(_isPaused ? 'START' : 'PAUSE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.card,
              ),
              child: const Text('FINISH HIIT'),
            )
          ],
        ),
      ),
    );
  }
}
