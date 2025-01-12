import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';

class OverviewBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double totalOverpayments;

  const OverviewBalanceCard({
    super.key,
    required this.totalBalance,
    required this.totalOverpayments,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final previousYearsBalance = appData.previousYearsBalance;
    final totalBalanceWithOverpayments =
        totalBalance + totalOverpayments + previousYearsBalance;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Einnahmen:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${totalBalance.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Spenden:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${totalOverpayments.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (previousYearsBalance > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vorjahre:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${previousYearsBalance.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tatsächlicher Kassenstand:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${totalBalanceWithOverpayments.toStringAsFixed(2)}€',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: totalBalanceWithOverpayments >= 0
                        ? Colors.blue
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
