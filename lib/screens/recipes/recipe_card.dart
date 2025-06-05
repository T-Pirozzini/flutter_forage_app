import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/recipe.dart';
import 'package:flutter_forager_app/screens/recipes/comments_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/recipe_background.webp'),
                fit: BoxFit.cover,
                opacity: 0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StyledHeadingLarge(
                      widget.recipe.name,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StyledTextLarge(
                      'Submitted by: ${widget.recipe.userName}',
                    ),
                    Text(
                      '${DateFormat.yMMMd().format(widget.recipe.timestamp)}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                StyledTextLarge(
                  'Ingredients:',
                ),
                for (var ingredient in widget.recipe.ingredients)
                  Row(
                    children: [
                      Icon(
                        ingredient.isForaged ? Icons.eco : Icons.shopping_cart,
                        color:
                            ingredient.isForaged ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: 5),
                      StyledHeadingSmall(
                        '${ingredient.quantity} ${ingredient.name}',
                      ),
                    ],
                  ),
                SizedBox(height: 10),
                if (widget.recipe.imageUrls.isNotEmpty)
                  widget.recipe.imageUrls.length == 1
                      ? Center(
                          child: Image.network(
                            widget.recipe.imageUrls.first,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Stack(
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
                                        if (_pageController
                                            .position.haveDimensions) {
                                          value = index - _pageController.page!;
                                          value = (1 - (value.abs() * 0.3))
                                              .clamp(0.0, 1.0);
                                        }
                                        return Center(
                                          child: SizedBox(
                                            height: Curves.easeInOut
                                                    .transform(value) *
                                                200,
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
                    style: GoogleFonts.josefinSans(
                      fontSize: 20,
                    ),
                  ),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var step in widget.recipe.steps.asMap().entries)
                      Text('${step.key + 1}. ${step.value}'),
                  ],
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CommentsPage(recipe: widget.recipe),
                        ),
                      );
                    },
                    icon: Icon(Icons.comment),
                    label:
                        Text('View Comments', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
