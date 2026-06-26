import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(Duration.zero);
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
      cardTheme: CardThemeData(
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
      cardTheme: CardThemeData(
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
    this.isStartingBudget = false,
  });

  final double amount;
  final TransactionType type;
  final String? category;
  final String? note;
  final DateTime timestamp;
  final bool isStartingBudget;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'type': type.name,
      'category': category,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'isStartingBudget': isStartingBudget,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final parsedType = TransactionType.values.firstWhere(
      (type) => type.name == rawType,
      orElse: () => TransactionType.expense,
    );

    return TransactionItem(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: parsedType,
      category: json['category'] as String? ?? '',
      note: json['note'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isStartingBudget: json['isStartingBudget'] as bool? ?? false,
    );
  }

  String get displayTitle {
    switch (type) {
      case TransactionType.income:
        return isStartingBudget ? 'Starting Budget' : 'Income';
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
  static const String _isDayActiveKey = 'isDayActive';
  static const String _dayStartBudgetKey = 'dayStartBudget';

  double _dailyBalance = 0;
  double _savingsBalance = 0;
  double _dayStartBudget = 0;
  bool _isDayActive = false;
  bool _isLoading = true;
  List<TransactionItem> _history = <TransactionItem>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<TransactionItem> parsedHistory = <TransactionItem>[];

    try {
      final historyJson = prefs.getString(_historyKey);
      final decodedHistory = historyJson == null ? <dynamic>[] : jsonDecode(historyJson) as List<dynamic>;

      parsedHistory = decodedHistory
          .whereType<Map<String, dynamic>>()
          .map(TransactionItem.fromJson)
          .toList()
        ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
    } catch (_) {
      parsedHistory = <TransactionItem>[];
      await prefs.setString(_historyKey, '[]');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyBalance = prefs.getDouble(_dailyBalanceKey) ?? 0;
      _savingsBalance = prefs.getDouble(_savingsBalanceKey) ?? 0;
      _dayStartBudget = prefs.getDouble(_dayStartBudgetKey) ?? 0;
      _isDayActive = prefs.getBool(_isDayActiveKey) ?? false;
      _history = parsedHistory;
      _isLoading = false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyBalanceKey, _dailyBalance);
    await prefs.setDouble(_savingsBalanceKey, _savingsBalance);
    await prefs.setDouble(_dayStartBudgetKey, _dayStartBudget);
    await prefs.setBool(_isDayActiveKey, _isDayActive);
    await prefs.setString(
      _historyKey,
      jsonEncode(_history.map((transaction) => transaction.toJson()).toList()),
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  DateTime? get _activeDayDate {
    final startingBudgetTransaction = _history.cast<TransactionItem?>().firstWhere(
          (transaction) => transaction?.isStartingBudget == true,
          orElse: () => null,
        );
    return startingBudgetTransaction == null
        ? null
        : DateTime(
            startingBudgetTransaction.timestamp.year,
            startingBudgetTransaction.timestamp.month,
            startingBudgetTransaction.timestamp.day,
          );
  }

  List<TransactionItem> get _activeDayTransactions {
    final activeDayDate = _activeDayDate;
    if (activeDayDate == null) {
      return <TransactionItem>[];
    }
    return _history.where((transaction) => _isSameDay(transaction.timestamp, activeDayDate)).toList();
  }

  Map<DateTime, List<TransactionItem>> _groupTransactionsByDay(List<TransactionItem> transactions) {
    final grouped = <DateTime, List<TransactionItem>>{};
    for (final transaction in transactions) {
      final dayKey = DateTime(transaction.timestamp.year, transaction.timestamp.month, transaction.timestamp.day);
      grouped.putIfAbsent(dayKey, () => <TransactionItem>[]).add(transaction);
    }
    return Map.fromEntries(grouped.entries.toList()..sort((left, right) => right.key.compareTo(left.key)));
  }

  Future<void> _startDay(double budgetAmount) async {
    final transaction = TransactionItem(
      amount: budgetAmount,
      type: TransactionType.income,
      category: 'Start Day Budget',
      note: 'Daily budget started',
      timestamp: DateTime.now(),
      isStartingBudget: true,
    );

    setState(() {
      _dayStartBudget = budgetAmount;
      _isDayActive = true;
      _dailyBalance += budgetAmount;
      _history = [transaction, ..._history];
    });

    await _saveState();
  }

  Future<void> _openAddTransactionSheet() async {
    if (!_isDayActive) {
      return;
    }

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
    if (!_isDayActive) {
      return;
    }

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

  void _recomputeDailyBalance() {
    final activeDayTransactions = _activeDayTransactions
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double balance = 0;
    for (final t in activeDayTransactions) {
      if (t.type == TransactionType.income) {
        balance += t.amount;
      } else if (t.type == TransactionType.expense) {
        balance -= t.amount;
      }
    }
    _dailyBalance = balance;
  }

  Future<void> _openEditTransactionSheet(TransactionItem transaction) async {
    final isEditable = transaction.type == TransactionType.income ||
        transaction.type == TransactionType.expense;

    if (!isEditable) return;

    final result = await showModalBottomSheet<_EditTransactionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTransactionSheet(transaction: transaction),
    );

    if (result == null) return;

    setState(() {
      if (result.deleted) {
        _history = _history
            .where((t) => t != transaction)
            .toList();
      } else {
        final index = _history.indexOf(transaction);
        if (index != -1) {
          _history[index] = TransactionItem(
            amount: result.amount,
            type: transaction.type,
            category: result.category,
            note: result.note,
            timestamp: transaction.timestamp,
            isStartingBudget: transaction.isStartingBudget,
          );
          if (transaction.isStartingBudget) {
            _dayStartBudget = result.amount;
          }
        }
      }
      _recomputeDailyBalance();
    });

    await _saveState();
  }

  Future<void> _openStartDaySheet() async {
    if (_isDayActive) {
      return;
    }

    final budgetAmount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StartDaySheet(),
    );

    if (budgetAmount == null) {
      return;
    }

    await _startDay(budgetAmount);
  }

  Future<void> _openTransactionHistory() async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TransactionHistorySheet(
      groupedTransactions: _groupTransactionsByDay(_history),
      ),
    );
  }

  Future<void> _openDaySummary() async {
    if (!_isDayActive) return;

    final activeDayTransactions = _activeDayTransactions;

    final totalExpenses = activeDayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncome = activeDayTransactions
        .where((t) => t.type == TransactionType.income && !t.isStartingBudget)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final finalDailyBalance = _dailyBalance;
    final double amountTransferred = finalDailyBalance > 0 ? finalDailyBalance : 0.0;
    final double amountDeducted = finalDailyBalance < 0 ? finalDailyBalance.abs() : 0.0;
    final endingSavingsBalance = _savingsBalance + finalDailyBalance;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DaySummarySheet(
        summary: DaySummaryData(
          date: DateTime.now(),
          startingBudget: _dayStartBudget,
          totalExpenses: totalExpenses,
          totalMidDayIncome: totalIncome,
          finalDailyBalance: finalDailyBalance,
          amountTransferredToSavings: amountTransferred,
          amountDeductedFromSavings: amountDeducted,
          endingSavingsBalance: endingSavingsBalance,
        ),
        onDone: _completeDay,
      ),
    );
  }

  Future<void> _completeDay() async {
    final remainder = _dailyBalance;

    setState(() {
      if (remainder != 0) {
        _savingsBalance += remainder;
        _history = [
          TransactionItem(
            amount: remainder.abs(),
            type: TransactionType.transfer,
            category: remainder > 0 ? 'To savings' : 'From savings',
            note: remainder > 0 ? 'Daily remainder transferred' : 'Daily deficit deducted',
            timestamp: DateTime.now(),
          ),
          ..._history,
        ];
      }

      _history = [
        TransactionItem(
          amount: remainder.abs(),
          type: TransactionType.endOfDay,
          category: 'End of day',
          note: remainder > 0
              ? 'Transferred to savings'
              : remainder < 0
                  ? 'Covered daily deficit'
                  : 'No transfer needed',
          timestamp: DateTime.now(),
        ),
        ..._history,
      ];

      _dailyBalance = 0;
      _dayStartBudget = 0;
      _isDayActive = false;
    });

    await _saveState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Money Manager'),
        actions: [
          IconButton(
            tooltip: 'Transaction history',
            onPressed: () => _openTransactionHistory(),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: widget.themeMode == ThemeMode.dark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: widget.onToggleThemeMode,
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          if (_isDayActive)
            IconButton(
              tooltip: 'Add transaction',
              onPressed: _openAddTransactionSheet,
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: _isDayActive
            ? _ActiveDayView(
                dailyBalance: _dailyBalance,
                savingsBalance: _savingsBalance,
                groupedTransactions: _groupTransactionsByDay(_activeDayTransactions),
                onAddTransaction: _openAddTransactionSheet,
                onWithdraw: _openWithdrawalSheet,
                onEndDay: _openDaySummary,
                onOpenHistory: _openTransactionHistory,
                onTransactionTap: _openEditTransactionSheet,
                formatCurrency: _formatCurrency,
              )
            : _StartOfDayView(
                savingsBalance: _savingsBalance,
                onStartDay: _openStartDaySheet,
                onOpenHistory: _openTransactionHistory,
                formatCurrency: _formatCurrency,
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDayActive ? _openAddTransactionSheet : _openStartDaySheet,
        icon: const Icon(Icons.add),
        label: Text(_isDayActive ? 'Add Transaction' : 'Start Day'),
      ),
    );
  }
}

class _StartOfDayView extends StatelessWidget {
  const _StartOfDayView({
    required this.savingsBalance,
    required this.onStartDay,
    required this.onOpenHistory,
    required this.formatCurrency,
  });

  final double savingsBalance;
  final VoidCallback onStartDay;
  final VoidCallback onOpenHistory;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Savings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${savingsBalance < 0 ? '-' : ''}${formatCurrency(savingsBalance)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: savingsBalance < 0 ? Colors.redAccent : null,
                        ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your savings reserve',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onStartDay,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Start Day'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onOpenHistory,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Transaction History'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveDayView extends StatelessWidget {
  const _ActiveDayView({
    required this.dailyBalance,
    required this.savingsBalance,
    required this.groupedTransactions,
    required this.onAddTransaction,
    required this.onWithdraw,
    required this.onEndDay,
    required this.onOpenHistory,
    required this.formatCurrency,
    required this.onTransactionTap
  });

  final double dailyBalance;
  final double savingsBalance;
  final Map<DateTime, List<TransactionItem>> groupedTransactions;
  final VoidCallback onAddTransaction;
  final VoidCallback onWithdraw;
  final VoidCallback onEndDay;
  final VoidCallback onOpenHistory;
  final String Function(double value) formatCurrency;

  final void Function(TransactionItem) onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final totalBalance = dailyBalance + savingsBalance;
    final entries = groupedTransactions.entries.toList();

    return Padding(
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
                        balance: dailyBalance,
                        accentColor: dailyBalance < 0 ? const Color(0xFFDC2626) : Theme.of(context).colorScheme.primary,
                        subtitle: "Today's spending budget",
                        trailingButtonLabel: 'Withdraw',
                        trailingButtonIcon: Icons.payments_outlined,
                        onTrailingButtonPressed: onWithdraw,
                        onLongPress: onWithdraw,
                        isNegative: dailyBalance < 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WalletCard(
                        title: 'Savings Wallet',
                        balance: savingsBalance,
                        accentColor: savingsBalance < 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        subtitle: 'Reserve from previous days',
                        trailingButtonLabel: 'Withdraw',
                        trailingButtonIcon: Icons.south_west_outlined,
                        onTrailingButtonPressed: onWithdraw,
                        onLongPress: onWithdraw,
                        isNegative: savingsBalance < 0,
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
                    border: Border.all(
                      color: totalBalance < 0
                          ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                          : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: totalBalance < 0
                              ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: totalBalance < 0
                              ? const Color(0xFFDC2626)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Combined Total',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalBalance < 0 ? '-' : ''}${formatCurrency(totalBalance)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: totalBalance < 0 ? Colors.redAccent : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onEndDay,
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
                      onPressed: onOpenHistory,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('History'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No transactions yet. Start the day to begin tracking.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _HistoryGroup(
                      date: entry.key,
                      transactions: entry.value,
                      onTransactionTap: onTransactionTap,
                    ),
                  );
                },
                childCount: entries.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }
}

class StartDaySheet extends StatefulWidget {
  const StartDaySheet({super.key});

  @override
  State<StartDaySheet> createState() => _StartDaySheetState();
}

class _StartDaySheetState extends State<StartDaySheet> {
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = double.tryParse(_budgetController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid budget amount.')));
      return;
    }

    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              Text('Start Day', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Today's budget amount"),
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

class TransactionHistorySheet extends StatelessWidget {
  const TransactionHistorySheet({super.key, required this.groupedTransactions});

  final Map<DateTime, List<TransactionItem>> groupedTransactions;

  @override
  Widget build(BuildContext context) {
    final entries = groupedTransactions.entries.toList();

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                  Row(
                    children: [
                      Text('Transaction History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Text(
                        'No transactions yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
                      ),
                    )
                  else
                    ...entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _HistoryGroup(
                          date: entry.key,
                          transactions: entry.value,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DaySummaryData {
  const DaySummaryData({
    required this.date,
    required this.startingBudget,
    required this.totalExpenses,
    required this.totalMidDayIncome,
    required this.finalDailyBalance,
    required this.amountTransferredToSavings,
    required this.amountDeductedFromSavings,
    required this.endingSavingsBalance,
  });

  final DateTime date;
  final double startingBudget;
  final double totalExpenses;
  final double totalMidDayIncome;
  final double finalDailyBalance;
  final double amountTransferredToSavings;
  final double amountDeductedFromSavings;
  final double endingSavingsBalance;
}

class DaySummarySheet extends StatelessWidget {
  const DaySummarySheet({super.key, required this.summary, required this.onDone});

  final DaySummaryData summary;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          shrinkWrap: true,
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
            Text(
              '${_formatDate(summary.date)} Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SummaryRow(label: 'Starting budget', value: _formatCurrency(summary.startingBudget)),
            SummaryRow(label: 'Total expenses', value: _formatCurrency(summary.totalExpenses)),
            SummaryRow(label: 'Total income added mid-day', value: _formatCurrency(summary.totalMidDayIncome)),
            SummaryRow(label: 'Final Daily Wallet balance', value: _formatCurrency(summary.finalDailyBalance)),
            SummaryRow(
              label: summary.finalDailyBalance >= 0 ? 'Amount transferred to Savings' : 'Amount deducted from Savings',
              value: _formatCurrency(summary.finalDailyBalance.abs()),
            ),
            SummaryRow(label: 'Ending Savings Wallet balance', value: _formatCurrency(summary.endingSavingsBalance)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await onDone();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
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
            color: isNegative ? accentColor.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.4),
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
                    color: accentColor.withValues(alpha: 0.12),
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
              '${balance < 0 ? '-' : ''}${_formatCurrency(balance)}',
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
  const _HistoryGroup({
    required this.date,
    required this.transactions,
    this.onTransactionTap,
  });

  final DateTime date;
  final List<TransactionItem> transactions;
  final void Function(TransactionItem)? onTransactionTap; 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
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
              child: TransactionTile(
                transaction: transaction,
                onTap: onTransactionTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final TransactionItem transaction;
  final void Function(TransactionItem)? onTap;

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

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(transaction) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                  '${isIncome || transaction.type == TransactionType.transfer && transaction.category == "To savings" ? '+' : '-'}${_formatCurrency(transaction.amount)}',
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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

class EditTransactionSheet extends StatefulWidget {
  const EditTransactionSheet({super.key, required this.transaction});

  final TransactionItem transaction;

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount % 1 == 0 
        ? widget.transaction.amount.toInt().toString()
        : widget.transaction.amount.toString()
    );
    _categoryController = TextEditingController(
      text: widget.transaction.category ?? '',
    );
    _noteController = TextEditingController(
      text: widget.transaction.note ?? '',
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than zero.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _EditTransactionResult(
        amount: amount,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        deleted: false,
      ),
    );
  }

  void _delete() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will remove the transaction and recalculate your balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        Navigator.of(context).pop(
          _EditTransactionResult(
            amount: widget.transaction.amount,
            category: widget.transaction.category,
            note: widget.transaction.note,
            deleted: true,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStartingBudget = widget.transaction.isStartingBudget;
    final canDelete = !isStartingBudget;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              Text(
                'Edit Transaction',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              if (!isStartingBudget) ...[
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
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _confirm,
                child: const Text('Save Changes'),
              ),
              if (canDelete) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Delete Transaction'),
                ),
              ],
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

class _EditTransactionResult {
  const _EditTransactionResult({
    required this.amount,
    required this.category,
    required this.note,
    required this.deleted,
  });

  final double amount;
  final String? category;
  final String? note;
  final bool deleted;
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
  return '₱$formatted';
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