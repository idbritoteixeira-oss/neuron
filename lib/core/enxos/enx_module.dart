enum EnxModule {
  inasx(
    title: 'Inasx',
    abbreviation: 'inx',
    brandColorValue: 0xFF6F7175,
    id: 'inasxId',
    description: 'Crypto Currency Inasx',
  ),
  pigeon(
    title: 'Pigeon',
    abbreviation: 'pru',
    brandColorValue: 0xFF5AB31E,
    id: 'pigeonId',
    description: 'Media Outlet Pigeon',
  ),
  freemarket(
    title: 'FreeMarket',
    abbreviation: 'fre',
    brandColorValue: 0xFFB3611E,
    id: 'freeId',
    description: 'Central Financial Market FreeMarket',
  );

  const EnxModule({
    required this.title,
    required this.abbreviation,
    required this.brandColorValue,
    required this.id,
    required this.description,
  });

  final String title;
  final String abbreviation;
  final int brandColorValue;
  final String id;
  final String description;
}

typedef EnxosLauncherCallback = Future<void> Function(EnxModule? target);