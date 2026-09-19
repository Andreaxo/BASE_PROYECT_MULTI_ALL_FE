import 'package:flutter/material.dart';

class IconLibrary {
  static const Map<String, IconData> icons = {
    // Basic / Navigation
    'home_rounded': Icons.home_rounded,
    'menu_rounded': Icons.menu_rounded,
    'grid_view_rounded': Icons.grid_view_rounded,
    'apps_rounded': Icons.apps_rounded,
    'dashboard_rounded': Icons.dashboard_rounded,
    'list_rounded': Icons.list_rounded,
    'view_list_rounded': Icons.view_list_rounded,
    'view_module_rounded': Icons.view_module_rounded,
    'share_rounded': Icons.share_rounded,
    
    // Admin / Org
    'people_rounded': Icons.people_rounded,
    'person_rounded': Icons.person_rounded,
    'group_rounded': Icons.group_rounded,
    'business_rounded': Icons.business_rounded,
    'store_rounded': Icons.store_rounded,
    'apartment_rounded': Icons.apartment_rounded,
    'admin_panel_settings_rounded': Icons.admin_panel_settings_rounded,
    'badge_rounded': Icons.badge_rounded,
    
    // Inventory / Catalog
    'inventory_rounded': Icons.inventory_rounded,
    'inventory_2_rounded': Icons.inventory_2_rounded,
    'category_rounded': Icons.category_rounded,
    'article_rounded': Icons.article_rounded,
    'receipt_long_rounded': Icons.receipt_long_rounded,
    'receipt_rounded': Icons.receipt_rounded,
    'shopping_bag_rounded': Icons.shopping_bag_rounded,
    'shopping_cart_rounded': Icons.shopping_cart_rounded,
    
    // Settings / Actions
    'settings_rounded': Icons.settings_rounded,
    'settings_applications_rounded': Icons.settings_applications_rounded,
    'build_rounded': Icons.build_rounded,
    'construction_rounded': Icons.construction_rounded,
    'security_rounded': Icons.security_rounded,
    'lock_rounded': Icons.lock_rounded,
    'lock_open_rounded': Icons.lock_open_rounded,
    'key_rounded': Icons.key_rounded,
    
    // Finance
    'payments_rounded': Icons.payments_rounded,
    'attach_money_rounded': Icons.attach_money_rounded,
    'credit_card_rounded': Icons.credit_card_rounded,
    'account_balance_rounded': Icons.account_balance_rounded,
    'account_balance_wallet_rounded': Icons.account_balance_wallet_rounded,
    'request_quote_rounded': Icons.request_quote_rounded,
    'analytics_rounded': Icons.analytics_rounded,
    'bar_chart_rounded': Icons.bar_chart_rounded,
    'pie_chart_rounded': Icons.pie_chart_rounded,
    'show_chart_rounded': Icons.show_chart_rounded,
    'trending_up_rounded': Icons.trending_up_rounded,
    'trending_down_rounded': Icons.trending_down_rounded,
    
    // Communication / Media
    'mail_rounded': Icons.mail_rounded,
    'email_rounded': Icons.email_rounded,
    'call_rounded': Icons.call_rounded,
    'chat_rounded': Icons.chat_rounded,
    'message_rounded': Icons.message_rounded,
    'forum_rounded': Icons.forum_rounded,
    'notifications_rounded': Icons.notifications_rounded,
    'translate_rounded': Icons.translate_rounded,
    'language_rounded': Icons.language_rounded,
    'image_rounded': Icons.image_rounded,
    'photo_camera_rounded': Icons.photo_camera_rounded,
    'videocam_rounded': Icons.videocam_rounded,
    
    // Tools / Docs
    'assignment_rounded': Icons.assignment_rounded,
    'assignment_turned_in_rounded': Icons.assignment_turned_in_rounded,
    'task_rounded': Icons.task_rounded,
    'note_rounded': Icons.note_rounded,
    'description_rounded': Icons.description_rounded,
    'folder_rounded': Icons.folder_rounded,
    'folder_open_rounded': Icons.folder_open_rounded,
    'attach_file_rounded': Icons.attach_file_rounded,
    'link_rounded': Icons.link_rounded,
    'qr_code_scanner_rounded': Icons.qr_code_scanner_rounded,
    'qr_code_2_rounded': Icons.qr_code_2_rounded,
    
    // Logistics / Maps
    'local_shipping_rounded': Icons.local_shipping_rounded,
    'delivery_dining_rounded': Icons.delivery_dining_rounded,
    'map_rounded': Icons.map_rounded,
    'location_on_rounded': Icons.location_on_rounded,
    'pin_drop_rounded': Icons.pin_drop_rounded,
    'navigation_rounded': Icons.navigation_rounded,
    'explore_rounded': Icons.explore_rounded,
    'flight_rounded': Icons.flight_rounded,
    
    // Tech
    'computer_rounded': Icons.computer_rounded,
    'desktop_windows_rounded': Icons.desktop_windows_rounded,
    'laptop_mac_rounded': Icons.laptop_mac_rounded,
    'smartphone_rounded': Icons.smartphone_rounded,
    'tablet_rounded': Icons.tablet_rounded,
    'watch_rounded': Icons.watch_rounded,
    'headset_rounded': Icons.headset_rounded,
    'wifi_rounded': Icons.wifi_rounded,
    'cloud_rounded': Icons.cloud_rounded,
    
    // Helpers / Support
    'info_rounded': Icons.info_rounded,
    'help_rounded': Icons.help_rounded,
    'help_outline_rounded': Icons.help_outline_rounded,
    'feedback_rounded': Icons.feedback_rounded,
    'contact_support_rounded': Icons.contact_support_rounded,
    'support_agent_rounded': Icons.support_agent_rounded,
    
    // Others
    'loyalty_rounded': Icons.loyalty_rounded,
    'card_giftcard_rounded': Icons.card_giftcard_rounded,
    'confirmation_number_rounded': Icons.confirmation_number_rounded,
    'emoji_events_rounded': Icons.emoji_events_rounded,
    'casino_rounded': Icons.casino_rounded,
    'star_rounded': Icons.star_rounded,
    'favorite_rounded': Icons.favorite_rounded,
    'thumb_up_rounded': Icons.thumb_up_rounded,
    'spa_rounded': Icons.spa_rounded,
    'eco_rounded': Icons.eco_rounded,
    'lightbulb_rounded': Icons.lightbulb_rounded,
    'workspace_premium_rounded': Icons.workspace_premium_rounded,
    'card_membership_rounded': Icons.card_membership_rounded,
    'diamond_rounded': Icons.diamond_rounded,
  };

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.grid_view_rounded;
  }
}
