import 'package:flutter/material.dart';
import 'cart.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Finalizar pedido')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text('Dados para entrega', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nome completo'), validator: _required),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail'), keyboardType: TextInputType.emailAddress,
                validator: (value) => value != null && value.contains('@') ? null : 'Digite um e-mail válido'),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Endereço'), validator: _required),
            const SizedBox(height: 24),
            Text('Total do pedido: R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                cart.clear();
                showDialog<void>(context: context, builder: (context) => AlertDialog(
                  title: const Text('Pedido recebido'),
                  content: const Text('Seus dados foram registrados para este pedido.'),
                  actions: [TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Concluir'))],
                ));
              },
              child: const Text('Confirmar pedido'),
            ),
          ]),
        ),
      );

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Preencha este campo' : null;
}
