import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/app_user.dart';
import '../../../data/models/app_user_model.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _imageFile;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _photoUrl;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _photoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300, // Giảm kích thước để có base64 ngắn hơn
        maxHeight: 300,
        imageQuality: 70, // Giảm chất lượng để giảm kích thước
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Phương thức để chuyển đổi ảnh thành base64
  Future<String?> _imageToBase64() async {
    if (_imageFile == null) {
      return null; // Không có ảnh mới
    }

    try {
      // Nén ảnh trước khi chuyển đổi
      List<int>? compressedImage;

      compressedImage = await FlutterImageCompress.compressWithFile(
        _imageFile!.path,
        minWidth: 300,
        minHeight: 300,
        quality: 70,
      );

      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      // Chuyển đổi sang base64
      final base64String = base64Encode(compressedImage);

      // Kiểm tra kích thước
      final sizeInKB = base64String.length / 1024;
      print('Base64 image size: ${sizeInKB.toStringAsFixed(2)} KB');

      // Thêm prefix để dễ dàng nhận biết và hiển thị
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Xử lý ảnh mới nếu có
    String? photoUrlToSave = _photoUrl;
    if (_imageChanged && _imageFile != null) {
      try {
        final base64Image = await _imageToBase64();

        if (base64Image != null) {
          photoUrlToSave = base64Image;
        } else {
          // Nếu có lỗi, giữ nguyên ảnh cũ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not process the image, profile info will be updated without new image')),
          );
        }
      } catch (e) {
        print('Error processing image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }

    // Tạo đối tượng user đã cập nhật
    final updatedUser = AppUserModel(
      id: widget.user.id,
      name: _nameController.text.trim(),
      email: widget.user.email,
      photoUrl: photoUrlToSave, // Lưu URL hoặc chuỗi base64
      createdAt: widget.user.createdAt,
      friendIds: widget.user.friendIds,
      friendRequestIds: widget.user.friendRequestIds,
    );

    // Gửi sự kiện cập nhật
    context.read<UserBloc>().add(UpdateUserEvent(updatedUser));

    setState(() {
      _isEditing = false;
      _isLoading = false;
      _photoUrl = photoUrlToSave;
      _imageChanged = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is UserUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileImage(),
                const SizedBox(height: 24),
                _buildUserInfo(),
                const SizedBox(height: 32),
                if (_isEditing) _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: Colors.grey[200],
          backgroundImage: _getAvatarImage(),
          child: _showInitial()
              ? Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
      ],
    );
  }

  // Helper để hiển thị ảnh hồ sơ
  ImageProvider? _getAvatarImage() {
    // Ưu tiên file ảnh mới được chọn
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }

    // Nếu không có file mới, kiểm tra photoUrl
    if (_photoUrl != null) {
      // Trường hợp là ảnh base64
      if (_photoUrl!.startsWith('data:image')) {
        try {
          // Trích xuất phần base64 từ data URL
          final base64String = _photoUrl!.split(',')[1];
          // Chuyển đổi về bytes và hiển thị
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          print('Error displaying base64 image: $e');
          return null;
        }
      }
      // Trường hợp là URL thông thường
      else if (_photoUrl!.startsWith('http')) {
        return NetworkImage(_photoUrl!);
      }
    }

    // Không có ảnh
    return null;
  }

  // Helper để xác định có hiển thị chữ cái đầu không
  bool _showInitial() {
    if (_imageFile != null) return false;

    // Nếu không có photoUrl hoặc photoUrl rỗng
    if (_photoUrl == null || _photoUrl!.isEmpty) return true;

    // Nếu là base64 hoặc URL hợp lệ, không hiển thị chữ cái
    return false;
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        if (!_isEditing) ...[
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text('Friends: ${widget.user.friendIds.length}'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Joined: ${_formatDate(widget.user.createdAt)}'),
          ),
        ] else ...[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.user.email,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            enabled: false, // Email cannot be changed
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _isEditing = false;
                    _imageFile = null;
                    _imageChanged = false;
                    _nameController.text = widget.user.name;
                  });
                },
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _updateProfile,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
