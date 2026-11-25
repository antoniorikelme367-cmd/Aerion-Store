import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart.dart';
import 'cart_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadTheme();
  runApp(const AerionApp());
}

// ───────────────────────── Design tokens ─────────────────────────
const kAccent = Color(0xFFFF5A1F);

/// Tema atual do app. Começa seguindo o sistema e muda pelo botão do cabeçalho.
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
const _kThemeKey = 'theme_mode';

/// Lê a preferência salva (sistema, claro ou escuro). Chamada uma vez no início do app.
Future<void> loadTheme() async {
  try {
    final v = (await SharedPreferences.getInstance()).getString(_kThemeKey);
    themeMode.value = ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
  } catch (_) {}
}

/// Define o tema (ThemeMode.system, .light ou .dark) e salva a escolha.
Future<void> setTheme(ThemeMode m) async {
  themeMode.value = m;
  try {
    await (await SharedPreferences.getInstance()).setString(_kThemeKey, m.name);
  } catch (_) {}
}

/// Alterna entre claro e escuro a partir do que está na tela agora.
void toggleTheme(BuildContext c) =>
    setTheme(Theme.of(c).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

class Tk {
  final Color bg, surface, ink, mute, line, dark;
  const Tk(this.bg, this.surface, this.ink, this.mute, this.line, this.dark);
  static const light = Tk(Color(0xFFEEF0F2), Colors.white, Color(0xFF14171A),
      Color(0xFF5D6670), Color(0xFFDDE1E5), Color(0xFF14171A));
  static const night = Tk(Color(0xFF101315), Color(0xFF1A1E22), Color(0xFFF1F3F5),
      Color(0xFF98A2AD), Color(0xFF2B3138), Color(0xFF1A1E22));
  static Tk of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? night : light;
}

class AerionApp extends StatelessWidget {
  const AerionApp({super.key});

  ThemeData _theme(Brightness b) {
    final k = b == Brightness.dark ? Tk.night : Tk.light;
    final base = ThemeData(brightness: b, useMaterial3: true, colorSchemeSeed: kAccent);
    return base.copyWith(
      scaffoldBackgroundColor: k.bg,
      textTheme: GoogleFonts.soraTextTheme(base.textTheme)
          .apply(bodyColor: k.ink, displayColor: k.ink),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeMode,
        builder: (_, mode, __) => MaterialApp(
          title: 'Aerion — Loja de Drones',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const Home(),
        ),
      );
}

// ───────────────────────── Dados ─────────────────────────
class Drone {
  final String name, sub, price, badge, img;
  final bool contain; // foto com fundo branco
  final double day; // preço do aluguel por dia
  final double val; // preço de compra
  const Drone(this.name, this.sub, this.price, this.badge, this.img, this.contain, this.day, this.val);
}

const drones = [
  Drone('Aerion Air 3', 'Câmera dupla, 46 min', 'R\$ 5.290', 'Novo', 'assets/images/air.jpg', false, 180, 5290),
  Drone('Aerion Mini 4', '249 g, 4K HDR', 'R\$ 3.890', '', 'assets/images/mini.jpg', false, 120, 3890),
  Drone('Aerion FPV Rush', 'Voo imersivo, 4K', 'R\$ 4.150', '-15%', 'assets/images/fpv.jpg', true, 150, 4150),
  Drone('Aerion Agro 20', 'Pulverização, 20 L', 'R\$ 18.900', '', 'assets/images/agro.jpg', true, 650, 18900),
];

// (nome, dias, desconto, unidade)
const periods = [
  ('Diária', 1, 0.0, 'dias'),
  ('Semanal', 7, 0.15, 'semanas'),
  ('Mensal', 30, 0.35, 'meses'),
];

// ───────────────────────── Helpers ─────────────────────────
String mo(num v) {
  final p = v.toStringAsFixed(2).split('.');
  final i = p[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return 'R\$ $i,${p[1]}';
}

String two(int n) => n.toString().padLeft(2, '0');

void toast(BuildContext c, String m, {String? label, VoidCallback? onAction}) {
  final s = ScaffoldMessenger.of(c);
  s.hideCurrentSnackBar();
  s.showSnackBar(SnackBar(
    content: Text(m),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 3000),
    action: label == null ? null : SnackBarAction(label: label, onPressed: onAction ?? () {}),
  ));
}

ButtonStyle pill(Color bg, Color fg, {Color? line}) => FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      shape: StadiumBorder(side: line == null ? BorderSide.none : BorderSide(color: line)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );

class Shell extends StatelessWidget {
  final Widget child;
  const Shell({required this.child, super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child),
        ),
      );
}

class Grid extends StatelessWidget {
  final List<Widget> kids;
  final int wide, mid, small;
  final double gap;
  const Grid(this.kids, {this.wide = 4, this.mid = 2, this.small = 1, this.gap = 16, super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, bc) {
        final w = bc.maxWidth;
        final n = w >= 960 ? wide : (w >= 520 ? mid : small);
        final cw = (w - gap * (n - 1)) / n;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final k in kids) SizedBox(width: cw, child: k),
        ]);
      });
}

Widget logo(Tk k) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('Aerion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.4, color: k.ink)),
    ]);

Widget head(Tk k, String t, {Widget? trail}) => Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(t, style: const TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w600, letterSpacing: -1)),
          ),
        ),
        if (trail != null) ...[const SizedBox(width: 16), trail],
      ]),
    );

BoxDecoration card(Tk k, {double r = 24}) => BoxDecoration(
      color: k.surface,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: k.line),
    );

Widget photo(Drone d, Tk k, {double? h}) => Container(
      height: h,
      width: double.infinity,
      color: d.contain ? Colors.white : k.bg,
      padding: EdgeInsets.all(d.contain ? 10 : 0),
      child: Image.asset(d.img, fit: d.contain ? BoxFit.contain : BoxFit.cover),
    );

// ───────────────────────── Página ─────────────────────────
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final sc = ScrollController();
  final em = TextEditingController();
  final kCat = GlobalKey(), kProd = GlobalKey(), kRent = GlobalKey(), kBan = GlobalKey(), kRev = GlobalKey();

  @override
  void dispose() {
    sc.dispose();
    em.dispose();
    super.dispose();
  }

  void go(GlobalKey k) {
    final c = k.currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void add(CartItem it) {
    cart.add(it);
    toast(context, '${it.title} adicionado ao carrinho', label: 'Ver carrinho', onAction: () => openCart(context));
  }

  Widget sect(GlobalKey? key, Widget child) =>
      Padding(key: key, padding: const EdgeInsets.symmetric(vertical: 44), child: child);

  @override
  Widget build(BuildContext context) {
    final k = Tk.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          header(k),
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              child: Column(children: [
                Shell(
                  child: Column(children: [
                    hero(k),
                    sect(kCat, cats(k)),
                    sect(kProd, prods(k)),
                    sect(kRent, Rental(k)),
                    sect(kBan, banner(k)),
                    sect(kRev, reviews(k)),
                    sect(null, news(k)),
                  ]),
                ),
                footer(k),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Cabeçalho
  Widget navLink(String t, GlobalKey key, Tk k) => TextButton(
        onPressed: () => go(key),
        child: Text(t, style: TextStyle(color: k.mute, fontSize: 14)),
      );

  Widget header(Tk k) => Container(
        decoration: BoxDecoration(color: k.bg, border: Border(bottom: BorderSide(color: k.line))),
        child: Shell(
          child: SizedBox(
            height: 68,
            child: LayoutBuilder(builder: (c, bc) {
              final wide = bc.maxWidth >= 900; // abaixo disso o menu de links estoura a largura
              return Row(children: [
                logo(k),
                if (wide) ...[
                  const SizedBox(width: 32),
                  navLink('Categorias', kCat, k),
                  navLink('Produtos', kProd, k),
                  navLink('Aluguel', kRent, k),
                  navLink('Destaque', kBan, k),
                  navLink('Avaliações', kRev, k),
                ],
                const Spacer(),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeMode,
                  builder: (_, mode, __) {
                    const ops = [
                      (ThemeMode.system, 'Automático', Icons.brightness_auto_outlined),
                      (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
                      (ThemeMode.dark, 'Escuro', Icons.dark_mode_outlined),
                    ];
                    return GestureDetector(
                      onDoubleTap: () => toggleTheme(c), // atalho: duplo toque alterna claro/escuro
                      child: PopupMenuButton<ThemeMode>(
                        tooltip: 'Tema',
                        initialValue: mode,
                        onSelected: setTheme,
                        icon: Icon(ops.firstWhere((o) => o.$1 == mode).$3, color: k.ink),
                        itemBuilder: (_) => [
                          for (final o in ops)
                            PopupMenuItem(
                              value: o.$1,
                              child: Row(children: [
                                Icon(o.$3, size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(o.$2)),
                                if (o.$1 == mode) const Icon(Icons.check, size: 18, color: kAccent),
                              ]),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ListenableBuilder(
                    listenable: cart,
                    builder: (_, __) => Badge(
                      isLabelVisible: cart.count > 0,
                      label: Text('${cart.count}'),
                      backgroundColor: k.ink,
                      textColor: k.bg,
                      child: FilledButton(
                        style: pill(Colors.transparent, k.ink, line: k.line),
                        onPressed: () => openCart(context),
                        child: const Text('Carrinho'),
                      ),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
      );

  // ── Hero
  Widget tag(String a, String b, Tk k) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: k.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(a, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(b, style: TextStyle(fontSize: 13, color: k.mute)),
        ]),
      );

  Widget hero(Tk k) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: LayoutBuilder(builder: (c, bc) {
          final wide = bc.maxWidth >= 900;
          final fs = (bc.maxWidth * (wide ? 0.055 : 0.12)).clamp(40.0, 72.0).toDouble();
          final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voe mais alto. Grave em 4K.',
                style: TextStyle(fontSize: fs, height: 1.02, fontWeight: FontWeight.w600, letterSpacing: -fs * 0.04)),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text('Drones para quem filma, mapeia e explora. Entrega em todo o Brasil e 12 meses de garantia.',
                  style: TextStyle(color: k.mute, height: 1.6)),
            ),
            const SizedBox(height: 32),
            Wrap(spacing: 12, runSpacing: 12, children: [
              FilledButton(style: pill(kAccent, Colors.white), onPressed: () => go(kProd), child: const Text('Comprar agora')),
              FilledButton(style: pill(Colors.transparent, k.ink, line: k.line), onPressed: () => go(kBan), child: const Text('Ver o Aerion X1')),
            ]),
          ]);
          final stage = AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), border: Border.all(color: k.line)),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/images/mini.jpg', fit: BoxFit.cover),
                Positioned(left: 20, bottom: 24, child: tag('46 min', 'de voo', k)),
                Positioned(right: 20, top: 24, child: tag('8 km', 'de alcance', k)),
              ]),
            ),
          );
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: left), const SizedBox(width: 40), Expanded(child: stage)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 40), stage]);
        }),
      );

  // ── Categorias
  Widget cats(Tk k) {
    final items = [
      ('Câmera e cinema', '24 modelos', drones[0]),
      ('Corrida FPV', '18 modelos', drones[2]),
      ('Agro e mapeamento', '9 modelos', drones[3]),
      ('Baterias e acessórios', '40 itens', drones[1]),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head(k, 'Escolha pelo seu tipo de voo',
          trail: FilledButton(style: pill(Colors.transparent, k.ink, line: k.line), onPressed: () => go(kProd), child: const Text('Ver todos'))),
      Grid([
        for (final i in items)
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => go(kProd),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: card(k),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: photo(i.$3, k, h: 150)),
                const SizedBox(height: 16),
                Text(i.$2, style: TextStyle(color: k.mute, fontSize: 14)),
                const SizedBox(height: 4),
                Text(i.$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ]),
    ]);
  }

  // ── Produtos
  Widget prods(Tk k) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        head(k, 'Mais vendidos da semana'),
        Grid(gap: 20, [for (final d in drones) prodCard(d, k)]),
      ]);

  Widget prodCard(Drone d, Tk k) => Container(
        padding: const EdgeInsets.all(16),
        decoration: card(k),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 1 / 0.9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(fit: StackFit.expand, children: [
                photo(d, k),
                if (d.badge.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(99)),
                      child: Text(d.badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(d.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(d.sub, style: TextStyle(color: k.mute, fontSize: 13))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(d.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: k.ink, foregroundColor: k.bg),
                tooltip: 'Adicionar ${d.name}',
                onPressed: () => add(CartItem(id: d.name, title: d.name, sub: d.sub, img: d.img, contain: d.contain, price: d.val)),
                icon: const Icon(Icons.add),
              ),
            ]),
          ),
        ]),
      );

  // ── Banner de destaque
  Widget banner(Tk k) => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: k.dark, borderRadius: BorderRadius.circular(36)),
        child: LayoutBuilder(builder: (c, bc) {
          final wide = bc.maxWidth >= 800;
          const soft = Color(0xFFAAB3BC);
          final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Aerion X1 Pro',
                style: TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w600, letterSpacing: -1, color: Color(0xFFF3F5F7))),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const Text('Sensor de 1 polegada, gimbal de 3 eixos e detecção de obstáculos em todas as direções.',
                  style: TextStyle(color: soft, height: 1.6)),
            ),
            const SizedBox(height: 28),
            FilledButton(style: pill(kAccent, Colors.white), onPressed: () => add(CartItem(id: 'x1', title: 'Aerion X1 Pro', sub: '5.4K, 46 min', img: 'assets/images/air.jpg', price: 7490)), child: const Text('Adicionar por R\$ 7.490')),
          ]);
          Widget spec(String v, String l) => Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF384049)))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -1, color: Color(0xFFF3F5F7))),
                  Text(l, style: const TextStyle(fontSize: 13, color: soft)),
                ]),
              );
          final right = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(height: 220, width: double.infinity, child: Image.asset('assets/images/air.jpg', fit: BoxFit.cover)),
            ),
            const SizedBox(height: 20),
            Grid(gap: 20, wide: 2, mid: 2, small: 2, [
              spec('5.4K', 'Vídeo a 60 fps'),
              spec('46 min', 'Autonomia de voo'),
              spec('249 g', 'Sem registro obrigatório'),
              spec('8 km', 'Transmissão em HD'),
            ]),
          ]);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: left), const SizedBox(width: 32), Expanded(child: right)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 32), right]);
        }),
      );

  // ── Avaliações
  Widget reviews(Tk k) {
    const r = [
      ('Chegou em dois dias e o voo de estreia foi perfeito. A imagem é de outro nível.', 'Marina, fotógrafa'),
      ('Uso no mapeamento de lavouras. A bateria dura o que promete.', 'Carlos, engenheiro agrônomo'),
      ('Suporte rápido e troca sem burocracia quando precisei.', 'Rafael, piloto FPV'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head(k, 'Quem já voa com a gente'),
      Grid(gap: 20, wide: 3, mid: 1, [
        for (final i in r)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: card(k),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.$1, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 20),
              Text(i.$2, style: TextStyle(color: k.mute, fontSize: 14)),
            ]),
          ),
      ]),
    ]);
  }

  // ── Newsletter
  Widget news(Tk k) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(36)),
        child: Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const Text('Receba ofertas antes de todo mundo',
                style: TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w600, letterSpacing: -1, color: Colors.white)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: em,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF14171A)),
                  decoration: InputDecoration(
                    hintText: 'Seu melhor e-mail',
                    hintStyle: const TextStyle(color: Color(0xFF5D6670)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: pill(const Color(0xFF14171A), Colors.white),
                onPressed: () {
                  if (!em.text.contains('@')) {
                    toast(context, 'Digite um e-mail válido');
                    return;
                  }
                  em.clear();
                  toast(context, 'Inscrição confirmada');
                },
                child: const Text('Assinar'),
              ),
            ]),
          ),
        ]),
      );

  // ── Rodapé
  Widget footer(Tk k) {
    Widget col(String t, List<String> l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final x in l) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(x, style: TextStyle(color: k.mute, fontSize: 14))),
        ]);
    return Container(
      margin: const EdgeInsets.only(top: 56),
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: k.line))),
      child: Shell(
        child: Grid(gap: 32, wide: 4, mid: 2, small: 2, [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            logo(k),
            const SizedBox(height: 12),
            Text('Drones e acessórios com garantia e suporte em português.', style: TextStyle(color: k.mute, fontSize: 14)),
          ]),
          col('Loja', ['Drones', 'Acessórios', 'Ofertas']),
          col('Ajuda', ['Entrega', 'Garantia', 'Contato']),
          col('Empresa', ['Sobre', 'Blog', 'Privacidade']),
        ]),
      ),
    );
  }
}

// ───────────────────────── Aluguel ─────────────────────────
class Rental extends StatefulWidget {
  final Tk k;
  const Rental(this.k, {super.key});
  @override
  State<Rental> createState() => _RentalState();
}

class _RentalState extends State<Rental> {
  int ri = 0, pi = 0, q = 1;
  DateTime? date;

  Tk get k => widget.k;

  Future<void> pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => date = d);
  }

  Widget opt(int i) {
    final d = drones[i];
    final on = i == ri;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => ri = i),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? kAccent : k.line, width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: photo(d, k, h: 110)),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(d.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          Padding(padding: const EdgeInsets.fromLTRB(4, 2, 4, 4), child: Text('${mo(d.day)} por dia', style: TextStyle(fontSize: 13, color: k.mute))),
        ]),
      ),
    );
  }

  Widget lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: TextStyle(fontSize: 13, color: k.mute)));

  Widget stepBtn(IconData ic, VoidCallback f) => SizedBox(
        width: 38,
        height: 38,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder(), side: BorderSide(color: k.line), foregroundColor: k.ink),
          onPressed: f,
          child: Icon(ic, size: 18),
        ),
      );

  Widget summary() {
    final d = drones[ri];
    final p = periods[pi];
    final days = p.$2 * q;
    final full = d.day * days;
    final total = full * (1 - p.$3);
    final unit = p.$4;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: card(k, r: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        lbl('Período'),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(99)),
          child: Row(children: [
            for (var i = 0; i < periods.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    pi = i;
                    q = 1;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: i == pi ? k.ink : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      periods[i].$1 + (periods[i].$3 > 0 ? ' −${(periods[i].$3 * 100).round()}%' : ''),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: i == pi ? k.bg : k.mute),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        lbl('Quantidade de $unit'),
        Row(children: [
          stepBtn(Icons.remove, () => setState(() => q = q > 1 ? q - 1 : 1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$q', style: const TextStyle(fontWeight: FontWeight.w700))),
          stepBtn(Icons.add, () => setState(() => q = q < 12 ? q + 1 : 12)),
        ]),
        const SizedBox(height: 18),
        lbl('Data de retirada'),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: k.line)),
            child: Row(children: [
              Expanded(child: Text(date == null ? 'Selecionar data' : '${two(date!.day)}/${two(date!.month)}/${date!.year}', style: TextStyle(color: date == null ? k.mute : k.ink))),
              Icon(Icons.calendar_today_outlined, size: 18, color: k.mute),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Divider(color: k.line, height: 1),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$days ${days > 1 ? 'dias' : 'dia'} de aluguel', style: TextStyle(fontSize: 13, color: k.mute)),
              Text(p.$3 > 0 ? 'Você economiza ${mo(full - total)}' : 'Escolha semanal ou mensal para pagar menos', style: TextStyle(fontSize: 13, color: k.mute)),
            ]),
          ),
          const SizedBox(width: 12),
          Text(mo(total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1)),
        ]),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: pill(kAccent, Colors.white),
            onPressed: () {
              if (date == null) {
                toast(context, 'Escolha a data de retirada');
                return;
              }
              final ds = '${two(date!.day)}/${two(date!.month)}/${date!.year}';
              cart.add(CartItem(
                id: 'rent-${d.name}-${p.$1}-$q-$ds',
                title: 'Aluguel · ${d.name}',
                sub: '${p.$1} × $q · retirada em $ds',
                img: d.img,
                contain: d.contain,
                price: total,
                rental: true,
              ));
              toast(context, 'Aluguel adicionado ao carrinho', label: 'Ver carrinho', onAction: () => openCart(context));
            },
            child: const Text('Reservar aluguel'),
          ),
        ),
        const SizedBox(height: 12),
        Text('Caução reembolsável de 20% na retirada. Seguro contra danos incluso.', style: TextStyle(fontSize: 12, color: k.mute)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pick = Grid(gap: 12, wide: 2, mid: 2, small: 2, [for (var i = 0; i < drones.length; i++) opt(i)]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      head(k, 'Alugue um drone para o seu projeto'),
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text('Sem investir no equipamento. Escolha o modelo, o período e a data de retirada.', style: TextStyle(color: k.mute)),
      ),
      LayoutBuilder(builder: (c, bc) {
        if (bc.maxWidth >= 900) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 14, child: pick),
            const SizedBox(width: 20),
            Expanded(flex: 10, child: summary()),
          ]);
        }
        return Column(children: [pick, const SizedBox(height: 20), summary()]);
      }),
    ]);
  }
}
