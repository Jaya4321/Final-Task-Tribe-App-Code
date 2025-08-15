import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../controller/providers/task_providers/task_form_provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../components/shared_components/loading_components.dart';

class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({super.key});

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TaskProvider _taskProvider;
  late TaskFormProvider _formProvider;
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _formProvider = Provider.of<TaskFormProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Initialize form with first category
    if (TaskCategories.categories.isNotEmpty) {
      _formProvider.setCategory(TaskCategories.categories.first);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _formProvider.setDate(picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _formProvider.setTime(picked);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    _formProvider.validateForm();
    if (!_formProvider.isFormValid) return;

    final user = _authProvider.userData;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post a task')),
      );
      return;
    }

    final taskModel = _formProvider.getTaskModel(user.uid);
    if (taskModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    _formProvider.setSubmitting(true);

    final success = await _taskProvider.createTask(taskModel);

    _formProvider.setSubmitting(false);

    if (success && mounted) {
      // Reset form to default values after successful task creation
      _formProvider.clearForm();
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_taskProvider.errorMessage ?? 'Failed to post task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Task Posted!'),
        content: const Text(
          'Your task has been successfully posted and is now visible to other users.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Post New Task'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer2<TaskFormProvider, TaskProvider>(
          builder: (context, formProvider, taskProvider, child) {
            return LoadingOverlay(
              isLoading: formProvider.isSubmitting || taskProvider.isLoading,
              message: 'Posting task...',
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(UIConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      Text(
                        'Task Title *',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      TextFormField(
                        controller: formProvider.titleController,
                        decoration: WidgetStyles.inputDecoration.copyWith(
                          hintText: 'Enter task title',
                          errorText: formProvider.errors['title'],
                        ),
                        validator: (value) => formProvider.errors['title'],
                        onChanged: (value) => formProvider.validateField('title'),
                      ),
                      const SizedBox(height: UIConstants.spacingL),
      
                      // Description
                      Text(
                        'Description *',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      TextFormField(
                        controller: formProvider.descriptionController,
                        maxLines: 4,
                        decoration: WidgetStyles.inputDecoration.copyWith(
                          hintText: 'Describe what needs to be done...',
                          errorText: formProvider.errors['description'],
                        ),
                        validator: (value) => formProvider.errors['description'],
                        onChanged: (value) => formProvider.validateField('description'),
                      ),
                      const SizedBox(height: UIConstants.spacingL),
      
                      // Category
                      Text(
                        'Category *',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      DropdownButtonFormField<String>(
                        value: formProvider.selectedCategory.isEmpty 
                            ? null 
                            : formProvider.selectedCategory,
                        decoration: WidgetStyles.inputDecoration.copyWith(
                          errorText: formProvider.errors['category'],
                        ),
                        items: TaskCategories.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  TaskCategories.categoryIcons[category],
                                  size: UIConstants.iconSizeS,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: UIConstants.spacingS),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            formProvider.setCategory(value);
                          }
                        },
                        validator: (value) => formProvider.errors['category'],
                      ),
                      const SizedBox(height: UIConstants.spacingL),
      
                      // Date and Time
                      Text(
                        'Date & Time *',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(UIConstants.spacingM),
                                decoration: BoxDecoration(
                                  border: Border.all(color: inputBorderColor),
                                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                                  color: inputBackgroundColor,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: textSecondaryColor),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      formProvider.selectedDate != null
                                          ? '${formProvider.selectedDate!.day}/${formProvider.selectedDate!.month}/${formProvider.selectedDate!.year}'
                                          : 'Select date',
                                      style: TextStyle(
                                        color: formProvider.selectedDate != null ? textPrimaryColor : textHintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: UIConstants.spacingM),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(UIConstants.spacingM),
                                decoration: BoxDecoration(
                                  border: Border.all(color: inputBorderColor),
                                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                                  color: inputBackgroundColor,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: textSecondaryColor),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      formProvider.selectedTime != null
                                          ? '${formProvider.selectedTime!.hour.toString().padLeft(2, '0')}:${formProvider.selectedTime!.minute.toString().padLeft(2, '0')}'
                                          : 'Select time',
                                      style: TextStyle(
                                        color: formProvider.selectedTime != null ? textPrimaryColor : textHintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (formProvider.errors['date'] != null || formProvider.errors['time'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: UIConstants.spacingS),
                          child: Text(
                            formProvider.errors['date'] ?? formProvider.errors['time'] ?? '',
                            style: TextStyle(color: errorColor, fontSize: UIConstants.fontSizeS),
                          ),
                        ),
                      const SizedBox(height: UIConstants.spacingL),
      
                      // Location
                      Text(
                        'Location *',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      TextFormField(
                        controller: formProvider.locationController,
                        decoration: WidgetStyles.inputDecoration.copyWith(
                          hintText: 'Enter location',
                          prefixIcon: const Icon(Icons.location_on),
                          errorText: formProvider.errors['location'],
                        ),
                        validator: (value) => formProvider.errors['location'],
                        onChanged: (value) => formProvider.validateField('location'),
                      ),
                      const SizedBox(height: UIConstants.spacingL),

                      // NEW: Mutual Task Toggle
                      Container(
                        padding: const EdgeInsets.all(UIConstants.spacingM),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              color: Colors.blue[700],
                              size: UIConstants.iconSizeM,
                            ),
                            const SizedBox(width: UIConstants.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mutual Task Exchange',
                                    style: TextStyles.heading3.copyWith(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: UIConstants.spacingS),
                                  Text(
                                    'Exchange tasks instead of offering payment',
                                    style: TextStyles.body2.copyWith(
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: formProvider.isMutualTask,
                              onChanged: (value) {
                                formProvider.setMutualTask(value);
                                if (value) {
                                  // Clear reward field when switching to mutual
                                  formProvider.rewardController.clear();
                                }
                              },
                              activeColor: Colors.blue[700],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingL),
      
                      // Reward (conditional based on mutual task)
                      if (!formProvider.isMutualTask) ...[
                        Text(
                          'Reward (£) *',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingS),
                        TextFormField(
                          controller: formProvider.rewardController,
                          keyboardType: TextInputType.number,
                          decoration: WidgetStyles.inputDecoration.copyWith(
                            hintText: 'Enter reward amount',
                            prefixIcon: const Icon(Icons.monetization_on),
                            errorText: formProvider.errors['reward'],
                          ),
                          validator: (value) => formProvider.errors['reward'],
                          onChanged: (value) => formProvider.validateField('reward'),
                        ),
                        const SizedBox(height: UIConstants.spacingL),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(UIConstants.spacingM),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[600],
                                size: UIConstants.iconSizeS,
                              ),
                              const SizedBox(width: UIConstants.spacingS),
                              Expanded(
                                child: Text(
                                  'No reward required - exchange-based task',
                                  style: TextStyles.body2.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingL),
                      ],
      
                      // Additional Requirements
                      Text(
                        'Additional Requirements (Optional)',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      TextFormField(
                        controller: formProvider.requirementsController,
                        maxLines: 3,
                        decoration: WidgetStyles.inputDecoration.copyWith(
                          hintText: 'Any additional requirements or notes...',
                          errorText: formProvider.errors['requirements'],
                        ),
                        onChanged: (value) => formProvider.validateField('requirements'),
                      ),
                      const SizedBox(height: UIConstants.spacingXXL),
      
                      // Submit Button
                      formProvider.isSubmitting
                          ? const LoadingButton(
                              isLoading: true,
                              text: 'Posting Task...',
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: UIConstants.buttonHeightL,
                              child: ElevatedButton(
                                onPressed: formProvider.isFormValid ? _submitTask : null,
                                style: WidgetStyles.primaryButtonStyle.copyWith(
                                  backgroundColor: WidgetStatePropertyAll(
                                    formProvider.isFormValid ? buttonPrimaryColor : buttonDisabledColor,
                                  ),
                                ),
                                child: const Text(
                                  'Post Task',
                                  style: TextStyle(fontSize: UIConstants.fontSizeL),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 