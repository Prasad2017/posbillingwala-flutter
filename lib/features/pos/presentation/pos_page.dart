import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/masters/domain/masters_providers.dart';
import 'package:pos_billingwala_v2/features/pos/domain/billing_session.dart';
import 'package:pos_billingwala_v2/features/pos/domain/kot_providers.dart';
import 'package:pos_billingwala_v2/features/pos/domain/pos_providers.dart';
import 'package:pos_billingwala_v2/features/pos/presentation/kot_preview_page.dart';
import 'package:pos_billingwala_v2/features/pos/presentation/portion_picker.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_providers.dart';
import 'package:pos_billingwala_v2/features/print/domain/print_service.dart';
import 'package:pos_billingwala_v2/features/print/domain/printer_settings.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key, this.resetSessionOnOpen = false});

  final bool resetSessionOnOpen;

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final _searchController = TextEditingController();
  final _speech = stt.SpeechToText();
  bool _showCombos = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    if (widget.resetSessionOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(billingSessionProvider.notifier).usePos();
      });
    }
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _voiceSearch() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition unavailable')),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        _searchController.text = result.recognizedWords;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        localeId: 'en_IN',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(billingSessionProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(posProductsProvider);
    final cartAsync = ref.watch(cartItemsProvider);
    final cartSummary = ref.watch(cartSummaryProvider);
    final selectedCategoryId = ref.watch(posSelectedCategoryIdProvider);
    final selectedSubcategoryId = ref.watch(posSelectedSubcategoryIdProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    final width = MediaQuery.sizeOf(context).width;
    final showSideCart = width >= 1000;

    final unprintedCount = ref.watch(unprintedCartCountProvider);
    final isTable = session.invoiceType == 'table_wise';
    final kotEnabled = ref.watch(printerSettingsProvider).kotEnable;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.title),
            if (session.tableNumber != null)
              Text(
                'Table ${session.tableNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          if (!cartSummary.isEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context, ref),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text(
                'Clear Cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: showSideCart
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _CatalogPane(
                      session: session,
                      categoriesAsync: categoriesAsync,
                      productsAsync: productsAsync,
                      selectedCategoryId: selectedCategoryId,
                      selectedSubcategoryId: selectedSubcategoryId,
                      currency: currency,
                      searchController: _searchController,
                      showCombos: _showCombos,
                      listening: _listening,
                      onVoiceSearch: _voiceSearch,
                      onToggleCombos: (v) => setState(() => _showCombos = v),
                    ),
                  ),
                  SizedBox(
                    width: 360,
                    child: _CartPane(
                      session: session,
                      cartAsync: cartAsync,
                      currency: currency,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: _CatalogPane(
                      session: session,
                      categoriesAsync: categoriesAsync,
                      productsAsync: productsAsync,
                      selectedCategoryId: selectedCategoryId,
                      selectedSubcategoryId: selectedSubcategoryId,
                      currency: currency,
                      searchController: _searchController,
                      showCombos: _showCombos,
                      listening: _listening,
                      onVoiceSearch: _voiceSearch,
                      onToggleCombos: (v) => setState(() => _showCombos = v),
                    ),
                  ),
                  if (isTable)
                    _DineInFooter(
                      summary: cartSummary,
                      currency: currency,
                      unprintedCount: unprintedCount,
                      kotEnabled: kotEnabled,
                      onKot: () => _sendKot(context, ref),
                      onSave: () {
                        if (!context.mounted) return;
                        context.go('/tables');
                      },
                      onPay: cartSummary.isEmpty
                          ? null
                          : () => context.push(session.paymentRoute),
                    )
                  else
                    _CartFooter(
                      summary: cartSummary,
                      currency: currency,
                      paymentRoute: session.paymentRoute,
                      onTap: cartSummary.isEmpty
                          ? () {}
                          : () => _openCartSheet(context, session),
                      onPay: cartSummary.isEmpty
                          ? null
                          : () => context.push(session.paymentRoute),
                    ),
                ],
              ),
        ),
      );
  }

  Future<void> _sendKot(BuildContext context, WidgetRef ref) async {
    try {
      final ticket =
          await ref.read(kotControllerProvider.notifier).createKot();
      if (!context.mounted) return;
      final settings = ref.read(printerSettingsProvider);
      if (settings.kotAutoPrint) {
        final copies = settings.kotCopies.clamp(1, 5);
        PrintResult? last;
        for (var i = 0; i < copies; i++) {
          last = await ref.read(printServiceProvider).printKot(ticket);
        }
        await ref
            .read(kotControllerProvider.notifier)
            .markPrinted(ticket.kot.kotId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              last?.message ??
                  'KOT printed${copies > 1 ? ' ×$copies' : ''}',
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => KotPreviewPage(ticket: ticket),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart'),
        content: const Text('Remove all items from this bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Clear',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(posCartControllerProvider.notifier).clear();
    }
  }

  Future<void> _openCartSheet(BuildContext context, BillingSession session) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: _CartSheetBody(session: session),
      ),
    );
  }
}

class _CatalogPane extends ConsumerWidget {
  const _CatalogPane({
    required this.session,
    required this.categoriesAsync,
    required this.productsAsync,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.currency,
    required this.searchController,
    required this.showCombos,
    required this.listening,
    required this.onVoiceSearch,
    required this.onToggleCombos,
  });

  final BillingSession session;
  final AsyncValue<List<ProductCategory>> categoriesAsync;
  final AsyncValue<List<Product>> productsAsync;
  final int? selectedCategoryId;
  final int? selectedSubcategoryId;
  final NumberFormat currency;
  final TextEditingController searchController;
  final bool showCombos;
  final bool listening;
  final VoidCallback onVoiceSearch;
  final ValueChanged<bool> onToggleCombos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = searchController.text.trim().toLowerCase();
    final combosAsync = ref.watch(posCombosProvider);
    final subsAsync = ref.watch(posSubcategoriesProvider);

    return Column(
      children: [
        if (session.tableNumber != null || session.customerName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                session.tableNumber != null
                    ? 'Table ${session.tableNumber}'
                    : 'Customer: ${session.customerName}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search product by name / code',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: listening ? 'Listeningâ€¦' : 'Voice search',
                    onPressed: onVoiceSearch,
                    icon: Icon(
                      listening ? Icons.mic : Icons.mic_none_rounded,
                      color: listening ? AppColors.primary : null,
                    ),
                  ),
                  if (query.isNotEmpty)
                    IconButton(
                      onPressed: searchController.clear,
                      icon: const Icon(Icons.clear_rounded),
                    ),
                ],
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Products')),
              ButtonSegment(value: true, label: Text('Combos')),
            ],
            selected: {showCombos},
            onSelectionChanged: (v) => onToggleCombos(v.first),
          ),
        ),
        const SizedBox(height: 8),
        if (!showCombos)
          SizedBox(
            height: 48,
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('No categories found. Sync Masters first.'),
                  );
                }
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategoryId == null,
                        onSelected: (_) {
                          ref
                              .read(posSelectedCategoryIdProvider.notifier)
                              .select(null);
                          ref
                              .read(posSelectedSubcategoryIdProvider.notifier)
                              .select(null);
                        },
                      ),
                    ),
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.categoryName),
                          selected:
                              selectedCategoryId == category.categoryId,
                          onSelected: (_) => ref
                              .read(posSelectedCategoryIdProvider.notifier)
                              .select(category.categoryId),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        if (!showCombos)
          SizedBox(
            height: 44,
            child: subsAsync.when(
              data: (subs) {
                if (subs.isEmpty) return const SizedBox.shrink();
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All sub'),
                        selected: selectedSubcategoryId == null,
                        onSelected: (_) => ref
                            .read(posSelectedSubcategoryIdProvider.notifier)
                            .select(null),
                      ),
                    ),
                    ...subs.map(
                      (sub) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sub.subcategoryName),
                          selected:
                              selectedSubcategoryId == sub.subcategoryId,
                          onSelected: (_) => ref
                              .read(posSelectedSubcategoryIdProvider.notifier)
                              .select(sub.subcategoryId),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        Expanded(
          child: showCombos
              ? combosAsync.when(
                  data: (combos) {
                    final filtered = query.isEmpty
                        ? combos
                        : combos
                            .where(
                              (c) =>
                                  c.comboName.toLowerCase().contains(query) ||
                                  (c.comboCode ?? '')
                                      .toLowerCase()
                                      .contains(query),
                            )
                            .toList();
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No combos found'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final combo = filtered[index];
                        final price = combo.comboWithGstPrice > 0
                            ? combo.comboWithGstPrice
                            : combo.comboPrice;
                        return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
                            title: Text(
                              combo.comboName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(currency.format(price)),
                            trailing: IconButton.filled(
                              onPressed: () => ref
                                  .read(posCartControllerProvider.notifier)
                                  .addCombo(combo),
                              icon: const Icon(Icons.add),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                )
              : productsAsync.when(
                  data: (products) {
                    final filtered = query.isEmpty
                        ? products
                        : products
                            .where(
                              (p) =>
                                  p.productName.toLowerCase().contains(query) ||
                                  (p.productCode ?? '')
                                      .toLowerCase()
                                      .contains(query),
                            )
                            .toList();
                    if (filtered.isEmpty) {
                      return _EmptyCatalog(
                        hasCategoryFilter: selectedCategoryId != null,
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isGrid = constraints.maxWidth >= 760;
                        if (!isGrid) {
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _ProductRowTile(
                              product: filtered[index],
                              currency: currency,
                            ),
                          );
                        }
                        final crossAxisCount =
                            constraints.maxWidth >= 1100 ? 3 : 2;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.28,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _ProductCard(
                            product: filtered[index],
                            currency: currency,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                ),
        ),
      ],
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.hasCategoryFilter});

  final bool hasCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasCategoryFilter ? 'No products in this category' : 'No products yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasCategoryFilter
                  ? 'Try another category or open Masters to sync more items.'
                  : 'Open Masters and sync your catalog before billing.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.currency});

  final Product product;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gstPercent = product.productCgst + product.productSgst;
    return AppCard(
      accentColor: product.openPrice == '1' ? AppColors.orange : AppColors.primary,
      onTap: () => addProductWithPortionPicker(context, ref, product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppModuleIcon(
                icon: Icons.shopping_bag_rounded,
                color: product.openPrice == '1' ? AppColors.orange : AppColors.primary,
                size: 50,
              ),
              const Spacer(),
              if (product.openPrice == '1')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Open Price',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            product.productName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (product.categoryName?.isNotEmpty == true) product.categoryName!,
              if (product.productCode?.isNotEmpty == true)
                'Code: ${product.productCode}',
              if (gstPercent > 0) 'GST ${gstPercent.toStringAsFixed(0)}%',
            ].join('  |  '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                currency.format(product.productPrice),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              AppButton(
                label: 'Add',
                icon: Icons.add_shopping_cart_rounded,
                expanded: false,
                onPressed: () =>
                    addProductWithPortionPicker(context, ref, product),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductRowTile extends ConsumerWidget {
  const _ProductRowTile({required this.product, required this.currency});

  final Product product;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gstPercent = product.productCgst + product.productSgst;
    return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const AppModuleIcon(
          icon: Icons.shopping_bag_rounded,
          color: AppColors.primary,
          size: 46,
        ),
        title: Text(product.productName),
        subtitle: Text(
          [
            if (product.categoryName?.isNotEmpty == true) product.categoryName!,
            if (gstPercent > 0) 'GST ${gstPercent.toStringAsFixed(0)}%',
          ].join(' | '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currency.format(product.productPrice),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => addProductWithPortionPicker(context, ref, product),
              child: const Text(
                'Add to Cart',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPane extends ConsumerWidget {
  const _CartPane({
    required this.session,
    required this.cartAsync,
    required this.currency,
  });

  final BillingSession session;
  final AsyncValue<List<CartItem>> cartAsync;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Row(
              children: [
                Text(
                  'Current Bill',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${summary.totalQuantity} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cartAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyCart();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CartItemTile(
                    item: items[index],
                    currency: currency,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          _BillSummary(
            summary: summary,
            currency: currency,
            paymentRoute: session.paymentRoute,
            showKot: session.invoiceType == 'table_wise',
          ),
        ],
      ),
    );
  }
}

class _CartSheetBody extends ConsumerWidget {
  const _CartSheetBody({required this.session});

  final BillingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CartPane(
      session: session,
      cartAsync: ref.watch(cartItemsProvider),
      currency: NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. '),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Cart is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap products to add them to the current bill.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item, required this.currency});

  final CartItem item;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineTotal = item.unitPrice * item.quantity;
    return AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (item.quantity > item.printedQuantity)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        'KOT +${item.quantity - item.printedQuantity}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: () => ref
                      .read(posCartControllerProvider.notifier)
                      .remove(item),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (item.categoryName?.isNotEmpty == true) item.categoryName!,
                if (item.gstPercent > 0) 'GST ${item.gstPercent.toStringAsFixed(0)}%',
              ].join(' | '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () => ref.read(posCartControllerProvider.notifier).decrement(item),
                ),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => ref.read(posCartControllerProvider.notifier).increment(item),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(lineTotal),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${currency.format(item.unitPrice)} each',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }
}

class _BillSummary extends ConsumerWidget {
  const _BillSummary({
    required this.summary,
    required this.currency,
    required this.paymentRoute,
    this.showKot = false,
  });

  final CartSummary summary;
  final NumberFormat currency;
  final String paymentRoute;
  final bool showKot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unprinted = ref.watch(unprintedCartCountProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Items', value: '${summary.totalQuantity}'),
          _SummaryRow(label: 'Subtotal', value: currency.format(summary.subtotal)),
          _SummaryRow(label: 'GST', value: currency.format(summary.taxTotal)),
          const Divider(height: 18),
          _SummaryRow(
            label: 'Grand Total',
            value: currency.format(summary.grandTotal),
            emphasized: true,
          ),
          const SizedBox(height: 14),
          if (showKot) ...[
            AppButton(
              label: unprinted > 0
                  ? 'Send KOT ($unprinted new)'
                  : 'KOT up to date',
              icon: Icons.print_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: unprinted <= 0
                  ? null
                  : () async {
                      try {
                        final ticket = await ref
                            .read(kotControllerProvider.notifier)
                            .createKot();
                        if (!context.mounted) return;
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => KotPreviewPage(ticket: ticket),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    },
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Proceed to Payment',
              icon: Icons.receipt_long_rounded,
              onPressed: summary.isEmpty
                  ? null
                  : () => context.push(paymentRoute),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            value,
            style: style?.copyWith(
              color: emphasized ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  const _CartFooter({
    required this.summary,
    required this.currency,
    required this.paymentRoute,
    required this.onTap,
    this.onPay,
  });

  final CartSummary summary;
  final NumberFormat currency;
  final String paymentRoute;
  final VoidCallback onTap;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              InkWell(
                onTap: summary.isEmpty ? null : onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${summary.totalQuantity}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Payable amount',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    Text(
                      currency.format(summary.grandTotal),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              AppButton(
            label: 'View Cart',
            onPressed: onPay ?? (summary.isEmpty ? null : onTap),
            expanded: false,
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DineInFooter extends StatelessWidget {
  const _DineInFooter({
    required this.summary,
    required this.currency,
    required this.unprintedCount,
    this.kotEnabled = true,
    required this.onKot,
    required this.onSave,
    required this.onPay,
  });

  final CartSummary summary;
  final NumberFormat currency;
  final int unprintedCount;
  final bool kotEnabled;
  final VoidCallback onKot;
  final VoidCallback onSave;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Payable',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  Text(
                    currency.format(summary.grandTotal),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (kotEnabled) ...[
                    Expanded(
                      child: AppButton(
                        label: unprintedCount > 0
                            ? 'KOT ($unprintedCount)'
                            : 'KOT',
                        variant: AppButtonVariant.outlined,
                        onPressed: unprintedCount <= 0 ? null : onKot,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: AppButton(
                      label: 'SAVE',
                      onPressed: onSave,
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'PAY',
                      onPressed: onPay,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
