import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_billingwala_v2/core/database/app_database.dart';
import 'package:pos_billingwala_v2/features/pos/domain/payment_mode.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('stores and watches active products by category', () async {
    await db.replaceCategories([
      ProductCategoriesCompanion.insert(
        categoryId: const Value(1),
        categoryName: const Value('Beverages'),
      ),
      ProductCategoriesCompanion.insert(
        categoryId: const Value(2),
        categoryName: const Value('Snacks'),
        categoryDeletedStatus: const Value('1'),
      ),
    ]);

    await db.replaceProducts([
      ProductsCompanion.insert(
        productId: const Value(10),
        categoryId: const Value(1),
        categoryName: const Value('Beverages'),
        productName: const Value('Tea'),
        productPrice: const Value(20),
      ),
      ProductsCompanion.insert(
        productId: const Value(11),
        categoryId: const Value(1),
        categoryName: const Value('Beverages'),
        productName: const Value('Coffee'),
        productPrice: const Value(30),
        productDeletedStatus: const Value('1'),
      ),
    ]);

    final categories = await db.watchActiveCategories().first;
    expect(categories.length, 1);
    expect(categories.first.categoryName, 'Beverages');

    final products = await db.watchActiveProducts(categoryId: 1).first;
    expect(products.length, 1);
    expect(products.first.productName, 'Tea');
    expect(await db.countActiveProducts(), 1);
  });

  test('adds, updates, and clears cart items', () async {
    final tea = Product(
      productId: 10,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'TEA',
      productName: 'Tea',
      productPrice: 20,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 2.5,
      productSgst: 2.5,
      productWithGstPrice: 21,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );

    await db.addProductToCart(tea);
    await db.addProductToCart(tea);

    var cart = await db.watchCartItems().first;
    expect(cart.length, 1);
    expect(cart.first.quantity, 2);
    expect(cart.first.gstPercent, 5);

    await db.changeCartQuantity(10, 4);
    cart = await db.watchCartItems().first;
    expect(cart.first.quantity, 4);

    await db.changeCartQuantity(10, 0);
    cart = await db.watchCartItems().first;
    expect(cart, isEmpty);

    await db.addProductToCart(tea);
    await db.clearCart();
    cart = await db.watchCartItems().first;
    expect(cart, isEmpty);
  });

  test('saves invoice from cart and clears cart', () async {
    final tea = Product(
      productId: 10,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'TEA',
      productName: 'Tea',
      productPrice: 100,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 2.5,
      productSgst: 2.5,
      productWithGstPrice: 105,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );

    await db.addProductToCart(tea);
    await db.addProductToCart(tea);

    final result = await db.saveInvoiceFromCart(
      tender: PaymentTender.resolve(
        mode: PaymentMode.cash,
        totalAmount: 210,
      ),
    );

    expect(result.invoiceNumber, contains('PB/'));
    expect(result.paymentMode, 'Cash');
    expect(result.totalAmount, 210);
    expect(await db.watchCartItems().first, isEmpty);

    final invoice = await db.getInvoiceByNumber(result.invoiceNumber);
    expect(invoice, isNotNull);
    expect(invoice!.cashAmount, 210);
    expect(invoice.upiAmount, 0);

    final lines = await db.getInvoiceItems(result.invoiceNumber);
    expect(lines.length, 1);
    expect(lines.first.productQuantity, 2);
    expect(lines.first.productName, 'Tea');
  });

  test('opens table session, scopes cart, and settles on payment', () async {
    await db.seedDefaultTablesIfEmpty();
    final tables = await db.watchActivePosTables().first;
    expect(tables, isNotEmpty);

    final session = await db.openOrGetDiningSession('1');
    expect(session.sessionStatus, 'RUNNING');

    final tea = Product(
      productId: 10,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'TEA',
      productName: 'Tea',
      productPrice: 50,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 0,
      productSgst: 0,
      productWithGstPrice: 50,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );

    await db.addProductToCart(
      tea,
      cartScope: '1',
      diningSessionId: session.sessionId,
    );
    expect(await db.getCartItems(cartScope: ''), isEmpty);
    expect((await db.getCartItems(cartScope: '1')).length, 1);

    final result = await db.saveInvoiceFromCart(
      tender: PaymentTender.resolve(mode: PaymentMode.cash, totalAmount: 50),
      invoiceType: 'table_wise',
      cartScope: '1',
      tableNumber: '1',
      diningSessionId: session.sessionId,
    );

    expect(result.totalAmount, 50);
    expect(await db.getCartItems(cartScope: '1'), isEmpty);

    final invoice = await db.getInvoiceByNumber(result.invoiceNumber);
    expect(invoice!.invoiceType, 'table_wise');
    expect(invoice.noOfTable, '1');
    expect(invoice.diningSessionId, session.sessionId);

    final closed = await db.getOpenSessionForTable('1');
    expect(closed, isNull);
  });

  test('creates delta KOT rounds and marks printed qty', () async {
    final session = await db.openOrGetDiningSession('2');
    final tea = Product(
      productId: 10,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'TEA',
      productName: 'Tea',
      productPrice: 20,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 0,
      productSgst: 0,
      productWithGstPrice: 20,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );

    await db.addProductToCart(
      tea,
      cartScope: '2',
      diningSessionId: session.sessionId,
    );
    await db.addProductToCart(
      tea,
      cartScope: '2',
      diningSessionId: session.sessionId,
    );

    final first = await db.createKotFromUnprintedCart(
      sessionId: session.sessionId,
      tableNumber: '2',
    );
    expect(first.kot.kotNumber, 'KOT-001');
    expect(first.roundNumber, 1);
    expect(first.items.single.productQuantity, 2);
    expect(
      (await db.getCartItems(cartScope: '2')).single.printedQuantity,
      2,
    );

    await db.changeCartQuantity(10, 5, cartScope: '2');
    final second = await db.createKotFromUnprintedCart(
      sessionId: session.sessionId,
      tableNumber: '2',
    );
    expect(second.kot.kotNumber, 'KOT-002');
    expect(second.items.single.productQuantity, 3);

    expect(
      () => db.createKotFromUnprintedCart(
        sessionId: session.sessionId,
        tableNumber: '2',
      ),
      throwsStateError,
    );
  });

  test('joins tables merging cart onto primary', () async {
    await db.seedDefaultTablesIfEmpty();
    final primary = await db.openOrGetDiningSession('1');
    await db.openOrGetDiningSession('2');

    final tea = Product(
      productId: 10,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'TEA',
      productName: 'Tea',
      productPrice: 40,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 0,
      productSgst: 0,
      productWithGstPrice: 40,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );
    final coffee = Product(
      productId: 11,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'COF',
      productName: 'Coffee',
      productPrice: 50,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 0,
      productSgst: 0,
      productWithGstPrice: 50,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );

    await db.addProductToCart(tea, cartScope: '1', diningSessionId: primary.sessionId);
    await db.addProductToCart(coffee, cartScope: '2');

    final joined = await db.joinTables(primaryTable: '1', secondaryTable: '2');
    expect(joined.joinedTableNumbers, '2');
    expect(await db.getCartItems(cartScope: '2'), isEmpty);
    final primaryCart = await db.getCartItems(cartScope: '1');
    expect(primaryCart.length, 2);
    expect(await db.getOpenSessionForTable('2'), isNotNull);
    expect(
      (await db.getOpenSessionForTable('2'))!.primaryTableNumber,
      '1',
    );
  });

  test('marks invoices pending then synced', () async {
    final tea = Product(
      productId: 10,
      categoryId: 1,
      categoryName: 'Beverages',
      subcategoryId: null,
      productCode: 'TEA',
      productName: 'Tea',
      productPrice: 100,
      openPrice: '0',
      productUnit: 'cup',
      productCgst: 0,
      productSgst: 0,
      productWithGstPrice: 100,
      productDeletedStatus: '0',
      productNetworkStatus: null,
      productStatus: '1',
      productSyncStatus: '1',
    );
    await db.addProductToCart(tea);
    final result = await db.saveInvoiceFromCart(
      tender: PaymentTender.resolve(mode: PaymentMode.cash, totalAmount: 100),
    );
    final pending = await db.getPendingSyncInvoices();
    expect(pending.length, 1);
    expect(pending.first.invoiceId, result.invoiceId);
    expect(pending.first.invoiceSyncStatus, '0');
    expect(pending.first.invoiceNetworkStatus.length, 10);

    await db.markInvoiceSynced(result.invoiceId);
    expect(await db.getPendingSyncInvoices(), isEmpty);
    final items = await db.getInvoiceItems(result.invoiceNumber);
    expect(items.single.invoiceItemSyncStatus, '1');
  });

  test('upserts cloud invoices as synced without re-upload queue', () async {
    final header = InvoicesCompanion.insert(
      invoiceNumber: 'PB/CLOUD/1',
      invoiceDate: DateTime(2026, 9, 9, 12),
      invoiceType: const Value('fast_billing'),
      subTotal: const Value(80),
      totalGstAmount: const Value(0),
      totalAmount: const Value(80),
      paymentMode: const Value('UPI'),
      cashAmount: const Value(0),
      upiAmount: const Value(80),
      invoiceNetworkStatus: 'cloudkey001',
      invoiceSyncStatus: const Value('1'),
      itemCount: const Value(1),
    );
    final lines = [
      InvoiceItemsCompanion.insert(
        invoiceNumber: 'PB/CLOUD/1',
        productName: const Value('Idli'),
        productPrice: const Value(40),
        productQuantity: const Value(2),
        productUnit: const Value('plate'),
        invoiceItemNetworkStatus: const Value('linekey001'),
        invoiceItemSyncStatus: const Value('1'),
      ),
    ];

    final first = await db.upsertCloudInvoices(
      headers: [header],
      itemsByNumber: {'PB/CLOUD/1': lines},
    );
    expect(first.inserted, 1);
    expect(await db.getPendingSyncInvoices(), isEmpty);

    final invoice = await db.getInvoiceByNetworkStatus('cloudkey001');
    expect(invoice, isNotNull);
    expect(invoice!.invoiceSyncStatus, '1');
    expect((await db.getInvoiceItems('PB/CLOUD/1')).length, 1);

    final second = await db.upsertCloudInvoices(
      headers: [
        header.copyWith(totalAmount: const Value(90), upiAmount: const Value(90)),
      ],
      itemsByNumber: {
        'PB/CLOUD/1': [
          InvoiceItemsCompanion.insert(
            invoiceNumber: 'PB/CLOUD/1',
            productName: const Value('Idli'),
            productPrice: const Value(45),
            productQuantity: const Value(2),
            invoiceItemNetworkStatus: const Value('linekey001'),
            invoiceItemSyncStatus: const Value('1'),
          ),
        ],
      },
    );
    expect(second.updated, 1);
    expect((await db.getInvoiceByNetworkStatus('cloudkey001'))!.totalAmount, 90);
  });

  test('stock in accumulates and sale deducts inventory', () async {
    await db.addStockIn(productId: 10, productName: 'Tea', quantity: 20);
    expect(await db.getCurrentStock(10), 20);

    await db.addStockIn(productId: 10, productName: 'Tea', quantity: 5);
    expect(await db.getCurrentStock(10), 25);

    await db.deductInventoryForSale(
      productId: 10,
      productName: 'Tea',
      quantity: 3,
    );
    expect(await db.getCurrentStock(10), 22);

    final pending = await db.getPendingInventory();
    expect(pending.length, 3);
  });

  test('adds expense and lists pending sync', () async {
    await db.addExpense(name: 'Gas', amount: 500);
    final rows = await db.watchExpenses().first;
    expect(rows.length, 1);
    expect(rows.first.expensesAmount, 500);
    expect((await db.getPendingExpenses()).length, 1);
  });

  test('issues and verifies mess token payload', () async {
    final memberId = await db.upsertLocalMessMember(
      memberName: 'Ravi',
      mobile: '9999999999',
    );
    final member = await db.getMessMember(memberId);
    expect(member, isNotNull);

    final token = await db.issueMessToken(
      tokenCode: 'abc123',
      memberId: '$memberId',
      memberName: member!.memberName,
      memberType: 'member',
    );
    expect(token.tokenState, 'active');

    final verified = await db.verifyMessToken('abc123');
    expect(verified!.tokenState, 'verified');
    expect(verified.verifiedDate, isNotNull);
  });

  test('adds combo to cart with negative productId and skips inventory', () async {
    await db.replaceCombos([
      CombosCompanion.insert(
        comboId: const Value(5),
        comboName: const Value('Thali'),
        comboPrice: const Value(120),
        comboCgst: const Value(2.5),
        comboSgst: const Value(2.5),
        comboWithGstPrice: const Value(126),
        comboNetworkStatus: const Value('cmb_5'),
      ),
    ]);
    final combo = (await db.watchActiveCombos().first).first;
    await db.addComboToCart(combo);
    await db.addComboToCart(combo);

    final cart = await db.watchCartItems().first;
    expect(cart.length, 1);
    expect(cart.first.productId, -5);
    expect(cart.first.lineType, 'combo');
    expect(cart.first.quantity, 2);
    expect(cart.first.unitPrice, 126);

    final result = await db.saveInvoiceFromCart(
      tender: PaymentTender.resolve(
        mode: PaymentMode.cash,
        totalAmount: 264.6,
      ),
    );
    final lines = await db.getInvoiceItems(result.invoiceNumber);
    expect(lines.single.invoiceItemType, 'combo');
    expect(await db.getPendingInventory(), isEmpty);
  });
}
