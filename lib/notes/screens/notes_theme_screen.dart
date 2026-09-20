import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../theme/notes_theme.dart';

/// Dedicated screen under Settings -> Appearance -> Notes Theme
/// allowing the user to select between Terracotta, Teal, and Monochrome themes.
class NotesThemeScreen extends StatelessWidget {
  const NotesThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final currentNotesTheme = themeController.notesTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesColors = NotesTheme.of(context);

    return Scaffold(
      backgroundColor: notesColors.background,
      appBar: AppBar(
        title: Text(
          'Notes Theme',
          style: TextStyle(
            color: notesColors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: notesColors.surface,
        elevation: 0,
        leading: IconButton(
          key: const Key('notes_theme_back_button'),
          icon: Icon(Icons.arrow_back, color: notesColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            Text(
              'SELECT V3 NOTES PALETTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: notesColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a visual skin for Notes and Checklists. The selected theme takes effect immediately across all Notes screens.',
              style: TextStyle(
                fontSize: 13,
                color: notesColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeCard(
              context: context,
              key: const Key('notes_theme_terracotta'),
              type: NotesThemeType.terracotta,
              isSelected: currentNotesTheme == NotesThemeType.terracotta,
              isDark: isDark,
              onTap: () => themeController.setNotesTheme(NotesThemeType.terracotta),
            ),
            const SizedBox(height: 14),
            _buildThemeCard(
              context: context,
              key: const Key('notes_theme_teal'),
              type: NotesThemeType.teal,
              isSelected: currentNotesTheme == NotesThemeType.teal,
              isDark: isDark,
              onTap: () => themeController.setNotesTheme(NotesThemeType.teal),
            ),
            const SizedBox(height: 14),
            _buildThemeCard(
              context: context,
              key: const Key('notes_theme_monochrome'),
              type: NotesThemeType.monochrome,
              isSelected: currentNotesTheme == NotesThemeType.monochrome,
              isDark: isDark,
              onTap: () => themeController.setNotesTheme(NotesThemeType.monochrome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required Key key,
    required NotesThemeType type,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final preview = NotesTheme.previewColors(type, isDark: isDark);
    final targetPalette = NotesTheme.getPalette(type, isDark: isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: targetPalette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? targetPalette.primary : targetPalette.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: targetPalette.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: targetPalette.textMain,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.titleCaseName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? targetPalette.primary : targetPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 22,
                    color: isSelected
                        ? targetPalette.primary
                        : targetPalette.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                type.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: targetPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ...preview.map((c) => Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: targetPalette.border,
                            width: 1.0,
                          ),
                        ),
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: targetPalette.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSelected ? 'ACTIVE' : 'SELECT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: targetPalette.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
