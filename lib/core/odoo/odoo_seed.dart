class SeedCustomer {
  final String ref;
  final String name;
  final String email;
  final String phone;
  final String street;
  final String city;

  const SeedCustomer(this.ref, this.name, this.email, this.phone, this.street, this.city);
}

class SeedProduct {
  final String code;
  final String name;
  final double price;

  const SeedProduct(this.code, this.name, this.price);
}

class SeedOrderLine {
  final String productCode;
  final double quantity;

  const SeedOrderLine(this.productCode, this.quantity);
}

class SeedOrder {
  final String ref;
  final String customerRef;
  final List<SeedOrderLine> lines;
  final bool confirm;

  const SeedOrder(this.ref, this.customerRef, this.lines, {this.confirm = false});
}

class OdooSeed {
  OdooSeed._();

  static const refPrefix = 'SEED-';

  static const customers = <SeedCustomer>[
    SeedCustomer(
      'SEED-01',
      'Ahmed El-Sayed',
      'ahmed.elsayed@example.com',
      '+20 100 123 4567',
      '15 El-Horreya St, Heliopolis',
      'Cairo',
    ),
    SeedCustomer(
      'SEED-02',
      'Nouran Mansour',
      'nouran.mansour@example.com',
      '+20 111 987 6543',
      '22 Ahmed Orabi St, Mohandessin',
      'Giza',
    ),
    SeedCustomer(
      'SEED-03',
      'Kareem Hassan',
      'kareem.hassan@example.com',
      '+20 122 345 6789',
      '45 Stanley Corniche',
      'Alexandria',
    ),
    SeedCustomer(
      'SEED-04',
      'Farida Shawky',
      'farida.shawky@example.com',
      '+20 106 555 8899',
      '88 Road 9, Maadi',
      'Cairo',
    ),
    SeedCustomer(
      'SEED-05',
      'Mahmoud El-Gohary',
      'mahmoud.gohary@example.com',
      '+20 115 444 3322',
      '12 El-Gomhoureya St',
      'Mansoura',
    ),
    SeedCustomer(
      'SEED-06',
      'Salma Zaki',
      'salma.zaki@example.com',
      '+20 109 876 5432',
      'Villa 4B, Fifth Settlement',
      'New Cairo',
    ),
    SeedCustomer('SEED-07', 'Mostafa Hegazy', 'mostafa.hegazy@example.com', '+20 128 777 6655', 'El-Bahr St', 'Tanta'),
    SeedCustomer(
      'SEED-08',
      'Yasmine Radwan',
      'yasmine.radwan@example.com',
      '+20 101 223 3445',
      'Beverly Hills, Gate 2',
      'Sheikh Zayed',
    ),
    SeedCustomer('SEED-09', 'Omar Fathy', 'omar.fathy@example.com', '+20 112 668 9001', '7 Port Said St', 'Port Said'),
    SeedCustomer(
      'SEED-10',
      'Mariam Adel',
      'mariam.adel@example.com',
      '+20 127 330 1188',
      '31 Salah Salem St',
      'Assiut',
    ),
    SeedCustomer(
      'SEED-11',
      'Youssef Nabil',
      'youssef.nabil@example.com',
      '+20 100 902 7744',
      '19 El-Geish St',
      'Ismailia',
    ),
    SeedCustomer(
      'SEED-12',
      'Habiba Samir',
      'habiba.samir@example.com',
      '+20 114 551 2090',
      '3 Corniche El-Nil',
      'Luxor',
    ),
  ];

  static const products = <SeedProduct>[
    SeedProduct('SEED-P01', 'Cotton Lounge Set', 650),
    SeedProduct('SEED-P02', 'Fleece Robe', 550),
    SeedProduct('SEED-P03', 'Velvet Pajama Set', 750),
    SeedProduct('SEED-P04', 'Satin Kimono', 900),
    SeedProduct('SEED-P05', 'Kids Winter Set', 450),
    SeedProduct('SEED-P06', 'Linen Lounge Pants', 350),
  ];

  static const orders = <SeedOrder>[
    SeedOrder('SEED-SO-01', 'SEED-01', [SeedOrderLine('SEED-P01', 2), SeedOrderLine('SEED-P02', 1)], confirm: true),
    SeedOrder('SEED-SO-02', 'SEED-02', [SeedOrderLine('SEED-P03', 2), SeedOrderLine('SEED-P04', 1)], confirm: true),
    SeedOrder('SEED-SO-03', 'SEED-03', [SeedOrderLine('SEED-P05', 4)], confirm: true),
    SeedOrder('SEED-SO-04', 'SEED-04', [SeedOrderLine('SEED-P05', 4), SeedOrderLine('SEED-P06', 4)]),
    SeedOrder('SEED-SO-05', 'SEED-05', [SeedOrderLine('SEED-P02', 1)]),
    SeedOrder('SEED-SO-06', 'SEED-06', [SeedOrderLine('SEED-P04', 2), SeedOrderLine('SEED-P01', 1)]),
    SeedOrder('SEED-SO-07', 'SEED-07', [SeedOrderLine('SEED-P06', 3)]),
    SeedOrder('SEED-SO-08', 'SEED-08', [SeedOrderLine('SEED-P03', 1), SeedOrderLine('SEED-P05', 2)]),
    SeedOrder('SEED-SO-09', 'SEED-09', [SeedOrderLine('SEED-P01', 3)]),
    SeedOrder('SEED-SO-10', 'SEED-10', [SeedOrderLine('SEED-P02', 2), SeedOrderLine('SEED-P06', 2)]),
  ];

  static const portalUserName = 'Seed Portal Customer';
  static const portalUserLogin = 'portal@example.com';

  static const legacyPortalUserLogin = 'portal.seed@2stask.test';

  static const demoUserName = 'Demo Sales User';
  static const demoUserLogin = 'demo@example.com';

  static const demoOrders = <SeedOrder>[
    SeedOrder('SEED-DEMO-01', 'SEED-11', [SeedOrderLine('SEED-P01', 1), SeedOrderLine('SEED-P06', 2)]),
    SeedOrder('SEED-DEMO-02', 'SEED-12', [SeedOrderLine('SEED-P04', 1)]),
    SeedOrder('SEED-DEMO-03', 'SEED-01', [SeedOrderLine('SEED-P03', 3)]),
    SeedOrder('SEED-DEMO-04', 'SEED-06', [SeedOrderLine('SEED-P05', 2), SeedOrderLine('SEED-P02', 1)]),
    SeedOrder('SEED-DEMO-05', 'SEED-08', [SeedOrderLine('SEED-P06', 5)]),
    SeedOrder('SEED-DEMO-06', 'SEED-02', [SeedOrderLine('SEED-P01', 2), SeedOrderLine('SEED-P04', 1)]),
  ];

  static const portalCustomer = SeedCustomer(
    'SEED-PORTAL',
    portalUserName,
    portalUserLogin,
    '+20 100 555 1234',
    '10 Tahrir Square, Downtown',
    'Cairo',
  );

  static const portalOrders = <SeedOrder>[
    SeedOrder('SEED-PORTAL-01', 'SEED-PORTAL', [SeedOrderLine('SEED-P02', 1)], confirm: true),
    SeedOrder('SEED-PORTAL-02', 'SEED-PORTAL', [SeedOrderLine('SEED-P03', 1), SeedOrderLine('SEED-P05', 1)]),
  ];
}
