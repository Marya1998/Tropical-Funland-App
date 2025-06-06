import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_skeleton/screen/rate_and_review_screen.dart'; // <<<--- CRITICAL: Ensure this import is present and correct!

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? product; // Optional: product details if pre-fetched

  const OrderDetailsScreen({super.key, required this.order, this.product});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _fetchedProduct;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _fetchedProduct = widget.product;
      _isLoading = false;
    } else {
      _fetchProductDetails(widget.order['product_id']);
    }
  }

  Future<void> _fetchProductDetails(String productId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*')
          .eq('id', productId)
          .single();
      setState(() {
        _fetchedProduct = response;
      });
    } catch (e) {
      debugPrint('Error fetching product details for order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteOrder() async {
    if (!mounted) return;
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this order? This action cannot be undone.'),
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
      try {
        await Supabase.instance.client.from('orders').delete().eq('id', widget.order['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully!')),
        );
        Navigator.pop(context, true); // Pop with true to indicate deletion
      } catch (e) {
        debugPrint('Error deleting order: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete order: $e')),
        );
      }
    }
  }

  void _editOrder() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit order functionality not fully implemented.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    String orderId = widget.order['id'].toString();
    String productName = _fetchedProduct?['name'] ?? 'Loading Product...';
    String productDescription = _fetchedProduct?['description'] ?? 'No description.';
    String productImageUrl = _fetchedProduct?['image_url'] ?? 'https://placehold.co/100x100/cccccc/ffffff?text=No+Image';
    double orderQuantity = (widget.order['quantity'] as num?)?.toDouble() ?? 1;
    double totalPrice = (widget.order['total_price'] as num?)?.toDouble() ?? 0.0;
    String status = widget.order['status'] ?? 'N/A';
    String createdAt = widget.order['created_at'] != null
        ? DateTime.parse(widget.order['created_at']).toLocal().toString().split('.')[0]
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: status == 'Pending' ? _editOrder : null,
            tooltip: 'Edit Order',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: status == 'Pending' ? _deleteOrder : null,
            tooltip: 'Delete Order',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Order Date: $createdAt',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: status == 'Approved'
                    ? Colors.green
                    : status == 'Rejected'
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
            const Divider(height: 30, thickness: 1),
            Text(
              'Product Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      productImageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          'https://placehold.co/180x180/cccccc/ffffff?text=Image+Error',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      productName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productDescription,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity: ${orderQuantity.toInt()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RM ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (status == 'Approved' || status == 'Completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Correctly navigate to RateAndReviewScreen
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RateAndReviewScreen(productId: widget.order['product_id'])));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Rate & Review Product'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
