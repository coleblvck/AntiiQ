import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/about.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/backup_restore.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/behaviour.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/library.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/user_interface.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class AntiiQSettings extends StatelessWidget {
  const AntiiQSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);

    final settings = [
      _SettingItem(
        id: 'interface',
        label: 'INTERFACE',
        icon: RemixIcon.magic,
        color: AntiiQTheme.of(context).colorScheme.primary,
        page: const UserInterface(),
      ),
      _SettingItem(
        id: 'library',
        label: 'LIBRARY',
        icon: RemixIcon.folder_music,
        color: AntiiQTheme.of(context).colorScheme.secondary,
        page: const Library(),
      ),
      _SettingItem(
        id: 'behaviour',
        label: 'BEHAVIOUR',
        icon: RemixIcon.toggle,
        color: AntiiQTheme.of(context).colorScheme.primary,
        page: const Behaviour(),
      ),
      _SettingItem(
        id: 'backup',
        label: 'BACKUP/RESTORE',
        icon: RemixIcon.save_3,
        color: AntiiQTheme.of(context).colorScheme.secondary,
        page: const BackupRestore(),
      ),
      _SettingItem(
        id: 'about',
        label: 'ABOUT',
        icon: RemixIcon.information,
        color: AntiiQTheme.of(context).colorScheme.primary,
        page: const About(),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(
          top: chaosBasePadding,
          left: chaosBasePadding,
          right: chaosBasePadding),
      itemCount: settings.length,
      itemBuilder: (context, index) {
        final setting = settings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: chaosBasePadding),
          child: _SettingCard(
            setting: setting,
            onTap: () {
              HapticFeedback.mediumImpact();
              pageManagerController?.push(
                setting.page,
                title: setting.label,
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Widget page;

  _SettingItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class _SettingCard extends StatefulWidget {
  final _SettingItem setting;
  final VoidCallback onTap;

  const _SettingCard({
    required this.setting,
    required this.onTap,
  });

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return ChaosRotatedStatefulWidget(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: _isPressed
                  ? widget.setting.color.withValues(alpha: 0.15)
                  : widget.setting.color.withValues(alpha: 0.05),
              border: Border.all(
                color: widget.setting.color
                    .withValues(alpha: _isPressed ? 0.6 : 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(currentRadius - 2),
            ),
            child: Stack(
              children: [
                /*
                Positioned(
                  right: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(
                      widget.setting.icon,
                      size: 120,
                      color: widget.setting.color,
                    ),
                  ),
                ),
                */

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: chaosBasePadding * 1.5,
                      vertical: chaosBasePadding * 1.5),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.setting.color.withValues(alpha: 0.1),
                          border: Border.all(
                            color: widget.setting.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(currentRadius - 6),
                        ),
                        child: Icon(
                          widget.setting.icon,
                          color: widget.setting.color,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Label
                      Expanded(
                        child: Text(
                          widget.setting.label,
                          style: TextStyle(
                            color: widget.setting.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      // Arrow
                      Icon(
                        RemixIcon.arrow_right_s,
                        color: widget.setting.color.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
