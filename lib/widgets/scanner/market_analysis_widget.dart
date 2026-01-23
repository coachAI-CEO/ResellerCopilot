import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// Widget displaying AI-generated market analysis
///
/// Shows the detailed market analysis text from Gemini AI
/// with proper formatting for bullets and sections
class MarketAnalysisWidget extends StatelessWidget {
  final String analysis;

  const MarketAnalysisWidget({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.analytics,
              size: IconSizes.base,
              color: Colors.blue.shade700,
            ),
            SizedBox(width: Spacing.sm),
            Text(
              'Market Analysis',
              style: TextStyle(
                fontSize: FontSizes.md,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: Spacing.md),

        // Analysis content
        Container(
          padding: EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(BorderRadii.md),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _parseAndFormatAnalysis(analysis),
          ),
        ),
      ],
    );
  }

  /// Parses the analysis text and formats it with proper styling
  List<Widget> _parseAndFormatAnalysis(String text) {
    final widgets = <Widget>[];
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check for section headers (lines ending with :)
      if (line.endsWith(':') && !line.startsWith('•') && !line.startsWith('-')) {
        widgets.add(SizedBox(height: Spacing.sm));
        widgets.add(
          Text(
            line,
            style: TextStyle(
              fontSize: FontSizes.md,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        );
        widgets.add(SizedBox(height: Spacing.xs));
        continue;
      }

      // Check for bullet points
      if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
        final content = line.substring(1).trim();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: Spacing.md, bottom: Spacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: FontSizes.md,
                  ),
                ),
                Expanded(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: FontSizes.base,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph text
      widgets.add(
        Text(
          line,
          style: TextStyle(
            fontSize: FontSizes.base,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
      );
      widgets.add(SizedBox(height: Spacing.xs));
    }

    return widgets;
  }
}
