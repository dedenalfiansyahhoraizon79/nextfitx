import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  String _searchQuery = '';
  NotificationType? _selectedType;

  late TabController _tabController;

  final List<NotificationType> _filterTypes = [
    NotificationType.general,
    NotificationType.water,
    NotificationType.workout,
    NotificationType.meal,
    NotificationType.sleep,
    NotificationType.fasting,
    NotificationType.achievement,
    NotificationType.system,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);

      final notifications =
          await _notificationService.getUserNotifications(limit: 100);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _filteredNotifications = notifications;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredNotifications = _notifications.where((notification) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          if (!notification.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) &&
              !notification.message
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Unread filter
        if (_showUnreadOnly && notification.isRead) {
          return false;
        }

        // Type filter
        if (_selectedType != null && notification.type != _selectedType) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead || notification.id == null) return;

    try {
      await _notificationService.markAsRead(notification.id!);
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking all as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    if (notification.id == null) return;

    try {
      await _notificationService.deleteNotification(notification.id!);
      await _loadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _notificationService.deleteAllNotifications();
        await _loadNotifications();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting all notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateSampleNotifications() async {
    try {
      await _notificationService.generateSampleNotifications();
      await _loadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample notifications generated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: TColor.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Mark all as read
          IconButton(
            onPressed:
                _notifications.any((n) => !n.isRead) ? _markAllAsRead : null,
            icon: Icon(
              Icons.done_all,
              color: _notifications.any((n) => !n.isRead)
                  ? TColor.primaryColor1
                  : TColor.gray,
            ),
          ),
          // Options menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete_all':
                  _deleteAllNotifications();
                  break;
                case 'generate_sample':
                  _generateSampleNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate_sample',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Add Samples'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: TColor.primaryColor1,
          unselectedLabelColor: TColor.gray,
          indicatorColor: TColor.primaryColor1,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications),
                  const SizedBox(width: 4),
                  Text('All (${_notifications.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle),
                  const SizedBox(width: 4),
                  Text(
                      'Unread (${_notifications.where((n) => !n.isRead).length})'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 4),
                  Text('Filter'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(false), // All notifications
                _buildNotificationsList(true), // Unread only
                _buildFiltersTab(), // Filters
              ],
            ),
    );
  }

  Widget _buildNotificationsList(bool unreadOnly) {
    final notifications = unreadOnly
        ? _filteredNotifications.where((n) => !n.isRead).toList()
        : _filteredNotifications;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unreadOnly ? Icons.mark_email_read : Icons.notifications_none,
              size: 80,
              color: TColor.gray,
            ),
            const SizedBox(height: 16),
            Text(
              unreadOnly ? 'No unread notifications' : 'No notifications yet',
              style: TextStyle(
                color: TColor.gray,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unreadOnly
                  ? 'All caught up! 🎉'
                  : 'Notifications will appear here',
              style: TextStyle(
                color: TColor.gray.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : TColor.primaryColor1.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? TColor.lightGray
              : TColor.primaryColor1.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type icon and priority indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.type.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: TColor.primaryColor1,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              notification.type.displayName,
                              style: TextStyle(
                                color: _getTypeColor(notification.type),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                color: TColor.gray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Priority indicator
                  if (notification.priority.level > 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notification.priority),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.priority.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                notification.message,
                style: TextStyle(
                  color: TColor.black.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              // Action buttons
              if (notification.isActionable) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Handle action
                        _notificationService
                            .handleNotificationAction(notification);
                        _markAsRead(notification);
                      },
                      icon: const Icon(Icons.touch_app, size: 16),
                      label: const Text('Take Action'),
                      style: TextButton.styleFrom(
                        foregroundColor: TColor.primaryColor1,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _deleteNotification(notification),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search notifications...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColor.lightGray),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
          ),

          const SizedBox(height: 20),

          // Filter by type
          Text(
            'Filter by Type',
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (selected) {
                  setState(() => _selectedType = null);
                  _applyFilters();
                },
                selectedColor: TColor.primaryColor1.withOpacity(0.2),
                checkmarkColor: TColor.primaryColor1,
              ),
              ..._filterTypes.map((type) => FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji),
                        const SizedBox(width: 4),
                        Text(type.displayName),
                      ],
                    ),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() => _selectedType = selected ? type : null);
                      _applyFilters();
                    },
                    selectedColor: _getTypeColor(type).withOpacity(0.2),
                    checkmarkColor: _getTypeColor(type),
                  )),
            ],
          ),

          const SizedBox(height: 20),

          // Show unread only toggle
          SwitchListTile(
            title: const Text('Show unread only'),
            subtitle: const Text('Hide notifications you\'ve already read'),
            value: _showUnreadOnly,
            onChanged: (value) {
              setState(() => _showUnreadOnly = value);
              _applyFilters();
            },
            activeColor: TColor.primaryColor1,
          ),

          const SizedBox(height: 20),

          // Quick actions
          Text(
            'Quick Actions',
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark All Read'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateSampleNotifications,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Samples'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.water:
        return const Color(0xFF00BCD4);
      case NotificationType.workout:
        return Colors.orange;
      case NotificationType.meal:
        return const Color(0xFF4CAF50);
      case NotificationType.sleep:
        return const Color(0xFF9C27B0);
      case NotificationType.fasting:
        return const Color(0xFF6A5ACD);
      case NotificationType.bodyComp:
        return TColor.primaryColor1;
      case NotificationType.achievement:
        return const Color(0xFFFFD700);
      case NotificationType.system:
        return const Color(0xFF607D8B);
      default:
        return TColor.gray;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.low:
        return Colors.grey;
    }
  }
}
