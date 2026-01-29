/// Model for shellfish species found in Nanaimo, BC
class ShellfishSpecies {
  final String name;
  final String scientificName;
  final String description;
  final String minSize; // Minimum size range
  final String maxSize; // Maximum size range
  final String legalLimit; // Legal size limit in cm
  final int dailyLimit; // Daily harvest limit
  final String season; // Best harvest season
  final String imageAsset;

  const ShellfishSpecies({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.minSize,
    required this.maxSize,
    required this.legalLimit,
    required this.dailyLimit,
    required this.season,
    required this.imageAsset,
  });
}

/// Shellfish species commonly found in Nanaimo, BC waters
class NanaimoShellfish {
  static const List<ShellfishSpecies> species = [
    ShellfishSpecies(
      name: 'Pacific Oyster',
      scientificName: 'Crassostrea gigas',
      description:
          'Large, irregularly shaped shells. Found attached to rocks and other hard surfaces in intertidal zones.',
      minSize: '7 cm',
      maxSize: '30 cm',
      legalLimit: '8 cm',
      dailyLimit: 12,
      season: 'Year-round (best in winter)',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Manila Clam',
      scientificName: 'Venerupis philippinarum',
      description:
          'Oval shell with radiating ridges. Buried 5-10cm deep in sandy or muddy beaches.',
      minSize: '3 cm',
      maxSize: '8 cm',
      legalLimit: '3.8 cm',
      dailyLimit: 75,
      season: 'Year-round',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Littleneck Clam',
      scientificName: 'Leukoma staminea',
      description:
          'Rounded shell with fine radiating ridges. Found 10-15cm deep in gravel or sandy beaches.',
      minSize: '4 cm',
      maxSize: '10 cm',
      legalLimit: '4.0 cm',
      dailyLimit: 75,
      season: 'Year-round',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Butter Clam',
      scientificName: 'Saxidomus gigantea',
      description:
          'Large, heavy shell with concentric growth rings. Burrows 20-40cm deep in gravel beaches.',
      minSize: '5 cm',
      maxSize: '13 cm',
      legalLimit: '7.5 cm',
      dailyLimit: 40,
      season: 'Year-round (best in winter)',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Horse Clam',
      scientificName: 'Tresus nuttallii',
      description:
          'Very large clam with long siphon. Burrows deep (60cm+) in sandy/muddy beaches.',
      minSize: '8 cm',
      maxSize: '20 cm',
      legalLimit: '9.0 cm',
      dailyLimit: 12,
      season: 'Year-round',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Blue Mussel',
      scientificName: 'Mytilus edulis',
      description:
          'Dark blue-black elongated shell. Forms clusters on rocks, pilings, and floats.',
      minSize: '2 cm',
      maxSize: '10 cm',
      legalLimit: '4.0 cm',
      dailyLimit: 75,
      season: 'Year-round (best Nov-Apr)',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Geoduck',
      scientificName: 'Panopea generosa',
      description:
          'Largest burrowing clam with massive siphon. Can weigh over 1kg. Buried very deep (1m+).',
      minSize: '10 cm',
      maxSize: '20 cm',
      legalLimit: 'License required',
      dailyLimit: 3,
      season: 'Year-round (license required)',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
    ShellfishSpecies(
      name: 'Cockle',
      scientificName: 'Clinocardium nuttallii',
      description:
          'Heart-shaped shell with prominent radiating ribs. Found shallow in sand/gravel.',
      minSize: '3 cm',
      maxSize: '10 cm',
      legalLimit: '5.5 cm',
      dailyLimit: 75,
      season: 'Year-round',
      imageAsset: 'lib/assets/images/shellfish_marker.png',
    ),
  ];
}
