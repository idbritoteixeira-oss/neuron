enum EnxModule {
  inasx(
    title: 'Inasx',
    id: 'id_inx',
    description: 'Espaço operacional Inasx',
  ),
  pigeon(
    title: 'Pigeon',
    id: 'id_pru',
    description: 'Espaço operacional Pigeon',
  ),
  freemarket(
    title: 'FreeMarket',
    id: 'id_fmk',
    description: 'Espaço operacional FreeMarket',
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