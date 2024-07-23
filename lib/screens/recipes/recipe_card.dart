import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/recipe.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;

  const RecipeCard({required this.recipe});

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.recipe.imageUrls.isNotEmpty
        ? (widget.recipe.imageUrls.length - 1) ~/ 2
        : 0;
    _pageController =
        PageController(viewportFraction: 0.6, initialPage: _currentPage);

    // Force a rebuild to ensure images are visible initially
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _nextPage() {
    if (_currentPage < widget.recipe.imageUrls.length - 1) {
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.recipe.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (var ingredient in widget.recipe.ingredients)
              Text('- $ingredient'),
            SizedBox(height: 10),
            if (widget.recipe.imageUrls.isNotEmpty)
              Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.recipe.imageUrls.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 0;
                              if (_pageController.position.haveDimensions) {
                                value = index - _pageController.page!;
                                value =
                                    (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                              }
                              return Center(
                                child: SizedBox(
                                  height:
                                      Curves.easeInOut.transform(value) * 200,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                widget.recipe.imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                  height: 100,
                  child: Center(child: Text('No images available.'))),
            SizedBox(height: 10),
            ExpansionTile(
              title: Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              expandedAlignment: Alignment.topLeft,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var step in widget.recipe.steps.asMap().entries)
                  Text('${step.key + 1}. ${step.value}'),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Submitted by: ${widget.recipe.userEmail}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(
              'Submitted by: ${widget.recipe.userName}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(
              'Timestamp: ${widget.recipe.timestamp}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
