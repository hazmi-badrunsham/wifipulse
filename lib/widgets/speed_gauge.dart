import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_network_speed_test/flutter_network_speed_test.dart';

class SpeedGaugeWidget extends StatelessWidget {
  final double gaugeValue;
  final bool showUploadGauge;
  final bool isTesting;
  final double downloadSpeed;
  final double uploadSpeed;
  final VoidCallback onStartTest;
  final Stream<ProgressData> progressStream;

  const SpeedGaugeWidget({
    super.key,
    required this.gaugeValue,
    required this.showUploadGauge,
    required this.isTesting,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.onStartTest,
    required this.progressStream,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              showUploadGauge ? 'Upload Speed' : 'Download Speed',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              width: 250,
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    minimum: 0,
                    maximum: 120,
                    pointers: [
                      NeedlePointer(
                        value: gaugeValue,
                        enableAnimation: true,
                      ),
                    ],
                    annotations: [
                      GaugeAnnotation(
                        widget: Text(
                          '${gaugeValue.toStringAsFixed(1)} Mbps',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.8,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isTesting ? null : onStartTest,
              child: Text(isTesting ? 'Testing...' : 'Start Speed Test'),
            ),
            const SizedBox(height: 10),
            StreamBuilder<ProgressData>(
              stream: progressStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.type != SpeedTestType.ping) {
                  return Text(
                    '${snapshot.data!.type.name.toUpperCase()}: ${snapshot.data!.speed.toStringAsFixed(2)} Mbps',
                    style: const TextStyle(fontSize: 16),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (!isTesting && (downloadSpeed > 0 || uploadSpeed > 0)) ...[
              Text('Download: ${downloadSpeed.toStringAsFixed(2)} Mbps'),
              Text('Upload: ${uploadSpeed.toStringAsFixed(2)} Mbps'),
            ]
          ],
        ),
      ),
    );
  }
}