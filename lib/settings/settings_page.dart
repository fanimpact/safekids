import 'package:flutter/material.dart';
import '../auth/supabase_auth_provider.dart';

import '../auth/account_service.dart';
import '../export/section_export.dart';
import '../auth/app_auth.dart';
import '../repositories/child_repository.dart';
import '../utils/auth_error_message.dart';
import '../welcome_page.dart';
import '../widgets/sk_password_field.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdatingPassword = false;
  bool _isSigningOut = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      _showMessage(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage(
        'Les deux mots de passe ne correspondent pas.',
      );
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      await SupabaseAuthProvider.instance.updatePassword(
        newPassword,
      );

      if (!mounted) {
        return;
      }

      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showMessage('Mot de passe mis à jour.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        friendlyAuthErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez saisir votre email et votre mot de passe pour '
          'vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await AccountService.instance.signOut();
      await ensureSignedIn();
      await ChildRepository.instance.loadFromSupabase();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Impossible de vous déconnecter : $error',
      );

      setState(() {
        _isSigningOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        SupabaseAuthProvider.instance.currentUserEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Compte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: const Text('Adresse email'),
                subtitle: Text(
                  email ?? 'Non renseignée',
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Changer le mot de passe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SkPasswordField(
                controller: _newPasswordController,
                label: 'Nouveau mot de passe',
                helperText: '8 caractères minimum.',
              ),
              const SizedBox(height: 16),
              SkPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmer le nouveau mot de passe',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isUpdatingPassword
                    ? null
                    : _updatePassword,
                child: _isUpdatingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Mettre à jour le mot de passe',
                      ),
              ),

              const SizedBox(height: 40),

              const SectionExportDonnees(),

              const SizedBox(height: 40),

              OutlinedButton.icon(
                onPressed:
                    _isSigningOut ? null : _confirmSignOut,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
