import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseChart extends StatelessWidget {

  final List<double> amounts;

  ExpenseChart(this.amounts);

  @override
  Widget build(BuildContext context) {

    List<BarChartGroupData> bars = [];

    for(int i=0;i<amounts.length;i++){

      bars.add(
        BarChartGroupData(
          x:i,
          barRods:[
            BarChartRodData(
              toY:amounts[i],
              color:Colors.teal,
              width:14,
            )
          ],
        ),
      );
    }

    return Container(
      height:200,
      padding:EdgeInsets.all(16),

      child:BarChart(
        BarChartData(
          borderData:FlBorderData(show:false),
          titlesData:FlTitlesData(show:false),
          barGroups:bars,
        ),
      ),
    );
  }
}