import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _currentContent = 'Dashboard';
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _productStatusActive = true;
  bool _isProcessingOperation = false;
  final TextEditingController _searchProductController = TextEditingController();
  final TextEditingController _searchBookingIdController = TextEditingController();
  final TextEditingController _searchMailController = TextEditingController();
  final TextEditingController _settingNameController = TextEditingController();
  final TextEditingController _settingEmailController = TextEditingController();
  final TextEditingController _settingNewPasswordController = TextEditingController();
  final TextEditingController _settingConfirmPasswordController = TextEditingController();
  final TextEditingController _settingGenderController = TextEditingController();
  String _currentUserId = '';
  String _currentUserName = 'Admin';
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentAdminProfile();
    // Add listener for product search input
    _searchProductController.addListener(() {
      setState(() {
        // Trigger a rebuild when search query changes to filter products
      });
    });
    // Add listener for booking search input
    _searchBookingIdController.addListener(() {
      setState(() {
        // Trigger a rebuild when search query changes to filter bookings
      });
    });
    // Add listener for message search input
    _searchMailController.addListener(() {
      setState(() {
        // Trigger a rebuild when search query changes to filter messages
      });
    });
  }

  Future<void> _fetchCurrentAdminProfile() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _currentUserEmail = user.email ?? 'N/A';
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('name, gender')
            .eq('id', user.id)
            .single();
        if (response != null) {
          if (!mounted) return;
          setState(() {
            _currentUserName = response['name'] as String? ?? 'Admin';
            _settingNameController.text = _currentUserName;
            _settingEmailController.text = _currentUserEmail;
            _settingGenderController.text = response['gender'] as String? ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error fetching admin profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _searchProductController.dispose();
    _searchMailController.dispose();
    _searchBookingIdController.dispose();
    _settingNameController.dispose();
    _settingEmailController.dispose();
    _settingNewPasswordController.dispose();
    _settingConfirmPasswordController.dispose();
    _settingGenderController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (_productNameController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required text fields.")),
      );
      return;
    }

    // Basic validation for price and quantity
    if (double.tryParse(_priceController.text.trim()) == null ||
        int.tryParse(_quantityController.text.trim()) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid numbers for Price and Quantity.")),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessingOperation = true;
    });

    try {
      String? imageUrl = null; // No image upload logic in this version
      await Supabase.instance.client.from('products').insert({
        'name': _productNameController.text.trim(),
        'category': _categoryController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'status_active': _productStatusActive,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully (text-only)! ")),
      );

      // Clear fields after successful addition
      _productNameController.clear();
      _categoryController.clear();
      _priceController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      setState(() {
        _productStatusActive = true;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Database error adding product: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessingOperation = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId, String? imageUrl) async {
    if (!mounted) return;
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      if (!mounted) return;
      setState(() {
        _isProcessingOperation = true;
      });
      try {
        // Keep image deletion logic here in case older products have images
        if (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAbsolutePath == true && imageUrl.startsWith('http')) {
          final String bucketName = 'product-images';
          final Uri uri = Uri.parse(imageUrl);
          int publicIndex = uri.pathSegments.indexOf('public');
          if (publicIndex != -1 && publicIndex + 1 < uri.pathSegments.length && uri.pathSegments[publicIndex + 1] == bucketName) {
            final String storagePath = uri.pathSegments.sublist(publicIndex + 2).join('/');
            if (storagePath.isNotEmpty) {
              await Supabase.instance.client.storage.from(bucketName).remove([storagePath]);
            }
          }
        }
        await Supabase.instance.client.from('products').delete().eq('id', productId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully!")),
        );
      } on StorageException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting image: ${e.message}. Product record still deleted.")),
        );
      } on PostgrestException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting product from database: ${e.message}")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred during deletion: $e")),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isProcessingOperation = false;
        });
      }
    }
  }

  // START: Added _editProduct function
  Future<void> _editProduct(Map<String, dynamic> product) async {
    // Create TextEditingControllers and a boolean for the product status
    // Pre-fill them with the current product data
    final TextEditingController editProductNameController = TextEditingController(text: product['name'] as String? ?? '');
    final TextEditingController editCategoryController = TextEditingController(text: product['category'] as String? ?? '');
    final TextEditingController editPriceController = TextEditingController(text: (product['price'] as num?)?.toString() ?? '0.0');
    final TextEditingController editQuantityController = TextEditingController(text: (product['quantity'] as int?)?.toString() ?? '0');
    final TextEditingController editDescriptionController = TextEditingController(text: product['description'] as String? ?? '');
    bool editProductStatusActive = product['status_active'] as bool? ?? true;

    if (!mounted) return;

    final bool? confirmUpdate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder to allow internal state changes in the dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: editProductNameController,
                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editCategoryController,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: editPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Price (RM)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: editQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Quantity Available', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editDescriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: editProductStatusActive,
                          onChanged: (bool? newValue) {
                            setDialogState(() { // Use setDialogState to update the dialog's UI
                              editProductStatusActive = newValue!;
                            });
                          },
                        ),
                        const Text('Status (Active)'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // Process the update if confirmed
    if (confirmUpdate == true) {
      if (!mounted) return;
      setState(() {
        _isProcessingOperation = true; // Show loading indicator
      });

      try {
        await Supabase.instance.client.from('products').update({
          'name': editProductNameController.text.trim(),
          'category': editCategoryController.text.trim(),
          'price': double.parse(editPriceController.text.trim()),
          'quantity': int.parse(editQuantityController.text.trim()),
          'description': editDescriptionController.text.trim(),
          'status_active': editProductStatusActive,
        }).eq('id', product['id']); // Update the specific product by its ID

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated successfully!")),
        );
      } on PostgrestException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database error updating product: ${e.message}")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred during update: $e")),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isProcessingOperation = false; // Hide loading indicator
        });
        // Dispose controllers after use
        editProductNameController.dispose();
        editCategoryController.dispose();
        editPriceController.dispose();
        editQuantityController.dispose();
        editDescriptionController.dispose();
      }
    }
  }
  // END: Added _editProduct function

  Future<void> _saveSettings() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not logged in.")),
      );
      return;
    }

    // Validate email if it's being changed (though currently readOnly)
    // if (_settingEmailController.text.isEmpty || !EmailValidator.validate(_settingEmailController.text.trim())) {
    //   if (!mounted) return;
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Please enter a valid email address.")),
    //   );
    //   return;
    // }

    if (!mounted) return;
    setState(() {
      _isProcessingOperation = true;
    });

    try {
      await Supabase.instance.client.from('users').update({
        'name': _settingNameController.text.trim(),
        'gender': _settingGenderController.text.trim(),
      }).eq('id', user.id);

      // Handle password update if new password is provided
      if (_settingNewPasswordController.text.isNotEmpty) {
        if (_settingNewPasswordController.text != _settingConfirmPasswordController.text) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New password and confirm password do not match.")),
          );
          if (!mounted) return;
          setState(() { _isProcessingOperation = false; });
          return;
        }
        await Supabase.instance.client.auth.updateUser(UserAttributes(
          password: _settingNewPasswordController.text,
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated successfully!")),
      );

      // Refresh profile data and clear password fields
      _fetchCurrentAdminProfile();
      _settingNewPasswordController.clear();
      _settingConfirmPasswordController.clear();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating auth: ${e.message}")),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessingOperation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - $_currentContent'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getBottomNavIndex(_currentContent),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFD4F0EC),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() { _currentContent = 'Dashboard'; });
              break;
            case 1:
              setState(() { _currentContent = 'Add New Product'; });
              break;
            case 2:
              setState(() { _currentContent = 'Manage Product'; });
              break;
            case 3:
              setState(() { _currentContent = 'View Booking'; });
              break;
            case 4:
              setState(() { _currentContent = 'Messages'; });
              break;
            case 5:
              setState(() { _currentContent = 'Setting'; _fetchCurrentAdminProfile(); });
              break;
            case 6: // Logout
              Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully!")),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add New Product'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manage Product'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'View Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }

  int _getBottomNavIndex(String currentContent) {
    switch (currentContent) {
      case 'Dashboard':
        return 0;
      case 'Add New Product':
        return 1;
      case 'Manage Product':
        return 2;
      case 'View Booking':
        return 3;
      case 'Messages':
        return 4;
      case 'Setting':
        return 5;
      default:
        return 0;
    }
  }

  Widget _buildBodyContent() {
    switch (_currentContent) {
      case 'Dashboard':
        return _buildAdminDashboardContent();
      case 'Add New Product':
        return _buildAddNewProductContent();
      case 'Manage Product':
        return _buildManageProductContent();
      case 'View Booking':
        return _buildViewBookingContent();
      case 'Messages':
        return _buildMessagesContent();
      case 'Setting':
        return _buildSettingContent();
      default:
        return const Center(child: Text('Unknown Admin Section'));
    }
  }

  Widget _buildAdminDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hi $_currentUserName',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800]),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.person_outline, size: 24, color: Colors.teal),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  title: 'Sales Statistics',
                  content: Column(
                    children: [
                      Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(child: Text('Graph Placeholder')),
                      ),
                      const SizedBox(height: 8),
                      const Text('Total visitor: [Number]', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDashboardCard(
                  title: 'Booking Status',
                  content: Column(
                    children: [
                      Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(child: Text('Graph Placeholder')),
                      ),
                      const SizedBox(height: 8),
                      const Text('Upcoming Events: [Number]', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({required String title, required Widget content}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewProductContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Product',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Removed the GestureDetector and FutureBuilder for image selection/preview
          TextFormField(
            controller: _productNameController,
            decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (RM)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity Available', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _productStatusActive,
                onChanged: (bool? newValue) {
                  setState(() {
                    _productStatusActive = newValue!;
                  });
                },
              ),
              const Text('Status (Active)'),
            ],
          ),
          const SizedBox(height: 24),
          _isProcessingOperation
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _addProduct,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildManageProductContent() {
    String searchQuery = _searchProductController.text.trim().toLowerCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Products',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchProductController,
              decoration: const InputDecoration(
                hintText: 'Search Product by Name or Category',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _isProcessingOperation
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('products').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              List<Map<String, dynamic>> products = snapshot.data ?? [];
              if (searchQuery.isNotEmpty) {
                products = products.where((product) {
                  final String name = (product['name'] as String? ?? '').toLowerCase();
                  final String category = (product['category'] as String? ?? '').toLowerCase();
                  return name.contains(searchQuery) || category.contains(searchQuery);
                }).toList();
              }
              if (products.isEmpty) {
                return const Center(child: Text('No products found. Add some new products!'));
              }
              List<DataRow> productRows = products.map((product) {
                String id = product['id'].toString();
                String? imageUrl = product['image_url'] as String?; // Still retrieve it, but won't display
                String name = product['name'] ?? 'N/A';
                String description = product['description'] ?? 'No description';
                double price = (product['price'] as num?)?.toDouble() ?? 0.0;
                int quantity = (product['quantity'] as int?) ?? 0;
                bool statusActive = product['status_active'] as bool? ?? false;

                return DataRow(cells: [
                  // Removed the DataCell for Image
                  DataCell(Text(name)),
                  DataCell(Text(description.length > 20 ? '${description.substring(0, 20)}...' : description)),
                  DataCell(Text('RM ${price.toStringAsFixed(2)}')),
                  DataCell(Text('$quantity')),
                  DataCell(Icon(
                    statusActive ? Icons.check_circle : Icons.cancel,
                    color: statusActive ? Colors.green : Colors.red,
                    size: 20,
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          if (!mounted) return;
                          _editProduct(product); // Call the new edit function, passing the entire product map
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          // Keep image deletion logic in _deleteProduct, just in case
                          // older products had images that need to be cleaned up from storage.
                          _deleteProduct(id, imageUrl);
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 8.0,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 60,
                  columns: const [
                    // Removed the DataColumn for Image
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Summary')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: productRows,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewBookingContent() {
    String searchQuery = _searchBookingIdController.text.trim().toLowerCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View Bookings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchBookingIdController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'Search Booking ID or Customer Email',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'All Upcoming Bookings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('bookings').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              List<Map<String, dynamic>> bookings = snapshot.data ?? [];
              if (searchQuery.isNotEmpty) {
                bookings = bookings.where((booking) {
                  final String bookingId = (booking['id'] as String? ?? '').toLowerCase();
                  final String customerEmail = (booking['customer_email'] as String? ?? '').toLowerCase();
                  return bookingId.contains(searchQuery) || customerEmail.contains(searchQuery);
                }).toList();
              }
              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }
              List<DataRow> bookingRows = bookings.map((booking) {
                String id = booking['id'].toString();
                String date = booking['booking_date'] != null
                    ? DateTime.parse(booking['booking_date']).toLocal().toString().split(' ')[0]
                    : 'N/A';
                String customerEmail = booking['customer_email'] ?? 'N/A';
                String status = booking['status'] ?? 'N/A';
                return DataRow(cells: [
                  DataCell(Text(date)),
                  DataCell(Text(customerEmail)),
                  DataCell(Text(status)),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle_outline, size: 20, color: status == 'Approved' ? Colors.grey : Colors.green),
                        onPressed: status == 'Approved' || _isProcessingOperation
                            ? null
                            : () async {
                          if (!mounted) return;
                          setState(() { _isProcessingOperation = true; });
                          await Supabase.instance.client.from('bookings').update({'status': 'Approved'}).eq('id', id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking Approved!")),
                          );
                          if (!mounted) return;
                          setState(() { _isProcessingOperation = false; });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel_outlined, size: 20, color: status == 'Rejected' ? Colors.grey : Colors.red),
                        onPressed: status == 'Rejected' || _isProcessingOperation
                            ? null
                            : () async {
                          if (!mounted) return;
                          setState(() { _isProcessingOperation = true; });
                          await Supabase.instance.client.from('bookings').update({'status': 'Rejected'}).eq('id', id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking Rejected!")),
                          );
                          if (!mounted) return;
                          setState(() { _isProcessingOperation = false; });
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12.0,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: bookingRows,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesContent() {
    String searchQuery = _searchMailController.text.trim().toLowerCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchMailController,
              decoration: const InputDecoration(
                hintText: 'Search by Sender Email',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('messages').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              List<Map<String, dynamic>> messages = snapshot.data ?? [];
              if (searchQuery.isNotEmpty) {
                messages = messages.where((message) {
                  final String senderEmail = (message['sender_email'] as String? ?? '').toLowerCase();
                  return senderEmail.contains(searchQuery);
                }).toList();
              }
              if (messages.isEmpty) {
                return const Center(child: Text('No messages found.'));
              }
              List<DataRow> messageRows = messages.map((message) {
                String senderName = message['sender_name'] ?? 'N/A';
                String senderEmail = message['sender_email'] ?? 'N/A';
                String subject = message['subject'] ?? 'N/A';
                String content = message['message_content'] ?? 'No content';
                return DataRow(cells: [
                  DataCell(Text(senderName)),
                  DataCell(Text(senderEmail)),
                  DataCell(Text(subject.length > 20 ? '${subject.substring(0, 20)}...' : subject)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Message from $senderName'),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  Text('From: $senderEmail'),
                                  Text('Subject: $subject'),
                                  const SizedBox(height: 10),
                                  Text(content),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ]);
              }).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12.0,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text('Sender Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Subject')),
                    DataColumn(label: Text('View')),
                  ],
                  rows: messageRows,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setting Page',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.teal[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.teal),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _settingNameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _settingEmailController,
            readOnly: true, // Email is read-only for now
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _settingNewPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password (leave blank to keep current)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _settingConfirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _settingGenderController,
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          _isProcessingOperation
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Save Settings'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
