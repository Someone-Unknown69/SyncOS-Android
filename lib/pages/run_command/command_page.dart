import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/features/run_command/remote_command_sender.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/features/run_command/models/remote_command.dart';
import 'package:mobile_controller/theme/app_theme.dart';

class CommandScreen extends ConsumerStatefulWidget {
  const CommandScreen({super.key});

  @override
  ConsumerState<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends ConsumerState<CommandScreen> {
  final padding = AppTheme.padding;
  final borderRadius = AppTheme.borderRadius;
  final spacing = AppTheme.spacing;
  
  late final colorScheme = Theme.of(context).colorScheme;
  late RemoteCommandSender _sender;

  @override
  void initState() {
    super.initState();
    _sender = RemoteCommandSender(ref.read(connectionManagerProvider));
  }

  final List<RemoteCommand> _commands = [
    RemoteCommand(
      id: '1',
      commandName: 'Lock PC',
      commandDescription: 'Locks the remote operating system session immediately.',
      payload: 'loginctl lock-session',
      colorValue: 0xFFE57373,
      requiresRoot: false,
    ),
    RemoteCommand(
      id: '2',
      commandName: 'Reboot System',
      commandDescription: 'Triggers a graceful system reboot sequence.',
      payload: 'reboot',
      colorValue: 0xFFFFB74D,
      requiresRoot: true,
    ),
    RemoteCommand(
      id: '3', 
      commandName: 'Send a Hi!', 
      commandDescription: "Be nice and send a hi to your remote machine", 
      payload: 'notify-send "SyncOS" "Hello from your phone!"', 
      colorValue: Colors.blue.toARGB32(), 
      requiresRoot: false
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Run Command', 
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _commands.length,
          itemBuilder: (context, index) {
            final command = _commands[index];
            return Card(
              key: Key(command.id),
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              child: ExpansionTile(
                shape: const Border(),
                expansionAnimationStyle: AnimationStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                ),
                leading: CircleAvatar(
                  backgroundColor: Color(command.colorValue),
                  child: Icon(
                    command.requiresRoot ? Icons.security : Icons.terminal,
                    color: Color(command.colorValue).computeLuminance() > 0.5 ? 
                          Colors.black : Colors.white,
                  ),
                ),

                title: Text(
                  command.commandName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Text(command.requiresRoot ? 'Requires Privileged Root Access' : 'Standard User Access'),
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        'Description:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4.0),
                        Text(command.commandDescription),
                        const SizedBox(height: 12.0),
                        Text(
                          'Executable:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4.0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius / 4),
                          ),
                          child: Text(
                            command.payload,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.green,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              _sender.sendRemoteCommand(command);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(borderRadius),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Execute Command'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        )
      ]
    );
  }
}