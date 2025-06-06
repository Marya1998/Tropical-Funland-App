import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessingClaim = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _claimReward(String rewardId, String rewardName) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to claim rewards.")),
      );
      return;
    }

    setState(() {
      _isProcessingClaim = true;
    });

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_name': user.email?.split('@')[0] ?? 'User',
        'sender_email': user.email ?? 'no_email@example.com',
        'subject': 'Reward Claimed: $rewardName',
        'message_content': 'User ${user.email} has claimed the reward "$rewardName" (Reward ID: $rewardId).',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("'$rewardName' claimed! Admin notified.")),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to claim reward: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      setState(() {
        _isProcessingClaim = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.teal[100],
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Available Rewards'),
            Tab(text: 'Claimed History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableRewards(),
          _buildClaimedHistory(),
        ],
      ),
    );
  }

  Widget _buildAvailableRewards() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('rewards')
          .stream(primaryKey: ['id'])
          .eq('is_claimable', true), // Only show claimable rewards
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading rewards: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Map<String, dynamic>> rewards = snapshot.data ?? [];

        if (rewards.isEmpty) {
          return const Center(child: Text('No available rewards at the moment.'));
        }

        // Changed from ListView.builder to GridView.builder for a better "show off" layout
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two items per row
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.8, // Adjusted aspect ratio for better card size
          ),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            String id = reward['id'].toString();
            String name = reward['name'] ?? 'Reward';
            String description = reward['description'] ?? 'No description.';
            int pointsCost = (reward['points_cost'] as int?) ?? 0;
            String imageUrl = reward['image_url'] ?? 'https://placehold.co/150x150/cccccc/ffffff?text=Reward'; // Placeholder image

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: InkWell(
                onTap: () {
                  // Show reward details in a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(name),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                imageUrl,
                                height: 150, // Larger image in dialog
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    'https://placehold.co/150x150/cccccc/ffffff?text=Error',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Cost: $pointsCost points', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(description),
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
                        if (reward['is_claimable'] == true)
                          ElevatedButton(
                            onPressed: _isProcessingClaim ? null : () => _claimReward(id, name),
                            child: _isProcessingClaim
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : const Text('Claim'),
                          ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center content for grid
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity, // Take full width of card
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.network(
                                'https://placehold.co/150x150/cccccc/ffffff?text=Error',
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pointsCost Points',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity, // Make button take full width
                        child: ElevatedButton(
                          onPressed: _isProcessingClaim ? null : () => _claimReward(id, name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isProcessingClaim
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : const Text('Claim', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClaimedHistory() {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view claimed rewards."));
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading claimed history: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> claimedMessages = snapshot.data ?? [];

        claimedMessages = claimedMessages.where((message) {
          final String senderEmail = (message['sender_email'] as String? ?? '').toLowerCase();
          final String subject = (message['subject'] as String? ?? '').toLowerCase();
          return senderEmail == (user.email ?? '').toLowerCase() &&
              subject.startsWith('reward claimed');
        }).toList();

        // Sort by creation date, newest first
        claimedMessages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));


        if (claimedMessages.isEmpty) {
          return const Center(child: Text('No claimed rewards in history.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: claimedMessages.length,
          itemBuilder: (context, index) {
            final message = claimedMessages[index];
            String rewardName = message['subject'].toString().replaceFirst('Reward Claimed: ', '').split(' (Reward ID:')[0];
            String claimDate = message['created_at'] != null
                ? DateTime.parse(message['created_at']).toLocal().toString().split(' ')[0]
                : 'N/A';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rewardName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('Claimed on: $claimDate', style: const TextStyle(color: Colors.grey)),
                    Text(message['message_content'] ?? ''),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
