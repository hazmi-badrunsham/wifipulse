import 'package:flutter/material.dart';

class PulseInsightCard extends StatelessWidget {
  final String insight;
  final bool isLoading;

  const PulseInsightCard({
    super.key,
    required this.insight,
    this.isLoading = false,
  });

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
      child: Row(
        children: [
          const Icon(Icons.psychology, color:  Color.fromARGB(255, 64, 196, 255), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: isLoading
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color:  Color.fromARGB(255, 64, 196, 255),
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
        ],
      ),
    );
  }
}