import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// Widget for selecting product condition
///
/// Displays three condition options:
/// - Used
/// - New
/// - New in Box
class ConditionSelectorWidget extends StatelessWidget {
  final String selectedCondition;
  final ValueChanged<String> onConditionChanged;
  final bool enabled;

  const ConditionSelectorWidget({
    Key? key,
    required this.selectedCondition,
    required this.onConditionChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Condition',
          style: TextStyle(
            fontSize: FontSizes.base,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: Spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(BorderRadii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildConditionButton(
                  context,
                  label: ConditionOptions.used,
                  icon: Icons.shopping_bag,
                ),
              ),
              Expanded(
                child: _buildConditionButton(
                  context,
                  label: ConditionOptions.new_,
                  icon: Icons.new_releases,
                ),
              ),
              Expanded(
                child: _buildConditionButton(
                  context,
                  label: ConditionOptions.newInBox,
                  icon: Icons.inventory_2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedCondition == label;

    return GestureDetector(
      onTap: enabled ? () => onConditionChanged(label) : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(BorderRadii.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: IconSizes.base,
            ),
            SizedBox(height: Spacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: FontSizes.sm,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
