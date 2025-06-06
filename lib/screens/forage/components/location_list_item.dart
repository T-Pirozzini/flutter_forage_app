import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:intl/intl.dart';

class LocationListItem extends StatelessWidget {
  final MarkerModel marker;
  final VoidCallback onTap;
  final ValueChanged<bool>? onBookmark;
  final bool isBookmarked;

  const LocationListItem({
    Key? key,
    required this.marker,
    required this.onTap,
    this.onBookmark,
    required this.isBookmarked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePreview(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                marker.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onBookmark != null)
                              IconButton(
                                icon: Icon(
                                  isBookmarked 
                                    ? Icons.bookmark 
                                    : Icons.bookmark_border,
                                  color: isBookmarked 
                                    ? Colors.amber 
                                    : Colors.grey,
                                ),
                                onPressed: () => onBookmark!(!isBookmarked),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          marker.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildLocationInfo(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTypeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: marker.imageUrls.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: marker.imageUrls.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[400]!),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            )
          : Center(
              child: Icon(
                Icons.photo,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          '${marker.latitude.toStringAsFixed(4)}, ${marker.longitude.toStringAsFixed(4)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const Spacer(),
        Text(
          DateFormat('MMM dd, yyyy').format(marker.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIndicator() {
    final color = _getTypeColor(marker.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageIcon(
            AssetImage(
              'lib/assets/images/${marker.type.toLowerCase()}_marker.png',
            ),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            marker.type,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
        return Colors.purpleAccent;
      case 'mushrooms':
        return Colors.orangeAccent;
      case 'nuts':
        return Colors.brown;
      case 'herbs':
        return Colors.lightGreen;
      case 'tree':
        return Colors.green;
      case 'fish':
        return Colors.blue;
      default:
        return Colors.deepOrangeAccent;
    }
  }
}
