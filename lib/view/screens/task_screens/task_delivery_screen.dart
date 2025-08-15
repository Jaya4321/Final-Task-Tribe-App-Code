import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../services/image_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/notification_helper.dart';
import '../../components/shared_components/loading_components.dart';

class TaskDeliveryScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDeliveryScreen({super.key, required this.task});

  @override
  State<TaskDeliveryScreen> createState() => _TaskDeliveryScreenState();
}

class _TaskDeliveryScreenState extends State<TaskDeliveryScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  
  File? _selectedImage;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingDeliveryData();
  }

  void _loadExistingDeliveryData() {
    // Check if task already has delivery proof
    if (widget.task.deliveryProof.isNotEmpty) {
      final existingMessage = widget.task.deliveryProof['message'] as String?;
      final existingImageUrl = widget.task.deliveryProof['url'] as String?;
      
      if (existingMessage != null) {
        _messageController.text = existingMessage;
      }
      
      if (existingImageUrl != null) {
        _existingImageUrl = existingImageUrl;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectImageFromGallery() async {
    try {
      final image = await _imageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _selectImageFromCamera() async {
    try {
      final image = await _imageService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deliverTask() async {
    // Validate message
    if (_messageController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Delivery message is required';
      });
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      String? imageUrl = _existingImageUrl; // Keep existing image if no new one selected
      
      // Handle image upload/replacement
      if (_selectedImage != null) {
        // Check if there's an existing image URL in deliveryProof that needs to be deleted
        String? existingImageUrlToDelete;
        
        // First check the current task's deliveryProof for existing image
        if (widget.task.deliveryProof.isNotEmpty) {
          existingImageUrlToDelete = widget.task.deliveryProof['url'] as String?;
        }
        
        // Also check if we have a local existing image URL
        if (existingImageUrlToDelete == null && _existingImageUrl != null) {
          existingImageUrlToDelete = _existingImageUrl;
        }
        
        // Delete old image if it exists
        if (existingImageUrlToDelete != null && existingImageUrlToDelete.isNotEmpty) {
          print('DEBUG: Deleting old image: $existingImageUrlToDelete');
          await _storageService.deleteImage(existingImageUrlToDelete);
        }
        
        // Upload new image
        print('DEBUG: Uploading new image for task: ${widget.task.id}');
        imageUrl = await _storageService.uploadTaskDeliveryImage(
          _selectedImage!, 
          widget.task.id
        );
        if (imageUrl == null) {
          setState(() {
            _errorMessage = 'Failed to upload image';
            _isSubmitting = false;
          });
          return;
        }
        print('DEBUG: New image uploaded successfully: $imageUrl');
      }

      // Update task with delivery proof
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.deliverTask(
        widget.task.id,
        _messageController.text.trim(),
        imageUrl,
      );

      if (success) {
        // Send notification to task poster about the delivery
        await NotificationHelper.notifyTaskDelivery(
          taskOwnerId: widget.task.posterId,
          taskTitle: widget.task.title,
          taskId: widget.task.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task.deliveryProof.isNotEmpty 
                ? 'Task delivery updated successfully!' 
                : 'Task delivered successfully!'
            ),
            backgroundColor: successColor,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate delivery
      } else {
        setState(() {
          _errorMessage = taskProvider.errorMessage ?? 'Failed to deliver task';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error delivering task: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingDelivery = widget.task.deliveryProof.isNotEmpty;
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(hasExistingDelivery ? 'Update Delivery' : 'Deliver Task'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacingL),
                decoration: WidgetStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Details',
                      style: TextStyles.heading3,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    Text(
                      widget.task.title,
                      style: TextStyles.body1.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingS),
                    Text(
                      widget.task.description,
                      style: TextStyles.body2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: UIConstants.iconSizeS,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: UIConstants.spacingS),
                        Text(
                          '£${widget.task.reward.toStringAsFixed(0)}',
                          style: TextStyles.body1.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: UIConstants.spacingL),
              
              // Existing delivery info (if any)
              if (hasExistingDelivery) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(UIConstants.spacingM),
                  decoration: BoxDecoration(
                    color: infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    border: Border.all(color: infoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: infoColor,
                        size: UIConstants.iconSizeM,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Expanded(
                        child: Text(
                          'This task has already been delivered. You can update the delivery details below.',
                          style: TextStyles.body2.copyWith(color: infoColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UIConstants.spacingL),
              ],
              
              // Delivery message
              Text(
                'Delivery Message *',
                style: TextStyles.heading3,
              ),
              const SizedBox(height: UIConstants.spacingM),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: WidgetStyles.inputDecoration.copyWith(
                  hintText: 'Describe how you completed the task...',
                  labelText: 'Delivery Message',
                ),
              ),
              
              const SizedBox(height: UIConstants.spacingL),
              
              // Delivery proof (optional)
              Text(
                'Delivery Proof (Optional)',
                style: TextStyles.heading3,
              ),
              const SizedBox(height: UIConstants.spacingS),
              Text(
                hasExistingDelivery 
                  ? 'Update the photo as proof of task completion'
                  : 'Add a photo as proof of task completion',
                style: TextStyles.caption,
              ),
              const SizedBox(height: UIConstants.spacingM),
              
              // Image selection/display
              if (_selectedImage != null)
                _buildSelectedImageWidget()
              else if (_existingImageUrl != null)
                _buildExistingImageWidget()
              else
                _buildAddImageWidget(),
              
              const SizedBox(height: UIConstants.spacingL),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(UIConstants.spacingM),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    border: Border.all(color: errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: errorColor,
                        size: UIConstants.iconSizeM,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyles.body2.copyWith(color: errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: UIConstants.spacingL),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: UIConstants.buttonHeightL,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _deliverTask,
                  style: WidgetStyles.primaryButtonStyle,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: UIConstants.spacingM),
                            Text('Processing...'),
                          ],
                        )
                      : Text(
                          hasExistingDelivery ? 'Update Delivery' : 'Deliver Task',
                          style: TextStyle(fontSize: UIConstants.fontSizeL),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImageWidget() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: UIConstants.spacingS,
            right: UIConstants.spacingS,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImageWidget() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
            child: Image.network(
              _existingImageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: UIConstants.spacingS,
            right: UIConstants.spacingS,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _existingImageUrl = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageWidget() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: _showImageSourceDialog,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: UIConstants.iconSizeL,
              color: textSecondaryColor,
            ),
            const SizedBox(height: UIConstants.spacingS),
            Text(
              'Add Photo',
              style: TextStyles.body2.copyWith(
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 