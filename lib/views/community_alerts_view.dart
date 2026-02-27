import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_entrance.dart';

class CommunityAlertsView extends StatefulWidget {
  const CommunityAlertsView({super.key});

  @override
  State<CommunityAlertsView> createState() => _CommunityAlertsViewState();
}

class _CommunityAlertsViewState extends State<CommunityAlertsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Nearby';
  bool _showProtocols = true;
  final bool _isAuthorityUser = false;

  final List<_CommunityPost> _posts = [
    const _CommunityPost(
      id: 'C-2201',
      type: PostType.alert,
      authorName: 'Kavya Nair',
      authorRole: 'Verified Volunteer',
      title: 'Loose power line near bus stop',
      description:
          'Avoid the north entrance until the electric team isolates the line.',
      location: 'MG Road',
      timeAgo: '12 mins ago',
      distanceKm: 0.8,
      category: 'Safety',
      severity: 'High',
      verified: true,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
      imageBytes: null,
      upvotes: 128,
      comments: 24,
      commentsData: [
        _Comment(
          author: 'Maya',
          role: 'Resident',
          message: 'Thanks for the heads up. Took the other gate.',
          timeAgo: '8 mins ago',
        ),
        _Comment(
          author: 'Rahul',
          role: 'Ward Volunteer',
          message: 'Team informed. Isolation expected by 4 PM.',
          timeAgo: '4 mins ago',
        ),
      ],
    ),
    const _CommunityPost(
      id: 'C-2196',
      type: PostType.update,
      authorName: 'Ward Control',
      authorRole: 'Authority',
      title: 'Pothole repair started',
      description:
          'Work crew is fixing the deep pothole near the flyover. Expect slow traffic.',
      location: 'Outer Ring Road',
      timeAgo: '40 mins ago',
      distanceKm: 2.4,
      category: 'Road',
      severity: 'Medium',
      verified: true,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
      imageBytes: null,
      upvotes: 62,
      comments: 12,
      commentsData: [
        _Comment(
          author: 'Ajay',
          role: 'Resident',
          message: 'Work in progress. Traffic is moving slowly.',
          timeAgo: '28 mins ago',
        ),
      ],
    ),
    const _CommunityPost(
      id: 'C-2210',
      type: PostType.tip,
      authorName: 'Sana',
      authorRole: 'Resident',
      title: 'Streetlight outage reported',
      description:
          'If you are walking, prefer the main road till 10 PM. Lights are off on 5th lane.',
      location: 'Indiranagar',
      timeAgo: '1h ago',
      distanceKm: 3.1,
      category: 'Lighting',
      severity: 'Low',
      verified: false,
      imageUrl: null,
      imageBytes: null,
      upvotes: 41,
      comments: 6,
      commentsData: [
        _Comment(
          author: 'Vikram',
          role: 'Resident',
          message: 'Confirmed. It is dark near the corner.',
          timeAgo: '40 mins ago',
        ),
      ],
    ),
    const _CommunityPost(
      id: 'C-2208',
      type: PostType.help,
      authorName: 'Ajith',
      authorRole: 'Resident',
      title: 'Water leakage near metro gate',
      description:
          'Requesting local attention. Water is overflowing and creating a slippery patch.',
      location: 'KR Puram',
      timeAgo: '2h ago',
      distanceKm: 4.2,
      category: 'Water',
      severity: 'Medium',
      verified: false,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
      imageBytes: null,
      upvotes: 18,
      comments: 4,
      commentsData: [],
    ),
    const _CommunityPost(
      id: 'C-2189',
      type: PostType.notice,
      authorName: 'City Office',
      authorRole: 'Authority',
      title: 'Ward cleanup drive tomorrow',
      description:
          'Join the 7 AM cleanup drive at the community park. Gloves and bags provided.',
      location: 'BTM Layout',
      timeAgo: '3h ago',
      distanceKm: 5.8,
      category: 'Community',
      severity: 'Low',
      verified: true,
      imageUrl: null,
      imageBytes: null,
      upvotes: 73,
      comments: 18,
      commentsData: [
        _Comment(
          author: 'Leena',
          role: 'Resident',
          message: 'I will join the drive with my neighbors.',
          timeAgo: '2h ago',
        ),
      ],
    ),
    const _CommunityPost(
      id: 'C-2214',
      type: PostType.alert,
      authorName: 'Nitin Kumar',
      authorRole: 'Resident',
      title: 'Open manhole near school gate',
      description:
          'Please avoid the left-side lane near the school gate. Manhole cover is displaced.',
      location: 'JP Nagar',
      timeAgo: '18 mins ago',
      distanceKm: 2.1,
      category: 'Public Safety',
      severity: 'High',
      verified: false,
      imageUrl:
          'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=900&q=80',
      imageBytes: null,
      upvotes: 54,
      comments: 9,
      commentsData: [
        _Comment(
          author: 'Asha',
          role: 'Resident',
          message: 'Shared with school admin. Barricades added temporarily.',
          timeAgo: '10 mins ago',
        ),
      ],
    ),
    const _CommunityPost(
      id: 'C-2217',
      type: PostType.update,
      authorName: 'Ward Engineer',
      authorRole: 'Authority',
      title: 'Drain cleaning completed in Sector 3',
      description:
          'Teams completed desilting of storm drains in Sector 3. Next zone starts tomorrow morning.',
      location: 'HSR Layout',
      timeAgo: '32 mins ago',
      distanceKm: 2.8,
      category: 'Water',
      severity: 'Low',
      verified: true,
      imageUrl: null,
      imageBytes: null,
      upvotes: 47,
      comments: 7,
      commentsData: [
        _Comment(
          author: 'Ritesh',
          role: 'Resident',
          message: 'Flow improved after rain. Thanks for quick action.',
          timeAgo: '20 mins ago',
        ),
      ],
    ),
    const _CommunityPost(
      id: 'C-2220',
      type: PostType.help,
      authorName: 'Megha',
      authorRole: 'Resident',
      title: 'Broken footpath tile caused minor fall',
      description:
          'Need immediate patching near metro pillar 17. Pedestrians are tripping at night.',
      location: 'Banashankari',
      timeAgo: '54 mins ago',
      distanceKm: 4.6,
      category: 'Road',
      severity: 'Medium',
      verified: false,
      imageUrl:
          'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=900&q=80',
      imageBytes: null,
      upvotes: 22,
      comments: 5,
      commentsData: [],
    ),
    const _CommunityPost(
      id: 'C-2222',
      type: PostType.tip,
      authorName: 'Community Volunteer',
      authorRole: 'Verified Volunteer',
      title: 'Temporary safe walking route after 9 PM',
      description:
          'Use the main service road between 9 PM and 11 PM. Streetlights are active and police patrol is visible.',
      location: 'Whitefield',
      timeAgo: '1h ago',
      distanceKm: 5.2,
      category: 'Safety',
      severity: 'Low',
      verified: true,
      imageUrl: null,
      imageBytes: null,
      upvotes: 66,
      comments: 13,
      commentsData: [
        _Comment(
          author: 'Naina',
          role: 'Resident',
          message: 'Very helpful. I followed this route yesterday.',
          timeAgo: '42 mins ago',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CommunityPost> get _filteredPosts {
    final query = _searchController.text.trim().toLowerCase();
    return _posts.where((post) {
      final matchesQuery = query.isEmpty ||
          post.title.toLowerCase().contains(query) ||
          post.description.toLowerCase().contains(query) ||
          post.location.toLowerCase().contains(query);
      if (!matchesQuery) return false;
      switch (_selectedFilter) {
        case 'Verified':
          return post.verified;
        case 'High Priority':
          return post.severity == 'High';
        case 'Nearby':
          return post.distanceKm <= 3;
        default:
          return true;
      }
    }).toList();
  }

  void _openComposer() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController =
        TextEditingController(text: 'MG Road, Bengaluru');
    PostType selectedType = PostType.alert;
    String selectedCategory = 'Road';
    String selectedSeverity = 'Medium';
    bool attachPhoto = false;
    bool postAsVerified = false;
    Uint8List? selectedImageBytes;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.border(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create civic update',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posts must be location-based and follow community rules.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Post type',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PostType.values.map((type) {
                          final selected = selectedType == type;
                          return ChoiceChip(
                            label: Text(type.label),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() => selectedType = type);
                            },
                            selectedColor: AppTheme.primaryNavy.withOpacity(0.12),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppTheme.primaryNavy
                                  : AppTheme.textMuted(context),
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(
                            value: 'Road',
                            child: Text('Road'),
                          ),
                          DropdownMenuItem(
                            value: 'Lighting',
                            child: Text('Lighting'),
                          ),
                          DropdownMenuItem(
                            value: 'Waste',
                            child: Text('Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'Water',
                            child: Text('Water'),
                          ),
                          DropdownMenuItem(
                            value: 'Public Safety',
                            child: Text('Public Safety'),
                          ),
                          DropdownMenuItem(
                            value: 'Community',
                            child: Text('Community'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedCategory = value);
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category_outlined),
                          hintText: 'Category',
                          filled: true,
                          fillColor: AppTheme.surface(context),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ComposerField(
                        controller: titleController,
                        hint: 'Title',
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ComposerField(
                        controller: descController,
                        hint: 'Describe the issue or update',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _ComposerField(
                        controller: locationController,
                        hint: 'Location',
                        icon: Icons.place_outlined,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSeverity,
                        items: const [
                          DropdownMenuItem(
                            value: 'Low',
                            child: Text('Low severity'),
                          ),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Text('Medium severity'),
                          ),
                          DropdownMenuItem(
                            value: 'High',
                            child: Text('High severity'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedSeverity = value);
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.flag_outlined),
                          hintText: 'Severity',
                          filled: true,
                          fillColor: AppTheme.surface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          setSheetState(() {
                            selectedImageBytes = bytes;
                            attachPhoto = true;
                          });
                        },
                        icon: Icon(
                          attachPhoto
                              ? Icons.check_circle_outline
                              : Icons.image_outlined,
                        ),
                        label: Text(
                          attachPhoto ? 'Photo added' : 'Add photo',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          setSheetState(() {
                            selectedImageBytes = bytes;
                            attachPhoto = true;
                          });
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Use camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: attachPhoto
                            ? () {
                                setSheetState(() {
                                  selectedImageBytes = null;
                                  attachPhoto = false;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ),
                      if (selectedImageBytes != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          child: Image.memory(
                            selectedImageBytes!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_isAuthorityUser)
                        SwitchListTile(
                          value: postAsVerified,
                          onChanged: (value) {
                            setSheetState(() => postAsVerified = value);
                          },
                          title: const Text('Publish as verified'),
                          subtitle: const Text(
                            'Only authorities can post verified updates.',
                          ),
                          activeColor: AppTheme.primaryNavy,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: AppTheme.primaryNavy),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Verified badge is reserved for authorities and trusted volunteers.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.textMuted(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      _PostButton(
                        label: 'Publish update',
                        onTap: () {
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          final location = locationController.text.trim();
                          if (title.isEmpty ||
                              desc.isEmpty ||
                              location.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fill all required fields.'),
                              ),
                            );
                            return;
                          }

                          final newPost = _CommunityPost(
                            id:
                                'C-${DateTime.now().millisecondsSinceEpoch % 10000}',
                            type: selectedType,
                            authorName: _isAuthorityUser
                                ? 'City Office'
                                : 'You',
                            authorRole:
                                _isAuthorityUser ? 'Authority' : 'Resident',
                            title: title,
                            description: desc,
                            location: location,
                            timeAgo: 'Just now',
                            distanceKm: 0.5,
                            category: selectedCategory,
                            severity: selectedSeverity,
                            verified: _isAuthorityUser && postAsVerified,
                            imageUrl: null,
                            imageBytes: attachPhoto ? selectedImageBytes : null,
                            upvotes: 0,
                            comments: 0,
                            commentsData: const [],
                          );

                          setState(() {
                            _posts.insert(0, newPost);
                          });
                          Navigator.pop(context);
                        },
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

  void _openCommentsSheet(_CommunityPost post) {
    final controller = TextEditingController();
    final List<_Comment> comments = List.of(post.commentsData);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.border(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Comments',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _CommentTile(comment: comment);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: comments.length,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Write a comment',
                              filled: true,
                              fillColor: AppTheme.surface(context),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            final newComment = _Comment(
                              author: 'You',
                              role: 'Resident',
                              message: text,
                              timeAgo: 'Just now',
                            );
                            setSheetState(() {
                              comments.insert(
                                0,
                                newComment,
                              );
                            });
                            setState(() {
                              final index = _posts.indexWhere(
                                (item) => item.id == post.id,
                              );
                              if (index != -1) {
                                final current = _posts[index];
                                _posts[index] = current.copyWith(
                                  comments: current.comments + 1,
                                  commentsData: [
                                    newComment,
                                    ...current.commentsData,
                                  ],
                                );
                              }
                            });
                            controller.clear();
                          },
                          icon: const Icon(Icons.send_rounded),
                          color: AppTheme.primaryNavy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: const Text(
          'Post update',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        foregroundColor: Colors.white,
        onPressed: _openComposer,
      ),
      body: SafeArea(
        child: AnimatedEntrance(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppTheme.primaryNavy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Community Alerts',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Hero(
                      tag: 'vidhigya-wordmark',
                      child: Image.asset(
                        'assets/images/vidhigya_wordmark.png',
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Civic updates from your neighborhood, verified and actionable.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _ProtocolCard(
                  expanded: _showProtocols,
                  onToggle: () {
                    setState(() {
                      _showProtocols = !_showProtocols;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SearchBar(controller: _searchController),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _FilterRow(
                  selected: _selectedFilter,
                  onSelect: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemBuilder: (context, index) {
                    final post = _filteredPosts[index];
                    return _PostCard(
                      post: post,
                      onAction: (action, selectedPost) {
                        if (action == 'Report') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thanks. Report sent for review.'),
                            ),
                          );
                        } else if (action == 'Save') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved for later.')),
                          );
                        } else if (action == 'Comment') {
                          _openCommentsSheet(selectedPost);
                        }
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _filteredPosts.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 1,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search alerts, locations, or updates',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _ProtocolCard({
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Text(
                'Community protocols',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                color: AppTheme.textMuted(context),
                onPressed: onToggle,
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            _ProtocolLine(text: 'Posts must be location-based.'),
            _ProtocolLine(text: 'Add a category and severity.'),
            _ProtocolLine(text: 'No spam, politics, or unrelated posts.'),
            _ProtocolLine(text: 'Verified updates are reviewed by authorities.'),
          ],
        ],
      ),
    );
  }
}

class _ProtocolLine extends StatelessWidget {
  final String text;

  const _ProtocolLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppTheme.primaryNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.textMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const filters = ['Nearby', 'Verified', 'High Priority', 'All'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = filters[index];
          final selectedChip = label == selected;
          return ChoiceChip(
            label: Text(label),
            selected: selectedChip,
            onSelected: (_) => onSelect(label),
            selectedColor: AppTheme.primaryNavy.withOpacity(0.12),
            labelStyle: TextStyle(
              color: selectedChip
                  ? AppTheme.primaryNavy
                  : AppTheme.textMuted(context),
              fontWeight: selectedChip ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _CommunityPost post;
  final void Function(String, _CommunityPost) onAction;

  const _PostCard({
    required this.post,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.border(context),
                  child: Text(
                    post.authorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      Text(
                        post.authorRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    post.timeAgo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => onAction(value, post),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Save', child: Text('Save')),
                    PopupMenuItem(value: 'Report', child: Text('Report')),
                  ],
                  icon: const Icon(Icons.more_vert, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _TypePill(type: post.type),
                _SeverityPill(severity: post.severity),
                _CategoryPill(category: post.category),
                if (post.verified) const _VerifiedPill(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.description,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.textMuted(context),
              ),
            ),
            if (post.imageBytes != null || post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: post.imageBytes != null
                    ? Image.memory(
                        post.imageBytes!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        post.imageUrl!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaChip(
                  icon: Icons.place_outlined,
                  label: '${post.location} • ${post.distanceKm} km',
                ),
                _MetaChip(
                  icon: Icons.timer_outlined,
                  label: post.timeAgo,
                ),
                _MetaChip(
                  icon: Icons.local_offer_outlined,
                  label: post.id,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  label: post.upvotes.toString(),
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: post.comments.toString(),
                  onTap: () => onAction('Comment', post),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.flag_outlined,
                  label: 'Report',
                  onTap: () => onAction('Report', post),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      color: AppTheme.primaryNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final PostType type;

  const _TypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: type.color,
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String severity;

  const _SeverityPill({required this.severity});

  Color get _color {
    switch (severity) {
      case 'High':
        return const Color(0xFFDC2626);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;

  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted(context),
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified, size: 14, color: AppTheme.primaryNavy),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppTheme.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppTheme.primaryNavy),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryNavy,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.primaryNavy.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ComposerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _ComposerField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor: AppTheme.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppTheme.primaryNavy,
              AppTheme.purpleAccent,
              AppTheme.tealAccent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityPost {
  final String id;
  final PostType type;
  final String authorName;
  final String authorRole;
  final String title;
  final String description;
  final String location;
  final String timeAgo;
  final double distanceKm;
  final String category;
  final String severity;
  final bool verified;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final int upvotes;
  final int comments;
  final List<_Comment> commentsData;

  const _CommunityPost({
    required this.id,
    required this.type,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.distanceKm,
    required this.category,
    required this.severity,
    required this.verified,
    required this.imageUrl,
    required this.imageBytes,
    required this.upvotes,
    required this.comments,
    required this.commentsData,
  });

  _CommunityPost copyWith({
    int? comments,
    List<_Comment>? commentsData,
  }) {
    return _CommunityPost(
      id: id,
      type: type,
      authorName: authorName,
      authorRole: authorRole,
      title: title,
      description: description,
      location: location,
      timeAgo: timeAgo,
      distanceKm: distanceKm,
      category: category,
      severity: severity,
      verified: verified,
      imageUrl: imageUrl,
      imageBytes: imageBytes,
      upvotes: upvotes,
      comments: comments ?? this.comments,
      commentsData: commentsData ?? this.commentsData,
    );
  }
}

enum PostType {
  alert('Alert', Color(0xFFDC2626)),
  update('Update', Color(0xFF2563EB)),
  tip('Community Tip', Color(0xFF16A34A)),
  help('Help Request', Color(0xFFF59E0B)),
  notice('Notice', Color(0xFF6366F1));

  final String label;
  final Color color;

  const PostType(this.label, this.color);
}

class _Comment {
  final String author;
  final String role;
  final String message;
  final String timeAgo;

  const _Comment({
    required this.author,
    required this.role,
    required this.message,
    required this.timeAgo,
  });
}

class _CommentTile extends StatelessWidget {
  final _Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.border(context),
          child: Text(
            comment.author.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.role,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      comment.timeAgo,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.message,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
