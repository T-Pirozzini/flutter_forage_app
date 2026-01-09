import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/services/location_service.dart';
import 'dart:async';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.onPlaceSelected});
  final Function(Map<String, dynamic> place) onPlaceSelected;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
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
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = [];
                        _isLoading = false;
                      });
                    },
                  ),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          try {
                            if (_searchController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter a city name')),
                              );
                              return;
                            }
                            setState(() => _isLoading = true);
                            final place = await LocationService()
                                .getPlace(_searchController.text);
                            setState(() => _isLoading = false);
                            if (place.isNotEmpty) {
                              widget.onPlaceSelected.call(place);
                              setState(() => _suggestions = []);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('No place found for your search')),
                              );
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                            String message = 'Error searching for place';
                            if (e.toString().contains('Place ID not found')) {
                              message =
                                  'No place found for "${_searchController.text}"';
                            } else if (e.toString().contains('network')) {
                              message =
                                  'Network error. Please check your connection.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                        },
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () async {
              if (value.isNotEmpty) {
                setState(() => _isLoading = true);
                final suggestions =
                    await LocationService().getPlaceSuggestions(value);
                setState(() {
                  _suggestions = suggestions;
                  _isLoading = false;
                });
              } else {
                setState(() {
                  _suggestions = [];
                  _isLoading = false;
                });
              }
            });
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            color: Colors.white,
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(suggestion['description'] ?? 'Unknown'),
                  onTap: () async {
                    try {
                      setState(() => _isLoading = true);
                      final place = await LocationService()
                          .getPlace(suggestion['place_id']);
                      setState(() => _isLoading = false);
                      if (place.isNotEmpty) {
                        widget.onPlaceSelected.call(place);
                        _searchController.text =
                            suggestion['description'] ?? '';
                        setState(() => _suggestions = []);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Unable to fetch place details')),
                        );
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
