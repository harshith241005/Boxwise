import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CollaboratorsScreen extends StatelessWidget {
  const CollaboratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family & Team', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final collaborators = provider.collaborators;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.group_add_rounded, size: 40, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Invite to Home Space',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share your inventory with family members or team mates to manage boxes together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showInviteDialog(context, provider),
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('Invite by Email'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text('Active Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: collaborators.length,
                  itemBuilder: (context, index) {
                    final member = collaborators[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E293B) 
                          : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withAlpha(26)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withAlpha(51),
                          child: Text(member['name']![0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(member['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(member['email']!),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: member['role'] == 'Admin' ? Colors.indigo.withAlpha(26) : Colors.teal.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member['role']!,
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              color: member['role'] == 'Admin' ? Colors.indigo : Colors.teal
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context, InventoryProvider provider) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'Editor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Collaborator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Permission Role'),
                items: ['Viewer', 'Editor', 'Admin'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (val) => setState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (emailCtrl.text.isEmpty) return;
                provider.inviteCollaborator(emailCtrl.text, selectedRole);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invitation sent to ${emailCtrl.text}')),
                );
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
