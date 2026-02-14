import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class BarChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color barColor;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.barColor = AppTheme.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ),
      );
    }

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context)
            ),
          ),
          const SizedBox(height: 20),
          ...data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = maxValue > 0 ? (item.value / maxValue) : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Background track
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.greyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // Animated bar
                            AnimatedContainer(
                              duration: Duration(milliseconds: 500 + (index * 100)),
                              height: 20,
                              width: constraints.maxWidth * percentage,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    item.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PieChartWidget extends StatelessWidget {
  final List<PieChartData> data;
  final String title;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ),
      );
    }

    final total = data.fold(0.0, (sum, item) => sum + item.value);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context)
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie chart visualization
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: PieChartPainter(data, total),
                    size: const Size.square(200),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final percentage = total > 0 ? (item.value / total) * 100 : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% (${item.value})',
                                  style: const TextStyle(
                                    color: AppTheme.greyColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LineChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color lineColor;

  const LineChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = AppTheme.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ),
      );
    }

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context)
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: LineChartPainter(
                    data,
                    maxValue,
                    minValue,
                    lineColor,
                    constraints.maxWidth,
                    constraints.maxHeight - 40,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight - 40),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // X-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((item) {
              return Text(
                item.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.greyColor,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Data models
class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}

class PieChartData {
  final String label;
  final double value;
  final Color color;

  PieChartData(this.label, this.value, this.color);
}

// Custom painters
class PieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;

  PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    double currentAngle = -90 * (3.14159 / 180); // Start from top

    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var item in data) {
      final sweepAngle = total > 0 ? (item.value / total) * 2 * 3.14159 : 0.0;
      
      paint.color = item.color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle.toDouble(),
        sweepAngle.toDouble(),
        true,
        paint,
      );
      
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double maxValue;
  final double minValue;
  final Color lineColor;
  final double width;
  final double height;

  LineChartPainter(this.data, this.maxValue, this.minValue, this.lineColor, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = maxValue > minValue 
          ? (data[i].value - minValue) / (maxValue - minValue)
          : 0;
      final y = size.height - (normalizedValue * size.height);
      
      points.add(Offset(x, y));
    }

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 6, pointPaint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppTheme.greyColor.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
