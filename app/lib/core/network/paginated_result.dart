class PaginatedResult<T> {
  const PaginatedResult({required this.data, required this.page, required this.pageSize, required this.total, required this.totalPages});

  factory PaginatedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResult(
      data: (json['data'] as List<dynamic>).map((item) => fromJson(item as Map<String, dynamic>)).toList(),
      page: meta['page'] as int? ?? 1,
      pageSize: meta['pageSize'] as int? ?? 20,
      total: meta['total'] as int? ?? 0,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  final List<T> data;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}
