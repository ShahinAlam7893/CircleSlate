
class Contact {
  final String id; // Numeric ID for API (e.g., "31")
  final String name;
  final String description;
  final String imageUrl;
  final bool isOnline;

  const Contact({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isOnline = false,
  });
}