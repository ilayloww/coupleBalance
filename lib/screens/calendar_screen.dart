import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:couple_balance/utils/date_time_utils.dart';
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
    if (kDebugMode) {
      debugPrint('Calendar Stream Error: $e');
    }
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

  double _calculateDailyTotal(DateTime day) {
    final transactions = _getEventsForDay(day);
    double dailyTotal = 0;
    for (var tx in transactions) {
      if (tx.senderUid == widget.userUid) {
        dailyTotal += tx.amount;
      } else {
        dailyTotal -= tx.amount;
      }
    }
    return dailyTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05100A), // Dark Background
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF05100A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Calendar - No Container
          TableCalendar<TransactionModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            locale: AppLocalizations.of(context)!.localeName,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableGestures: AvailableGestures.all,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF2ECC71), // Emerald Green
                fontWeight: FontWeight.bold,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFF2ECC71), // Emerald Green
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              // Selected Day
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF2ECC71), // Emerald Green
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.black, // Dark text on green
                fontWeight: FontWeight.bold,
              ),
              // Today
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              // Markers
              markersMaxCount: 1,
              markersAlignment: Alignment.bottomCenter,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) {
                  return const SizedBox();
                }
                final total = _calculateDailyTotal(date);
                if (total == 0) {
                  return const SizedBox(); // Or show a neutral dot
                }

                return Positioned(
                  bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: total < 0
                          ? Colors.redAccent
                          : const Color(0xFF2ECC71),
                    ),
                    width: 7.0,
                    height: 7.0,
                  ),
                );
              },
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
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                  )
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
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
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTransactionsToday,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate daily total (Net balance change for the user)
    // If I paid, I am owed (+)
    // If Partner paid, I owe (-)
    double dailyTotal = 0;
    for (var tx in transactions) {
      if (tx.senderUid == widget.userUid) {
        dailyTotal += tx.amount;
      } else {
        dailyTotal -= tx.amount;
      }
    }

    final isNegative = dailyTotal < 0;
    final displayColor = isNegative
        ? Colors.redAccent
        : const Color(0xFF2ECC71);

    final dateStr = DateFormat(
      'MMM d',
      AppLocalizations.of(context)!.localeName,
    ).format(_selectedDay!);

    return Column(
      children: [
        // Daily Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transactions for $dateStr",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${dailyTotal.toStringAsFixed(2)} Total",
                  style: TextStyle(
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 100, // Padding for BottomNav
            ),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = transactions[index];

              // Determine Icon
              IconData iconData = Icons.receipt;
              final lowerNote = tx.note.toLowerCase();
              if (lowerNote.contains('food') || lowerNote.contains('grocery')) {
                iconData = Icons.shopping_basket;
              } else if (lowerNote.contains('movie') ||
                  lowerNote.contains('cinema')) {
                iconData =
                    Icons.local_activity; // Ticket icon looks better for movies
              } else if (lowerNote.contains('dinner') ||
                  lowerNote.contains('restaurant')) {
                iconData = Icons.restaurant;
              }

              return InkWell(
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
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B3B24), // Darker green bg
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconData,
                          color: const Color(0xFF2ECC71), // Emerald Icon
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.note,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              // Using hardcoded string/business name simulation or just reuse note/category
                              "Transaction",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Amount & Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "-${tx.amount.toStringAsFixed(2)}", // Assuming expense logic
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateTimeUtils.formatTime(context, tx.timestamp),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
