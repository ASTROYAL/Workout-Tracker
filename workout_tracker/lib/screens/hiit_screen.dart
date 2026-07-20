import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'wild_widgets.dart';

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
  bool _isWorkPhase = true;
  int _secondsRemaining = workSeconds;
  Timer? _timer;
  bool _isPaused = true;

  bool get _isFinished =>
      _currentRound == totalRounds && !_isWorkPhase && _secondsRemaining == 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
      } else {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          return;
        }
        if (_isWorkPhase) {
          _isWorkPhase = false;
          _secondsRemaining = restSeconds;
        } else if (_currentRound < totalRounds) {
          _currentRound++;
          _isWorkPhase = true;
          _secondsRemaining = workSeconds;
        } else {
          _timer?.cancel();
          _isPaused = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HIIT Finisher')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: WildCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isFinished ? 'DONE' : 'ROUND $_currentRound OF $totalRounds',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  _isFinished
                      ? 'Finisher Complete'
                      : (_isWorkPhase ? 'WORK' : 'REST'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _isWorkPhase ? AppTheme.orangeSoft : AppTheme.violet,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _isFinished ? '0' : '$_secondsRemaining',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 86,
                    color: AppTheme.snow,
                  ),
                ),
                const SizedBox(height: 28),
                if (!_isFinished)
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(_isPaused ? 'Start' : 'Pause'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.onFinish,
                  child: Text(_isFinished ? 'Finish HIIT' : 'Skip and Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
