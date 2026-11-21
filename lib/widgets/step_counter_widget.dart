import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class StepCounterWidget extends StatefulWidget {
  final ValueChanged<double> onDistanceUpdated;

  const StepCounterWidget({super.key, required this.onDistanceUpdated});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  bool _isWalking = false;
  double _distanceMeters = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  Timer? _walkTimer;

  @override
  void initState() {
    super.initState();
    _startSensorMonitoring();
  }

  void _startSensorMonitoring() {
    // Acumula distancia cada segundo mientras se detecta movimiento de caminata
    _walkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isWalking) {
        setState(() {
          _distanceMeters += 1.2; // Velocidad promedio estimada (1.2 m/s)
        });
        widget.onDistanceUpdated(_distanceMeters);
      }
    });

    // Escucha el giroscopio para detectar la rotación rítmica del paso
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      final double rotationMagnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final bool walkingNow = rotationMagnitude > 1.25;

      if (walkingNow != _isWalking) {
        setState(() {
          _isWalking = walkingNow;
        });

        if (_isWalking) {
          Vibration.vibrate(duration: 150);
        }
      }
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _walkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeGreen = Color(0xFF2E7D32);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: _isWalking ? activeGreen : Colors.grey.shade300,
          width: _isWalking ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isWalking
                    ? activeGreen.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _isWalking ? Icons.directions_walk : Icons.pause_circle_outline,
                size: 36,
                color: _isWalking ? activeGreen : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isWalking ? 'En movimiento' : 'En reposo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isWalking ? activeGreen : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Distancia acumulada',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    '${_distanceMeters.toStringAsFixed(1)} m',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}