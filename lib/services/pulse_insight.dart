
// Network Insight Card - Data-driven predictive connectivity insights
import 'package:flutter/material.dart';

class NetworkInsightCard extends StatelessWidget {
  final String insight;
  final String insightType;
  final int confidenceScore;
  final bool isLoading;

  const NetworkInsightCard({
    super.key,
    required this.insight,
    this.insightType = '',
    this.confidenceScore = 0,
    this.isLoading = false,
  });

  Color _getConfidenceColor() {
    if (confidenceScore >= 85) return Colors.green;
    if (confidenceScore >= 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getInsightIcon() {
    switch (insightType) {
      case 'time_comparison':
        return Icons.access_time;
      case 'stability':
        return Icons.speed;
      case 'crowdedness':
        return Icons.people;
      case 'location_quality':
        return Icons.location_on;
      case 'weekly_trend':
        return Icons.trending_up;
      case 'alternative_wifi':
        return Icons.wifi_find;
      case 'freshness':
        return Icons.update;
      case 'optimal_time':
        return Icons.schedule;
      default:
        return Icons.psychology;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getInsightIcon(),
                color: const Color.fromARGB(255, 64, 196, 255),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isLoading
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: Color.fromARGB(255, 64, 196, 255),
                      )
                    : Text(
                        insight,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
              if (!isLoading && confidenceScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getConfidenceColor(), width: 1),
                  ),
                  child: Text(
                    '$confidenceScore%',
                    style: TextStyle(
                      color: _getConfidenceColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}