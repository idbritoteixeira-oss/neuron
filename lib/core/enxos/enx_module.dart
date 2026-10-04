enum EnxModule {
  inasx(
    title: 'Inasx',
    id: 'inasxId',
    description: 'Crypto Currency Inasx',
  ),
  pigeon(
    title: 'Pigeon',
    id: 'pigeonId',
    description: 'Media Outlet Pigeon',
  ),
  freemarket(
    title: 'FreeMarket',
    id: 'freeId',
    description: 'Central Financial Market FreeMarket',
  );

  const EnxModule({
    required this.title,
    required this.id,
    required this.description,
  });

  final String title;
  final String id;
  final String description;
}