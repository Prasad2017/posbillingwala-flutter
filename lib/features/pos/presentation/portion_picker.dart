import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/core/database/database_provider.dart';
import 'package:pos_billingwala_v2/features/pos/domain/pos_providers.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

/// Shows portion picker when product has portions; otherwise adds base price.
Future<void> addProductWithPortionPicker(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final portions =
      await ref.read(appDatabaseProvider).getPortionsForProduct(product.productId);
  if (!context.mounted) return;

  if (portions.isEmpty) {
    await ref.read(posCartControllerProvider.notifier).addProduct(product);
    return;
  }

  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final choice = await showAppBottomSheet<Object>(
    context: context,
    title: product.productName,
    icon: Icons.restaurant_rounded,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Choose portion'),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Regular'),
          subtitle: Text(currency.format(product.productPrice)),
          onTap: () => Navigator.pop(context, 'base'),
        ),
        for (final p in portions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              p.portionName.trim().isEmpty ? 'Portion' : p.portionName,
            ),
            subtitle: Text(currency.format(p.portionPrice)),
            onTap: () => Navigator.pop(context, p),
          ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return;
  if (choice == 'base') {
    await ref.read(posCartControllerProvider.notifier).addProduct(product);
  } else if (choice is ProductPortion) {
    await ref
        .read(posCartControllerProvider.notifier)
        .addProduct(product, portion: choice);
  }
}
