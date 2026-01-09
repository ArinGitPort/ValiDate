import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/warranty_provider.dart';
import '../models/activity_log.dart';
import '../widgets/page_header.dart';

class LogHistoryScreen extends StatelessWidget {
  const LogHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<WarrantyProvider>(
          builder: (context, provider, child) {
            final logs = provider.logs;

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: PageHeader(
                    title: "History",
                    notificationCount: 0, 
                  ),
                ),
                if (logs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.history, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            "No activity yet",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildLogList(logs),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogList(List<ActivityLog> logs) {
    // Group logs by day
    final Map<String, List<ActivityLog>> groupedLogs = {};
    
    for (var log in logs) {
      final dateKey = _getDateKey(log.timestamp);
      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final key = groupedLogs.keys.elementAt(index);
            final dayLogs = groupedLogs[key]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    key.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...dayLogs.map((log) => _buildLogItem(log)),
              ],
            );
          },
          childCount: groupedLogs.length,
        ),
      ),
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) return "Today";
    if (logDate == yesterday) return "Yesterday";
    return DateFormat('MMMM d, y').format(date);
  }

  Widget _buildLogItem(ActivityLog log) {
    IconData icon;
    Color color;

    switch (log.actionType) {
      case "added":
        icon = LucideIcons.circle_plus;
        color = Colors.green;
        break;
      case "archived":
        icon = LucideIcons.archive;
        color = Colors.orange;
        break;
      case "unarchived":
        icon = LucideIcons.archive_restore;
        color = Colors.blue;
        break;
      case "deleted":
        icon = LucideIcons.trash_2;
        color = Colors.red;
        break;
      default:
        icon = LucideIcons.activity;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(log.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
