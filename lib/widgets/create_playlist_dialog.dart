import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../models/playlist.dart';

class CreatePlaylistDialog extends StatefulWidget {
  final Playlist? playlist;

  const CreatePlaylistDialog({super.key, this.playlist});

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.playlist == null ? 'Create Playlist' : 'Rename Playlist',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter playlist name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a playlist name';
            }
            return null;
          },
          onFieldSubmitted: (_) => _savePlaylist(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePlaylist,
          child: Text(widget.playlist == null ? 'Create' : 'Rename'),
        ),
      ],
    );
  }

  void _savePlaylist() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final mediaProvider = context.read<MediaProvider>();

      if (widget.playlist == null) {
        // Create new playlist
        mediaProvider.createPlaylist(name);
      } else {
        // Rename existing playlist
        widget.playlist!.name = name;
        widget.playlist!.lastModified = DateTime.now();
      }

      Navigator.of(context).pop();
    }
  }
}
