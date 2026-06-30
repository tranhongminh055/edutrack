import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum UserRole { student, lecturer, admin }

class RoleSelector extends StatelessWidget {
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final bool isLightMode;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.isLightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            role: UserRole.student,
            icon: Icons.school_rounded,
            label: 'Sinh viên',
            subtitle: 'Student',
            isSelected: selectedRole == UserRole.student,
            color: AppColors.studentColor,
            isLightMode: isLightMode,
            onTap: () => onRoleChanged(UserRole.student),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RoleCard(
            role: UserRole.lecturer,
            icon: Icons.person_rounded,
            label: 'Giảng viên',
            subtitle: 'Lecturer',
            isSelected: selectedRole == UserRole.lecturer,
            color: AppColors.lecturerColor,
            isLightMode: isLightMode,
            onTap: () => onRoleChanged(UserRole.lecturer),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RoleCard(
            role: UserRole.admin,
            icon: Icons.admin_panel_settings_rounded,
            label: 'Quản trị',
            subtitle: 'Admin',
            isSelected: selectedRole == UserRole.admin,
            color: AppColors.adminColor,
            isLightMode: isLightMode,
            onTap: () => onRoleChanged(UserRole.admin),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatefulWidget {
  final UserRole role;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isLightMode;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isLightMode,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : (widget.isLightMode ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2)),
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            color: widget.isSelected
                ? widget.color.withOpacity(0.15)
                : (widget.isLightMode ? Colors.transparent : Colors.white.withOpacity(0.05)),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Icon container with glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? widget.color.withOpacity(0.2)
                      : (widget.isLightMode ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.08)),
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.color.withOpacity(0.5)
                        : (widget.isLightMode ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.15)),
                    width: 2,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 15,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? widget.color
                      : (widget.isLightMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? (widget.isLightMode ? widget.color : Colors.white)
                      : (widget.isLightMode ? Colors.black87 : Colors.white.withOpacity(0.7)),
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: widget.isSelected
                      ? widget.color.withOpacity(0.8)
                      : (widget.isLightMode ? Colors.black54 : Colors.white.withOpacity(0.4)),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
              // Checkmark indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? widget.color
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.color
                        : (widget.isLightMode ? Colors.black26 : Colors.white.withOpacity(0.3)),
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
