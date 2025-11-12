import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/delivery_card.dart';
import '../../providers/delivery_provider.dart';

class DeliveryListScreen extends ConsumerWidget {
  const DeliveryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryHistoryAsync = ref.watch(deliveryHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(title: const Text('All Deliveries')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(deliveryHistoryProvider);
          // Wait a bit for the stream to emit
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: deliveryHistoryAsync.when(
          data: (deliveries) {
            if (deliveries.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No deliveries found'),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeliveryCard(
                    delivery: deliveries[index],
                    onTap: () =>
                        context.push('/delivery/${deliveries[index].id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Error loading deliveries'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
