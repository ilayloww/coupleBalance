import 'package:flutter/material.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../models/transaction_model.dart';
import 'transaction_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final String userUid;
  final String partnerUid;

  const CalendarScreen({
    super.key,
    required this.userUid,
    required this.partnerUid,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TransactionModel>> _events = {};
  StreamSubscription? _sentSub;
  StreamSubscription? _receivedSub;
  List<DocumentSnapshot> _sentDocs = [];
  List<DocumentSnapshot> _receivedDocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initStreams();
  }

  @override
  void dispose() {
    _sentSub?.cancel();
    _receivedSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.partnerUid != oldWidget.partnerUid ||
        widget.userUid != oldWidget.userUid) {
      _sentSub?.cancel();
      _receivedSub?.cancel();
      _initStreams();
    }
  }

  void _initStreams() {
    setState(() {
      _isLoading = true;
    });

    // Stream 1: Sent by me
    _sentSub = FirebaseFirestore.instance
        .collection('transactions')
        .where('senderUid', isEqualTo: widget.userUid)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .listen((snapshot) {
          _sentDocs = snapshot.docs;
          _processUpdates();
        }, onError: _handleError);

    // Stream 2: Received by me
    _receivedSub = FirebaseFirestore.instance
        .collection('transactions')
        .where('receiverUid', isEqualTo: widget.userUid)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .listen((snapshot) {
          _receivedDocs = snapshot.docs;
          _processUpdates();
        }, onError: _handleError);
  }

  void _handleError(dynamic e) {
    debugPrint('Calendar Stream Error: $e');
    if (!mounted) return;

    if (e.toString().contains('failed-precondition') ||
        e.toString().contains('index')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Database Index'),
          content: const Text(
            'The app is missing a required database index.\n\n'
            'Please check your terminal logs for the creation link.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _processUpdates() {
    if (!mounted) return;

    final allDocs = [..._sentDocs, ..._receivedDocs];
    final Map<DateTime, List<TransactionModel>> newEvents = {};

    // Deduplicate by ID
    final uniqueDocs = {for (var doc in allDocs) doc.id: doc}.values;

    for (var doc in uniqueDocs) {
      final data = doc.data() as Map<String, dynamic>;

      final sender = data['senderUid'];
      final receiver = data['receiverUid'];

      if ((sender == widget.partnerUid || receiver == widget.partnerUid) &&
          data['isDeleted'] != true) {
        final tx = TransactionModel.fromMap(data, doc.id);

        // Normalize date to UTC for TableCalendar
        final date = DateTime.utc(
          tx.timestamp.year,
          tx.timestamp.month,
          tx.timestamp.day,
        );

        if (newEvents[date] == null) {
          newEvents[date] = [];
        }
        newEvents[date]!.add(tx);
      }
    }

    setState(() {
      _events = newEvents;
      _isLoading = false;
    });
  }

  List<TransactionModel> _getEventsForDay(DateTime day) {
    // USE UTC for lookup to match the keys
    final date = DateTime.utc(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar<TransactionModel>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              locale: AppLocalizations.of(context)!.localeName,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: primaryColor,
                ),
              ),
              calendarStyle: CalendarStyle(
                // Modern Markers
                markerDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 4,
                markersAlignment: Alignment.bottomCenter,

                // Selected Day
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withValues(alpha: 0.7), primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),

                // Today
                todayDecoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                // No need to fetch, we have streams.
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTransactionList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isDark) {
    if (_selectedDay == null) return const SizedBox();

    // Normalize date for lookup (UTC)
    final date = DateTime.utc(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final transactions = _events[date] ?? [];

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTransactionsToday,
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isMe = tx.senderUid == widget.userUid;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final secondaryColor = Theme.of(context).colorScheme.secondary;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          color: Theme.of(context).cardColor,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(
                    transaction: tx,
                    currentUserId: widget.userUid,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: isMe
                  ? primaryColor.withValues(alpha: 0.1)
                  : secondaryColor.withValues(alpha: 0.1),
              child: Icon(
                isMe ? Icons.arrow_outward : Icons.arrow_downward,
                color: isMe ? primaryColor : secondaryColor,
              ),
            ),
            title: Text(
              tx.note,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat.Hm(
                AppLocalizations.of(context)!.localeName,
              ).format(tx.timestamp), // Show Time
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              '${isMe ? '+' : '-'}${tx.amount % 1 == 0 ? tx.amount.toInt().toString() : tx.amount.toString()} ${tx.currency}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isMe ? primaryColor : secondaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
