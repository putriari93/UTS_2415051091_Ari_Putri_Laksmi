import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_info.dart';
import '../core/utils/formatters.dart';
import '../providers/favorite_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showInfo(
    BuildContext context, {
    required String title,
    required String description,
    required List<(String, String)> details,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                if (details.isNotEmpty) const SizedBox(height: 16),
                for (final item in details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            item.$1,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loans = context.watch<LoanProvider>();
    final favorites = context.watch<FavoriteProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 700 ? 28.0 : 16.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IdentityCard(student: AppInfo.studentName),
                        const SizedBox(height: 20),
                        _ProfileStats(
                          loans: loans,
                          favorites: favorites,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Tampilan'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.dark_mode_outlined, size: 20, color: colors.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Mode tampilan',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pilih tema terang, gelap, atau ikuti pengaturan perangkat.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Builder(
                                builder: (context) {
                                  final compactSegments =
                                      MediaQuery.sizeOf(context).width < 420;
                                  return SegmentedButton<ThemeMode>(
                                    segments: [
                                      ButtonSegment(
                                        value: ThemeMode.light,
                                        icon: compactSegments
                                            ? null
                                            : const Icon(Icons.light_mode_outlined, size: 16),
                                        label: const Text('Terang'),
                                      ),
                                      ButtonSegment(
                                        value: ThemeMode.dark,
                                        icon: compactSegments
                                            ? null
                                            : const Icon(Icons.dark_mode_outlined, size: 16),
                                        label: const Text('Gelap'),
                                      ),
                                      ButtonSegment(
                                        value: ThemeMode.system,
                                        icon: compactSegments
                                            ? null
                                            : const Icon(Icons.settings_suggest_outlined, size: 16),
                                        label: const Text('Sistem'),
                                      ),
                                    ],
                                    selected: {themeProvider.mode},
                                    onSelectionChanged: (selection) {
                                      themeProvider.setMode(selection.first);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Sumber data'),
                        const SizedBox(height: 8),
                        _SettingsTile(
                          icon: Icons.menu_book_outlined,
                          title: 'Open Library',
                          subtitle: 'Katalog, cover, dan deskripsi buku',
                          onTap: () => _showInfo(
                            context,
                            title: 'Open Library',
                            description:
                                'Seluruh data buku diambil dari Open Library, layanan terbuka '
                                'dari Internet Archive. Aplikasi memakai endpoint pencarian dan '
                                'detail work untuk menampilkan katalog tanpa menyimpan salinannya.',
                            details: const [
                              ('Endpoint', '/search.json'),
                              ('Detail', '/works/{id}.json'),
                              ('Cover', 'covers.openlibrary.org'),
                              ('Akses', 'GET tanpa API key'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SettingsTile(
                          icon: Icons.storage_outlined,
                          title: 'Supabase',
                          subtitle: 'Menyimpan catatan peminjaman',
                          onTap: () => _showInfo(
                            context,
                            title: 'Supabase',
                            description:
                                'Catatan peminjaman disimpan pada tabel loans di Supabase. '
                                'Aplikasi memakai publishable key sehingga operasi dibatasi '
                                'oleh Row Level Security, bukan service role key.',
                            details: const [
                              ('Tabel', 'public.loans'),
                              ('Operasi', 'Create, Read, Update, Delete'),
                              ('Kolom', 'id, book_key, judul, peminjam, tanggal, status'),
                              ('Keamanan', 'RLS + publishable key'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Aplikasi'),
                        const SizedBox(height: 8),
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Tentang ${AppInfo.appName}',
                          subtitle: 'Versi 1.0.0 · UTS Pemrograman Mobile',
                          onTap: () => _showInfo(
                            context,
                            title: AppInfo.appName,
                            description: AppInfo.description,
                            details: const [
                              ('Nama', AppInfo.studentName),
                              ('NIM', AppInfo.studentId),
                              ('Kelas', AppInfo.studentClass),
                              ('Semester', AppInfo.semester),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Text(
                            'Dibuat untuk UTS Pemrograman Mobile\n${AppInfo.appName} · 2026',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.student});

  final String student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.55) ?? colors.primary,
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.onPrimary.withValues(alpha: 0.18),
            child: Text(
              Formatters.initials(student),
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppInfo.studentId} · ${AppInfo.studentClass}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppInfo.semester,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_stories_rounded,
            color: colors.onPrimary.withValues(alpha: 0.7),
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.loans, required this.favorites});

  final LoanProvider loans;
  final FavoriteProvider favorites;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MiniStat(width: itemWidth, value: '${loans.loans.length}', label: 'Peminjaman'),
            _MiniStat(width: itemWidth, value: '${loans.activeCount}', label: 'Aktif'),
            _MiniStat(width: itemWidth, value: '${favorites.count}', label: 'Favorit'),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.width, required this.value, required this.label});

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
