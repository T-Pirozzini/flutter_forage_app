import 'package:flutter/material.dart';
import 'package:flutter_forager_app/services/location_service.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.onPlaceSelected});
  final Function(Map<String, dynamic> place) onPlaceSelected;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _searchController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        hintText: 'Search by City',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Colors.grey.shade600,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Colors.grey.shade800,
            width: 2.0,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: () async {
            var place =
                await LocationService().getPlace(_searchController.text);
            widget.onPlaceSelected.call(place);
          },
          icon: const Icon(Icons.search),
        ),
      ),
      onChanged: (value) {},
    );
  }
}
