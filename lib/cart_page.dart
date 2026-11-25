import 'package:flutter/material.dart';
import 'cart.dart';
import 'checkout_page.dart';

String _money(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

void openCart(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CartPage()));
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seu carrinho')),
        body: ListenableBuilder(
          listenable: cart,
          builder: (context, _) {
            if (cart.items.isEmpty) {
              return const Center(child: Text('Seu carrinho está vazio.'));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final item in cart.items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(item.img, width: 76, height: 76, fit: item.contain ? BoxFit.contain : BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 76, height: 76, child: Icon(Icons.image_not_supported_outlined))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(item.sub),
                          Text(_money(item.price), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ])),
                        IconButton(onPressed: () => cart.setQuantity(item, item.quantity - 1), icon: const Icon(Icons.remove)),
                        Text('${item.quantity}'),
                        IconButton(onPressed: () => cart.setQuantity(item, item.quantity + 1), icon: const Icon(Icons.add)),
                        IconButton(tooltip: 'Remover', onPressed: () => cart.remove(item), icon: const Icon(Icons.delete_outline)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: Text('Total: ${_money(cart.total)}', style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CheckoutPage())),
                  child: const Text('Continuar para o checkout'),
                ),
              ],
            );
          },
        ),
      );
}
