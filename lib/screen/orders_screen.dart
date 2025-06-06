import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_skeleton/screen/order_details_screen.dart';
import 'package:flutter_skeleton/screen/rate_and_review_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchOrderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchOrderController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.teal[100],
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Orders'),
            Tab(text: 'Purchase History'),
            Tab(text: 'Rate & Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyOrdersTab(), // New dedicated method for My Orders tab
          _buildPurchaseHistoryTab(), // Renamed for clarity
          _buildRateAndReviewTab(),
        ],
      ),
    );
  }

  // New method for the "My Orders" tab content
  Widget _buildMyOrdersTab() {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view your orders."));
    }

    // Fetch only pending orders for "My Orders" tab
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> allOrders = snapshot.data ?? [];

        // Filter for current user's pending orders
        List<Map<String, dynamic>> pendingOrders = allOrders.where((order) {
          return (order['user_id'] as String? ?? '') == user.id &&
              (order['status'] as String? ?? '') == 'Pending';
        }).toList();

        // Sort pending orders by creation date, newest first
        pendingOrders.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

        // Get the first active booking to display prominently
        Map<String, dynamic>? activeBooking = pendingOrders.isNotEmpty ? pendingOrders.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeBooking != null)
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('products')
                      .select('name, image_url')
                      .eq('id', activeBooking['product_id'])
                      .limit(1),
                  builder: (context, productSnapshot) {
                    String productName = 'Product N/A';
                    String productImageUrl = 'https://placehold.co/60x60/cccccc/ffffff?text=No+Img';
                    if (productSnapshot.connectionState == ConnectionState.done && productSnapshot.hasData && productSnapshot.data!.isNotEmpty) {
                      productName = productSnapshot.data![0]['name'] as String? ?? productName;
                      productImageUrl = productSnapshot.data![0]['image_url'] as String? ?? productImageUrl;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () async {
                          final bool? deleted = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: activeBooking, product: productSnapshot.data?.first)),
                          );
                          if (deleted == true) {
                            setState(() {}); // Refresh data if an order was deleted
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  productImageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      'https://placehold.co/60x60/cccccc/ffffff?text=Error',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Your Active Booking: $productName',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No active bookings found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // You can optionally add a list of all pending orders here if needed,
              // or just rely on the single "Active Booking" card.
              // For now, let's keep it simple as per the screenshot.
            ],
          ),
        );
      },
    );
  }

  // Renamed from _buildOrderList to _buildPurchaseHistoryTab for clarity
  Widget _buildPurchaseHistoryTab() {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view your purchase history."));
    }

    String searchQuery = _searchOrderController.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchOrderController,
              decoration: const InputDecoration(
                hintText: 'Search purchase history by product name',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('orders')
                .stream(primaryKey: ['id']), // Fetch all orders for client-side filtering
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Map<String, dynamic>> allOrders = snapshot.data ?? [];

              // Client-side filtering by user_id and status (Approved or Completed for history)
              List<Map<String, dynamic>> historyOrders = allOrders.where((order) {
                final String orderUserId = (order['user_id'] as String? ?? '');
                final String orderStatus = (order['status'] as String? ?? '');
                return orderUserId == user.id && (orderStatus == 'Approved' || orderStatus == 'Completed');
              }).toList();

              // Sort history orders by creation date, newest first
              historyOrders.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

              if (historyOrders.isEmpty) {
                return const Center(child: Text('No purchase history found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: historyOrders.length,
                itemBuilder: (context, index) {
                  final order = historyOrders[index];
                  String orderIdDisplay = order['id'].toString().substring(0, 8);
                  String status = order['status'] ?? 'N/A';
                  String createdAt = order['created_at'] != null
                      ? DateTime.parse(order['created_at']).toLocal().toString().split(' ')[0]
                      : 'N/A';
                  double totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;
                  String productId = order['product_id'].toString();

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: Supabase.instance.client
                        .from('products')
                        .select('name, image_url')
                        .eq('id', productId)
                        .limit(1),
                    builder: (context, productSnapshot) {
                      String productName = 'Product N/A';
                      String productImageUrl = 'https://placehold.co/60x60/cccccc/ffffff?text=No+Img';

                      if (productSnapshot.connectionState == ConnectionState.done && productSnapshot.hasData && productSnapshot.data!.isNotEmpty) {
                        productName = productSnapshot.data![0]['name'] as String? ?? productName;
                        productImageUrl = productSnapshot.data![0]['image_url'] as String? ?? productImageUrl;
                      }

                      // Apply client-side search query filtering based on product name
                      if (searchQuery.isNotEmpty && !productName.toLowerCase().contains(searchQuery)) {
                        return Container(); // Hide if it doesn't match search
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: InkWell(
                          onTap: () async {
                            final bool? deleted = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order, product: productSnapshot.data?.first)),
                            );
                            if (deleted == true) {
                              setState(() {});
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    productImageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        'https://placehold.co/60x60/cccccc/ffffff?text=Error',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Order Date: $createdAt'),
                                      Text('Total: RM ${totalPrice.toStringAsFixed(2)}'),
                                      Text(
                                        'Status: $status',
                                        style: TextStyle(
                                          color: status == 'Pending'
                                              ? Colors.orange
                                              : (status == 'Approved' || status == 'Completed' ? Colors.green : Colors.red),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRateAndReviewTab() {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view products to review."));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading orders for review: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> allOrders = snapshot.data ?? [];

        List<Map<String, dynamic>> ordersToReview = allOrders.where((order) {
          final String orderUserId = (order['user_id'] as String? ?? '');
          final String orderStatus = (order['status'] as String? ?? '');
          // Assuming 'Approved' or 'Completed' orders can be reviewed
          return orderUserId == user.id && (orderStatus == 'Approved' || orderStatus == 'Completed');
        }).toList();

        // Sort by creation date, newest first
        ordersToReview.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));


        if (ordersToReview.isEmpty) {
          return const Center(child: Text('No completed orders eligible for review.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: ordersToReview.length,
          itemBuilder: (context, index) {
            final order = ordersToReview[index];
            String orderIdDisplay = order['id'].toString().substring(0, 8);
            String productId = order['product_id'].toString();

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('products')
                  .select('name, image_url')
                  .eq('id', productId)
                  .limit(1),
              builder: (context, productSnapshot) {
                String productName = 'Product ID: ${productId.substring(0,8)}';
                String productImageUrl = 'https://placehold.co/60x60/cccccc/ffffff?text=No+Img';

                if (productSnapshot.connectionState == ConnectionState.done && productSnapshot.hasData && productSnapshot.data!.isNotEmpty) {
                  productName = productSnapshot.data![0]['name'] as String? ?? productName;
                  productImageUrl = productSnapshot.data![0]['image_url'] as String? ?? productImageUrl;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RateAndReviewScreen(productId: productId)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              productImageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  'https://placehold.co/60x60/cccccc/ffffff?text=Error',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('Order ID: #$orderIdDisplay', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.rate_review, color: Colors.teal, size: 24), // Review icon
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18), // Arrow
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
