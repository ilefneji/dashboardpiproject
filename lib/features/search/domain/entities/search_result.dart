class SearchResult {
  final String id;
  final String title;
  final String description;
  final String type; // organization, project, task, etc.
  final String route; // Route to navigate to when clicked

  SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.route,
  });
}
