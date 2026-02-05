import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/services/location_service.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'dart:async';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onPlaceSelected,
    this.onFocusChanged,
  });
  final Function(Map<String, dynamic> place) onPlaceSelected;
  final Function(bool isFocused)? onFocusChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _dismissKeyboard() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.1),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: _isFocused ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
              controller: _searchController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 16.0,
                ),
                hintText: 'Search location...',
                hintStyle: TextStyle(
                  color: AppTheme.textMedium.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: _isFocused ? AppTheme.primary : AppTheme.textMedium,
                    size: 22,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.textMedium,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = [];
                            _isLoading = false;
                          });
                        },
                      ),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () => _performSearch(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
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
              onFieldSubmitted: (_) => _performSearch(),
            ),
        ),

        // Suggestions Dropdown - larger when focused for better visibility
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    title: Text(
                      suggestion['description'] ?? 'Unknown',
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a location'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final place = await LocationService().getPlace(_searchController.text);
      setState(() => _isLoading = false);

      if (place.isNotEmpty) {
        _dismissKeyboard();
        widget.onPlaceSelected.call(place);
        setState(() => _suggestions = []);
      } else {
        _showError('No place found for your search');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String message = 'Error searching for place';
      if (e.toString().contains('Place ID not found')) {
        message = 'No place found for "${_searchController.text}"';
      } else if (e.toString().contains('network')) {
        message = 'Network error. Please check your connection.';
      }
      _showError(message);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    // Dismiss keyboard immediately when tapping a suggestion
    _dismissKeyboard();

    try {
      setState(() => _isLoading = true);
      final description = suggestion['description'] ?? '';
      final place = await LocationService().getPlace(description);
      setState(() => _isLoading = false);

      if (place.isNotEmpty) {
        widget.onPlaceSelected.call(place);
        _searchController.text = description;
        setState(() => _suggestions = []);
      } else {
        _showError('Unable to fetch place details');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
