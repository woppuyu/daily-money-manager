import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoadingTheme = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_themeModeKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = storedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _isLoadingTheme = false;
    });
  }

  Future<void> _toggleThemeMode() async {
    final nextMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, nextMode == ThemeMode.dark ? 'dark' : 'light');

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = nextMode;
    });
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
      surface: const Color(0xFFFAFAFA),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F7F4),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFFF7F7F4),
        foregroundColor: Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF111827),
        surfaceTintColor: const Color(0xFF111827),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Money Manager',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: _isLoadingTheme
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : HomeScreen(
              onToggleThemeMode: _toggleThemeMode,
              themeMode: _themeMode,
            ),
    );
  }
}

enum TransactionType { income, expense, transfer, withdrawal, endOfDay }

class TransactionItem {
  const TransactionItem({
    required this.amount,
    required this.type,
    required this.timestamp,
    this.category,
    this.note,
  });

  final double amount;
  final TransactionType type;
  final String? category;
  final String? note;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'type': type.name,
      'category': category,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final parsedType = TransactionType.values.firstWhere(
      (type) => type.name == json['type'],
      orElse: () => TransactionType.expense,
    );

    return TransactionItem(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: parsedType,
      category: json['category'] as String?,
      note: json['note'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get displayTitle {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'End day transfer';
      case TransactionType.withdrawal:
        return 'Savings withdrawal';
      case TransactionType.endOfDay:
        return 'End of day';
    }
  }

  String get displaySubtitle {
    final details = <String>[];
    if (category != null && category!.trim().isNotEmpty) {
      details.add(category!.trim());
    }
    if (note != null && note!.trim().isNotEmpty) {
      details.add(note!.trim());
    }
    if (details.isEmpty) {
      return _formatDateTime(timestamp);
    }
    return '${details.join(' · ')} · ${_formatDateTime(timestamp)}';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onToggleThemeMode, required this.themeMode});

  final Future<void> Function() onToggleThemeMode;
  final ThemeMode themeMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _dailyBalanceKey = 'daily_balance';
  static const String _savingsBalanceKey = 'savings_balance';
  static const String _historyKey = 'transaction_history';

  double _dailyBalance = 0;
  double _savingsBalance = 0;
  bool _isLoading = true;
  List<TransactionItem> _history = <TransactionItem>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    final decodedHistory = historyJson == null ? <dynamic>[] : jsonDecode(historyJson) as List<dynamic>;

    final parsedHistory = decodedHistory
        .whereType<Map<String, dynamic>>()
        .map(TransactionItem.fromJson)
        .toList()
      ..sort((left, right) => right.timestamp.compareTo(left.timestamp));

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyBalance = prefs.getDouble(_dailyBalanceKey) ?? 0;
      _savingsBalance = prefs.getDouble(_savingsBalanceKey) ?? 0;
      _history = parsedHistory;
      _isLoading = false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyBalanceKey, _dailyBalance);
    await prefs.setDouble(_savingsBalanceKey, _savingsBalance);
    await prefs.setString(
      _historyKey,
      jsonEncode(_history.map((transaction) => transaction.toJson()).toList()),
    );
  }

  Future<void> _openAddTransactionSheet() async {
    final transaction = await showModalBottomSheet<_TransactionInputResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );

    if (transaction == null) {
      return;
    }

    final signedAmount = transaction.type == TransactionType.expense ? -transaction.amount : transaction.amount;
    final updatedTransaction = TransactionItem(
      amount: transaction.amount,
      type: transaction.type,
      category: transaction.category,
      note: transaction.note,
      timestamp: DateTime.now(),
    );

    setState(() {
      _dailyBalance += signedAmount;
      _history = [updatedTransaction, ..._history];
    });

    await _saveState();
  }

  Future<void> _openWithdrawalSheet() async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WithdrawalSheet(),
    );

    if (amount == null) {
      return;
    }

    setState(() {
      _savingsBalance -= amount;
      _history = [
        TransactionItem(
          amount: amount,
          type: TransactionType.withdrawal,
          category: 'Savings',
          note: 'Manual withdrawal',
          timestamp: DateTime.now(),
        ),
        ..._history,
      ];
    });

    await _saveState();
  }

  Future<void> _endDay() async {
    final remainder = _dailyBalance;
    double savingsDelta = 0;
    TransactionType eventType = TransactionType.endOfDay;
    String note;

    if (remainder > 0) {
      _savingsBalance += remainder;
      savingsDelta = remainder;
      note = 'Transferred to savings';
    } else if (remainder < 0) {
      _savingsBalance += remainder;
      savingsDelta = remainder;
      note = 'Covered daily deficit';
    } else {
      note = 'No transfer needed';
    }

    setState(() {
      _dailyBalance = 0;
      _history = [
        TransactionItem(
          amount: remainder.abs(),
          type: eventType,
          category: 'End of day',
          note: note,
          timestamp: DateTime.now(),
        ),
        if (savingsDelta != 0)
          TransactionItem(
            amount: savingsDelta.abs(),
            type: TransactionType.transfer,
            category: savingsDelta > 0 ? 'To savings' : 'From savings',
            note: savingsDelta > 0 ? 'Daily remainder transferred' : 'Daily deficit deducted',
            timestamp: DateTime.now(),
          ),
        ..._history,
      ];
    });

    await _saveState();
  }

  Map<DateTime, List<TransactionItem>> _groupTransactionsByDay() {
    final grouped = <DateTime, List<TransactionItem>>{};

    for (final transaction in _history) {
      final dayKey = DateTime(transaction.timestamp.year, transaction.timestamp.month, transaction.timestamp.day);
      grouped.putIfAbsent(dayKey, () => <TransactionItem>[]).add(transaction);
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((left, right) => right.key.compareTo(left.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    final groupedTransactions = _groupTransactionsByDay();
    final totalBalance = _dailyBalance + _savingsBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Money Manager'),
        actions: [
          IconButton(
            tooltip: widget.themeMode == ThemeMode.dark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: widget.onToggleThemeMode,
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Add transaction',
            onPressed: _openAddTransactionSheet,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: WalletCard(
                            title: 'Daily Wallet',
                            balance: _dailyBalance,
                            accentColor: _dailyBalance < 0 ? const Color(0xFFDC2626) : Theme.of(context).colorScheme.primary,
                            subtitle: 'Today's spending budget',
                            trailingButtonLabel: 'Withdraw',
                            trailingButtonIcon: Icons.payments_outlined,
                            onTrailingButtonPressed: _openWithdrawalSheet,
                            onLongPress: _openWithdrawalSheet,
                            isNegative: _dailyBalance < 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: WalletCard(
                            title: 'Savings Wallet',
                            balance: _savingsBalance,
                            accentColor: const Color(0xFF059669),
                            subtitle: 'Reserve from previous days',
                            trailingButtonLabel: 'Withdraw',
                            trailingButtonIcon: Icons.south_west_outlined,
                            onTrailingButtonPressed: _openWithdrawalSheet,
                            onLongPress: _openWithdrawalSheet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Combined Total',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(totalBalance),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _endDay,
                      icon: const Icon(Icons.nightlight_round),
                      label: const Text('End Day'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction History',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        TextButton.icon(
                          onPressed: _openAddTransactionSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (groupedTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No transactions yet. Add one to start tracking your day.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entries = groupedTransactions.entries.toList();
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _HistoryGroup(
                          date: entry.key,
                          transactions: entry.value,
                        ),
                      );
                    },
                    childCount: groupedTransactions.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransactionSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }
}

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.title,
    required this.balance,
    required this.accentColor,
    required this.subtitle,
    required this.trailingButtonLabel,
    required this.trailingButtonIcon,
    required this.onTrailingButtonPressed,
    required this.onLongPress,
    this.isNegative = false,
  });

  final String title;
  final double balance;
  final Color accentColor;
  final String subtitle;
  final String trailingButtonLabel;
  final IconData trailingButtonIcon;
  final VoidCallback onTrailingButtonPressed;
  final VoidCallback onLongPress;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isNegative ? accentColor.withOpacity(0.3) : Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(trailingButtonIcon, color: accentColor, size: 20),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onTrailingButtonPressed,
                  child: Text(trailingButtonLabel),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(balance),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isNegative ? Colors.redAccent : null,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionItem> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatDate(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${transactions.length} item${transactions.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...transactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransactionTile(transaction: transaction),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionItem transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income || transaction.type == TransactionType.transfer && transaction.category == 'To savings';
    final color = switch (transaction.type) {
      TransactionType.income => const Color(0xFF059669),
      TransactionType.expense => const Color(0xFFDC2626),
      TransactionType.transfer => const Color(0xFF2563EB),
      TransactionType.withdrawal => const Color(0xFF7C3AED),
      TransactionType.endOfDay => const Color(0xFF0F766E),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForTransaction(transaction.type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.displayTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  transaction.displaySubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome || transaction.type == TransactionType.transfer && transaction.category == 'To savings' ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(transaction.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount greater than zero.')));
      return;
    }

    Navigator.of(context).pop(
      _TransactionInputResult(
        amount: amount,
        type: _selectedType,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Add Transaction', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 14),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment<TransactionType>(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment<TransactionType>(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
            ],
          ),
        ),
      ),
    );
  }
}

class WithdrawalSheet extends StatefulWidget {
  const WithdrawalSheet({super.key});

  @override
  State<WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<WithdrawalSheet> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid withdrawal amount.')));
      return;
    }

    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Withdraw from Savings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionInputResult {
  const _TransactionInputResult({
    required this.amount,
    required this.type,
    this.category,
    this.note,
  });

  final double amount;
  final TransactionType type;
  final String? category;
  final String? note;
}

IconData _iconForTransaction(TransactionType type) {
  return switch (type) {
    TransactionType.income => Icons.arrow_downward,
    TransactionType.expense => Icons.arrow_upward,
    TransactionType.transfer => Icons.swap_horiz,
    TransactionType.withdrawal => Icons.south_west,
    TransactionType.endOfDay => Icons.bedtime,
  };
}

String _formatCurrency(double amount) {
  final formatted = amount.abs().toStringAsFixed(2);
  return '\$${formatted}';
}

String _formatDate(DateTime date) {
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} • ${_formatTime(date)}';
}
