import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _openLogin() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _openEditProfile({
    required AuthState auth,
    bool focusAdresse = false,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: auth.userName ?? '',
          initialEmail: auth.email ?? '',
          initialPhone: auth.phone ?? '',
          initialAdresse: auth.adresse ?? '',
          focusAdresse: focusAdresse,
        ),
      ),
    );
    if (!mounted) return;
    await context.read<AuthState>().refreshMe();
  }

  Future<void> _openChangePassword() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final auth = context.read<AuthState>();
    if (!auth.isAuthenticated) return;

    final ctrl = TextEditingController();
    bool loading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            Future<void> submit() async {
              final code = ctrl.text.trim();
              if (code.isEmpty) return;
              setSheetState(() => loading = true);
              try {
                await context.read<AuthState>().deleteAccount(code: code);
                if (!mounted) return;
                Navigator.of(sheetCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compte supprimé')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              } finally {
                if (sheetCtx.mounted) setSheetState(() => loading = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E132E),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Supprimer le compte',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(sheetCtx).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cette action est définitive. Pour confirmer, saisis le code de ton compte.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ctrl,
                      enabled: !loading,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.text),
                      decoration: const InputDecoration(
                        labelText: 'Code du compte',
                        prefixIcon: Icon(
                          Icons.password_rounded,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading
                                ? null
                                : () => Navigator.of(sheetCtx).pop(),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Supprimer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ton compte, tes paiements et tes réglages',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        if (!auth.isAuthenticated) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.55),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person_outline,
                          color: AppTheme.bgTop,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Connecte-toi pour gérer ton profil et payer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openLogin,
                        icon: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Se connecter',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.lock_outline,
            title: 'Connexion au paiement',
            value: 'Seulement au checkout',
          ),
        ] else ...[
          _ProfileHeroCard(auth: auth),
          const SizedBox(height: 22),
          _ProfileSectionLabel(title: 'Paiements & fidélité'),
          const SizedBox(height: 10),
          _GroupedGlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoPanelRow(
                  icon: Icons.waves,
                  title: 'Wave',
                  value: auth.waveEnabled ? 'Activé' : 'Désactivé',
                  valuePositive: auth.waveEnabled,
                ),
                _panelDivider(),
                _InfoPanelRow(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Fidélité',
                  value: auth.fidelityEnabled ? 'Points activés' : 'Désactivé',
                  valuePositive: auth.fidelityEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ProfileSectionLabel(title: 'Paramètres'),
          const SizedBox(height: 10),
          _GroupedGlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SettingsPanelRow(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Modifier le profil',
                  subtitle: auth.email ?? '',
                  onTap: () => _openEditProfile(auth: auth),
                ),
                _panelDivider(),
                _SettingsPanelRow(
                  icon: Icons.location_on_outlined,
                  title: 'Adresse',
                  subtitle:
                      (auth.adresse == null || auth.adresse!.trim().isEmpty)
                      ? 'Non renseignée'
                      : auth.adresse!,
                  onTap: () => _openEditProfile(auth: auth, focusAdresse: true),
                ),
                _panelDivider(),
                _SettingsPanelRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Mot de passe',
                  subtitle: 'Changer ton mot de passe',
                  onTap: _openChangePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GroupedGlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SettingsPanelRow(
                  icon: Icons.logout_rounded,
                  title: 'Déconnexion',
                  subtitle: 'Quitter ce compte sur cet appareil',
                  danger: true,
                  showChevron: false,
                  onTap: () => context.read<AuthState>().logout(),
                ),
                _panelDivider(),
                _SettingsPanelRow(
                  icon: Icons.delete_forever_rounded,
                  title: 'Supprimer le compte',
                  subtitle: 'Suppression définitive (confirmation par code)',
                  danger: true,
                  showChevron: false,
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

Widget _panelDivider() => Divider(
  height: 1,
  thickness: 1,
  indent: 62,
  color: Colors.white.withValues(alpha: 0.09),
);

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textMuted.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _GroupedGlassPanel extends StatelessWidget {
  const _GroupedGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    final phone = auth.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface.withValues(alpha: 0.95),
            AppTheme.surface2.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGold.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandGoldLight,
                  AppTheme.accent.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'logo.jpeg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.person_rounded,
                    color: AppTheme.bgTop,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.userName ?? 'Client',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (hasPhone) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_iphone_rounded,
                        size: 15,
                        color: AppTheme.textMuted.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandGold.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.brandGoldLight.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 18, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      '${auth.pointsFidelite} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanelRow extends StatelessWidget {
  const _InfoPanelRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valuePositive = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool valuePositive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.text, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: valuePositive
                  ? Colors.green.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: valuePositive
                    ? Colors.greenAccent.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valuePositive
                    ? Colors.lightGreenAccent.shade100
                    : AppTheme.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanelRow extends StatelessWidget {
  const _SettingsPanelRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final titleColor = danger ? Colors.redAccent.shade100 : AppTheme.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: danger
                      ? Colors.redAccent.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  color: danger ? Colors.redAccent : AppTheme.text,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: danger ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: AppTheme.text),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialAdresse,
    required this.focusAdresse,
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialAdresse;
  final bool focusAdresse;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _adresseCtrl;

  final _adresseFocus = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _adresseCtrl = TextEditingController(text: widget.initialAdresse);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.focusAdresse) {
        _adresseFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _adresseCtrl.dispose();
    _adresseFocus.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.accent, width: 2),
      ),
      labelStyle: const TextStyle(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppTheme.accent,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.22),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final adresse = _adresseCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom, email et téléphone sont obligatoires'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthState>().updateProfile(
        name: name,
        email: email,
        phone: phone,
        adresse: adresse.isEmpty ? null : adresse,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassIconButton(
                      onTap: () => Navigator.of(context).pop(false),
                      icon: Icons.arrow_back_ios_new,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Modifier le profil',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration: _dec(
                              'Nom complet',
                              Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration: _dec(
                              'Email',
                              Icons.alternate_email_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration: _dec('Téléphone', Icons.phone_outlined),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _adresseCtrl,
                            focusNode: _adresseFocus,
                            maxLines: 2,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration: _dec(
                              'Adresse',
                              Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_rounded,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _saving ? 'Enregistrement...' : 'Enregistrer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _new2Ctrl = TextEditingController();

  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureNew2 = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _new2Ctrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.accent, width: 2),
      ),
      labelStyle: const TextStyle(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppTheme.accent,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.22),
    );
  }

  Future<void> _save() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final next2 = _new2Ctrl.text;

    if (current.isEmpty || next.isEmpty || next2.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Remplis tous les champs')));
      return;
    }
    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nouveau mot de passe doit faire 6 caractères'),
        ),
      );
      return;
    }
    if (next != next2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthState>().updatePassword(
        currentPassword: current,
        newPassword: next,
        newPasswordConfirmation: next2,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassIconButton(
                      onTap: () => Navigator.of(context).pop(false),
                      icon: Icons.arrow_back_ios_new,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mot de passe',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _currentCtrl,
                            obscureText: _obscureCurrent,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration:
                                _dec(
                                  'Mot de passe actuel',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent,
                                    ),
                                    icon: Icon(
                                      _obscureCurrent
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newCtrl,
                            obscureText: _obscureNew,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration:
                                _dec(
                                  'Nouveau mot de passe',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                    icon: Icon(
                                      _obscureNew
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _new2Ctrl,
                            obscureText: _obscureNew2,
                            style: const TextStyle(color: AppTheme.text),
                            cursorColor: AppTheme.accent,
                            decoration:
                                _dec(
                                  'Confirmer le nouveau mot de passe',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureNew2 = !_obscureNew2,
                                    ),
                                    icon: Icon(
                                      _obscureNew2
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.10,
                                ),
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.security_rounded,
                                      color: AppTheme.text,
                                    ),
                              label: Text(
                                _saving ? '...' : 'Modifier le mot de passe',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
