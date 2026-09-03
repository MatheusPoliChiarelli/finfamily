import 'package:flutter/material.dart';

import '../data/fashion.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/product_dialog.dart';

class ViseVersaScreen extends StatefulWidget {
  const ViseVersaScreen({super.key, required this.fs});

  final FirestoreService fs;

  @override
  State<ViseVersaScreen> createState() => _ViseVersaScreenState();
}

class _ViseVersaScreenState extends State<ViseVersaScreen> {
  bool _showSoldOut = false;

  Future<void> _newProduct() async {
    final product = await showProductDialog(context);
    if (product != null) await widget.fs.addProduct(product);
  }

   Future<void> _sell(Product product) async {
    final result = await showSellPieceDialog(context, product);
    if (result != null) {
      await widget.fs.registerSale(product.id, product.sold, product.revenue, result.$1, result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: widget.fs.products(),
      builder: (context, snap) {
        final all = snap.data ?? const <Product>[];
        final inStock = all.where((p) => !p.soldOut).toList();
        final soldOut = all.where((p) => p.soldOut).toList();

        final stockValue = inStock.fold<double>(0, (s, p) => s + p.stockValue);
        final revenue = all.fold<double>(0, (s, p) => s + p.revenue);
        final profit = all.fold<double>(0, (s, p) => s + p.profit);
        final unitsInStock = inStock.fold<int>(0, (s, p) => s + p.stock);
        final unitsSold = all.fold<int>(0, (s, p) => s + p.sold);
        final avgMargin = all.isEmpty
            ? 0.0
            : all.fold<double>(0, (s, p) => s + p.margin) / all.length;

        final list = _showSoldOut ? soldOut : inStock;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vise Versa', style: AppTheme.display(34)),
                      const SizedBox(height: 2),
                      Text('Estoque e vendas de roupas', style: AppTheme.ui(12, color: AppColors.textMuted)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: _newProduct,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nova peça'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _metric('Valor em estoque', money(stockValue), AppColors.accent, Icons.inventory_2_outlined)),
                  const SizedBox(width: 14),
                  Expanded(child: _metric('Faturamento', money(revenue), AppColors.income, Icons.point_of_sale_outlined)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _metric(
                      'Lucro realizado',
                      money(profit),
                      profit >= 0 ? AppColors.income : AppColors.expense,
                      Icons.trending_up,
                      borderColor: unitsSold == 0 ? null : (profit >= 0 ? AppColors.income : AppColors.expense),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _metric('Valor investido', money(all.fold<double>(0, (s, p) => s + p.invested)), AppColors.textPrimary, Icons.shopping_bag_outlined)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _miniStat('Peças em estoque', '$unitsInStock')),
                  const SizedBox(width: 14),
                  Expanded(child: _miniStat('Peças vendidas', '$unitsSold')),
                  const SizedBox(width: 14),
                  Expanded(child: _miniStat('Modelos cadastrados', '${all.length}')),
                  const SizedBox(width: 14),
                  Expanded(child: _miniStat('Margem média', all.isEmpty ? '--' : '${avgMargin.toStringAsFixed(1)}%')),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _tab('Em estoque', '${inStock.length}', !_showSoldOut, () => setState(() => _showSoldOut = false)),
                  const SizedBox(width: 10),
                  _tab('Vendidas', '${soldOut.length}', _showSoldOut, () => setState(() => _showSoldOut = true)),
                ],
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    ),
                  ),
                )
              else if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      _showSoldOut ? 'Nenhuma peça vendida ainda' : 'Nenhuma peça em estoque',
                      style: AppTheme.ui(13, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 1250
                        ? 3
                        : constraints.maxWidth > 850
                            ? 2
                            : 1;
                    const gap = 14.0;
                    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: list.map((p) => SizedBox(width: width, child: _productCard(p))).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _productCard(Product p) {
    final type = PieceTypes.byId(p.type);
    final statusColor = p.soldOut ? AppColors.income : AppColors.accent;
    final progress = p.quantity == 0 ? 0.0 : p.sold / p.quantity;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.soldOut ? statusColor.withValues(alpha: 0.4) : AppColors.border,
          width: p.soldOut ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(type.icon, size: 20, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTheme.ui(16, weight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      '${type.name} · comprado em ${fullDate(p.purchaseDate)}',
                      style: AppTheme.ui(11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${p.sold} de ${p.quantity} vendidas',
                          style: AppTheme.ui(11, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          p.soldOut ? 'Vendida' : '${p.stock} em estoque',
                          style: AppTheme.ui(11, color: statusColor, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.surfaceRaised,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _stat('Custo unitário', money(p.unitCost), null)),
              Expanded(
                child: _stat(
                  'Preço médio de venda',
                  p.sold == 0 ? '--' : money(p.avgSalePrice),
                  null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _stat('Investido', money(p.invested), AppColors.accent)),
              Expanded(
                child: _stat(
                  'Lucro',
                  p.sold == 0 ? '--' : '${money(p.profit)}   ${p.margin.toStringAsFixed(0)}%',
                  p.profit > 0 ? AppColors.income : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (!p.soldOut)
                _smallButton('Vender', Icons.sell_outlined, AppColors.income, () => _sell(p))
              else
                _smallButton('Reabrir', Icons.undo, AppColors.textSecondary, () => widget.fs.reopenProduct(p.id)),
              const Spacer(),
              InkWell(
                onTap: () => widget.fs.deleteProduct(p.id),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, String count, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.ui(
                13,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                weight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            Text(count, style: AppTheme.uiMoney(12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.ui(11, color: AppColors.textMuted)),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppTheme.uiMoney(14, color: color, weight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _smallButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
            Text(label, style: AppTheme.ui(12, color: color, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color, IconData icon, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border, width: borderColor != null ? 1 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.ui(16, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTheme.displayMoney(26, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.ui(12, color: AppColors.accent))),
          Text(value, style: AppTheme.uiMoney(13, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}