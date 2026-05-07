import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const Center(child: Text('Connecte-toi pour accéder au profil'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person, color: AppTheme.brandGold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName ?? 'Client',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Points fidélité: ${auth.pointsFidelite}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.waves),
                title: const Text('Wave'),
                subtitle: Text(auth.waveEnabled ? 'Activé' : 'Désactivé'),
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text('Fidélité'),
                subtitle: Text(auth.fidelityEnabled ? 'Paiement en points activé' : 'Désactivé'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.read<AuthState>().logout(),
                  child: const Text('Déconnexion'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

