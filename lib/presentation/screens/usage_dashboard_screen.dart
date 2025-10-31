import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/quota/quota_bloc.dart';
import '../../data/models/quota.dart';
import '../widgets/quota_progress_bar.dart';
import '../widgets/main_scaffold.dart';

class UsageDashboardScreen extends StatelessWidget {
  const UsageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Home Dashboard',
      body: BlocBuilder<QuotaBloc, QuotaState>(
        builder: (context, state) {
          // Trigger initial load if needed
          if (state is QuotaInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<QuotaBloc>().add(const RefreshQuota());
            });
          }

          if (state is QuotaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

            if (state is QuotaError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<QuotaBloc>().add(const RefreshQuota());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is QuotaOk || state is QuotaNearLimit || state is QuotaExceeded) {
              final quota = (state as dynamic).quota as UserQuota;
              final percentages = (state as dynamic).percentages as Map<String, double>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier badge
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              quota.isPremium ? Icons.star : Icons.account_circle,
                              color: quota.isPremium ? Colors.amber : Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              quota.isPremium ? 'Premium' : 'Free',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (quota.isFree) ...[
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  // TODO: Navigate to upgrade screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Upgrade feature coming soon')),
                                  );
                                },
                                child: const Text('Upgrade'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pages quota
                    QuotaProgressBar(
                      label: 'Pages Uploaded',
                      used: quota.pagesUploadedThisMonth,
                      limit: quota.isPremium ? null : 100,
                      percentage: percentages['pages']!,
                      color: Colors.blue,
                      unit: 'pages',
                    ),
                    const SizedBox(height: 16),

                    // Storage quota
                    QuotaProgressBar(
                      label: 'Storage Used',
                      used: _bytesToMB(quota.storageUsedBytes),
                      limit: quota.isPremium ? null : 5120, // 5GB in MB
                      percentage: percentages['storage']!,
                      color: Colors.orange,
                      unit: 'MB',
                    ),
                    const SizedBox(height: 16),

                    // API calls
                    QuotaProgressBar(
                      label: 'API Calls This Month',
                      used: quota.apiCallsThisMonth,
                      limit: null, // No hard limit shown for API calls
                      percentage: percentages['api']!,
                      color: Colors.green,
                      unit: 'calls',
                    ),
                    const SizedBox(height: 24),

                    // Reset date
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quota Reset Date',
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  Text(
                                    _formatDate(quota.quotaResetDate),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Alert banners
                    if (state is QuotaNearLimit) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'re using ${(percentages['pages']! * 100).toStringAsFixed(0)}% of your monthly quota',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (state is QuotaExceeded) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Quota Exceeded',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.red,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have reached your monthly limit. Upgrade to premium for unlimited pages and storage.',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Navigate to upgrade
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Upgrade to Premium'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  int _bytesToMB(int bytes) => (bytes / (1024 * 1024)).round();

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

