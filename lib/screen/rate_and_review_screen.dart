import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ensure this class name and file name match!
class RateAndReviewScreen extends StatefulWidget { // This class name must be correct
  final String productId;

  const RateAndReviewScreen({super.key, required this.productId});

  @override
  State<RateAndReviewScreen> createState() => _RateAndReviewScreenState();
}

class _RateAndReviewScreenState extends State<RateAndReviewScreen> {
  int _currentRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  String _productName = 'Product';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductName();
  }

  Future<void> _fetchProductName() async {
    setState(() { _isLoading = true; });
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('name')
          .eq('id', widget.productId)
          .single();
      if (response != null) {
        setState(() {
          _productName = response['name'] as String? ?? 'Product';
        });
      }
    } catch (e) {
      debugPrint('Error fetching product name for review: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _submitReview() async {
    if (_currentRating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }

    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a review.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_name': user.email?.split('@')[0] ?? 'User',
        'sender_email': user.email,
        'subject': 'Product Review: $_productName (Rating: $_currentRating/5)',
        'message_content': _reviewController.text.isEmpty ? 'No review text provided.' : _reviewController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
      Navigator.pop(context); // Go back to previous screen
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate & Review $_productName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rating for $_productName:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _currentRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 30),
            Text(
              'Your Review:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts about the product...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
