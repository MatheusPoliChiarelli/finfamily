import 'package:flutter/material.dart';

import '../models/car.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/car_dialogs.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key, required this.fs});

  final FirestoreService fs;

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  bool _showSold = false;
  final _expanded = <String>{};

  Future<void> _newCar() async {
    final car = await showCarDialog(context);
    if (car != null) await widget.fs.addCar(car);
  }

  Future<void> _addCost(Car car) async {
    final cost = await showCostDialog(context);
    if (cost != null) await widget.fs.updateCosts(car.id, [...car.costs, cost]);
  }

  Future<void> _removeCost(Car car, CarCost cost) async {
    await widget.fs.updateCosts(car.id, car.costs.where((c) => c.id != cost.id).toList());
  }

  Future<void> _sell(Car car) async {
    final result = await showSellDialog(context, car);
    if (result != null) await widget.fs.sellCar(car.id, result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Car>>(
      stream: widget.fs.cars(),
      builder: (context, snap) {
        final all = snap.data ?? const <Car>[];
        final active = all.where((c) => !c.isSold).toList();
        final sold = all.where((c) => c.isSold).toList()
          ..sort((a, b) => b.saleDate!.compareTo(a.saleDate!));

        final capital = active.fold<double>(0, (s, c) => s + c.totalInvested);
        final realized = sold.fold<double>(0, (s, c) => s + c.profit);
        final avgMargin = sold.isEmpty
            ? 0.0
            : sold.fold<double>(0, (s, c) => s + c.margin) / sold.length;
        final avgDays = sold.isEmpty
            ? 0
            : (sold.fold<int>(0, (s, c) => s + c.daysHeld) / sold.length).round();

        final list = _showSold ? sold : active;

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
                      Text('RobMotors', style: AppTheme.display(34)),
                      const SizedBox(height: 2),
                      Text(
                        'Compra e venda de veículos',
                        style: AppTheme.ui(12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: _newCar,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Novo carro'),
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
                  Expanded(child: _metric('Capital em estoque', money(capital), AppColors.accent, Icons.inventory_2_outlined)),
                  const SizedBox(width: 14),
                  Expanded(child: _metric('Carros ativos', '${active.length}', AppColors.textPrimary, Icons.directions_car_outlined)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _metric(
                      'Lucro realizado',
                      money(realized),
                      realized >= 0 ? AppColors.income : AppColors.expense,
                      Icons.trending_up,
                      borderColor: sold.isEmpty ? null : (realized >= 0 ? AppColors.income : AppColors.expense),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _metric(
                      'Margem média',
                      sold.isEmpty ? '--' : '${avgMargin.toStringAsFixed(1)}%',
                      avgMargin >= 0 ? AppColors.income : AppColors.expense,
                      Icons.percent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _miniStat('Carros vendidos', '${sold.length}')),
                  const SizedBox(width: 14),
                  Expanded(child: _miniStat('Tempo médio até a venda', sold.isEmpty ? '--' : '$avgDays dias')),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _miniStat(
                      'Custos em carros ativos',
                      money(active.fold<double>(0, (s, c) => s + c.totalCosts)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _tab('Ativos', '${active.length}', !_showSold, () => setState(() => _showSold = false)),
                  const SizedBox(width: 10),
                  _tab('Vendidos', '${sold.length}', _showSold, () => setState(() => _showSold = true)),
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
                      _showSold ? 'Nenhum carro vendido ainda' : 'Nenhum carro no estoque',
                      style: AppTheme.ui(13, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 1150 ? 2 : 1;
                    const gap = 14.0;
                    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: list
                          .map((c) => SizedBox(width: width, child: _carCard(c)))
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
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

  Widget _carCard(Car car) {
    final open = _expanded.contains(car.id);
    final statusColor = car.isSold
        ? (car.profit >= 0 ? AppColors.income : AppColors.expense)
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: car.isSold ? statusColor.withValues(alpha: 0.4) : AppColors.border,
          width: car.isSold ? 1 : 0.5,
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
                child: Icon(Icons.directions_car_outlined, size: 20, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(car.name, style: AppTheme.ui(16, weight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (car.plate.isNotEmpty) car.plate,
                        if (car.year.isNotEmpty) car.year,
                        'comprado em ${dayLabel(car.purchaseDate)}',
                      ].join(' · '),
                      style: AppTheme.ui(11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Text(
                  car.isSold ? 'Vendido' : '${car.daysHeld} dias em estoque',
                  style: AppTheme.ui(11, color: statusColor, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _stat('Compra', money(car.purchasePrice), null)),
              Expanded(child: _stat('Custos', money(car.totalCosts), null)),
              Expanded(child: _stat('Investido', money(car.totalInvested), AppColors.accent)),
              if (car.isSold) ...[
                Expanded(child: _stat('Venda', money(car.salePrice!), null)),
                Expanded(
                  child: _stat(
                    'Lucro',
                    '${money(car.profit)}  ${car.margin >= 0 ? '+' : ''}${car.margin.toStringAsFixed(1)}%',
                    statusColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => open ? _expanded.remove(car.id) : _expanded.add(car.id)),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        open ? Icons.expand_less : Icons.expand_more,
                        size: 17,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${car.costs.length} ${car.costs.length == 1 ? 'custo' : 'custos'}',
                        style: AppTheme.ui(12, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (!car.isSold) ...[
                _smallButton('Custo', Icons.add, AppColors.textSecondary, () => _addCost(car)),
                const SizedBox(width: 8),
                _smallButton('Vender', Icons.sell_outlined, AppColors.income, () => _sell(car)),
              ] else
                _smallButton('Reabrir', Icons.undo, AppColors.textSecondary, () => widget.fs.reopenCar(car.id)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => widget.fs.deleteCar(car.id),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          if (open) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 20),
            if (car.costs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Nenhum custo lançado neste carro',
                  style: AppTheme.ui(12, color: AppColors.textMuted),
                ),
              )
            else
              ...car.costs.map((cost) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        const Icon(Icons.build_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(cost.description, style: AppTheme.ui(13)),
                        ),
                        Text(dayLabel(cost.date), style: AppTheme.ui(11, color: AppColors.textMuted)),
                        const SizedBox(width: 14),
                        Text(money(cost.amount), style: AppTheme.uiMoney(13)),
                        if (!car.isSold) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _removeCost(car, cost),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.close, size: 13, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
          ],
        ],
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
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.ui(14, color: AppColors.accent)),
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