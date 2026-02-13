class MenuCategoryEntity {
  final String id;
  final String name;
  final int itemCount;

  const MenuCategoryEntity({
    required this.id,
    required this.name,
    this.itemCount = 0,
  });
}
